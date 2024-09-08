import 'dart:async';
import 'dart:collection';

import 'package:control/src/core/controller.dart';
import 'package:meta/meta.dart';

/// A mixin that provides sequential controller concurrency handling.
/// This mixin should be used on classes that extend [Controller].
base mixin SequentialControllerHandler on Controller {
  // The event queue for sequential execution.
  final _ControllerEventQueue _eventQueue = _ControllerEventQueue();

  @override
  @nonVirtual
  bool get isProcessing => _eventQueue.length > 0;

  /// Handles a given operation with error handling and queues it for
  /// sequential execution.
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
  }) =>
      _eventQueue.push<void>(
        () async {
          if (isDisposed) return;

          /// Function that is called when an error occurs during handler
          /// execution.
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
        },
      );

  @override
  void dispose() {
    _eventQueue.close();
    super.dispose();
  }
}

/// A queue for managing sequential execution of controller events.
class _ControllerEventQueue {
  final DoubleLinkedQueue<_SequentialTask<Object?>> _queue =
      DoubleLinkedQueue<_SequentialTask<Object?>>();
  Future<void>? _processing;
  bool _isClosed = false;

  /// Event queue length.
  int get length => _queue.length;

  /// The current processing future, if any.
  Future<void>? get processing => _processing;

  /// Pushes a new task to the end of the queue.
  ///
  /// Returns a [Future] that completes with the result of the task.
  /// Throws a [StateError] if the queue is closed.
  Future<T> push<T>(Future<T> Function() task) {
    if (_isClosed) {
      throw StateError('Cannot push to a closed queue');
    }

    final sequentialTask = _SequentialTask<T>(task);
    _queue.add(sequentialTask);
    _startProcessing();

    return sequentialTask.future;
  }

  /// Marks the queue as closed.
  ///
  /// The queue will be processed until it's empty.
  /// All new push attempts will be rejected with [StateError].
  Future<void> close() async {
    _isClosed = true;
    await _processing;
  }

  /// Starts processing the queue if it's not already being processed.
  void _startProcessing() {
    _processing ??= _processQueue();
  }

  /// Processes the queue sequentially.
  Future<void> _processQueue() async {
    while (_queue.isNotEmpty) {
      final task = _queue.first;
      try {
        await task();
      } on Object catch (error, stackTrace) {
        task.reject(error, stackTrace);
      } finally {
        _queue.removeFirst();
      }
    }
    _processing = null;
  }
}

/// Represents a task in the sequential queue.
class _SequentialTask<T> {
  _SequentialTask(this._task);
  final Future<T> Function() _task;
  final _completer = Completer<T>();

  Future<T> get future => _completer.future;

  Future<void> call() async {
    final result = await _task();
    _completer.complete(result);
  }

  void reject(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }
}
