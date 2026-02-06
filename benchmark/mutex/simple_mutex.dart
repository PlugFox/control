/// {@template simple_mutex}
/// A simple mutex implementation that serializes access to a critical section
/// of code using a single future chain.
/// {@endtemplate}
class SimpleMutex {
  /// Creates a new instance of the mutex.
  ///
  /// {@macro simple_mutex}
  SimpleMutex();

  /// The initial completed future used to represent an unlocked state.
  static final Future<void> _initial = Future<void>.value();

  Future<void> _task = _initial;

  /// Indicates whether the mutex is currently locked.
  bool get locked => !identical(_task, _initial);

  /// Executes a function while holding the mutex lock.
  /// Beware that [action] should never throw exceptions.
  ///
  /// ```dart
  /// for (var i = 3; i > 0; i--)
  ///   mutex.synchronize(() => criticalSection(i));
  /// ```
  Future<T> synchronize<T>(Future<T> Function() action) async {
    final prior = _task;
    final task = _task = Future<T>(() async {
      if (!identical(_task, _initial)) await prior;
      return action();
    });
    final result = await task;
    if (identical(_task, task)) _task = _initial;
    return result;
  }
}
