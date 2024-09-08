import 'dart:async';

import 'package:control/control.dart';
import 'package:control/src/core/registry.dart';
import 'package:flutter/foundation.dart'
    show ChangeNotifier, Listenable, VoidCallback;
import 'package:meta/meta.dart';

/// The interface for controllers responsible for processing logic,
/// connecting widgets, and managing data layers.
///
/// This interface defines the core functionality that all controllers
/// should implement. It extends [Listenable] to allow widgets to listen
/// for changes in the controller's state.
@internal
abstract interface class IController implements Listenable {
  /// Handles invocation in the controller.
  ///
  /// Depending on the implementation, the handler may be executed
  /// sequentially, concurrently, or dropped when busy.
  ///
  /// See:
  ///  - [ConcurrentControllerHandler] - handler that executes concurrently
  ///  - [SequentialControllerHandler] - handler that executes sequentially
  ///  - [DroppableControllerHandler] - handler that drops the request when busy
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? onError,
    Future<void> Function()? onDone,
  });

  /// Whether the controller has been permanently disposed.
  bool get isDisposed;

  /// Whether the controller is currently processing an operation.
  bool get isProcessing;

  /// Discards any resources used by the object.
  ///
  /// This method should only be called by the object's owner.
  void dispose();
}

/// Observer interface for monitoring controller lifecycle and state changes.
abstract interface class IControllerObserver {
  /// Called when a controller is created.
  void onCreate(Controller controller);

  /// Called when a controller is disposed.
  void onDispose(Controller controller);

  /// Called on any state change in a [StateController].
  void onStateChanged<S extends Object>(
      StateController<S> controller, S prevState, S nextState);

  /// Called on any error in a controller.
  void onError(Controller controller, Object error, StackTrace stackTrace);
}

/// {@template controller}
/// The base class for controllers responsible for processing logic,
/// connecting widgets, and managing data layers.
///
/// This class provides core functionality for state management and
/// lifecycle handling. It implements [ChangeNotifier] to allow widgets
/// to listen for changes in the controller's state.
/// {@endtemplate}
abstract base class Controller with ChangeNotifier implements IController {
  /// {@macro controller}
  Controller() {
    ControllerRegistry().insert<Controller>(this);
    _runSafely(() => observer?.onCreate(this));
  }

  /// Global observer for all controllers.
  ///
  /// This can be set to monitor the lifecycle and state changes of all
  /// controllers.
  static IControllerObserver? observer;

  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  int _subscribers = 0;

  /// The number of subscribers listening to the controller.
  int get subscribers => _subscribers;

  /// Error handling callback.
  ///
  /// This method is called when an error occurs in the controller.
  /// It can be overridden to provide custom error handling.
  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) =>
      _runSafely(() => observer?.onError(this, error, stackTrace));

  @protected
  @nonVirtual
  @override
  void notifyListeners() {
    if (isDisposed) {
      assert(
        false,
        'A $runtimeType called notifyListeners after being disposed.',
      );
      return;
    }
    super.notifyListeners();
  }

  @override
  @mustCallSuper
  void addListener(VoidCallback listener) {
    if (isDisposed) {
      assert(
        false,
        'A $runtimeType called addListener after being disposed.',
      );
      return;
    }
    super.addListener(listener);
    _subscribers++;
  }

  @override
  @mustCallSuper
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!isDisposed) _subscribers--;
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) {
      assert(false, 'A $runtimeType has been disposed multiple times.');
      return;
    }
    _isDisposed = true;
    _subscribers = 0;

    ControllerRegistry().remove<Controller>();

    _runSafely(() {
      observer?.onDispose(this);
    });
    super.dispose();
  }

  void _runSafely(void Function() handler) {
    runZonedGuarded(
      handler,
      (error, stackTrace) {/* ignore */},
    );
  }
}
