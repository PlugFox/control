import 'dart:async';
import 'dart:collection';

import 'package:control/src/controller.dart';
import 'package:control/src/handler_context.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:meta/meta.dart';

/// Sequential controller concurrency
base mixin SequentialControllerHandler on Controller {
  final _ControllerEventQueue _eventQueue = _ControllerEventQueue();

  @override
  @nonVirtual
  bool get isProcessing => _eventQueue.length > 0;

  @override
  Future<void> get done =>
      _eventQueue._processing ?? SynchronousFuture<void>(null);

  @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
    String? name,
    Map<String, Object?>? context,
  }) =>
      _eventQueue.push<void>(
        () {
          final completer = Completer<void>();
          var isDone = false; // ignore error callback after done

          Future<void> onError(Object e, StackTrace st) async {
            try {
              super.onError(e, st);
              if (isDone || isDisposed || completer.isCompleted) return;
              await error?.call(e, st);
            } on Object catch (error, stackTrace) {
              super.onError(error, stackTrace);
            }
          }

          final handlerContext = HandlerContextImpl(
            controller: this,
            name: name ?? '$runtimeType.handler#${handler.runtimeType}',
            context: <String, Object?>{
              ...?context,
            },
          );

          runZonedGuarded<void>(
            () async {
              if (isDisposed) return;
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
                if (!completer.isCompleted) completer.complete();
              }
            },
            onError,
            zoneValues: <Object?, Object?>{
              HandlerContext.key: handlerContext,
            },
          );

          return completer.future;
        },
      ).catchError((_, __) => null);
}

final class _ControllerEventQueue {
  _ControllerEventQueue();

  final DoubleLinkedQueue<_SequentialTask<Object?>> _queue =
      DoubleLinkedQueue<_SequentialTask<Object?>>();
  Future<void>? _processing;
  bool _isClosed = false;

  /// Event queue length.
  int get length => _queue.length;

  /// Push it at the end of the queue.
  Future<T> push<T>(Future<T> Function() fn) {
    final task = _SequentialTask<T>(fn);
    _queue.add(task);
    _exec();
    return task.future;
  }

  /// Mark the queue as closed.
  /// The queue will be processed until it's empty.
  /// But all new and current events will be rejected with [WSClientClosed].
  Future<void> close() async {
    _isClosed = true;
    await _processing;
  }

  /// Execute the queue.
  void _exec() => _processing ??= Future.doWhile(() async {
        final event = _queue.first;
        try {
          if (_isClosed) {
            event.reject(StateError('Controller\'s event queue are disposed'),
                StackTrace.current);
          } else {
            await event();
          }
        } on Object catch (error, stackTrace) {
          /* warning(
            error,
            stackTrace,
            'Error while processing event "${event.id}"',
          ); */
          Future<void>.sync(() => event.reject(error, stackTrace)).ignore();
        }
        _queue.removeFirst();
        final isEmpty = _queue.isEmpty;
        if (isEmpty) _processing = null;
        return !isEmpty;
      });
}

class _SequentialTask<T> {
  _SequentialTask(Future<T> Function() fn)
      : _fn = fn,
        _completer = Completer<T>();

  final Completer<T> _completer;

  final Future<T> Function() _fn;

  Future<T> get future => _completer.future;

  Future<T> call() async {
    final result = await _fn();
    if (!_completer.isCompleted) {
      _completer.complete(result);
    }
    return result;
  }

  void reject(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) return;
    _completer.completeError(error, stackTrace);
  }
}
