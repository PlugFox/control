import 'dart:async';

import 'package:control/control.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<IControllerObserver>(),
])
export 'handler_utils.mocks.dart';

abstract base class FakeTestController extends Controller {
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

  Future<void> throwUnawaited() => handle(() async {
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          throw Exception('Error');
        });
      });

  Future<void> throwErrorEverywhere() => handle(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          throw Exception('Error');
        },
        onError: (error, stackTrace) async {
          throw Exception('Error');
        },
        onDone: () async {
          throw Exception('Error');
        },
      );
}
