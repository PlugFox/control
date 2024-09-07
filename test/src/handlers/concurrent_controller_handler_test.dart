import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'ConcurrentControllerHandler',
    () {
      late _FakeController controller;

      setUp(() {
        controller = _FakeController();
      });

      tearDown(() {
        controller.dispose();
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
    },
  );
}

final class _FakeController extends Controller
    with ConcurrentControllerHandler {
  int _state = 0;

  int get state => _state;

  Future<void> increment() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _state++;
      });

  Future<void> decrement() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        _state--;
      });

  Future<void> throwError() => handle(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw Exception('Error');
      });
}
