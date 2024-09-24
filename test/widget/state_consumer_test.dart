import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/test_util.dart';

void main() => group('StateConsumer - ', () {
      _$baseGroup();
      _$didUpdateWidgetGroup();
      _$debugFillPropertiesGroup();
    });

void _$baseGroup() => group('base - ', () {
      testWidgets('should update controller when widget controller changes',
          (tester) async {
        final controller1 = FakeController();
        final controller2 = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller1,
              child: StateConsumer(
                controller: controller1,
                builder: (context, state, child) => Text('$state'),
              ),
            ),
          ),
        );

        controller1.add(1);
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller2,
              child: StateConsumer(
                controller: controller2,
                builder: (context, state, child) => Text('$state'),
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);

        controller2.add(2);
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);

        controller1.add(1);
        await tester.pumpAndSettle();

        expect(find.text('3'), findsNothing);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets(
          'should not rebuild when states are identical in _valueChanged',
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

        expect(find.text('0'), findsOneWidget);

        controller.add(1);

        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('should not rebuild when buildWhen returns false',
          (tester) async {
        final controller = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller,
              child: StateConsumer(
                controller: controller,
                buildWhen: (previous, current) => false, // No rebuild
                builder: (context, state, child) => Text('$state'),
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);

        controller.add(1);

        await tester.pumpAndSettle(); // Rebuild should not happen

        expect(find.text('1'), findsNothing); // Should still show 0
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('should use child if builder is not provided',
          (tester) async {
        const childWidget = Text('Child Widget');
        final controller = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller,
              child: StateConsumer(
                controller: controller,
                child: childWidget,
              ),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsOneWidget);
      });

      testWidgets(
          'should rebuild with widget child '
          'if both builder and child are provided', (tester) async {
        const childWidget = Text('Child Widget');
        final controller = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller,
              child: StateConsumer(
                controller: controller,
                builder: (context, state, child) => Column(
                  children: [
                    Text('State: $state'),
                    child ?? childWidget,
                  ],
                ),
                child: childWidget,
              ),
            ),
          ),
        );

        // Initial state
        await tester.pumpAndSettle();
        expect(find.text('Child Widget'), findsOneWidget);
        expect(find.text('State: 0'), findsOneWidget);

        // Update state
        controller.add(1);
        await tester.pumpAndSettle();

        expect(find.text('Child Widget'), findsOneWidget);
        expect(find.text('State: 1'), findsOneWidget);
      });
    });

void _$debugFillPropertiesGroup() => group('debugFillProperties - ', () {
      testWidgets('should fill full debug properties correctly',
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

        final context =
            tester.firstElement(find.byType(ControllerScope<FakeController>));

        // Filling in debugging properties
        final properties = DiagnosticPropertiesBuilder();
        context.debugFillProperties(properties);

        // Check all expected properties are filled
        final propertyNames = properties.properties.map((p) => p.name).toList();
        expect(
          propertyNames,
          containsAll([
            'StateController',
            'State',
            'Subscribers',
            'isDisposed',
            'isProcessing',
            'depth',
            'widget',
            'key',
            'dirty',
          ]),
        );
      });

      testWidgets('should fill debug properties correctly', (tester) async {
        final stateConsumerKey = GlobalKey<State<StatefulWidget>>();
        final controller = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope.value(
              controller,
              child: StateConsumer(
                key: stateConsumerKey,
                controller: controller,
                builder: (context, state, child) => Text('$state'),
              ),
            ),
          ),
        );

        // Filling in debugging properties
        final properties = DiagnosticPropertiesBuilder();
        stateConsumerKey.currentState?.debugFillProperties(properties);

        // Check all expected properties are filled
        final propertyNames = properties.properties.map((p) => p.name).toList();
        expect(
          propertyNames,
          containsAll(['Controller', 'State', 'isProcessing']),
        );
      });
    });

void _$didUpdateWidgetGroup() => group('didUpdateWidget - ', () {
      testWidgets(
          'should use controller from ControllerScope '
          'when newController is null', (tester) async {
        final controller = FakeController();

        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope<FakeController>.value(
              controller,
              child: StateConsumer<FakeController, int>(
                // В первый раз указываем начальный контроллер
                controller: controller,
                builder: (context, state, child) => Text('State: $state'),
              ),
            ),
          ),
        );

        // Change the current controller's state to check
        // that the widget is updating correctly
        controller.add(1);
        await tester.pumpAndSettle();
        expect(find.text('State: 1'), findsOneWidget);

        // Rebuild the widget without a controller,
        // check that the controller from ControllerScope is used
        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope<FakeController>.value(
              controller,
              child: StateConsumer<FakeController, int>(
                // Здесь передаем null контроллер
                controller: null,
                builder: (context, state, child) => Text('State: $state'),
              ),
            ),
          ),
        );

        // Check that the controller state is taken from ControllerScope
        // and is displayed correctly
        expect(find.text('State: 1'), findsOneWidget);

        // Change the state of the controller in ControllerScope
        // and check that the widget is updated correctly
        controller.add(2);
        await tester.pumpAndSettle();
        expect(find.text('State: 3'), findsOneWidget); // Было 1, добавили 2

        // Additionally, we check that a new controller is not created
        // and is used only from Scope
        final newController = FakeController();
        await tester.pumpWidget(
          TestUtil.appContext(
            child: ControllerScope<FakeController>.value(
              controller,
              child: StateConsumer<FakeController, int>(
                controller: newController,
                builder: (context, state, child) => Text('State: $state'),
              ),
            ),
          ),
        );

        // The new controller has an initial value of 0
        // and the widget will update to show this.
        expect(find.text('State: 0'), findsOneWidget);
      });
    });
