import 'dart:async';

import 'package:control/src/mutex.dart';

/// {@template linked_mutex}
/// A mutex implementation using a linked list of tasks.
/// This allows for synchronizing access to a critical section of code,
/// ensuring that only one task can execute the critical section at a time.
/// {@endtemplate}
class LinkedMutex implements Mutex {
  /// Creates a new instance of the mutex.
  ///
  /// {@macro linked_mutex}
  LinkedMutex();

  /// The head of the linked list of mutex tasks.
  _MutexTask? _head;

  /// Check if the mutex is currently locked.
  @override
  bool get locked => _head != null;

  /// Locks the mutex and returns
  /// a future that completes when the lock is acquired.
  ///
  /// ```dart
  /// for (var i = 3; i > 0; i--)
  ///   Future<void>(() async {
  ///     final unlock = await mutex.lock();
  ///     try {
  ///       await criticalSection(i);
  ///     } finally {
  ///       unlock();
  ///     }
  ///   });
  /// ```
  @override
  Future<void Function()> lock() async {
    final prior = _head;
    final node = _head = _MutexTask.sync();
    if (prior != null) {
      prior.next = node;
      await prior.future;
    }
    return () {
      if (node.isCompleted) return;
      node.complete();
      if (identical(_head, node)) _head = null;
    };
  }

  /// Synchronizes the execution of a function, ensuring that only one
  /// task can execute the function at a time.
  ///
  /// ```dart
  /// for (var i = 3; i > 0; i--)
  ///   mutex.synchronize(() => criticalSection(i));
  /// ```
  @override
  Future<T> synchronize<T>(Future<T> Function() action) async {
    final prior = _head;
    final node = _head = _MutexTask.sync();
    if (prior != null) {
      prior.next = node;
      await prior.future;
    }
    try {
      final result = await action();
      return result;
    } on Object {
      rethrow;
    } finally {
      node.complete();
      if (identical(_head, node)) _head = null;
    }
  }
}

/// A task in the linked list of mutex tasks.
final class _MutexTask {
  _MutexTask.sync() : _completer = Completer<void>.sync();

  final Completer<void> _completer;

  /// Whether the task has been completed.
  bool get isCompleted => _completer.isCompleted;

  /// The future that completes when the task is done.
  Future<void> get future => _completer.future;

  /// Executes the task.
  /// After completion, it triggers the execution of the next task in the queue.
  void complete() => _completer.complete();

  /// Next task in the mutex queue.
  _MutexTask? next;
}
