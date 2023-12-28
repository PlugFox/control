import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:l/l.dart';

/// Observer for [Controller].
final class ControllerObserver implements IControllerObserver {
  const ControllerObserver();

  @override
  void onCreate(IController controller) {
    l.v6('Controller | ${controller.runtimeType} | Created');
  }

  @override
  void onDispose(IController controller) {
    l.v5('Controller | ${controller.runtimeType} | Disposed');
  }

  @override
  void onStateChanged(
      IController controller, Object prevState, Object nextState) {
    l.d('Controller | ${controller.runtimeType} | $prevState -> $nextState');
  }

  @override
  void onError(IController controller, Object error, StackTrace stackTrace) {
    l.w('Controller | ${controller.runtimeType} | $error', stackTrace);
  }
}

void main() => runZonedGuarded<Future<void>>(
      () async {
        Controller.observer = const ControllerObserver();
        runApp(const App());
      },
      (error, stackTrace) => l.e('Top level exception: $error', stackTrace),
    );

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Control example',
        home: HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body: const SafeArea(
          child: Center(
            child: Text('Hello World'),
          ),
        ),
      );
}
