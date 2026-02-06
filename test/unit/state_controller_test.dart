// ignore_for_file: unnecessary_lambdas, unused_element
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('StateController', () {
  _$concurrencyGroup();
  _$genericHandleGroup();
  _$exceptionalGroup();
  _$assertionGroup();
  _$methodsGroup();
  _$onErrorGroup();
});

void _$concurrencyGroup() => group('concurrency', () {
  test('sequential', () async {
    final controller = _FakeControllerSequential();
    expect(controller.isProcessing, isFalse);
    expect(controller.state, equals(0));
    expect(controller.subscribers, equals(0));
    expect(controller.isDisposed, isFalse);
    final done = Future.wait(<Future<void>>[
      controller.add(1),
      controller.subtract(2),
      controller.add(4),
    ]);
    expect(controller.isProcessing, isTrue);
    await expectLater(done, completes);
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

    // Start first operation (will succeed)
    final first = controller.add(1);
    expect(controller.isProcessing, isTrue);

    // These will be dropped (controller is busy)
    final dropped1 = controller.subtract(2);
    final dropped2 = controller.add(4);

    // Dropped operations complete with null
    await expectLater(dropped1, completion(isNull));
    await expectLater(dropped2, completion(isNull));

    // First operation completes
    await expectLater(first, completes);
    expect(controller.isProcessing, isFalse);
    expect(controller.state, equals(1)); // Only first operation executed
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
    final done = Future.wait(<Future<void>>[
      controller.add(1),
      controller.subtract(2),
      controller.add(4),
    ]);
    expect(controller.isProcessing, isTrue);
    await expectLater(done, completes);
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

void _$exceptionalGroup() => group('exceptional', () {
  test('throws if dispose called multiple times', () {
    final controller = _FakeControllerConcurrent()..dispose();
    expect(() => controller.dispose(), throwsA(isA<AssertionError>()));
  });

  test('handles edge case of adding large values', () async {
    const largeValue = 9223372036854775807;
    final controller = _FakeControllerConcurrent();
    await expectLater(controller.add(largeValue), completes);
    expect(controller.state, equals(largeValue));
    controller.dispose();
  });

  test('handles edge case of subtracting large values', () async {
    const largeNegativeValue = 9223372036854775807;
    final controller = _FakeControllerConcurrent();
    await expectLater(controller.subtract(largeNegativeValue), completes);
    expect(controller.state, equals(-largeNegativeValue));
    controller.dispose();
  });

  test('processes multiple operations efficiently', () async {
    final stopwatch = Stopwatch()..start();
    try {
      final controller = _FakeControllerConcurrent();
      final done = Future.wait(<Future<void>>[
        for (var i = 0; i < 1000; i++) controller.add(1),
      ]);
      await expectLater(done, completes);
      expect(controller.state, equals(1000));
      controller.dispose();
    } finally {
      debugPrint('${(stopwatch..stop()).elapsedMicroseconds} μs');
    }
  });

  test('should correctly manage multiple listeners', () {
    final controller = _FakeControllerConcurrent();

    void listener1() {}
    void listener2() {}

    expect(controller.subscribers, equals(0));

    controller
      ..addListener(listener1)
      ..addListener(listener2);
    expect(controller.subscribers, equals(2));

    controller.removeListener(listener1);
    expect(controller.subscribers, equals(1));

    controller.removeListener(listener2);
    expect(controller.subscribers, equals(0));
  });
});

void _$assertionGroup() => group('assertion', () {
  test('should assert when notifyListeners called on disposed controller', () {
    final controller = _FakeControllerSequential();
    controller.dispose(); // ignore: cascade_invocations

    expect(controller.isDisposed, isTrue);

    expect(
      () => controller.addWithNotifyListeners(1),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('A _FakeControllerSequential was already disposed.'),
        ),
      ),
    );
  });
  test('should assert when addListener called on disposed controller', () {
    final controller = _FakeControllerSequential();
    controller.dispose(); // ignore: cascade_invocations

    expect(controller.isDisposed, isTrue);

    void listener() {}

    expect(
      () => controller.addListener(listener),
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('A _FakeControllerSequential was already disposed.'),
        ),
      ),
    );
  });
});

void _$genericHandleGroup() => group('generic handle', () {
  test('returns value from handler', () async {
    final controller = _FakeControllerConcurrent();
    final result = await controller.getValue(42);
    expect(result, equals(42));
    controller.dispose();
  });

  test('sequential returns value', () async {
    final controller = _FakeControllerSequential();
    final result = await controller.getValue(100);
    expect(result, equals(100));
    controller.dispose();
  });

  test('droppable returns value when not busy', () async {
    final controller = _FakeControllerDroppable();
    final result = await controller.getValue(77);
    expect(result, equals(77));
    controller.dispose();
  });

  test('droppable returns null when busy', () async {
    final controller = _FakeControllerDroppable();
    // Start first operation
    final first = controller.getValue(1);
    // Try second operation while first is running - returns null
    final second = await controller.getValue(2);
    expect(second, isNull); // Dropped, returns null
    // First operation completes with value
    await expectLater(first, completion(1));
    controller.dispose();
  });
});

