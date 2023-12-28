import 'package:control/src/controller.dart';
import 'package:control/src/state_controller.dart';
import 'package:meta/meta.dart';

/// StateRegistry Singleton class
/// {@nodoc}
@internal
final class ControllerRegistry with ControllerRegistry$Global {
  /// {@nodoc}
  factory ControllerRegistry() => _internalSingleton;
  ControllerRegistry._internal();
  static final ControllerRegistry _internalSingleton =
      ControllerRegistry._internal();
}

/// {@nodoc}
@internal
base mixin ControllerRegistry$Global {
  final Map<Type, List<WeakReference<IController>>> _globalRegistry =
      <Type, List<WeakReference<IController>>>{};

  @internal
  List<Controller> getAll() {
    final result = <Controller>[];
    for (final list in _globalRegistry.values) {
      var j = 0;
      for (var i = 0; i < list.length; i++) {
        final wr = list[i];
        final target = wr.target;
        if (target == null || target.isDisposed) continue;
        if (i != j) list[j] = wr;
        if (target is Controller) result.add(target);
        j++;
      }
      list.length = j;
    }
    return result;
  }

  /// Get the controller from the registry.
  @internal
  List<Controller> get<Controller extends IStateController>() {
    final result = <Controller>[];
    final list = _globalRegistry[Controller];
    if (list == null) return result;
    var j = 0;
    for (var i = 0; i < list.length; i++) {
      final wr = list[i];
      final target = wr.target;
      if (target == null || target.isDisposed) continue;
      if (i != j) list[j] = wr;
      if (target is Controller) result.add(target);
      j++;
    }
    list.length = j;
    return result;
  }

  /// Upsert the controller in the registry.
  @internal
  void insert<Controller extends IController>(Controller controller) {
    remove<IController>();
    (_globalRegistry[Controller] ??= <WeakReference<IController>>[])
        .add(WeakReference(controller));
  }

  /// Remove the controller from the registry.
  @internal
  void remove<Controller extends IController>() {
    final list = _globalRegistry[Controller];
    if (list == null) return;
    var j = 0;
    for (var i = 0; i < list.length; i++) {
      if (list[i] is WeakReference<Controller>) continue;
      if (i != j) list[j] = list[i];
      j++;
    }
    list.length = j;
  }
}
