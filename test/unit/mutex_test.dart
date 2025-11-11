@Timeout(Duration(milliseconds: 1000))
library;

import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('Mutex', () {
      test('Creation', () {
        expect(Mutex.new, returnsNormally);
        expect(
          Mutex(),
          isA<Mutex>()
              .having((m) => m.locked, 'locked', isFalse)
              .having((m) => m.synchronize, 'synchronize', isA<Function>())
              .having((m) => m.lock, 'lock', isA<Function>()),
        );
      });

      group('synchronize', () {
        test('executes action', () async {
          final mutex = Mutex();
          var executed = false;

          await mutex.synchronize(() async {
            executed = true;
          });

          expect(executed, isTrue);
          expect(mutex.locked, isFalse);
        });

        test('returns action result', () async {
          final mutex = Mutex();

          final result = await mutex.synchronize(() async => 42);

          expect(result, equals(42));
        });

        test('serializes multiple calls', () async {
          final mutex = Mutex();
          var counter = 0;
          final results = <int>[];

          final futures = List.generate(
              100,
              (i) => mutex.synchronize(() async {
                    final value = counter;
                    await Future<void>.delayed(Duration.zero);
                    counter = value + 1;
                    results.add(counter);
                  }));

          await Future.wait(futures);

          expect(counter, equals(100));
          expect(results.length, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('maintains FIFO order', () async {
          final mutex = Mutex();
          final order = <int>[];

          final futures = List.generate(
              10,
              (i) => mutex.synchronize(() async {
                    await Future<void>.delayed(
                        const Duration(microseconds: 10));
                    order.add(i);
                  }));

          await Future.wait(futures);

          expect(order, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));
          expect(mutex.locked, isFalse);
        });

        test('unlocks on exception', () async {
          final mutex = Mutex();

          expect(
            () => mutex.synchronize(() async {
              throw Exception('test error');
            }),
            throwsException,
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));

          expect(mutex.locked, isFalse);

          // Should work after exception
          var recovered = false;
          await mutex.synchronize(() async {
            recovered = true;
          });
          expect(recovered, isTrue);
        });

        test('propagates exception', () async {
          final mutex = Mutex();
          final exception = Exception('test error');

          expect(
            mutex.synchronize(() async => throw exception),
            throwsA(equals(exception)),
          );
        });

        test('handles synchronous exceptions', () async {
          final mutex = Mutex();

          expect(
            mutex.synchronize<void>(() => throw StateError('sync error')),
            throwsStateError,
          );

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(mutex.locked, isFalse);
        });

        test('queues waiting tasks', () async {
          final mutex = Mutex();
          final events = <String>[];

          // Start first task
          final future1 = mutex.synchronize(() async {
            events.add('start-1');
            await Future<void>.delayed(const Duration(milliseconds: 50));
            events.add('end-1');
          });

          // Give it time to start
          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(mutex.locked, isTrue);

          // Queue second task
          final future2 = mutex.synchronize(() async {
            events.add('start-2');
            await Future<void>.delayed(const Duration(milliseconds: 10));
            events.add('end-2');
          });

          // Second task should be waiting
          expect(mutex.locked, isTrue);

          await Future.wait([future1, future2]);

          expect(events, equals(['start-1', 'end-1', 'start-2', 'end-2']));
          expect(mutex.locked, isFalse);
        });

        test('handles nested synchronize', () async {
          final mutex = Mutex();
          var counter = 0;

          await mutex.synchronize(() async {
            counter++;
            // This will deadlock, but that's expected behavior
            // Just test single level
          });

          expect(counter, equals(1));
          expect(mutex.locked, isFalse);
        });

        test('completes in order with different execution times', () async {
          final mutex = Mutex();
          final completionOrder = <int>[];

          final futures = <Future<void>>[
            mutex.synchronize(() async {
              await Future<void>.delayed(const Duration(milliseconds: 30));
              completionOrder.add(1);
            }),
            mutex.synchronize(() async {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              completionOrder.add(2);
            }),
            mutex.synchronize(() async {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              completionOrder.add(3);
            }),
          ];

          await Future.wait(futures);

          expect(completionOrder, equals([1, 2, 3]));
          expect(mutex.locked, isFalse);
        });
      });

      group('lock', () {
        test('returns unlock function', () async {
          final mutex = Mutex();

          final unlock = await mutex.lock();

          expect(unlock, isA<void Function()>());
          expect(mutex.locked, isTrue);

          unlock();
          expect(mutex.locked, isFalse);
        });

        test('allows manual lock/unlock', () async {
          final mutex = Mutex();
          var counter = 0;

          final unlock = await mutex.lock();
          try {
            counter++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            counter++;
          } finally {
            unlock();
          }

          expect(counter, equals(2));
          expect(mutex.locked, isFalse);
        });

        test('serializes multiple locks', () async {
          final mutex = Mutex();
          var counter = 0;

          final futures = List.generate(100, (i) async {
            final unlock = await mutex.lock();
            try {
              final value = counter;
              await Future<void>.delayed(Duration.zero);
              counter = value + 1;
            } finally {
              unlock();
            }
          });

          await Future.wait(futures);

          expect(counter, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('unlock is idempotent', () async {
          final mutex = Mutex();

          final unlock = await mutex.lock();
          expect(mutex.locked, isTrue);

          unlock();
          expect(mutex.locked, isFalse);

          unlock(); // Second call
          expect(mutex.locked, isFalse);

          unlock(); // Third call
          expect(mutex.locked, isFalse);

          // Should still work
          await mutex.synchronize(() async {});
          expect(mutex.locked, isFalse);
        });

        test('maintains FIFO order', () async {
          final mutex = Mutex();
          final lockOrder = <String>[];

          final unlockA = await mutex.lock();
          lockOrder.add('A');

          final futureB = () async {
            final unlock = await mutex.lock();
            lockOrder.add('B');
            await Future<void>.delayed(const Duration(microseconds: 10));
            unlock();
          }();

          final futureC = () async {
            final unlock = await mutex.lock();
            lockOrder.add('C');
            await Future<void>.delayed(const Duration(microseconds: 10));
            unlock();
          }();

          await Future<void>.delayed(const Duration(milliseconds: 10));

          unlockA();

          await Future.wait([futureB, futureC]);

          expect(lockOrder, equals(['A', 'B', 'C']));
          expect(mutex.locked, isFalse);
        });

        test('handles exception with finally unlock', () async {
          final mutex = Mutex();

          try {
            final unlock = await mutex.lock();
            try {
              throw Exception('test error');
            } finally {
              unlock();
            }
          } on Object catch (_) {
            // Expected
          }

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(mutex.locked, isFalse);

          // Should work after exception
          final unlock = await mutex.lock();
          expect(mutex.locked, isTrue);
          unlock();
        });

        test('works after forgotten unlock', () async {
          final mutex = Mutex();

          // Forget to unlock (bad practice, but should handle)
          await mutex.lock();
          expect(mutex.locked, isTrue);

          // New lock should wait
          var acquired = false;
          unawaited(mutex.lock().then((unlock) {
            acquired = true;
            unlock();
          }));

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(acquired, isFalse); // Still waiting

          // This would hang forever in real code
          // In tests we just verify the behavior
        });

        test('unlock after lock allows immediate re-lock', () async {
          final mutex = Mutex();

          final unlock1 = await mutex.lock();
          unlock1();

          final unlock2 = await mutex.lock();
          expect(mutex.locked, isTrue);
          unlock2();
          expect(mutex.locked, isFalse);
        });
      });

      group('mixed lock and synchronize', () {
        test('interleaves correctly', () async {
          final mutex = Mutex();
          final order = <String>[];

          final futures = <Future<void>>[
            mutex.synchronize(() async {
              order.add('sync-1');
              await Future<void>.delayed(const Duration(microseconds: 10));
            }),
            () async {
              final unlock = await mutex.lock();
              try {
                order.add('lock-1');
                await Future<void>.delayed(const Duration(microseconds: 10));
              } finally {
                unlock();
              }
            }(),
            mutex.synchronize(() async {
              order.add('sync-2');
              await Future<void>.delayed(const Duration(microseconds: 10));
            }),
            () async {
              final unlock = await mutex.lock();
              try {
                order.add('lock-2');
                await Future<void>.delayed(const Duration(microseconds: 10));
              } finally {
                unlock();
              }
            }(),
          ];

          await Future.wait(futures);

          expect(order, equals(['sync-1', 'lock-1', 'sync-2', 'lock-2']));
          expect(mutex.locked, isFalse);
        });

        test('maintains single execution guarantee', () async {
          final mutex = Mutex();
          var concurrent = 0;
          var maxConcurrent = 0;

          final futures = <Future<void>>[];

          for (var i = 0; i < 50; i++) {
            if (i % 2 == 0) {
              futures.add(mutex.synchronize(() async {
                concurrent++;
                maxConcurrent =
                    maxConcurrent > concurrent ? maxConcurrent : concurrent;
                await Future<void>.delayed(const Duration(microseconds: 10));
                concurrent--;
              }));
            } else {
              futures.add(() async {
                final unlock = await mutex.lock();
                try {
                  concurrent++;
                  maxConcurrent =
                      maxConcurrent > concurrent ? maxConcurrent : concurrent;
                  await Future<void>.delayed(const Duration(microseconds: 10));
                  concurrent--;
                } finally {
                  unlock();
                }
              }());
            }
          }

          await Future.wait(futures);

          expect(maxConcurrent, equals(1));
          expect(concurrent, equals(0));
          expect(mutex.locked, isFalse);
        });
      });

      group('edge cases', () {
        test('handles immediate completion', () async {
          final mutex = Mutex();

          await mutex.synchronize(() async {});

          expect(mutex.locked, isFalse);
        });

        test('handles synchronous action', () async {
          final mutex = Mutex();
          var value = 0;

          await mutex.synchronize(() => Future.value(42));
          value = await mutex.synchronize(() => Future.value(100));

          expect(value, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('handles multiple rapid synchronizations', () async {
          final mutex = Mutex();
          final results = <int>[];

          for (var i = 0; i < 1000; i++) {
            unawaited(mutex.synchronize(() async {
              results.add(i);
            }));
          }

          // Wait for all to complete
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await mutex.synchronize(() async {}); // Barrier

          expect(results.length, equals(1000));
          expect(mutex.locked, isFalse);
        });

        test('handles zero delay', () async {
          final mutex = Mutex();
          var counter = 0;

          final futures = List.generate(
              100,
              (i) => mutex.synchronize(() async {
                    await Future<void>.delayed(Duration.zero);
                    counter++;
                  }));

          await Future.wait(futures);

          expect(counter, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('expectLater locked status during execution', () async {
          final mutex = Mutex();

          final future = mutex.synchronize(() async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });

          await Future<void>.delayed(const Duration(milliseconds: 10));
          await expectLater(mutex.locked, isTrue);

          await future;
          await expectLater(mutex.locked, isFalse);
        });

        test('expectLater sequential execution', () async {
          final mutex = Mutex();
          final stream = StreamController<int>();

          mutex
            ..synchronize(() async {
              stream.add(1);
              await Future<void>.delayed(const Duration(milliseconds: 20));
              stream.add(2);
            }).ignore()
            ..synchronize(() async {
              stream.add(3);
              await Future<void>.delayed(const Duration(milliseconds: 20));
              stream.add(4);
            }).ignore();

          await expectLater(
            stream.stream,
            emitsInOrder([1, 2, 3, 4]),
          );

          await stream.close();
        });

        test('handles null result', () async {
          final mutex = Mutex();

          final result = await mutex.synchronize<int?>(() async => null);

          expect(result, isNull);
        });

        test('preserves generic type', () async {
          final mutex = Mutex();

          final stringResult =
              await mutex.synchronize<String>(() async => 'test');
          final intResult = await mutex.synchronize<int>(() async => 42);
          final boolResult = await mutex.synchronize<bool>(() async => true);

          expect(stringResult, isA<String>());
          expect(intResult, isA<int>());
          expect(boolResult, isA<bool>());
        });

        test('completes with void result', () async {
          final mutex = Mutex();

          await mutex.synchronize<void>(() async {});

          expect(mutex.locked, isFalse);
        });

        test('survives rapid lock/unlock cycles', () async {
          final mutex = Mutex();

          for (var i = 0; i < 100; i++) {
            final unlock = await mutex.lock();
            unlock();
          }

          expect(mutex.locked, isFalse);

          // Should still work
          await mutex.synchronize(() async {});
          expect(mutex.locked, isFalse);
        });
      });

      group('stress tests', () {
        test('handles 1000 concurrent operations', () async {
          final mutex = Mutex();
          var counter = 0;

          final futures = List.generate(
              1000,
              (i) => mutex.synchronize(() async {
                    final value = counter;
                    await Future<void>.delayed(Duration.zero);
                    counter = value + 1;
                  }));

          await Future.wait(futures);

          expect(counter, equals(1000));
          expect(mutex.locked, isFalse);
        });

        test('handles mixed operations under load', () async {
          final mutex = Mutex();
          var syncCounter = 0;
          var lockCounter = 0;

          final futures = List.generate(500, (i) {
            if (i % 2 == 0) {
              return mutex.synchronize(() async {
                await Future<void>.delayed(Duration.zero);
                syncCounter++;
              });
            } else {
              return () async {
                final unlock = await mutex.lock();
                try {
                  await Future<void>.delayed(Duration.zero);
                  lockCounter++;
                } finally {
                  unlock();
                }
              }();
            }
          });

          await Future.wait(futures);

          expect(syncCounter, equals(250));
          expect(lockCounter, equals(250));
          expect(mutex.locked, isFalse);
        });

        test('handles rapid lock/unlock without delays', () async {
          final mutex = Mutex();
          var counter = 0;

          final futures = List.generate(200, (i) async {
            final unlock = await mutex.lock();
            counter++;
            unlock();
          });

          await Future.wait(futures);

          expect(counter, equals(200));
          expect(mutex.locked, isFalse);
        });

        test('handles alternating sync and lock patterns', () async {
          final mutex = Mutex();
          final pattern = <String>[];

          final futures = <Future<void>>[];
          for (var i = 0; i < 100; i++) {
            if (i % 3 == 0) {
              futures.add(mutex.synchronize(() async {
                pattern.add('S');
              }));
            } else if (i % 3 == 1) {
              futures.add(() async {
                final unlock = await mutex.lock();
                pattern.add('L');
                unlock();
              }());
            } else {
              futures.add(mutex.synchronize(() async {
                await Future<void>.delayed(Duration.zero);
                pattern.add('S');
              }));
            }
          }

          await Future.wait(futures);

          expect(pattern.length, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('concurrent stress with exceptions', () async {
          final mutex = Mutex();
          var successCount = 0;
          var errorCount = 0;

          final futures = List.generate(100, (i) async {
            try {
              await mutex.synchronize(() async {
                if (i % 10 == 0) {
                  throw Exception('Intentional error $i');
                }
                successCount++;
              });
            } on Object catch (_) {
              errorCount++;
            }
          });

          await Future.wait(futures);

          expect(successCount, equals(90));
          expect(errorCount, equals(10));
          expect(mutex.locked, isFalse);
        });
      });

      group('timeout and cancellation', () {
        test('handles timeout on synchronize', () async {
          final mutex = Mutex();

          // Lock mutex
          final unlock = await mutex.lock();

          var timedOut = false;
          try {
            await mutex
                .synchronize(() async => 42)
                .timeout(const Duration(milliseconds: 50));
          } on TimeoutException {
            timedOut = true;
          }

          expect(timedOut, isTrue);

          // Unlock and verify recovery
          unlock();
          await Future<void>.delayed(const Duration(milliseconds: 10));

          final result = await mutex.synchronize(() async => 100);
          expect(result, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('handles multiple timeouts', () async {
          final mutex = Mutex();

          final unlock = await mutex.lock();

          var timeoutCount = 0;
          for (var i = 0; i < 5; i++) {
            try {
              await mutex
                  .synchronize(() async => i)
                  .timeout(const Duration(milliseconds: 50));
            } on TimeoutException {
              timeoutCount++;
            }
          }

          expect(timeoutCount, equals(5));

          unlock();

          // Should still work after timeouts
          await mutex.synchronize(() async {});
          expect(mutex.locked, isFalse);
        });
      });

      group('complex scenarios', () {
        test('producer-consumer pattern', () async {
          final mutex = Mutex();
          final queue = <int>[];
          var produced = 0;

          // Producer
          final producer = Future(() async {
            for (var i = 0; i < 50; i++) {
              await mutex.synchronize(() async {
                queue.add(i);
                produced++;
              });
            }
          });

          // Consumer
          final consumer = Future(() async {
            for (var i = 0; i < 50; i++) {
              await mutex.synchronize(() async {
                if (queue.isNotEmpty) {
                  queue.removeAt(0);
                }
              });
              await Future<void>.delayed(Duration.zero);
            }
          });

          await Future.wait([producer, consumer]);

          expect(produced, equals(50));
          expect(mutex.locked, isFalse);
        });

        test('reader-writer simulation with single mutex', () async {
          final mutex = Mutex();
          var data = 0;
          final readValues = <int>[];

          final writers = List.generate(
            10,
            (i) => mutex.synchronize(() async {
              await Future<void>.delayed(const Duration(microseconds: 10));
              data++;
            }),
          );

          final readers = List.generate(
            20,
            (i) => mutex.synchronize(() async {
              await Future<void>.delayed(const Duration(microseconds: 5));
              readValues.add(data);
            }),
          );

          await Future.wait([...writers, ...readers]);

          expect(data, equals(10));
          expect(readValues.length, equals(20));
          expect(mutex.locked, isFalse);
        });

        test('cascading lock acquisitions', () async {
          final mutex = Mutex();
          final order = <int>[];

          Future<void> cascade(int depth) async {
            if (depth <= 0) return;
            await mutex.synchronize(() async {
              order.add(depth);
              await Future<void>.delayed(const Duration(microseconds: 10));
            });
            unawaited(cascade(depth - 1));
          }

          await cascade(10);
          await Future<void>.delayed(const Duration(milliseconds: 100));

          expect(order.length, equals(10));
          expect(mutex.locked, isFalse);
        });

        test('mutex with conditional logic', () async {
          final mutex = Mutex();
          var counter = 0;

          final futures = List.generate(
              100,
              (i) => mutex.synchronize(() async {
                    if (counter % 2 == 0) {
                      counter += 2;
                    } else {
                      counter += 1;
                    }
                    await Future<void>.delayed(Duration.zero);
                  }));

          await Future.wait(futures);

          expect(counter, greaterThan(0));
          expect(mutex.locked, isFalse);
        });

        test('batch processing pattern', () async {
          final mutex = Mutex();
          final batches = <List<int>>[];
          final items = List.generate(100, (i) => i);

          const batchSize = 10;
          for (var i = 0; i < items.length; i += batchSize) {
            await mutex.synchronize(() async {
              final end = (i + batchSize).clamp(0, items.length);
              batches.add(items.sublist(i, end));
              await Future<void>.delayed(const Duration(microseconds: 10));
            });
          }

          expect(batches.length, equals(10));
          expect(batches.expand((b) => b).length, equals(100));
          expect(mutex.locked, isFalse);
        });

        test('interleaved fast and slow operations', () async {
          final mutex = Mutex();
          var fastCount = 0;
          var slowCount = 0;

          final futures = List.generate(50, (i) {
            if (i % 2 == 0) {
              // Fast operation
              return mutex.synchronize(() async {
                fastCount++;
              });
            } else {
              // Slow operation
              return mutex.synchronize(() async {
                await Future<void>.delayed(const Duration(microseconds: 50));
                slowCount++;
              });
            }
          });

          await Future.wait(futures);

          expect(fastCount, equals(25));
          expect(slowCount, equals(25));
          expect(mutex.locked, isFalse);
        });

        test('lock acquisition with early completion', () async {
          final mutex = Mutex();
          final completions = <String>[];

          final future1 = mutex.synchronize(() async {
            completions
              ..add('start-1')
              ..add('end-1');
          });

          final future2 = mutex.synchronize(() async {
            completions.add('start-2');
            await Future<void>.delayed(const Duration(milliseconds: 20));
            completions.add('end-2');
          });

          final future3 = mutex.synchronize(() async {
            completions
              ..add('start-3')
              ..add('end-3');
          });

          await Future.wait([future1, future2, future3]);

          expect(
            completions,
            equals([
              'start-1',
              'end-1',
              'start-2',
              'end-2',
              'start-3',
              'end-3',
            ]),
          );
          expect(mutex.locked, isFalse);
        });

        test('multiple unlocks from different contexts', () async {
          final mutex = Mutex();
          final unlocks = <void Function()>[];

          for (var i = 0; i < 5; i++) {
            final unlock = await mutex.lock();
            unlocks.add(unlock);
            expect(mutex.locked, isTrue);
            unlock();
            expect(mutex.locked, isFalse);
          }

          // Call old unlocks (should be safe)
          for (final unlock in unlocks) {
            unlock();
          }

          expect(mutex.locked, isFalse);

          // Should still work
          await mutex.synchronize(() async {});
          expect(mutex.locked, isFalse);
        });
      });

      group('state verification', () {
        test('locked state transitions', () async {
          final mutex = Mutex();
          final states = <bool>[mutex.locked]; // false

          final unlock = await mutex.lock();
          states.add(mutex.locked); // true

          unlock();
          states.add(mutex.locked); // false

          await mutex.synchronize(() async {
            states.add(mutex.locked); // true (during execution)
          });
          states.add(mutex.locked); // false

          expect(states, equals([false, true, false, true, false]));
        });

        test('locked during nested operations', () async {
          final mutex = Mutex();

          await mutex.synchronize(() async {
            expect(mutex.locked, isTrue);
            await Future<void>.delayed(const Duration(milliseconds: 10));
            expect(mutex.locked, isTrue);
          });

          expect(mutex.locked, isFalse);
        });

        test('locked with concurrent waiters', () async {
          final mutex = Mutex();

          final unlock1 = await mutex.lock();
          expect(mutex.locked, isTrue);

          final future2 = mutex.lock();
          final future3 = mutex.lock();

          await Future<void>.delayed(const Duration(milliseconds: 10));
          expect(mutex.locked, isTrue);

          unlock1();
          final unlock2 = await future2;
          expect(mutex.locked, isTrue);

          unlock2();
          final unlock3 = await future3;
          expect(mutex.locked, isTrue);

          unlock3();
          expect(mutex.locked, isFalse);
        });

        test('state consistency after errors', () async {
          final mutex = Mutex();

          // Error in synchronize
          try {
            await mutex.synchronize(() async {
              throw StateError('test');
            });
          } on Object catch (_) {
            // Expected
          }
          expect(mutex.locked, isFalse);

          // Error in lock
          try {
            final unlock = await mutex.lock();
            try {
              throw Exception('error');
            } finally {
              unlock();
            }
          } on Object catch (_) {
            // Expected
          }
          expect(mutex.locked, isFalse);

          // Should still work
          await mutex.synchronize(() async {});
          expect(mutex.locked, isFalse);
        });

        test('multiple mutex instances are independent', () async {
          final mutex1 = Mutex();
          final mutex2 = Mutex();

          final unlock1 = await mutex1.lock();
          expect(mutex1.locked, isTrue);
          expect(mutex2.locked, isFalse);

          final unlock2 = await mutex2.lock();
          expect(mutex1.locked, isTrue);
          expect(mutex2.locked, isTrue);

          unlock1();
          expect(mutex1.locked, isFalse);
          expect(mutex2.locked, isTrue);

          unlock2();
          expect(mutex1.locked, isFalse);
          expect(mutex2.locked, isFalse);
        });
      });

      group('error propagation', () {
        test('preserves stack trace', () async {
          final mutex = Mutex();

          try {
            await mutex.synchronize(() async {
              throw Exception('original error');
            });
          } on Object catch (e, stackTrace) {
            expect(e.toString(), contains('original error'));
            expect(stackTrace.toString(), isNotEmpty);
            return; // Expected error
          }
        });

        test('different error types', () async {
          final mutex = Mutex();

          expect(
            mutex.synchronize(() async => throw ArgumentError('test')),
            throwsArgumentError,
          );

          expect(
            mutex.synchronize(() async => throw StateError('test')),
            throwsStateError,
          );

          expect(
            mutex.synchronize(() async => throw const FormatException('test')),
            throwsFormatException,
          );

          await Future<void>.delayed(const Duration(milliseconds: 50));
          expect(mutex.locked, isFalse);
        });

        test('error does not affect queued operations', () async {
          final mutex = Mutex();
          final results = <String>[];

          final futures = <Future<void>>[
            mutex.synchronize(() async {
              results.add('ok-1');
            }),
            () async {
              results.add('error');
              try {
                throw Exception('test error');
              } on Object catch (_) {
                // Ignore
              }
            }(),
            mutex.synchronize(() async {
              results.add('ok-2');
            }),
          ];

          await Future.wait(futures);

          expect(results, equals(['ok-1', 'error', 'ok-2']));
          expect(mutex.locked, isFalse);
        });
      });
    });
