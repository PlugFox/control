## 1.0.0-dev.1

### Features

- **ADDED**: Generic `handle<T>()` method - now supports return values
  - Example: `Future<User> fetchUser(String id) => handle<User>(() async { ... return user; })`
  - Type-safe return values from controller operations
  - Works with all concurrency strategies (sequential, concurrent, droppable)

### Breaking Changes

- **REMOVED**: `base` modifier from `Controller`, `StateController`, and concurrency handler mixins
  - Controllers no longer require `final` or `base` in user code
  - Provides more flexibility for inheritance patterns
- **CHANGED**: `Controller.handle()` now has a default concurrent implementation
  - No longer abstract - controllers can be used without choosing a concurrency mixin
  - Operations execute concurrently by default
  - Provides zone for error catching, HandlerContext, observer notifications, and callbacks
- **CHANGED**: Concurrency handler mixins simplified to wrap `super.handle()` with `Mutex`
  - `SequentialControllerHandler` - wraps handle with mutex for sequential execution
  - `DroppableControllerHandler` - wraps handle with mutex and drops new operations if busy
  - `ConcurrentControllerHandler` - **deprecated** (base behavior is already concurrent)
- **CHANGED**: `Controller.handle()` signature now includes `error` and `done` callbacks
  - Before: `handle(handler, {name, meta})`
  - After: `handle<T>(handler, {error, done, name, meta})`
- **CHANGED**: `DroppableControllerHandler` now returns `null` when dropping operations
  - Handle method returns `Future<T?>` to support nullable return values
  - Dropped operations return `null` instead of throwing errors
  - This is the expected behavior for droppable operations

### Added

- **ADDED**: Base `handle()` implementation in `Controller` class
  - Concurrent execution by default
  - Zone-based error catching (including unawaited futures)
  - HandlerContext for debugging
  - Observer notifications
  - Error and done callbacks
- **ADDED**: `Mutex` is now the core primitive for concurrency control
  - Can be used directly in controllers for custom concurrency patterns
  - Sequential and droppable mixins built on top of Mutex

### Improved

- **IMPROVED**: Reduced code complexity
  - Concurrency handler mixins reduced from ~300 lines to ~90 lines
  - Removed `_ControllerEventQueue` class (no longer needed)
  - Simplified architecture easier to understand and maintain
- **IMPROVED**: More flexibility in concurrency control
  - Use mixins for simple cases (sequential/droppable)
  - Use Mutex directly for custom patterns
  - Mix and match strategies in the same controller

### Migration Guide

See [MIGRATION.md](MIGRATION.md) for detailed migration instructions from 0.x to 1.0.0.

**Quick migration:**
- Remove `base` from your controller classes
- `ConcurrentControllerHandler` can be removed (controllers are concurrent by default)
- `SequentialControllerHandler` and `DroppableControllerHandler` work the same way
- For custom concurrency, use `Mutex` directly instead of creating custom mixins

## 0.2.0

- **ADDED**: `HandlerContext` to handlers, available at zone and observer.
- **ADDED**: `name` getter for `Controller`
- **ADDED**: `void onHandler(HandlerContext context)` to `IControllerObserver`
- **REMOVED**: `done` getter from `Controller`

## 0.1.0

- **BREAKING CHANGE**: Replace FutureOr with Future in handler

## 0.0.3-pre.1

- **BREAKING CHANGE**: Change `handler` api and implementation

## 0.0.2

- Add example to README.md
- ControllerRegistry only for debug mode

## 0.0.1-pre.0

- Initial release
