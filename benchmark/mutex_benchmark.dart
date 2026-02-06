import 'dart:async';
import 'dart:io' as io;

import 'package:meta/meta.dart';

//import 'package:synchronized/synchronized.dart' as synchronized;

import 'mutex/linked_mutex.dart';
import 'mutex/queue_mutex.dart';
import 'mutex/simple_mutex.dart';

void main() => runZonedGuarded<void>(
      () async {
        io.stdout.writeln('Starting mutex benchmark...');
        final benchmarks = <BenchmarkBase>[
          WithoutMutexBenchmark(),
          SimpleMutexBenchmark(),
          //SynchronizedBenchmark(),
          QueueMutexBenchmark(),
          LinkedMutexBenchmark(),
          LinkedLockBenchmark(),
        ];

        final ranks =
            <({double score, int iterations, int elapsed, String name})>[];

        for (final benchmark in benchmarks) {
          final result = await benchmark.measure();
          final iterations = result.iterations;
          final elapsed = result.elapsed;
          final score = iterations / (elapsed / 1000);
          ranks.add((
            score: score,
            iterations: iterations,
            elapsed: elapsed,
            name: benchmark.name
          ));
        }

        final buffer = StringBuffer('Mutex Benchmark Results:\n');
        ranks.sort((a, b) => b.score.compareTo(a.score));
        for (final rank in ranks) {
          buffer.writeln('${rank.name.padLeft(16, ' ')}: '
              '${rank.score.toStringAsFixed(2)} ops/sec '
              '(${rank.iterations} iterations in ${rank.elapsed} µs)');
        }
        io.stdout.writeln(buffer.toString());
        await io.stdout.flush();
        io.exit(0);
      },
      (error, stack) async {
        io.stderr.writeln('Error in mutex benchmark: $error\n$stack');
        await io.stderr.flush();
        io.exit(1);
      },
    );

abstract class BenchmarkBase {
  BenchmarkBase() : _counter = 0;

  /// The name of the benchmark.
  String get name;

  /// Internal counter for executed iterations.
  int _counter;

  /// Measures the score for this benchmark by executing it repeatedly until
  /// time minimum has been reached.
  static Future<({int iterations, int elapsed})> _measureFor(
      Future<void> Function() f, int minimumMillis) async {
    const batchSize = 100000;
    final futures = List<Future<void>>.filled(batchSize, Future<void>.value());
    final minimumMicros = minimumMillis * 1000;
    var iter = 0;
    var elapsed = 0;
    try {
      final watch = Stopwatch()..start();
      while (elapsed < minimumMicros) {
        for (var i = 0; i < batchSize; i++) {
          futures[i] = f();
          iter++;
        }
        await Future.wait<void>(futures);
        elapsed = watch.elapsedMicroseconds;
      }
    } on Object catch (e) {
      io.stderr.writeln('Error during benchmark measurement: $e');
      rethrow;
    }
    return (iterations: iter, elapsed: elapsed);
  }

  /// Resets the benchmark state.
  void reset() {
    _counter = 0;
  }

  Future<void> run();

  @mustCallSuper
  void test(int iterations) {
    if (iterations <= 0)
      throw StateError('Invalid iterations count in test: $iterations.');
    if (_counter != iterations)
      throw StateError('Test for $name mismatch: '
          'expected $iterations, got $_counter.');
  }

  /// Measures the score for the benchmark and returns it.
  @mustCallSuper
  Future<({int iterations, int elapsed})> measure() async {
    // Warmup for at least 100ms. Discard result.
    await _measureFor(run, 100);
    // Reset state
    reset();
    // Run the benchmark for at least 2000ms.
    final result = await _measureFor(run, 2000);
    // Test result
    test(result.iterations);
    return result;
  }
}

class WithoutMutexBenchmark extends BenchmarkBase {
  WithoutMutexBenchmark();

  @override
  String get name => 'WithoutMutex';

  @override
  Future<void> run() => Future<void>.delayed(Duration.zero, () {
        _counter++;
      });
}

class QueueMutexBenchmark extends BenchmarkBase {
  QueueMutexBenchmark();

  @override
  String get name => 'QueueMutex';

  final QueueMutex _m = QueueMutex();

  @override
  Future<void> run() => _m.synchronize(() async {
        final value = _counter;
        await Future<void>.delayed(Duration.zero);
        _counter = value + 1;
      });
}

class SimpleMutexBenchmark extends BenchmarkBase {
  SimpleMutexBenchmark();

  @override
  String get name => 'SimpleMutex';

  final SimpleMutex _m = SimpleMutex();

  @override
  Future<void> run() => _m.synchronize(() async {
        final value = _counter;
        await Future<void>.delayed(Duration.zero);
        _counter = value + 1;
      });

  @override
  void test(int iterations) {
    super.test(iterations);
    if (_m.locked) throw StateError('SimpleMutex is still locked.');
  }
}

/* class SynchronizedBenchmark extends BenchmarkBase {
  SynchronizedBenchmark();

  @override
  String get name => 'Synchronized';

  final synchronized.Lock _lock = synchronized.Lock();

  @override
  Future<void> run() => _lock.synchronized(() async {
        final value = _counter;
        await Future<void>.delayed(Duration.zero);
        _counter = value + 1;
      });

  @override
  void test(int iterations) {
    super.test(iterations);
    if (_lock.locked) throw StateError('Synchronized lock is still locked.');
  }
} */

class LinkedMutexBenchmark extends BenchmarkBase {
  LinkedMutexBenchmark();

  @override
  String get name => 'LinkedMutex';

  final LinkedMutex _m = LinkedMutex();

  @override
  Future<void> run() => _m.synchronize(() async {
        final value = _counter;
        await Future<void>.delayed(Duration.zero);
        _counter = value + 1;
      });
}

class LinkedLockBenchmark extends BenchmarkBase {
  LinkedLockBenchmark();

  @override
  String get name => 'LinkedLock';

  final LinkedMutex _m = LinkedMutex();

  @override
  Future<void> run() async {
    final unlock = await _m.lock();
    try {
      final value = _counter;
      await Future<void>.delayed(Duration.zero);
      _counter = value + 1;
    } finally {
      unlock();
    }
  }
}
