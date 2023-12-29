import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:l/l.dart';

/// Observer for [Controller], react to changes in the any controller.
final class ControllerObserver implements IControllerObserver {
  const ControllerObserver();

  @override
  void onCreate(Controller controller) {
    l.v6('Controller | ${controller.runtimeType} | Created');
  }

  @override
  void onDispose(Controller controller) {
    l.v5('Controller | ${controller.runtimeType} | Disposed');
  }

  @override
  void onStateChanged<S extends Object>(
      StateController<S> controller, S prevState, S nextState) {
    l.d('StateController | ${controller.runtimeType} | $prevState -> $nextState');
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    l.w('Controller | ${controller.runtimeType} | $error', stackTrace);
  }
}

void main() => runZonedGuarded<Future<void>>(
      () async {
        // Setup controller observer
        Controller.observer = const ControllerObserver();
        runApp(const App());
      },
      (error, stackTrace) => l.e('Top level exception: $error', stackTrace),
    );

/// Counter state for [CounterController]
typedef CounterState = ({int count, bool idle});

/// Counter controller
final class CounterController extends StateController<CounterState>
    with SequentialControllerHandler {
  CounterController({CounterState? initialState})
      : super(initialState: initialState ?? (idle: true, count: 0));

  void add(int value) => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        setState((idle: true, count: state.count + value));
      });

  void subtract(int value) => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        setState((idle: true, count: state.count - value));
      });
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'StateController example',
      theme: ThemeData.dark(),
      home: const CounterScreen(),
      builder: (context, child) =>
          // Create and inject the controller into the element tree.
          ControllerScope<CounterController>(
            CounterController.new,
            child: child,
          ));
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Counter'),
        ),
        floatingActionButton: const CounterScreen$Buttons(),
        body: const SafeArea(
          child: Center(
            child: CounterScreen$Text(),
          ),
        ),
      );
}

class CounterScreen$Text extends StatelessWidget {
  const CounterScreen$Text({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.headlineMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Count: ',
          style: style,
        ),
        SizedBox.square(
          dimension: 64,
          child: Center(
            // Receive CounterController from the element tree
            // and rebuild the widget when the state changes.
            child: StateConsumer<CounterController, CounterState>(
              buildWhen: (previous, current) =>
                  previous.count != current.count ||
                  previous.idle != current.idle,
              builder: (context, state, _) {
                final text = state.count.toString();
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  ),
                  child: state.idle
                      ? Text(text, style: style, overflow: TextOverflow.fade)
                      : const CircularProgressIndicator(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CounterScreen$Buttons extends StatelessWidget {
  const CounterScreen$Buttons({
    super.key,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        // Transform [StateController] in to [ValueListenable]
        valueListenable: context
            .controllerOf<CounterController>()
            .select((state) => state.idle),
        builder: (context, idle, _) => IgnorePointer(
          ignoring: !idle,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: idle ? 1 : .25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FloatingActionButton(
                  key: ValueKey('add#${idle ? 'enabled' : 'disabled'}'),
                  onPressed: idle
                      ? () => context.controllerOf<CounterController>().add(1)
                      : null,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  key: ValueKey('subtract#${idle ? 'enabled' : 'disabled'}'),
                  onPressed: idle
                      ? () =>
                          context.controllerOf<CounterController>().subtract(1)
                      : null,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ),
      );
}
