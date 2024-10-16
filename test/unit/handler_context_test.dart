import 'dart:math' as math;

import 'package:control/control.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('HandlerContext', () {
      test('FakeControllers', () async {
        final controllers = <_FakeControllerBase>[
          _FakeControllerSequential(),
          _FakeControllerDroppable(),
          _FakeControllerConcurrent(),
        ];
        for (final controller in controllers) {
          final observer = Controller.observer = _FakeControllerObserver();
          expect(controller.isProcessing, isFalse);
          expect(observer.lastContext, isNull);
          expect(observer.lastStateContext, isNull);
          expect(observer.lastErrorContext, isNull);
          expect(Controller.context, isNull);

          // After the normal event is called, the context should be available.
          final value = math.Random().nextDouble();
          HandlerContext? lastContext;
          controller.event(
            meta: <String, Object?>{'double': value},
            out: (ctx) => lastContext = ctx,
          ).ignore();
          expect(controller.isProcessing, isTrue);
          expect(lastContext, isNotNull);
          await expectLater(lastContext!.done, completes);
          // Event should be done by now.
          expect(lastContext!.isDone, isTrue);
          expect(
            lastContext,
            allOf(
              isNotNull,
              same(observer.lastContext),
              same(observer.lastStateContext),
              isA<HandlerContext>()
                  .having(
                    (ctx) => ctx.name,
                    'name',
                    'event',
                  )
                  .having(
                    (ctx) => ctx.meta['double'],
                    'meta should contain double',
                    equals(value),
                  )
                  .having(
                    (ctx) => ctx.meta['started_at'],
                    'meta should contain started_at',
                    allOf(
                      isNotNull,
                      isA<DateTime>(),
                    ),
                  )
                  .having(
                    (ctx) => ctx.meta['duration'],
                    'meta should contain duration',
                    allOf(
                      isNotNull,
                      isA<Duration>(),
                      isNot(Duration.zero),
                    ),
                  )
                  .having(
                    (ctx) => ctx.controller,
                    'controller',
                    same(controller),
                  )
                  .having(
                    (ctx) => ctx.isDone,
                    'isDone',
                    isTrue,
                  ),
            ),
          );
          expect(observer.lastErrorContext, isNull);
          expect(Controller.context, isNull);

          controller.dispose();
        }
      });
    });

final class _FakeControllerObserver implements IControllerObserver {
  HandlerContext? lastContext;
  HandlerContext? lastStateContext;
  HandlerContext? lastErrorContext;

  @override
  void onCreate(Controller controller) {/* ignore */}

  @override
  void onDispose(Controller controller) {/* ignore */}

  @override
  void onHandler(HandlerContext context) {
    lastContext = context;
  }

  @override
  void onStateChanged<S extends Object>(
    StateController<S> controller,
    S prevState,
    S nextState,
  ) {
    lastStateContext = Controller.context;
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    lastErrorContext = Controller.context;
  }
}

abstract base class _FakeControllerBase extends StateController<bool> {
  _FakeControllerBase() : super(initialState: false);

  Future<void> event({
    Map<String, Object?>? meta,
    void Function(HandlerContext context)? out,
  }) =>
      handle(
        () async {
          out?.call(Controller.context!);
          final stopwatch = Stopwatch()..start();
          try {
            setState(false);
            await Future<void>.delayed(Duration.zero);
            () {
              out?.call(Controller.context!);
            }();
            setState(true);
            Controller.context?.meta['duration'] = stopwatch.elapsed;
          } finally {
            stopwatch.stop();
          }
        },
        name: 'event',
        meta: {
          ...?meta,
          'started_at': DateTime.now(),
        },
      );
}

final class _FakeControllerSequential = _FakeControllerBase
    with SequentialControllerHandler;

final class _FakeControllerDroppable = _FakeControllerBase
    with DroppableControllerHandler;

final class _FakeControllerConcurrent = _FakeControllerBase
    with ConcurrentControllerHandler;
