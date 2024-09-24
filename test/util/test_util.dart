// ignore_for_file: avoid_classes_with_only_static_members

import 'package:control/control.dart';
import 'package:flutter/material.dart';

abstract final class TestUtil {
  /// Basic wrapper for the current widgets.
  static Widget appContext({required Widget child, Size? size}) => MediaQuery(
        data: MediaQueryData(size: size ?? const Size(800, 600)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            elevation: 0,
            child: DefaultSelectionStyle(
              child: ScaffoldMessenger(
                child: HeroControllerScope.none(
                  child: Navigator(
                    pages: <Page<void>>[
                      MaterialPage<void>(
                        child: Scaffold(
                          body: SafeArea(
                            child: Center(
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                    onDidRemovePage: (route) => route.canPop,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Base fake controller for testing.
final class FakeController extends StateController<int>
    with SequentialControllerHandler {
  FakeController({int? initialState}) : super(initialState: initialState ?? 0);

  void add(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state + value);
      });

  void subtract(int value) => handle(() async {
        await Future<void>.delayed(Duration.zero);
        setState(state - value);
      });
}
