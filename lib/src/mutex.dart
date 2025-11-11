import 'package:control/src/util/linked_mutex.dart';

/// {@template mutex}
/// A mutex (mutual exclusion) is a synchronization primitive
/// that is used to protect shared resources from concurrent access.
/// {@endtemplate}
abstract class Mutex {
  /// Creates a new instance of the mutex.
  ///
  /// {@macro mutex}
  factory Mutex() => LinkedMutex();

  /// Check if the mutex is currently locked.
  bool get locked;

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
  Future<void Function()> lock();

  /// Synchronizes the execution of a function, ensuring that only one
  /// task can execute the function at a time.
  ///
  /// ```dart
  /// for (var i = 3; i > 0; i--)
  ///   mutex.synchronize(() => criticalSection(i));
  /// ```
  Future<T> synchronize<T>(Future<T> Function() action);
}
