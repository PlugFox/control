import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:control/src/handler_context.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:meta/meta.dart';

/// Concurrent controller concurrency
base mixin ConcurrentControllerHandler on Controller {
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
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
    String? name,
    Map<String, Object?>? context,
  }) {
    if (isDisposed) return Future<void>.value(null);
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

    final handlerContext = HandlerContextImpl(
      controller: this,
      name: name ?? '$runtimeType.handler#${handler.runtimeType}',
      context: <String, Object?>{
        ...?context,
      },
    );

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
      zoneValues: <Object?, Object?>{
        HandlerContext.key: handlerContext,
      },
    );

    return completer.future;
  }

  /* @override
  @protected
  @mustCallSuper
  Future<void> handle(
    Future<void> Function() handler, {
    Future<void> Function(Object error, StackTrace stackTrace)? error,
    Future<void> Function()? done,
  }) =>
      runZonedGuarded<void>(
        () async {
          if (isDisposed) return;
          _$processingCalls++;
          _done ??= Completer<void>.sync();
          try {
            await handler();
          } on Object catch (e, st) {
            onError(e, st);
            await Future<void>(() async {
              await error?.call(e, st);
            }).catchError(onError);
          } finally {
            isDone = true;
            await Future<void>(() async {
              await done?.call();
            }).catchError(onError);
            _$processingCalls--;
            if (_$processingCalls == 0) {
              final completer = _done;
              if (completer != null && !completer.isCompleted) {
                completer.complete();
              }
              _done = null;
            }
          }
        },
        onError,
      ); */
}
