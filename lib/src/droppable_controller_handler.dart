import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:meta/meta.dart';

/// Droppable controller concurrency
base mixin DroppableControllerHandler on Controller {
  @override
  @nonVirtual
  bool get isProcessing => _$processingCalls > 0;
  int _$processingCalls = 0;

  @override
  Future<void> get done => _done?.future ?? SynchronousFuture<void>(null);
  Completer<void>? _done;

  @override
  @protected
  @mustCallSuper
  FutureOr<void> handle(
    FutureOr<void> Function() handler, {
    FutureOr<void> Function(Object error, StackTrace stackTrace)? error,
    FutureOr<void> Function()? done,
  }) {
    if (isDisposed || isProcessing) return Future<void>.value(null);
    _$processingCalls++;
    final completer = _done ??= Completer<void>();
    var isDone = false; // ignore error callback after done

    Future<void> onError(Object e, StackTrace st) async {
      try {
        super.onError(e, st);
        if (isDone || isDisposed || completer.isCompleted) return;
        await error?.call(e, st);
      } on Object catch (error, stackTrace) {
        super.onError(error, stackTrace);
      }
    }

    void onDone() {
      if (completer.isCompleted) return;
      _$processingCalls--;
      if (_$processingCalls != 0) return;
      completer.complete();
      _done = null;
    }

    runZonedGuarded<void>(
      () async {
        try {
          await handler();
        } on Object catch (error, stackTrace) {
          await onError(error, stackTrace);
        } finally {
          isDone = true;
          try {
            await done?.call();
          } on Object catch (error, stackTrace) {
            super.onError(error, stackTrace);
          }
          onDone();
        }
      },
      onError,
    );
  }
}
