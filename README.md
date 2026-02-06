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

## Return Values from Operations

The `handle()` method is generic and can return values:

```dart
class UserController extends StateController<UserState> {
  UserController(this.api) : super(initialState: UserState.initial());

  final UserApi api;

  /// Fetch user and return the user object
  Future<User> fetchUser(String id) => handle<User>(() async {
    final user = await api.getUser(id);
    setState(state.copyWith(user: user, loading: false));
    return user; // Type-safe return value
  });

  /// Update user and return success status
  Future<bool> updateUser(User user) => handle<bool>(() async {
    try {
      await api.updateUser(user);
      setState(state.copyWith(user: user));
      return true;
    } catch (e) {
      return false;
    }
  });
}

// Usage
final user = await controller.fetchUser('123');
print('Fetched: ${user.name}');

final success = await controller.updateUser(updatedUser);
if (success) {
  print('User updated successfully');
}
```

**Note:** With `DroppableControllerHandler`, dropped operations return `null` instead of executing.

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

## Advanced Usage

### UI Feedback with Callbacks

Use `error` and `done` callbacks to provide user feedback through SnackBars, dialogs, or notifications:

```dart
class UserController extends StateController<UserState> {
  UserController(this.api) : super(initialState: UserState.initial());

  final UserApi api;

  Future<User?> updateProfile(
    User user, {
    void Function(User user)? onSuccess,
    void Function(Object error)? onError,
  }) => handle<User>(
    () async {
      final updatedUser = await api.updateUser(user);
      setState(state.copyWith(user: updatedUser));
      onSuccess?.call(updatedUser);
      return updatedUser;
    },
    error: (error, stackTrace) async {
      onError?.call(error);
    },
    name: 'updateProfile',
    meta: {'userId': user.id},
  );
}

// Usage in UI
ElevatedButton(
  onPressed: () => controller.updateProfile(
    updatedUser,
    onSuccess: (user) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated: ${user.name}')),
      );
    },
    onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    },
  ),
  child: const Text('Update Profile'),
)
```

### Interactive Dialogs During Processing

Add interactive dialogs in the middle of processing for user input:

```dart
class AuthController extends StateController<AuthState> {
  AuthController(this.api) : super(initialState: AuthState.initial());

  final AuthApi api;

  Future<bool?> login(
    String email,
    String password, {
    required Future<String> Function() requestSmsCode,
  }) => handle<bool>(
    () async {
      // Step 1: Initial login
      final session = await api.login(email, password);

      // Step 2: Check if 2FA is required
      if (session.requires2FA) {
        // Request SMS code from user via dialog
        final smsCode = await requestSmsCode();

        // Step 3: Verify SMS code
        await api.verify2FA(session.id, smsCode);
      }

      setState(state.copyWith(isAuthenticated: true));
      return true;
    },
    error: (error, stackTrace) async {
      setState(state.copyWith(error: error.toString()));
    },
    name: 'login',
    meta: {'email': email, 'requires2FA': true},
  );
}

// Usage in UI
ElevatedButton(
  onPressed: () => controller.login(
    email,
    password,
    requestSmsCode: () async {
      // Show dialog and wait for user input
      final code = await showDialog<String>(
        context: context,
        builder: (context) => SmsCodeDialog(),
      );
      return code ?? '';
    },
  ),
  child: const Text('Login'),
)
```

### Debugging and Observability

Use `name` and `meta` parameters for debugging, logging, and integration with error tracking services like Sentry or Crashlytics:

```dart
class ControllerObserver implements IControllerObserver {
  const ControllerObserver();

  @override
  void onHandler(HandlerContext context) {
    // Log operation start with metadata
    print('START | ${context.controller.name}.${context.name}');
    print('META  | ${context.meta}');

    final stopwatch = Stopwatch()..start();

    context.done.whenComplete(() {
      // Log operation completion with duration
      stopwatch.stop();
      print('DONE  | ${context.controller.name}.${context.name} | '
            'duration: ${stopwatch.elapsed}');
    });
  }

  @override
  void onError(Controller controller, Object error, StackTrace stackTrace) {
    final context = Controller.context;

    if (context != null) {
      // Send breadcrumbs to Sentry/Crashlytics
      Sentry.addBreadcrumb(Breadcrumb(
        message: '${controller.name}.${context.name}',
        data: context.meta,
        level: SentryLevel.error,
      ));

      // Report error with full context
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'controller': controller.name,
          'operation': context.name,
          'metadata': context.meta,
        }),
      );
    }
  }

  @override
  void onStateChanged<S extends Object>(
    StateController<S> controller,
    S prevState,
    S nextState,
  ) {
    final context = Controller.context;

    // Log state changes with operation context
    if (context != null) {
      print('STATE | ${controller.name}.${context.name} | '
            '$prevState -> $nextState');
      print('META  | ${context.meta}');
    }
  }

  @override
  void onCreate(Controller controller) {
    print('CREATE | ${controller.name}');
  }

  @override
  void onDispose(Controller controller) {
    print('DISPOSE | ${controller.name}');
  }
}

// Setup in main
void main() {
  Controller.observer = const ControllerObserver();
  runApp(const App());
}
```

**Benefits of using `name` and `meta`:**
- **Debugging**: Easily track which operation is executing
- **Logging**: Add context to logs for better traceability
- **Profiling**: Measure operation duration and performance
- **Error tracking**: Send rich context to Sentry/Crashlytics
- **Analytics**: Track user actions with metadata
- **Breadcrumbs**: Build execution trail for debugging crashes

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
