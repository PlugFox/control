import 'dart:async';

import 'package:control/src/core/controller.dart';
import 'package:meta/meta.dart';

/// A mixin that provides sequential controller concurrency handling.
/// This mixin should be used on classes that extend [Controller].
base mixin ConcurrentControllerHandler on Controller {
  @override
  bool get isProcessing => _processingCalls > 0;

  /// Tracks the number of ongoing processing calls.
  int _processingCalls = 0;

  /// Handles a given operation with error handling and completion tracking.
  ///
  /// [handler] is the main operation to be executed.
  /// [onError] is an optional error handler.
  /// [onDone] is an optional callback to be executed when the operation is done
  @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? onError,
    Future<void> Function()? onDone,
  }) async {
    if (isDisposed) return;

    _processingCalls++;

    Future<void> handleError(Object error, StackTrace stackTrace) async {
      if (isDisposed) return;
      super.onError(error, stackTrace);
      try {
        await onError?.call(error, stackTrace);
      } on Object catch (secondaryError, secondaryStackTrace) {
        super.onError(secondaryError, secondaryStackTrace);
      }
    }

    Future<void> handleZoneError(
      Object error,
      StackTrace stackTrace,
    ) async {
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

    await runZonedGuarded(
      () async {
        try {
          await handler();
        } on Object catch (error, stackTrace) {
          await handleError(error, stackTrace);
        } finally {
          try {
            await onDone?.call();
          } on Object catch (error, stackTrace) {
            super.onError(error, stackTrace);
          }
        }
      },
      handleZoneError,
    );

    _processingCalls--;
  }
}
