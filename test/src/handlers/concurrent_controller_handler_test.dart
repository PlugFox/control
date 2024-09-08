import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<IControllerObserver>(),
])
import 'concurrent_controller_handler_test.mocks.dart';
import 'fake_controller.dart';

void main() {
  group(
    'ConcurrentControllerHandler',
    () {
      late _FakeController controller;
      late MockIControllerObserver observer;

      setUp(() {
        controller = _FakeController();
        observer = MockIControllerObserver();
        Controller.observer = observer;
      });

      tearDown(() {
        controller.dispose();
        Controller.observer = null;
        reset(observer);
      });

      test(
        'should execute operations concurrently',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final stopwatch = Stopwatch()..start();

          final futures = <Future<void>>[
            controller.increment(),
            controller.increment(),
            controller.increment(),
            controller.increment(),
            controller.decrement(),
            controller.decrement(),
            controller.decrement(),
            controller.decrement(),
          ];

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(Future.wait(futures), completes);

          stopwatch.stop();

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);
          expect(stopwatch.elapsedMilliseconds, lessThan(200));
        },
      );

      test('should maintain correct state after mixed operations', () async {
        final futures = <Future<void>>[
          controller.increment(),
          controller.increment(),
          controller.decrement(),
          controller.increment(),
        ];

        await Future.wait(futures);
        expect(controller.state, 2);
      });

      test('should handle rapid successive calls', () async {
        for (var i = 0; i < 100; i++) {
          controller.increment().ignore();
        }

        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(controller.state, 100);
      });

      test('should reset isProcessing after all operations complete', () async {
        final future = controller.increment();
        expect(controller.isProcessing, isTrue);

        await expectLater(future, completes);
        expect(controller.isProcessing, isFalse);
      });

      test('should handle errors', () async {
        final future = controller.throwError();
        expect(controller.isProcessing, isTrue);

        await expectLater(future, completes);
        expect(controller.isProcessing, isFalse);

        verify(observer.onError(controller, any, any)).called(1);
      });

      test('should handle errors when observer throws', () async {
        when(
          observer.onError(controller, any, any),
        ).thenThrow(Exception('Error'));

        final future = controller.throwError();
        expect(controller.isProcessing, isTrue);

        await expectLater(future, completes);
        expect(controller.isProcessing, isFalse);

        verify(observer.onError(controller, any, any)).called(1);
      });

      test('should handle mixed operations with errors', () async {
        final futures = <Future<void>>[
          controller.increment(),
          controller.throwError(),
          controller.decrement(),
          controller.throwError(),
        ];

        await expectLater(Future.wait(futures), completes);
        expect(controller.state, 0);
        expect(controller.isProcessing, isFalse);

        verify(observer.onError(controller, any, any)).called(2);
      });

      test('should not process operations after disposal', () async {
        final controller = _FakeController()..dispose();

        final future = controller.increment();
        await expectLater(future, completes);

        expect(controller.state, 0);
        expect(controller.isProcessing, isFalse);
      });

      test('should handle errors in onError and onDone', () async {
        final future = controller.throwErrorEverywhere();
        expect(controller.isProcessing, isTrue);

        await expectLater(future, completes);
        expect(controller.isProcessing, isFalse);

        verify(observer.onError(controller, any, any)).called(3);
      });

      test(
        'handles an error when handle spawns unawaited future',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          Object zoneError = 0;

          await runZonedGuarded(
            controller.throwUnawaited,
            (err, stack) => zoneError = err,
          );

          await Future<void>.delayed(const Duration(milliseconds: 200));

          expect(
            zoneError,
            isA<AssertionError>(),
            reason: 'The error must be raised when an unawaited future '
                'is spawned',
          );

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          // Reported to observer once
          verify(
            observer.onError(controller, any, any),
          ).called(1);
        },
      );
    },
  );
}

final class _FakeController = FakeTestController
    with ConcurrentControllerHandler;
