import 'dart:async';
import 'dart:collection';

/// A simple mutex implementation using a linked list of completers.
/// This allows for synchronizing access to a critical section of code,
/// ensuring that only one task can execute the critical section at a time.
class Mutex {
  /// Creates a new instance of the mutex.
  Mutex();

  /// Queue of completers representing tasks waiting for the mutex.
  final DoubleLinkedQueue<Completer<void>> _queue =
      DoubleLinkedQueue<Completer<void>>();

  /// Check if the mutex is currently locked.
  bool get isLocked => _queue.isNotEmpty;

  /// Returns the number of tasks waiting for the mutex.
  int get tasks => _queue.length;

  /// Locks the mutex and returns
  /// a future that completes when the lock is acquired.
  /// The returned function can be called to unlock the mutex,
  /// but it should only be called once and relatively expensive to call.
  Future<void> lock() {
    final previous = _queue.lastOrNull?.future ?? Future<void>.value();
    _queue.add(Completer<void>.sync());
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
  Future<T> synchronize<T>(Future<T> Function() action) async {
    await lock();
    try {
      return await action();
    } finally {
      unlock();
    }
  }
}

/* void main() async {
  final mutext = Mutext();

  // Simulate a critical section
  Future<void> criticalSection(int id) async {
    //print('Task $id is in the critical section');
    await Future<void>.delayed(const Duration(seconds: 1));
    //print('Task $id is leaving the critical section');
  }

  // Start multiple tasks
  for (var i = 0; i < 5; i++) mutext.synchronize(() => criticalSection(i));
} */
