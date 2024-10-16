import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:control/src/handler_context.dart';
import 'package:meta/meta.dart';

/// A mixin that provides concurrent controller concurrency handling.
/// This mixin should be used on classes that extend [Controller].
base mixin ConcurrentControllerHandler on Controller {
  @override
  @nonVirtual
  bool get isProcessing => _$processingCalls > 0;

  /// Tracks the number of ongoing processing calls.
  int _$processingCalls = 0;

  /// Handles a given operation with error handling and completion tracking.
  ///
  /// [handler] is the main operation to be executed.
  /// [error] is an optional error handler.
  /// [done] is an optional callback to be executed when the operation is done.
  /// [name] is an optional name for the operation, used for debugging.
  /// [context] is an optional HashMap of context data to be passed to the zone.
  @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
    String? name,
    Map<String, Object?>? context,
  }) {
    if (isDisposed) return Future<void>.value(null);
    _$processingCalls++;
    final completer = Completer<void>();
    var isDone = false; // ignore error callback after done

    Future<void> onError(Object e, StackTrace st) async {
      if (isDisposed) return;
      try {
        super.onError(e, st);
        if (isDone || isDisposed || completer.isCompleted) return;
        await error?.call(e, st);
      } on Object catch (error, stackTrace) {
        super.onError(error, stackTrace);
      }
    }

    Future<void> handleZoneError(Object error, StackTrace stackTrace) async {
      if (isDisposed) return;
      super.onError(error, stackTrace);
      assert(
        false,
        'A zone error occurred during controller event handling. '
        'This may be caused by an unawaited future. '
        'Make sure to await all futures in the controller '
        'event handlers.',
      );
    }

    void onDone() {
      if (completer.isCompleted) return;
      _$processingCalls--;
      if (_$processingCalls != 0) return;
      completer.complete();
    }

    final handlerContext = HandlerContextImpl(
      controller: this,
      name: name ?? '$runtimeType.handler#${handler.runtimeType}',
      completer: completer,
      context: <String, Object?>{
        ...?context,
      },
    );

    runZonedGuarded<void>(
      () async {
        try {
          await handler();
        } on Object catch (error, stackTrace) {
          await onError(error, stackTrace);
        } finally {
          isDone = true;
          try {
            await done?.call();
          } on Object catch (error, stackTrace) {
            super.onError(error, stackTrace);
          }
          onDone();
        }
      },
      handleZoneError,
      zoneValues: <Object?, Object?>{
        HandlerContext.key: handlerContext,
      },
    );

    return completer.future;
  }

  /* @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
  }) =>
      runZonedGuarded<void>(
        () async {
          if (isDisposed) return;
          _$processingCalls++;
          _done ??= Completer<void>.sync();
          try {
            await handler();
          } on Object catch (e, st) {
            onError(e, st);
            await Future<void>(() async {
              await error?.call(e, st);
            }).catchError(onError);
          } finally {
            isDone = true;
            await Future<void>(() async {
              await done?.call();
            }).catchError(onError);
            _$processingCalls--;
            if (_$processingCalls == 0) {
              final completer = _done;
              if (completer != null && !completer.isCompleted) {
                completer.complete();
              }
              _done = null;
            }
          }
        },
        onError,
      ); */
}
