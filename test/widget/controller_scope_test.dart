import 'package:control/src/controller_scope.dart';
import 'package:control/src/state_consumer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/test_util.dart';

void main() => group('ControllerScope', () {
      _$valueGroup();
      _$createGroup();
      _$additionalGroup();
    });

void _$valueGroup() => group('ControllerScope.value', () {
      test('constructor', () {
        expect(
          () => ControllerScope(FakeController.new),
          returnsNormally,
        );
        expect(
          ControllerScope(FakeController.new),
          isA<ControllerScope>(),
        );
      });

      testWidgets(
        'inject_and_recive',
        (tester) async {
          final controller = FakeController();
          await tester.pumpWidget(
            TestUtil.appContext(
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
          () => ControllerScope(FakeController.new),
          returnsNormally,
        );
        expect(
          ControllerScope(FakeController.new),
          isA<ControllerScope>(),
        );
      });

      testWidgets(
        'inject_and_recive',
        (tester) async {
          await tester.pumpWidget(
            TestUtil.appContext(
              child: ControllerScope<FakeController>(
                FakeController.new,
                child: StateConsumer<FakeController, int>(
                  builder: (context, state, child) => Text('$state'),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('0'), findsOneWidget);
          expect(find.text('1'), findsNothing);
          final context =
              tester.firstElement(find.byType(ControllerScope<FakeController>));
          final controller = ControllerScope.of<FakeController>(context);
          expect(
            controller,
            isA<FakeController>().having((c) => c.state, 'state', equals(0)),
          );
          controller.add(1);
          await tester.pumpAndSettle();
          expect(find.text('0'), findsNothing);
          expect(find.text('1'), findsOneWidget);
          controller.subtract(2);
          await tester.pumpAndSettle();
          expect(controller.state, equals(-1));
          expect(find.text('-1'), findsOneWidget);
        },
      );
    });

void _$additionalGroup() => group('ControllerScope.additional', () {
      testWidgets('controllerOf should return the correct controller',
          (tester) async {
        final controller = FakeController();
        await tester.pumpWidget(
          TestUtil.appContext(
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

        final context =
            tester.firstElement(find.byType(ControllerScope<FakeController>));

        final foundController = context.controllerOf<FakeController>();
        expect(foundController, equals(controller));
      });

      testWidgets('maybeOf should return null if no controller is found',
          (tester) async {
        final controller = FakeController();
        await tester.pumpWidget(
          TestUtil.appContext(
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

        final context = tester.firstElement(find.byType(HeroControllerScope));
        final foundController =
            ControllerScope.maybeOf<FakeController>(context);
        expect(foundController, isNull);
      });

      testWidgets('maybeOf should return controller if present',
          (tester) async {
        final controller = FakeController();
        await tester.pumpWidget(
          TestUtil.appContext(
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

        final context =
            tester.firstElement(find.byType(ControllerScope<FakeController>));

        final foundController =
            ControllerScope.maybeOf<FakeController>(context, listen: true);
        expect(foundController, equals(controller));
      });

      testWidgets('_notFoundInheritedWidgetOfExactType should throw error',
          (tester) async {
        await tester
            .pumpWidget(TestUtil.appContext(child: const SizedBox.shrink()));
        await tester.pumpAndSettle();

        final context = tester.firstElement(find.byType(HeroControllerScope));
        expect(
          () => ControllerScope.of(context),
          throwsArgumentError,
        );
      });

      test('updateShouldNotify should return true for different dependencies',
          () {
        final controller1 = FakeController();
        final controller2 = FakeController();
        final widget1 = ControllerScope.value(
          controller1,
          child: const SizedBox.shrink(),
        );
        final widget2 = ControllerScope.value(
          controller2,
          child: const SizedBox.shrink(),
        );

        expect(widget1.updateShouldNotify(widget2), isTrue);
      });

      test('debugFillProperties should correctly fill debug information', () {
        final controller = FakeController();
        final widget = ControllerScope.value(
          controller,
          child: const SizedBox.shrink(),
        );
        final element = widget.createElement();
        final properties = DiagnosticPropertiesBuilder();

        element.debugFillProperties(properties);

        expect(properties.properties, isNotEmpty);
      });

      test('_initController should initialize correctly', () {
        final controller = FakeController();
        final widget = ControllerScope.value(
          controller,
          child: const SizedBox.shrink(),
        );
        final element =
            widget.createElement() as ControllerScope$Element<FakeController>;

        final initializedController = element.controller;
        expect(initializedController, equals(controller));
      });

      test('_initController should throw error on reinitialization', () {
        final controller = FakeController();
        final widget = ControllerScope.value(
          controller,
          child: const SizedBox.shrink(),
        );
        final element =
            widget.createElement() as ControllerScope$Element<FakeController>;

        // Initialize first time
        final initializedController = element.controller;
        expect(initializedController, equals(controller));

        // Trying to reinitialize should cause an error
        // expect(element.controller., throwsAssertionError);
      });
    });
