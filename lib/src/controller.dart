import 'dart:async';

import 'package:control/control.dart';
import 'package:control/src/registry.dart';
import 'package:flutter/foundation.dart'
    show ChangeNotifier, Listenable, VoidCallback;
import 'package:meta/meta.dart';

/// The controller responsible for processing the logic,
/// the connection of widgets and the date of the layer.
///
/// Do not implement this interface directly, instead extend [Controller].
@internal
abstract interface class IController implements Listenable {
  /// Whether the controller is permanently disposed
  bool get isDisposed;

  /// The number of subscribers to the controller
  int get subscribers;

  /// Whether any listeners are currently registered.
  bool get hasListeners;

  /// Whether the controller is currently handling a requests
  bool get isProcessing;

  /// A future that completes when the controller is done processing.
  Future<void> get done;

  /// Discards any resources used by the object.
  ///
  /// This method should only be called by the object's owner.
  void dispose();

  /// Handles request in the controller.
  ///
  /// Depending on the implementation, the handler may be executed
  /// sequentially, concurrently, dropped and etc.
  /// See [ConcurrentControllerHandler], [SequentialControllerHandler],
  /// [DroppableControllerHandler] for more details.
  void handle(Future<void> Function() handler);
}

/// Controller observer
abstract interface class IControllerObserver {
  /// Called when the controller is created.
  void onCreate(Controller controller);

  /// Called when the controller is disposed.
  void onDispose(Controller controller);

  /// Called on any state change in the controller.
  void onStateChanged<S extends Object>(
      StateController<S> controller, S prevState, S nextState);

  /// Called on any error in the controller.
  void onError(Controller controller, Object error, StackTrace stackTrace);
}

/// {@template controller}
/// The controller responsible for processing the logic,
/// the connection of widgets and the date of the layer.
/// {@endtemplate}
abstract base class Controller with ChangeNotifier implements IController {
  /// {@macro controller}
  Controller() {
    ControllerRegistry().insert<Controller>(this);
    runZonedGuarded<void>(
      () => Controller.observer?.onCreate(this),
      (error, stackTrace) {/* ignore */},
    );
  }

  /// Controller observer
  static IControllerObserver? observer;

  /// Return a [Listenable] that triggers when any of the given [Listenable]s
  /// themselves trigger.
  static Listenable merge(Iterable<Listenable?> listenables) =>
      Listenable.merge(
        List<Listenable>.unmodifiable(listenables.whereType<Listenable>()),
      );

  @override
  bool get isDisposed => _$isDisposed;
  bool _$isDisposed = false;

  @override
  int get subscribers => _$subscribers;
  int _$subscribers = 0;

  /// Error handling callback
  @protected
  void onError(Object error, StackTrace stackTrace) => runZonedGuarded<void>(
        () => Controller.observer?.onError(this, error, stackTrace),
        (error, stackTrace) {/* ignore */},
      );

  @protected
  @override
  Future<void> handle(Future<void> Function() handler);

  @protected
  @nonVirtual
  @override
  void notifyListeners() {
    if (isDisposed) {
      assert(false, 'A $runtimeType was already disposed.');
      return;
    }
    super.notifyListeners();
  }

  @override
  @mustCallSuper
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      assert(false, 'A $runtimeType was already disposed.');
      return;
    }
    super.addListener(listener);
    _$subscribers++;
  }

  @override
  @mustCallSuper
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (isDisposed) return;
    _$subscribers--;
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_$isDisposed) {
      assert(false, 'A $runtimeType was already disposed.');
      return;
    }
    _$isDisposed = true;
    _$subscribers = 0;
    runZonedGuarded<void>(
      () => Controller.observer?.onDispose(this),
      (error, stackTrace) {/* ignore */},
    );
    ControllerRegistry().remove<Controller>();
    super.dispose();
  }
}
