import 'dart:async';

import 'package:control/src/controller.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:meta/meta.dart';

/// Sequential controller concurrency
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
  void handle(
    FutureOr<void> Function() handler, [
    FutureOr<void> Function(Object error, StackTrace stackTrace)? errorHandler,
    FutureOr<void> Function()? doneHandler,
  ]) =>
      runZonedGuarded<void>(
        () async {
          if (isDisposed) return;
          _$processingCalls++;
          _done ??= Completer<void>.sync();
          try {
            await handler();
          } on Object catch (error, stackTrace) {
            onError(error, stackTrace);
            await Future<void>(() async {
              await errorHandler?.call(error, stackTrace);
            }).catchError(onError);
          } finally {
            await Future<void>(() async {
              await doneHandler?.call();
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
      );
}
