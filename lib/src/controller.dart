import 'dart:async';

import 'package:control/src/handler_context.dart';
import 'package:control/src/registry.dart';
import 'package:control/src/state_controller.dart';
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

  /// Handles invocation in the controller.
  ///
  /// Depending on the implementation, the handler may be executed
  /// sequentially, concurrently, dropped and etc.
  ///
  /// The [name] parameter is used to identify the handler.
  /// The [context] parameter is used to pass additional
  /// information to the handler's zone.
  ///
  /// See:
  ///  - [ConcurrentControllerHandler] - handler that executes concurrently
  ///  - [SequentialControllerHandler] - handler that executes sequentially
  ///  - [DroppableControllerHandler] - handler that drops the request when busy
  void handle(
    Future<void> Function() handler, {
    String? name,
    Map<String, Object?>? context,
  });
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
      (error, stackTrace) {/* ignore */}, // coverage:ignore-line
    );
  }

  /// Get the handler's context from the current zone.
  static HandlerContext? getContext(Controller controller) =>
      HandlerContext.zoned();

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
        (error, stackTrace) {/* ignore */}, // coverage:ignore-line
      );

  @protected
  @override
  Future<void> handle(
    Future<void> Function() handler, {
    String? name,
    Map<String, Object?>? context,
  });

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
      (error, stackTrace) {/* ignore */}, // coverage:ignore-line
    );
    ControllerRegistry().remove<Controller>();
    super.dispose();
  }
}
