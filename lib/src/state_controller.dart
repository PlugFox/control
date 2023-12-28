import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// State controller
///
/// Do not implement this interface directly, instead extend [StateController].
///
/// {@nodoc}
@internal
abstract interface class IStateController<S extends Object>
    implements IController {
  /// The current state of the controller.
  S get state;
}

/// State controller
abstract base class StateController<S extends Object> extends Controller
    with _StateControllerShortcutsMixin<S>
    implements IStateController<S> {
  /// State controller
  StateController({required S initialState}) : _$state = initialState;

  @override
  @nonVirtual
  S get state => _$state;
  S _$state;

  /// Emit a new state, usually based on [state] and some additional logic.
  @protected
  @nonVirtual
  void setState(S state) {
    runZonedGuarded<void>(
      () => Controller.observer?.onStateChanged(this, _$state, state),
      (error, stackTrace) {/* ignore */},
    );
    _$state = state;
    if (isDisposed) return;
    notifyListeners();
  }
}

/// {@nodoc}
base mixin _StateControllerShortcutsMixin<S extends Object> on Controller
    implements IStateController<S> {
  late final List<StreamController<S>> _$streamControllers =
      <StreamController<S>>[];

  /// Returns a [ValueListenable] view of this controller's state.
  ValueListenable<S> toValueListenable() =>
      _StateController$ValueListenableView<S>(this);

  /// Returns a [Stream] of state changes.
  Stream<S> toStream() {
    final controller = StreamController<S>(sync: true);
    _$streamControllers.add(controller);
    void listener() => controller.add(state);
    addListener(listener);
    controller.onCancel = () {
      _$streamControllers.remove(controller);
      if (isDisposed) return;
      removeListener(listener);
    };
    return controller.stream;
  }

  @override
  void dispose() {
    for (final controller in _$streamControllers) controller.close();
    _$streamControllers.length = 0;
    super.dispose();
  }
}

final class _StateController$ValueListenableView<S extends Object>
    implements ValueListenable<S> {
  _StateController$ValueListenableView(this._controller);

  final IStateController<S> _controller;

  @override
  S get value => _controller.state;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);
}
