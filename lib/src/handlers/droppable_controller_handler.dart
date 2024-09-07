import 'dart:async';

import 'package:control/src/core/controller.dart';
import 'package:meta/meta.dart';

/// A mixin that provides droppable controller concurrency handling.
/// This mixin should be used on classes that extend [Controller].
/// It allows only one operation to be processed at a time, dropping
/// new requests if one is already in progress.
base mixin DroppableControllerHandler on Controller {
  /// Indicates whether the controller is currently processing an operation.
  @override
  @nonVirtual
  bool get isProcessing => _processingCalls > 0;

  /// Tracks the number of ongoing processing calls (should be 0 or 1).
  int _processingCalls = 0;

  /// Handles a given operation with error handling and completion tracking.
  /// If an operation is already in progress, this method returns immediately
  /// without starting a new operation.
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
    if (isDisposed || isProcessing) return;

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

    _processingCalls--;
  }
}