void _$methodsGroup() => group('methods', () {
  test('merge', () async {
    final controllerOne = _FakeControllerSequential();
    final controllerTwo = _FakeControllerSequential();

    final mergedListenable = Controller.merge([controllerOne, controllerTwo]);

    // Check that the result is an object of type Listenable
    expect(mergedListenable, isA<Listenable>());

    // Check that subscribers to mergedListenable listen for changes
    // in both controllers
    var listenerCalled = 0;
    mergedListenable.addListener(() => listenerCalled++);

    controllerOne.add(1).ignore();
    await Future<void>.delayed(Duration.zero);
    expect(listenerCalled, equals(1));

    controllerTwo.add(1).ignore();
    await Future<void>.delayed(Duration.zero);
    expect(listenerCalled, equals(2));
  });

  test('toStream', () async {
    final controller = _FakeControllerConcurrent();
    expect(controller.toStream(), isA<Stream<int>>());
    // ignore: unawaited_futures
    expectLater(
      controller.toStream(),
      emitsInOrder(<Object>[1, 0, -1, 2, emitsDone]),
    );
    await expectLater(
      Future.wait([
        controller.add(1),
        controller.subtract(1),
        controller.subtract(1),
        controller.add(3),
      ]),
      completes,
    );
    controller.dispose();
  });

  test('toValueListenable', () async {
    final controller = _FakeControllerConcurrent();
    final listenable = controller.toValueListenable();
    expect(listenable, isA<ValueListenable<int>>());
    expect(listenable.value, equals(controller.state));
    await expectLater(
      Future.wait([controller.add(2), controller.subtract(1)]),
      completes,
    );
    expect(listenable.value, equals(controller.state));
    final completer = Completer<void>();
    listenable.addListener(completer.complete);
    controller.add(1).ignore();
    await expectLater(completer.future, completes);
    expect(completer.isCompleted, isTrue);
    controller.dispose();
  });
});

void _$onErrorGroup() => group('onError', () {
  group('sequential', () {
    test('should call onError and error callback '
        'when an exception is thrown', () async {
      final controller = _FakeControllerSequential();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() => doneCalled++;

      controller.makeError(
        onError: () async {
          onError();
          throw Exception();
        },
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
    test('should execute handler, handle errors, '
        'and call done callback within runZonedGuarded', () async {
      final controller = _FakeControllerSequential();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() {
        doneCalled++;
        throw Exception();
      }

      controller.makeError(
        onError: () async => onError(),
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
  });
  group('droppable', () {
    test('should call onError and error callback '
        'when an exception is thrown', () async {
      final controller = _FakeControllerDroppable();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() => doneCalled++;

      controller.makeError(
        onError: () async {
          onError();
          throw Exception();
        },
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
    test('should execute handler, handle errors, '
        'and call done callback within runZonedGuarded', () async {
      final controller = _FakeControllerDroppable();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() {
        doneCalled++;
        throw Exception();
      }

      controller.makeError(
        onError: () async => onError(),
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
  });
  group('concurrent', () {
    test('should call onError and error callback '
        'when an exception is thrown', () async {
      final controller = _FakeControllerConcurrent();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() => doneCalled++;

      controller.makeError(
        onError: () async {
          onError();
          throw Exception();
        },
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
    test('should execute handler, handle errors, '
        'and call done callback within runZonedGuarded', () async {
      final controller = _FakeControllerConcurrent();

      var errorCalled = 0;
      void onError() {
        errorCalled++;
        throw Exception();
      }

      var doneCalled = 0;
      void onDone() {
        doneCalled++;
        throw Exception();
      }

      controller.makeError(
        onError: () async => onError(),
        onDone: () async => onDone(),
      );
      await Future<void>.delayed(Duration.zero);

      expect(errorCalled, same(1));
      expect(doneCalled, same(1));
    });
  });
});

abstract base class _FakeControllerBase extends StateController<int> {
  _FakeControllerBase({int? initialState})
    : super(initialState: initialState ?? 0);

  Future<void> add(int value) => handle(() async {
    await Future<void>.delayed(Duration.zero);
    setState(state + value);
  });

  Future<void> subtract(int value) => handle(() async {
    await Future<void>.delayed(Duration.zero);
    setState(state - value);
  });

  /// Test generic handle - returns a value
  Future<int?> getValue(int value) => handle<int>(() async {
    await Future<void>.delayed(Duration.zero);
    return value;
  });
}

final class _FakeControllerSequential extends _FakeControllerBase
    with SequentialControllerHandler {
  void addWithNotifyListeners(int value) {
    state + value; // ignore: unnecessary_statements
    notifyListeners();
  }

  void makeError({void Function()? onError, void Function()? onDone}) => handle(
    () async {
      throw Exception();
    },
    error: (_, _) async => onError?.call(),
    done: () async => onDone?.call(),
  );
}

final class _FakeControllerDroppable extends _FakeControllerBase
    with DroppableControllerHandler {
  void makeError({void Function()? onError, void Function()? onDone}) => handle(
    () async {
      throw Exception();
    },
    error: (_, _) async => onError?.call(),
    done: () async => onDone?.call(),
  );
}

final class _FakeControllerConcurrent extends _FakeControllerBase
    with ConcurrentControllerHandler {
  void makeError({void Function()? onError, void Function()? onDone}) => handle(
    () async {
      throw Exception();
    },
    error: (_, _) async => onError?.call(),
    done: () async => onDone?.call(),
  );
}
