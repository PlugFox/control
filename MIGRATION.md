# Migration Guide: 0.x to 1.0.0

This guide will help you migrate from Control 0.x to 1.0.0.

## Overview of Changes

Version 1.0.0 introduces significant architectural improvements:

1. **Removed `base` modifiers** - More flexibility in inheritance
2. **Default concurrent behavior** - No forced mixin selection
3. **Simplified mixins** - Built on top of Mutex
4. **New `handle()` signature** - Added `error` and `done` callbacks

## Breaking Changes

### 1. Remove `base` from Controller Classes

**Before (0.x):**
```dart
final class MyController extends StateController<MyState>
    with SequentialControllerHandler {
  // ...
}
```

**After (1.0.0):**
```dart
class MyController extends StateController<MyState>
    with SequentialControllerHandler {
  // ...
}
```

**Why:** The `base` modifier forced users to use `final` or `base` on their controller classes. Removing it provides more flexibility.

**Action Required:** Remove `base` or `final` modifiers from your controller class declarations if you want more flexibility. You can keep `final` if you prefer.

### 2. Remove ConcurrentControllerHandler Mixin

**Before (0.x):**
```dart
class MyController extends StateController<MyState>
    with ConcurrentControllerHandler {
  void operation() => handle(() async { ... });
}
```

**After (1.0.0):**
```dart
class MyController extends StateController<MyState> {
  // Concurrent by default - no mixin needed!
  void operation() => handle(() async { ... });
}
```

**Why:** The base `Controller` class now provides concurrent behavior by default. The mixin is redundant.

**Action Required:** Remove `with ConcurrentControllerHandler` from your controller declarations. The mixin is deprecated but still available for backwards compatibility.

### 3. Update handle() Calls with Error Handling

The `handle()` method signature has been extended:

**Before (0.x):**
```dart
void operation() => handle(
  () async { ... },
  name: 'operation',
  meta: {'key': 'value'},
);
```

**After (1.0.0):**
```dart
void operation() => handle(
  () async { ... },
  error: (error, stackTrace) async {
    // Optional: handle errors
  },
  done: () async {
    // Optional: cleanup or completion logic
  },
  name: 'operation',
  meta: {'key': 'value'},
);
```

**Why:** The new parameters were always available in mixins but not in the base interface. Now they're standardized.

**Action Required:**
- No action required - `error` and `done` are optional
- If you were using custom error handling in mixins, you can now use it in all controllers
- Update your code if you want to use the new error handling capabilities

## Migration Scenarios

### Scenario 1: Simple Concurrent Controller

**Before:**
```dart
final class MyController extends StateController<MyState>
    with ConcurrentControllerHandler {
  MyController() : super(initialState: MyState.initial());

  void fetchData() => handle(() async {
    final data = await api.fetch();
    setState(state.copyWith(data: data));
  });
}
```

**After:**
```dart
class MyController extends StateController<MyState> {
  MyController() : super(initialState: MyState.initial());

  void fetchData() => handle(() async {
    final data = await api.fetch();
    setState(state.copyWith(data: data));
  });
}
```

**Changes:**
- Removed `final` modifier
- Removed `with ConcurrentControllerHandler`

### Scenario 2: Sequential Controller

**Before:**
```dart
final class MyController extends StateController<MyState>
    with SequentialControllerHandler {
  void operation1() => handle(() async { ... });
  void operation2() => handle(() async { ... });
}
```

**After:**
```dart
class MyController extends StateController<MyState>
    with SequentialControllerHandler {
  void operation1() => handle(() async { ... });
  void operation2() => handle(() async { ... });
}
```

**Changes:**
- Only removed `final` modifier (optional)
- Mixin works the same way

### Scenario 3: Droppable Controller

**Before:**
```dart
final class MyController extends StateController<MyState>
    with DroppableControllerHandler {
  void operation() => handle(() async { ... });
}
```

**After:**
```dart
class MyController extends StateController<MyState>
    with DroppableControllerHandler {
  void operation() => handle(() async { ... });
}
```

**Changes:**
- Only removed `final` modifier (optional)
- Mixin works the same way

### Scenario 4: Mixed Concurrency Patterns

**New in 1.0.0:** You can now use Mutex directly for custom patterns:

```dart
class MyController extends StateController<MyState> {
  MyController() : super(initialState: MyState.initial());

  final _criticalMutex = Mutex();
  final _batchMutex = Mutex();

  // Sequential critical operations
  void saveToDB() => _criticalMutex.synchronize(
    () => handle(() async {
      // Critical database operation
    }),
  );

  // Sequential batch operations
  void processBatch() => _batchMutex.synchronize(
    () => handle(() async {
      // Batch processing
    }),
  );

  // Concurrent queries (default behavior)
  void fetchData() => handle(() async {
    // Fast concurrent query
  });

  // Droppable UI actions
  void onButtonTap() {
    final unlock = _criticalMutex.tryLock();
    if (unlock == null) return; // Already running, drop

    handle(() async {
      // Handle button tap
    }).whenComplete(unlock);
  }
}
```

## Step-by-Step Migration Checklist

1. **Update dependency in pubspec.yaml:**
   ```yaml
   dependencies:
     control: ^1.0.0
   ```

2. **Run Flutter pub get:**
   ```bash
   flutter pub get
   ```

3. **Find all controllers:**
   ```bash
   grep -r "extends.*Controller" lib/
   ```

4. **For each controller:**
   - [ ] Remove `base` or `final` modifier (optional but recommended)
   - [ ] Remove `with ConcurrentControllerHandler` if present
   - [ ] Keep `with SequentialControllerHandler` or `with DroppableControllerHandler`
   - [ ] Consider using Mutex directly for complex scenarios

5. **Run tests:**
   ```bash
   flutter test
   ```

6. **Check for deprecation warnings:**
   ```bash
   flutter analyze
   ```

## Common Issues and Solutions

### Issue 1: "The member 'handle' overrides an inherited member"

**Solution:** This is just an informational message. The code works correctly. The IDE may show this while it updates its cache.

### Issue 2: "ConcurrentControllerHandler is deprecated"

**Solution:** Remove `with ConcurrentControllerHandler` from your controller. Concurrent is now the default behavior.

### Issue 3: Tests failing after migration

**Solution:**
- Ensure all test controllers are updated
- Check if tests rely on specific timing - concurrent behavior may differ
- Update mocks if using custom mixins

## Benefits After Migration

After migrating to 1.0.0, you'll benefit from:

1. **More flexibility** - No forced `final` modifier
2. **Cleaner code** - No redundant `ConcurrentControllerHandler`
3. **Better control** - Use Mutex directly for custom patterns
4. **Simpler architecture** - Less boilerplate, easier to understand
5. **Same guarantees** - All existing tests pass

## Need Help?

If you encounter issues during migration:

1. Check the [examples](example/) directory for updated patterns
2. Review [IDEAS.md](IDEAS.md) for architecture explanation
3. Open an issue on [GitHub](https://github.com/PlugFox/control/issues)

## Rollback

If you need to rollback to 0.x:

```yaml
dependencies:
  control: ^0.2.0
```

Then restore your `base`/`final` modifiers and `ConcurrentControllerHandler` mixins.
