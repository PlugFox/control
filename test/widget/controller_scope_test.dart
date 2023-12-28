import 'package:control/src/controller_scope.dart';
import 'package:control/src/sequential_controller_concurrency.dart';
import 'package:control/src/state_consumer.dart';
import 'package:control/src/state_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() => group('ControllerScope', () {
      _$valueGroup();
      _$createGroup();
    });

void _$valueGroup() => group('ControllerScope.value', () {
      test('constructor', () {
        expect(
          () => ControllerScope(_FakeController.new),
          returnsNormally,
        );
        expect(
          ControllerScope(_FakeController.new),
          isA<ControllerScope>(),
        );
      });

      testWidgets(
        'inject_and_recive',
        (tester) async {
          final controller = _FakeController();
          await tester.pumpWidget(
            _appContext(
              child: ControllerScope.value(
                controller,
                child: StateConsumer(
                  controller: controller,
                  builder: (context, state, child) => Text('$state'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('0'), findsOneWidget);
          expect(find.text('1'), findsNothing);
          controller.add(1);
          await tester.pumpAndSettle();
          expect(find.text('0'), findsNothing);
          expect(find.text('1'), findsOneWidget);
          controller.subtract(2);
          await tester.pumpAndSettle();
          expect(controller.state, equals(-1));
          expect(find.text('-1'), findsOneWidget);
          controller.dispose();
        },
      );
    });

void _$createGroup() => group('ControllerScope.create', () {
      test('constructor', () {
        expect(
          () => ControllerScope(_FakeController.new),
          returnsNormally,
        );
        expect(
          ControllerScope(_FakeController.new),
          isA<ControllerScope>(),
        );
      });

      testWidgets(
        'inject and recive',
        (tester) async {},
      );
    });

/// Basic wrapper for the current widgets.
Widget _appContext({required Widget child, Size? size}) => MediaQuery(
      data: MediaQueryData(
        size: size ?? const Size(800, 600),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          elevation: 0,
          child: DefaultSelectionStyle(
            child: ScaffoldMessenger(
              child: HeroControllerScope.none(
                child: Navigator(
                  pages: <Page<void>>[
                    MaterialPage<void>(
                      child: Scaffold(
                        body: SafeArea(
                          child: Center(
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                  onPopPage: (route, result) => route.didPop(result),
                ),
              ),
            ),
          ),
        ),
      ),
    );

final class _FakeController extends StateController<int>
    with SequentialControllerConcurrency {
  _FakeController({int? initialState}) : super(initialState: initialState ?? 0);

  void add(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state + value);
      });

  void subtract(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state - value);
      });
}
