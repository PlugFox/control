# Future Improvements and Ideas

This document contains ideas and recommendations for future improvements to the Control library.

## Architecture Improvements

### Phase 1: MVP (Implemented in v1.0.0)

#### 1. Remove `base` Modifiers ✅
**Problem:** The `base` modifier forces users to use `final` or `base` on their controller classes, which creates unnecessary restrictions.

**Solution:** Remove `base` from:
- `Controller` class
- `StateController` class
- Concurrency handler mixins

**Benefits:**
- More flexibility for users
- No forced inheritance patterns
- Simpler API

#### 2. Base `handle()` Implementation ✅
**Problem:** Currently `handle()` is abstract in `Controller`, forcing users to choose a concurrency strategy via mixins.

**Solution:** Implement base `handle()` in `Controller` with concurrent behavior by default. The method provides:
- Zone for error catching (including unawaited futures)
- HandlerContext for debugging
- Observer notifications
- error/done callbacks
- isProcessing tracking

**Benefits:**
- No forced mixin selection
- Concurrent by default (most common case)
- Mixins become optional

#### 3. Simplify Concurrency Handler Mixins ✅
**Problem:** Current mixins have ~100 lines each with duplicated error handling logic.

**Solution:** Make mixins simple wrappers around `super.handle()` + `Mutex`:

```dart
mixin SequentialControllerHandler on Controller {
  final Mutex _$mutex = Mutex();

  @override
  Future<void> handle(...) =>
      _$mutex.synchronize(() => super.handle(...));
}
```

**Benefits:**
- Reduces code from ~300 lines to ~90 lines
- Eliminates duplication
- Mixins are now just 10-15 lines each
- Easier to understand and maintain

### Phase 2: Enhancements (Future)

#### 4. Generic `handle<T>()` ⭐
**Current:** `handle()` only returns `Future<void>`

**Proposal:** Make it generic to support return values:

```dart
Future<T> handle<T>(Future<T> Function() handler, {...});

// Usage
Future<User> fetchUser(String id) => handle<User>(() async {
  final user = await api.getUser(id);
  setState(state.copyWith(user: user));
  return user; // Can return values!
});
```

**Benefits:**
- More flexible API
- Better composition
- Type-safe return values

#### 5. `tryLock()` Method for Mutex ⭐
**Proposal:** Add non-blocking lock attempt:

```dart
abstract class Mutex {
  /// Attempts to acquire lock without waiting
  /// Returns unlock function if successful, null if already locked
  void Function()? tryLock();
}

// Usage - droppable pattern without mixin
void operation() {
  final unlock = _mutex.tryLock();
  if (unlock == null) return; // Already running, drop
  try {
    // critical section
  } finally {
    unlock();
  }
}
```

**Benefits:**
- Enables droppable pattern without mixin
- More control over locking behavior
- No waiting if lock unavailable

#### 6. `isIdle` Getter ⭐
**Proposal:** Add convenience getter:

```dart
abstract class Controller {
  bool get isProcessing;
  bool get isIdle => !isProcessing; // Opposite of isProcessing
}
```

**Benefits:**
- More readable in UI code
- Natural language

#### 7. Extension Methods 💡
**Proposal:** Add convenience extensions:

```dart
extension MutexControllerExtension on Mutex {
  Future<void> handleWith(
    Controller controller,
    Future<void> Function() handler, {...}
  ) => synchronize(() => controller.handle(handler, ...));
}

// Usage
void operation() => _mutex.handleWith(this, () async {...});
```

**Benefits:**
- Shorter, more readable code
- Composable helpers

#### 8. Debounce/Throttle Utilities 💡
**Proposal:** Add common patterns:

```dart
class ControllerUtils {
  static Future<void> Function() debounce(
    Duration duration,
    Future<void> Function() action,
  ) {...}

  static Future<void> Function() throttle(
    Duration duration,
    Future<void> Function() action,
  ) {...}
}

// Usage
class SearchController extends StateController<SearchState> {
  late final _debouncedSearch = ControllerUtils.debounce(
    const Duration(milliseconds: 300),
    _performSearch,
  );

  void search(String query) => handle(_debouncedSearch);
}
```

**Benefits:**
- Common use cases covered
- Less boilerplate
- Reusable patterns

### Phase 3: Polish (Future)

#### 9. Integration Tests
Add comprehensive integration tests for:
- Concurrent behavior
- Sequential behavior
- Droppable behavior
- Mixed strategies
- Error handling across all strategies

#### 10. Performance Benchmarks
Add benchmarks comparing:
- Different concurrency strategies
- Mutex implementations
- Handler overhead

#### 11. Enhanced Documentation
- Add dartdoc examples to all public APIs
- Create cookbook with common patterns
- Add diagrams showing concurrency flows
- Video tutorials

#### 12. Performance Optimizations
- Cache `isProcessing` flag in sequential handler
- Optimize zone creation
- Consider object pooling for handler contexts

## API Stability

### Stable APIs (keep unchanged)
- `StateController.state`
- `StateController.setState()`
- `Controller.addListener()`
- `Controller.dispose()`
- `Mutex.lock()`
- `Mutex.synchronize()`

### Evolving APIs (may change)
- Handler mixins (simplified in 1.0.0)
- `handle()` signature (may become generic)
- Observer interface (may add more hooks)

## Breaking Changes for 1.0.0

### Removed
- `base` modifiers on classes and mixins

### Changed
- `Controller.handle()` now has a default implementation (concurrent)
- Concurrency handler mixins simplified (now just wrap `super.handle()` + mutex)
- `ConcurrentControllerHandler` is now redundant (base behavior)

### Migration
See MIGRATION.md for detailed migration guide from 0.x to 1.0.0

## Naming Considerations

### Current Names (Keep)
- `handle()` - short, clear, conventional
- `Controller` - standard pattern name
- `StateController` - descriptive
- `Mutex` - well-known CS term

### Potential Alternatives (Not Recommended)
- `handle()` → `execute()` / `runHandler()` - too verbose
- `Controller` → `Bloc` / `Manager` - different patterns
- `Mutex` → `Lock` - less precise

## Questions for Community

1. Should `handle()` be generic `<T>` or stay `<void>`?
2. Is `tryLock()` needed or is checking `locked` sufficient?
3. Should debounce/throttle be in core or separate package?
4. What other concurrency patterns are needed? (semaphore, rwlock, etc.)

## References

- [Mutex tests](test/unit/mutex_test.dart) - comprehensive test coverage
- [Controller tests](test/unit/state_controller_test.dart) - concurrency tests
- [Example app](example/lib/main.dart) - real-world usage

## Contributing

Feel free to:
- Open issues discussing these ideas
- Submit PRs implementing phase 2/3 features
- Share your use cases and patterns
- Suggest new ideas

---

**Last Updated:** 2026-02-06
**Status:** Phase 1 (MVP) implemented in v1.0.0-dev.1
