import 'dart:async';
import 'dart:collection';

/// {@template queue_mutex}
/// A mutex implementation that uses a queue to manage access
/// to a critical section of code.
/// This ensures that only one task can execute the critical section at a time.
/// {@endtemplate}
class QueueMutex {
  /// Creates a new instance of the mutex.
  ///
  /// {@macro queue_mutex}
  QueueMutex();

  /// Initial completed future used to represent an unlocked state.
  static final Future<void> _empty = Future<void>.value();

  /// Queue of completers representing tasks waiting for the mutex.
  final DoubleLinkedQueue<Completer<void>> _queue =
      DoubleLinkedQueue<Completer<void>>();

  /// Check if the mutex is currently locked.
  bool get locked => _queue.isNotEmpty;

  /// Returns the number of tasks waiting for the mutex.
  int get tasks => _queue.length;

  /// Locks the mutex and returns
  /// a future that completes when the lock is acquired.
  /// The returned function can be called to unlock the mutex,
  /// but it should only be called once and relatively expensive to call.
  Future<void> lock() {
    final previous = _queue.lastOrNull?.future ?? _empty;
    _queue.addLast(Completer<void>.sync());
    return previous;
  }

  /// Unlocks the mutex, allowing the next waiting task to proceed.
  void unlock() {
    if (_queue.isEmpty) {
      assert(false, 'Mutex unlock called when no tasks are waiting.');
      return;
    }
    final completer = _queue.removeFirst(); // Remove the current lock holder
    if (completer.isCompleted) {
      assert(false,
          'Mutex unlock called when the completer is already completed.');
      return;
    }
    completer.complete();
  }

  /// Synchronizes the execution of a function, ensuring that only one
  /// task can execute the function at a time.
  ///
  /// ```dart
  /// for (var i = 3; i > 0; i--)
  ///   mutex.synchronize(() => criticalSection(i));
  /// ```
  Future<T> synchronize<T>(Future<T> Function() action) async {
    await lock();
    try {
      return await action();
    } finally {
      unlock();
    }
  }
}
