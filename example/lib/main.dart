import 'dart:async';

import 'package:control/control.dart';
import 'package:flutter/material.dart';
import 'package:l/l.dart';

/// Observer for [Controller], react to changes in the any controller.
final class ControllerObserver implements IControllerObserver {
  const ControllerObserver();

  @override
  void onCreate(Controller controller) {
    l.v6('Controller | ${controller.name}.new');
  }

  @override
  void onDispose(Controller controller) {
    l.v5('Controller | ${controller.name}.dispose');
  }

  @override
  void onHandler(HandlerContext context) {
    final stopwatch = Stopwatch()..start();
    l.d(
      'Controller | '
      '${context.controller.name}.${context.name}',
      context.meta,
    );
    context.done.whenComplete(() {
      stopwatch.stop();
      l.d(
        'Controller | '
        '${context.controller.name}.${context.name} | '
        'duration: ${stopwatch.elapsed}',
        context.meta,
      );
    });
  }

  @override
  void onStateChanged<S extends Object>(
    StateController<S> controller,
    S prevState,
    S nextState,
  ) {
    final context = Controller.context;
    if (context == null) {
      // State change occurred outside of the handler
      l.d(
        'StateController | '
        '${controller.name} | '
        '$prevState -> $nextState',
      );
    } else {
      // State change occurred inside the handler
      l.d(
        'StateController | '
        '${controller.name}.${context.name} | '
        '$prevState -> $nextState',
        context.meta,
      );
    }
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    final context = Controller.context;
    if (context == null) {
      // Error occurred outside of the handler
      l.w(
        'Controller | '
        '${controller.name} | '
        '$error',
        stackTrace,
      );
    } else {
      // Error occurred inside the handler
      l.w(
        'Controller | '
        '${controller.name}.${context.name} | '
        '$error',
        stackTrace,
        context.meta,
      );
    }
  }
}

void main() => runZonedGuarded<Future<void>>(() async {
  // Setup controller observer
  Controller.observer = const ControllerObserver();
  runApp(const App());
}, (error, stackTrace) => l.e('Top level exception: $error', stackTrace));

/// Counter state for [CounterController]
typedef CounterState = ({int count, bool idle});

/// Counter controller with sequential handler
class CounterController extends StateController<CounterState>
    with SequentialControllerHandler {
  /// Creates a [CounterController] with an optional initial state.
  CounterController({CounterState? initialState})
    : super(initialState: initialState ?? (idle: true, count: 0));

  /// Adds a value to the current count.
  Future<int?> add(
    int value, {
    void Function(int result)? onSuccess,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) => handle<int>(
    () async {
      setState((idle: false, count: state.count));
      final result = await Future<int>.delayed(
        const Duration(milliseconds: 1500),
        () => state.count + value,
      );
      setState((idle: true, count: result));
      onSuccess?.call(result);
      return result;
    },
    error: (error, stackTrace) async {
      onError?.call(error, stackTrace);
    },
    done: () async {},
    name: 'add',
    meta: {'operation': 'add', 'value': value},
  );

  /// Subtracts a value from the current count.
  Future<int?> subtract(
    int value, {
    void Function(int result)? onSuccess,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) => handle<int>(
    () async {
      setState((idle: false, count: state.count));
      final result = await Future<int>.delayed(
        const Duration(milliseconds: 1500),
        () => state.count - value,
      );
      onSuccess?.call(result);
      setState((idle: true, count: result));
      return result;
    },
    error: (error, stackTrace) async {
      onError?.call(error, stackTrace);
    },
    done: () async {},
    name: 'subtract',
    meta: {'operation': 'subtract', 'value': value},
  );
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
        ControllerScope<CounterController>(CounterController.new, child: child),
  );
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Counter')),
    floatingActionButton: const CounterScreen$Buttons(),
    body: const SafeArea(child: Center(child: CounterScreen$Text())),
  );
}

class CounterScreen$Text extends StatelessWidget {
  const CounterScreen$Text({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.headlineMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Count: ', style: style),
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
                    child: FadeTransition(opacity: animation, child: child),
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
  const CounterScreen$Buttons({super.key});

  /// Show a message using a [SnackBar].
  static void showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    // Transform [StateController] in to [ValueListenable]
    valueListenable: context.controllerOf<CounterController>().select(
      (state) => state.idle,
    ),
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
                  ? () => context.controllerOf<CounterController>().add(
                      1,
                      onSuccess: (result) =>
                          showMessage(context, 'Result: $result'),
                    )
                  : null,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              key: ValueKey('subtract#${idle ? 'enabled' : 'disabled'}'),
              onPressed: idle
                  ? () => context.controllerOf<CounterController>().subtract(
                      1,
                      onSuccess: (result) =>
                          showMessage(context, 'Result: $result'),
                    )
                  : null,
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      ),
    ),
  );
}
