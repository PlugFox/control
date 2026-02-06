import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:control/src/mutex.dart';
import 'package:meta/meta.dart';

/// Sequential controller concurrency handler.
///
/// This mixin ensures that all operations execute sequentially (one at a time)
/// by wrapping the base [Controller.handle] method with a [Mutex].
///
/// Example:
/// ```dart
/// class MyController extends StateController<MyState>
///     with SequentialControllerHandler {
///   void operation1() => handle(() async { ... });
///   void operation2() => handle(() async { ... });
///   // Operations execute one after another, never in parallel
/// }
/// ```
mixin SequentialControllerHandler on Controller {
  final Mutex _$mutex = Mutex();

  @override
  bool get isProcessing => _$mutex.locked;

  /// Handles a given operation sequentially.
  ///
  /// Operations are queued and executed one at a time.
  @override
  @protected
  @mustCallSuper
  Future<T?> handle<T>(
    Future<T> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
    String? name,
    Map<String, Object?>? meta,
  }) => _$mutex.synchronize<T?>(
    () => super.handle<T>(
      handler,
      error: error,
      done: done,
      name: name,
      meta: meta,
    ),
  );
}
