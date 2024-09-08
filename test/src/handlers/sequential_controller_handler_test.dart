import 'dart:async';

import 'package:control/control.dart';
import 'package:control/src/handlers/sequential_controller_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'handler_utils.dart';

void main() {
  group(
    'SequentialControllerHandler',
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
        'should execute operations sequentially',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future1 = controller.increment();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          final future2 = controller.decrement();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future1, completes);
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 1);

          await expectLater(future2, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);
        },
      );

      test(
        'handles error and reports to bloc observer',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future = controller.throwError();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          verify(
            observer.onError(controller, any, any),
          ).called(1);
        },
      );

      test(
        'handles an error when observer throws',
        () async {
          when(
            observer.onError(controller, any, any),
          ).thenThrow(Exception('Error'));

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future = controller.throwError();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);
        },
      );

      test(
        'handles an error when observer throws everywhere',
        () async {
          when(
            observer.onError(controller, any, any),
          ).thenThrow(Exception('Error'));

          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final future = controller.throwErrorEverywhere();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(future, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);
        },
      );

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

      test(
        'error in SequentialControllerEventQueue',
        () async {
          final eventQueue = SequentialControllerEventQueue();

          Future<void> task() => Future<void>.delayed(
                const Duration(milliseconds: 100),
                () => throw Exception('Error'),
              );

          await expectLater(eventQueue.push(task), throwsA(isA<Exception>()));
        },
      );

      test(
        'when processing in queue finishes, it should be empty',
        () async {
          final eventQueue = SequentialControllerEventQueue();

          unawaited(eventQueue.push(() async {}));
          unawaited(eventQueue.push(() async {}));

          expect(eventQueue.length, 2);

          await eventQueue.processing;

          expect(eventQueue.length, 0);
        },
      );
    },
  );
}

final class _FakeController = FakeTestController
    with SequentialControllerHandler;
