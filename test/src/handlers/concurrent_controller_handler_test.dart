import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'ConcurrentControllerHandler',
    () {
      test(
        'should execute operations concurrently',
        () async {
          final controller = _FakeController();
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
