import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'handler_utils.dart';

void main() {
  group(
    'DroppableControllerHandler',
    () {
      late MockIControllerObserver observer;
      late _FakeController controller;

      setUp(() {
        controller = _FakeController();
        observer = MockIControllerObserver();
        Controller.observer = observer;
      });

      tearDown(() {
        reset(observer);
        Controller.observer = null;
        controller.dispose();
      });

      test(
        'should drop operations when busy',
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
          expect(
            controller.state,
            1,
            reason: 'Only first increment should be executed',
          );
          expect(stopwatch.elapsedMilliseconds, lessThan(200));
        },
      );

      test(
        'should drop operations when busy 2',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future1 = controller.increment();
          final future2 = controller.throwError();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future1, completes);
          await expectLater(future2, completes);

          verifyNever(observer.onError(controller, any, any));

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 1);
        },
      );

      test(
        'should drop operations when busy 3',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future1 = controller.increment();
          final future2 = controller.throwErrorEverywhere();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future1, completes);
          await expectLater(future2, completes);

          verifyNever(observer.onError(controller, any, any));

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 1);
        },
      );

      test(
        'should drop operations when busy 4',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future1 = controller.throwError();
          final future2 = controller.increment();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future1, completes);
          await expectLater(future2, completes);

          verify(observer.onError(controller, any, any)).called(1);

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);
        },
      );

      test(
        'should drop and when finished start new operation',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future1 = controller.increment();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future1, completes);

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 1);

          final future2 = controller.increment();

          await expectLater(future2, completes);
          expect(controller.isProcessing, false);
          expect(controller.state, 2);
        },
      );

      test(
        'should handle error and drop operations',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future = controller.throwError();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future, completes);

          verify(observer.onError(controller, any, any)).called(1);
        },
      );

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
    with DroppableControllerHandler;
