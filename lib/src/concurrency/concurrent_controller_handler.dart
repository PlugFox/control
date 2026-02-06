import 'package:control/src/controller.dart';

/// A mixin that provides concurrent controller concurrency handling.
///
/// **Deprecated:** This mixin is no longer needed as [Controller] handles
/// operations concurrently by default. Simply remove this mixin from your
/// controller declarations.
///
/// Before:
/// ```dart
/// class MyController extends StateController<MyState>
///     with ConcurrentControllerHandler {
///   // ...
/// }
/// ```
///
/// After:
/// ```dart
/// class MyController extends StateController<MyState> {
///   // Operations execute concurrently by default
/// }
/// ```
@Deprecated(
  'ConcurrentControllerHandler is no longer needed. '
  'Controller handles operations concurrently by default. '
  'Remove this mixin from your controller declarations.',
)
mixin ConcurrentControllerHandler on Controller {
  // Empty mixin - base Controller behavior is already concurrent
  // This is kept for backwards compatibility only
}
