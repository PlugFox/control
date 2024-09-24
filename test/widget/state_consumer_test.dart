import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/test_util.dart';

void main() => group('StateConsumer - ', () {
      _$baseGroup();
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
