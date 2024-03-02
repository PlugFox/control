import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Selector from [StateController]
typedef StateControllerSelector<S extends Object, Value> = Value Function(
    S state);

/// Filter for [StateController]
typedef StateControllerFilter<Value> = bool Function(Value prev, Value next);

/// State controller
///
/// Do not implement this interface directly, instead extend [StateController].
///
@internal
abstract interface class IStateController<S extends Object>
    implements IController {
  /// The current state of the controller.
  S get state;
}

/// State controller
abstract base class StateController<S extends Object> extends Controller
    implements IStateController<S> {
  /// State controller
  StateController({required S initialState}) : _$state = initialState;

  @override
  @nonVirtual
  S get state => _$state;
  S _$state;

  /// Emit a new state, usually based on [state] and some additional logic.
  @protected
  @mustCallSuper
  void setState(S state) {
    runZonedGuarded<void>(
      () => Controller.observer?.onStateChanged(this, _$state, state),
      (error, stackTrace) {/* ignore */},
    );
    _$state = state;
    if (isDisposed) return;
    notifyListeners();
  }

  // --- Helper --- //

  late final List<StreamController<S>> _$streamControllers =
      <StreamController<S>>[];

  /// Returns a [ValueListenable] view of this controller's state.
  ValueListenable<S> toValueListenable() =>
      _StateController$ValueListenableView<S>(this);

  /// Returns a [Stream] of state changes.
  Stream<S> toStream() {
    final controller = StreamController<S>();
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

  /// Transform [StateController] in to [ValueListenable]
  /// using [selector] with optional [test] filter.
  ///
  /// The [selector] is called with the current [StateController] and
  /// returns a value derived from [StateController.state].
  ValueListenable<Value> select<Value>(
    StateControllerSelector<S, Value> selector, [
    StateControllerFilter<Value>? test,
  ]) =>
      _StateController$ValueListenableSelect<S, Value>(this, selector, test);

  @override
  void dispose() {
    for (final controller in _$streamControllers) controller.close();
    _$streamControllers.length = 0;
    scheduleMicrotask(() {});
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

final class _StateController$ValueListenableSelect<S extends Object, Value>
    with ChangeNotifier
    implements ValueListenable<Value> {
  _StateController$ValueListenableSelect(
    this._controller,
    this._selector,
    this._test,
  );

  final IStateController<S> _controller;
  final StateControllerSelector<S, Value> _selector;
  final StateControllerFilter<Value>? _test;
  bool get _isDisposed => _controller.isDisposed;
  bool _subscribed = false;

  late Value _$value = _selector(_controller.state);

  @override
  Value get value =>
      _subscribed ? _$value : _$value = _selector(_controller.state);

  void _update() {
    final newValue = _selector(_controller.state);
    if (identical(_$value, newValue)) return;
    if (!(_test?.call(_$value, newValue) ?? true)) return;
    _$value = newValue;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) return;
    if (!_subscribed) {
      _$value = _selector(_controller.state);
      _controller.addListener(_update);
      _subscribed = true;
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_isDisposed) return;
    if (!hasListeners && _subscribed) {
      _controller.removeListener(_update);
      _subscribed = false;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _subscribed = false;
    super.dispose();
  }
}
