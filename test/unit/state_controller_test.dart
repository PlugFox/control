// ignore_for_file: unnecessary_lambdas, unused_element

import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('StateController', () {
      _$concurrencyGroup();
      _$methodsGroup();
    });

void _$concurrencyGroup() => group('concurrency', () {
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
        await expectLater(controller.done, completes);
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(3));
        expect(controller.subscribers, equals(0));
        expect(() => controller.addListener(() {}), returnsNormally);
        expect(controller.subscribers, equals(1));
        controller.dispose();
        expect(controller.subscribers, equals(0));
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(3));
        expect(controller.isDisposed, isTrue);
        expect(() => controller.removeListener(() {}), returnsNormally);
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
        await expectLater(controller.done, completes);
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(1));
        expect(controller.subscribers, equals(0));
        expect(() => controller.addListener(() {}), returnsNormally);
        expect(controller.subscribers, equals(1));
        controller.dispose();
        expect(controller.subscribers, equals(0));
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(1));
        expect(controller.isDisposed, isTrue);
        expect(() => controller.removeListener(() {}), returnsNormally);
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
        await expectLater(controller.done, completes);
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(3));
        expect(controller.subscribers, equals(0));
        expect(() => controller.addListener(() {}), returnsNormally);
        expect(controller.subscribers, equals(1));
        controller.dispose();
        expect(controller.subscribers, equals(0));
        expect(controller.isProcessing, isFalse);
        expect(controller.state, equals(3));
        expect(controller.isDisposed, isTrue);
        expect(() => controller.removeListener(() {}), returnsNormally);
      });
    });

void _$methodsGroup() => group('methods', () {
      test('toStream', () async {
        final controller = _FakeControllerConcurrent();
        expect(controller.toStream(), isA<Stream<int>>());
        // ignore: unawaited_futures
        expectLater(
          controller.toStream(),
          emitsInOrder(<Object>[1, 0, -1, 2, emitsDone]),
        );
        controller
          ..add(1)
          ..subtract(1)
          ..subtract(1)
          ..add(3);
        await expectLater(controller.done, completes);
        controller.dispose();
      });

      test('toValueListenable', () async {
        final controller = _FakeControllerConcurrent();
        final listenable = controller.toValueListenable();
        expect(listenable, isA<ValueListenable<int>>());
        expect(listenable.value, equals(controller.state));
        controller
          ..add(2)
          ..subtract(1);
        await expectLater(controller.done, completes);
        expect(listenable.value, equals(controller.state));
        final completer = Completer<void>();
        listenable.addListener(completer.complete);
        controller.add(1);
        await expectLater(completer.future, completes);
        expect(completer.isCompleted, isTrue);
        controller.dispose();
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
