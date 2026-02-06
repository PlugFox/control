# Control: State Management for Flutter

[![Pub](https://img.shields.io/pub/v/control.svg)](https://pub.dev/packages/control)
[![Actions Status](https://github.com/PlugFox/control/actions/workflows/checkout.yml/badge.svg)](https://github.com/PlugFox/control/actions)
[![Coverage](https://codecov.io/gh/PlugFox/control/branch/master/graph/badge.svg)](https://codecov.io/gh/PlugFox/control)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Linter](https://img.shields.io/badge/style-linter-40c4ff.svg)](https://pub.dev/packages/linter)
[![GitHub stars](https://img.shields.io/github/stars/plugfox/control?style=social)](https://github.com/plugfox/control/)

A simple, flexible state management library for Flutter with built-in concurrency support.

---

## Features

- 🎯 **Simple API** - Easy to learn and use
- 🔄 **Flexible Concurrency** - Sequential, concurrent, or droppable operation handling
- 🛡️ **Type Safe** - Full type safety with Dart's type system
- 🔍 **Observable** - Built-in observer for debugging and logging
- 🧪 **Well Tested** - Comprehensive test coverage
- 📦 **Lightweight** - Minimal dependencies
- 🔧 **Customizable** - Use Mutex for custom concurrency patterns

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  control: ^1.0.0
```

## Quick Start

### Basic Example

```dart
/// Counter state
typedef CounterState = ({int count, bool idle});

/// Counter controller - concurrent by default
class CounterController extends StateController<CounterState> {
  CounterController({CounterState? initialState})
      : super(initialState: initialState ?? (idle: true, count: 0));

  void increment() => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        setState((idle: true, count: state.count + 1));
      });

  void decrement() => handle(() async {
        setState((idle: false, count: state.count));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        setState((idle: true, count: state.count - 1));
      });
}
```

## Concurrency Strategies

### 1. Concurrent (Default)

Operations execute in parallel without waiting for each other:

```dart
class MyController extends StateController<MyState> {
  MyController() : super(initialState: MyState.initial());

  // These operations run concurrently
  void operation1() => handle(() async { ... });
  void operation2() => handle(() async { ... });
}
```

### 2. Sequential (with Mixin)

Operations execute one after another in FIFO order:

```dart
class MyController extends StateController<MyState>
    with SequentialControllerHandler {
  MyController() : super(initialState: MyState.initial());

  // These operations run sequentially
  void operation1() => handle(() async { ... });
  void operation2() => handle(() async { ... });
}
```

### 3. Droppable (with Mixin)

New operations are dropped if one is already running:

```dart
class MyController extends StateController<MyState>
    with DroppableControllerHandler {
  MyController() : super(initialState: MyState.initial());

  // If operation1 is running, operation2 is dropped
  void operation1() => handle(() async { ... });
  void operation2() => handle(() async { ... });
}
```

### 4. Custom (with Mutex)

Use `Mutex` directly for fine-grained control:

```dart
class MyController extends StateController<MyState> {
  MyController() : super(initialState: MyState.initial());

  final _criticalMutex = Mutex();
  final _batchMutex = Mutex();

  // Sequential critical operations
  void criticalOperation() => _criticalMutex.synchronize(
    () => handle(() async { ... }),
  );

  // Sequential batch operations (different queue)
  void batchOperation() => _batchMutex.synchronize(
    () => handle(() async { ... }),
  );

  // Concurrent fast operations
  void fastOperation() => handle(() async { ... });
}
```

## Usage in Flutter

### Inject Controller

Use `ControllerScope` to provide controller to widget tree:

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: ControllerScope<CounterController>(
      CounterController.new,
      child: const CounterScreen(),
    ),
  );
}
```

### Consume State

Use `StateConsumer` to rebuild widgets when state changes:

```dart
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: StateConsumer<CounterController, CounterState>(
      builder: (context, state, _) => Text('Count: ${state.count}'),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () => context.controllerOf<CounterController>().increment(),
      child: Icon(Icons.add),
    ),
  );
}
```

### Use ValueListenable

Convert state to `ValueListenable` for granular updates:

```dart
ValueListenableBuilder<bool>(
  valueListenable: controller.select((state) => state.idle),
  builder: (context, isIdle, _) => ElevatedButton(
    onPressed: isIdle ? () => controller.increment() : null,
    child: Text('Increment'),
  ),
)
```

## Advanced Features

### Error Handling

The `handle()` method provides built-in error handling:

```dart
void riskyOperation() => handle(
  () async {
    // Your operation
    throw Exception('Something went wrong');
  },
  error: (error, stackTrace) async {
    // Handle error
    print('Error: $error');
  },
  done: () async {
    // Always called, even if error occurs
    print('Operation completed');
  },
  name: 'riskyOperation', // For debugging
);
```

### Observer Pattern

Monitor all controller events for debugging:

```dart
class MyObserver implements IControllerObserver {
  @override
  void onCreate(Controller controller) {
    print('Controller created: ${controller.name}');
  }

  @override
  void onHandler(HandlerContext context) {
    print('Handler started: ${context.name}');
  }

  @override
  void onStateChanged<S extends Object>(
    StateController<S> controller,
    S prevState,
    S nextState,
  ) {
    print('State changed: $prevState -> $nextState');
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    print('Error in ${controller.name}: $error');
  }

  @override
  void onDispose(Controller controller) {
    print('Controller disposed: ${controller.name}');
  }
}

void main() {
  Controller.observer = MyObserver();
  runApp(MyApp());
}
```

### Mutex

Use `Mutex` for custom synchronization:

```dart
final mutex = Mutex();

// Method 1: synchronize (automatic unlock)
await mutex.synchronize(() async {
  // Critical section
});

// Method 2: lock/unlock (manual control)
final unlock = await mutex.lock();
try {
  // Critical section
  if (someCondition) {
    unlock();
    return; // Early exit
  }
  // More code
} finally {
  unlock();
}

// Check if locked
if (mutex.locked) {
  print('Mutex is currently locked');
}
```

## Migration from 0.x to 1.0.0

See [MIGRATION.md](MIGRATION.md) for detailed migration guide.

**Key changes:**
- Remove `base` from controller classes
- `ConcurrentControllerHandler` is deprecated (remove it)
- Controllers are concurrent by default
- Use `Mutex` for custom concurrency patterns

## Best Practices

1. **Choose the right concurrency strategy:**
   - Default (concurrent) for independent operations
   - Sequential for operations that must complete in order
   - Droppable for operations that should cancel if busy
   - Custom Mutex for complex scenarios

2. **Use `handle()` for all async operations:**
   - Automatic error catching
   - Observer notifications
   - Proper disposal handling

3. **Keep state immutable:**
   - Use records or immutable classes for state
   - Always create new state instances

4. **Dispose controllers:**
   - Controllers are automatically disposed by `ControllerScope`
   - Manual disposal only needed for manually created controllers

## Examples

See [example/](example/) directory for complete examples:
- Basic counter
- Advanced concurrency patterns
- Error handling
- Custom observers

## Coverage

[![](https://codecov.io/gh/PlugFox/control/branch/master/graphs/sunburst.svg)](https://codecov.io/gh/PlugFox/control/branch/master)

## Changelog

Refer to the [Changelog](https://github.com/PlugFox/control/blob/master/CHANGELOG.md) to get all release notes.

## Maintainers

- [Matiunin Mikhail aka Plague Fox](https://plugfox.dev)

## Funding

If you want to support the development of our library, there are several ways you can do it:

- [Buy me a coffee](https://www.buymeacoffee.com/plugfox)
- [Support on Patreon](https://www.patreon.com/plugfox)
- [Subscribe through Boosty](https://boosty.to/plugfox)

We appreciate any form of support, whether it's a financial donation or just a star on GitHub. It helps us to continue developing and improving our library. Thank you for your support!

## License

[MIT](https://opensource.org/licenses/MIT)
