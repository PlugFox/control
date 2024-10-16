import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:meta/meta.dart';

/// Handler's context.
abstract interface class HandlerContext {
  /// Key to access the handler's context.
  static const Object key = #handler;

  /// Get the handler's context from the current zone.
  static HandlerContext? zoned() => switch (Zone.current[HandlerContext.key]) {
        HandlerContext context => context,
        _ => null,
      };

  /// Controller that the handler is attached to.
  abstract final Controller controller;

  /// Name of the handler.
  abstract final String name;

  /// Future that completes when the handler is done.
  Future<void> get done;

  /// Whether the handler is done.
  bool get isDone;

  /// Extra meta information about the handler.
  abstract final Map<String, Object?> context;
}

@internal
final class HandlerContextImpl implements HandlerContext {
  HandlerContextImpl(
      {required this.controller,
      required this.name,
      required this.context,
      required Completer<void> completer})
      : _completer = completer;

  @override
  final Controller controller;

  @override
  final String name;

  @override
  Future<void> get done => _completer.future;

  @override
  bool get isDone => _completer.isCompleted;

  final Completer<void> _completer;

  @override
  final Map<String, Object?> context;
}
