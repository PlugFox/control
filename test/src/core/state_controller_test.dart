// ignore_for_file: unnecessary_lambdas, unused_element

import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('StateController', () {
      group('concurrency', () {
        test('sequential', () async {
          final controller = _FakeControllerSequential();
          expect(controller.isProcessing, isFalse);
          expect(controller.state, equals(0));
          expect(controller.subscribers, equals(0));
          expect(controller.isDisposed, isFalse);
          controller
            ..add(1)
            ..subtract(2)
            ..add(4);
          expect(controller.isProcessing, isTrue);
        });

        test('droppable', () async {
          final controller = _FakeControllerDroppable();
          expect(controller.isProcessing, isFalse);
          expect(controller.state, equals(0));
          expect(controller.subscribers, equals(0));
          expect(controller.isDisposed, isFalse);
          controller
            ..add(1)
            ..subtract(2)
            ..add(4);
          expect(controller.isProcessing, isTrue);
        });

        test('concurrent', () async {
          final controller = _FakeControllerConcurrent();
          expect(controller.isProcessing, isFalse);
          expect(controller.state, equals(0));
          expect(controller.subscribers, equals(0));
          expect(controller.isDisposed, isFalse);
          controller
            ..add(1)
            ..subtract(2)
            ..add(4);
          expect(controller.isProcessing, isTrue);
        });
      });

      group('methods', () {
        test('toValueListenable', () async {
          final controller = _FakeControllerConcurrent();
          final listenable = controller.toValueListenable();
          expect(listenable, isA<ValueListenable<int>>());
          expect(listenable.value, equals(controller.state));
          controller
            ..add(2)
            ..subtract(1);
        });
      });
    });

abstract base class _FakeControllerBase extends StateController<int> {
  _FakeControllerBase({int? initialState})
      : super(initialState: initialState ?? 0);

  void add(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state + value);
      });

  void subtract(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state - value);
      });
}

final class _FakeControllerSequential = _FakeControllerBase
    with SequentialControllerHandler;

final class _FakeControllerDroppable = _FakeControllerBase
    with DroppableControllerHandler;

final class _FakeControllerConcurrent = _FakeControllerBase
    with ConcurrentControllerHandler;
