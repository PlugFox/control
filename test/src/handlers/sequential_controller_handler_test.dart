import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateNiceMocks([
  MockSpec<IControllerObserver>(),
])
import 'sequential_controller_handler_test.mocks.dart';

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
        'handles error in onDone',
        () async {
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 0);

          final incrementFuture = controller.increment();
          expect(controller.isProcessing, isTrue);
          expect(controller.state, 0);

          await expectLater(incrementFuture, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 1);

          final throwFuture = controller.throwErrorOnDone();

          expect(controller.isProcessing, isTrue);
          expect(controller.state, 1);

          await expectLater(throwFuture, completes);
          expect(controller.isProcessing, isFalse);
          expect(controller.state, 1);

          verify(
            observer.onError(controller, any, any),
          ).called(2);
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
    },
  );
}

final class _FakeController extends StateController<int>
    with SequentialControllerHandler {
  _FakeController() : super(initialState: 0);

  /// Increments the state by one.
  Future<void> increment() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        setState(state + 1);
      });

  /// Decrements the state by one.
  Future<void> decrement() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        setState(state - 1);
      });

  /// Throws an error.
  Future<void> throwError() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw Exception('Error');
      });

  /// Throws an error in onDone.
  Future<void> throwErrorOnDone() => handle(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          throw Exception('Error');
        },
        onDone: () async {
          throw Exception('Error in onDone');
        },
      );

  /// Throws an error in onError, onDone, and the main handler.
  Future<void> throwErrorEverywhere() => handle(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          throw Exception('Error');
        },
        onError: (error, stackTrace) async {
          throw Exception('Error in onError');
        },
        onDone: () async {
          throw Exception('Error in onDone');
        },
      );
}
