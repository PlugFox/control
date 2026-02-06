import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:control/src/mutex.dart';
import 'package:meta/meta.dart';

/// Droppable controller concurrency handler.
///
/// This mixin drops new operations if one is already running.
/// When an operation is in progress, new calls to [handle] return immediately
/// without executing the handler.
///
/// Example:
/// ```dart
/// class MyController extends StateController<MyState>
///     with DroppableControllerHandler {
///   void operation1() => handle(() async { ... });
///   void operation2() => handle(() async { ... });
///   // If operation1 is running, operation2 is dropped
/// }
/// ```
mixin DroppableControllerHandler on Controller {
  final Mutex _$mutex = Mutex();

  @override
  bool get isProcessing => _$mutex.locked;

  /// Handles a given operation with droppable behavior.
  ///
  /// If an operation is already running, the new one is dropped.
  @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
    String? name,
    Map<String, Object?>? meta,
  }) {
    // If already locked, drop this operation
    if (_$mutex.locked) return Future<void>.value(null);

    return _$mutex.synchronize(
      () => super.handle(
        handler,
        error: error,
        done: done,
        name: name,
        meta: meta,
      ),
    );
  }
}
