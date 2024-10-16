import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:control/src/handler_context.dart';
import 'package:meta/meta.dart';

/// Droppable controller concurrency
base mixin DroppableControllerHandler on Controller {
  @override
  @nonVirtual
  bool get isProcessing => _$processingCalls > 0;
  int _$processingCalls = 0;

  /// Handles a given operation with error handling and completion tracking.
  ///
  /// [handler] is the main operation to be executed.
  /// [error] is an optional error handler.
  /// [done] is an optional callback to be executed when the operation is done.
  /// [name] is an optional name for the operation, used for debugging.
  /// [meta] is an optional HashMap of context data to be passed to the zone.
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
    if (isDisposed || isProcessing) return Future<void>.value(null);
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
      completer.complete();
    }

    final handlerContext = HandlerContextImpl(
      controller: this,
      name: name ?? 'handler#${handler.runtimeType}',
      completer: completer,
      meta: <String, Object?>{
        ...?meta,
      },
    );

    runZonedGuarded<void>(
      () async {
        try {
          if (isDisposed) return;
          Controller.observer?.onHandler(handlerContext);
          await handler();
        } on Object catch (error, stackTrace) {
          await onError(error, stackTrace);
        } finally {
          isDone = true;
          try {
            await done?.call();
          } on Object catch (error, stackTrace) {
            super.onError(error, stackTrace);
          } finally {
            onDone();
          }
        }
      },
      handleZoneError,
      zoneValues: <Object?, Object?>{
        HandlerContext.key: handlerContext,
      },
    );

    return completer.future;
  }
}
