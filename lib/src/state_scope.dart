import 'package:control/src/state_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// {@template state_scope}
/// Container for [StateController]s.
/// {@endtemplate}
@experimental
sealed class StateScope extends InheritedWidget {
  /// {@macro state_scope}
  const factory StateScope({
    required IStateController Function() create,
    Widget child,
    Key? key,
  }) = _StateScope$Create;

  /// {@macro state_scope}
  const factory StateScope.value(
    IStateController controller, {
    Widget child,
    Key? key,
  }) = _StateScope$Value;

  /// {@nodoc}
  const StateScope._({
    super.child = const SizedBox.shrink(),
    super.key, // ignore: unused_element
  });
}

// --- Create --- //

final class _StateScope$Create extends StateScope {
  const _StateScope$Create({
    required this.create,
    super.child,
    super.key, // ignore: unused_element
  }) : super._();

  final IStateController Function() create;

  @override
  bool updateShouldNotify(covariant _StateScope$Create oldWidget) =>
      !identical(create, oldWidget.create);

  @override
  InheritedElement createElement() => _StateScope$Create$Element(this);
}

final class _StateScope$Create$Element extends InheritedElement {
  _StateScope$Create$Element(_StateScope$Create widget)
      : _controller = widget.create(),
        super(widget);

  final IStateController _controller;
  late Object _state;
  bool _dirty = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    _state = _controller.state;
    _controller.addListener(_handleUpdate);
    super.mount(parent, newSlot);
  }

  @override
  void update(covariant _StateScope$Create newWidget) {
    // We should never recreate this controller when widget changes
    super.update(newWidget);
  }

  void _handleUpdate() {
    if (identical(_state, _controller.state)) return; // Do nothing
    _state = _controller.state;
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(covariant StateScope oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    _controller
      ..removeListener(_handleUpdate)
      ..dispose();
    super.unmount();
  }

  @override
  Widget build() {
    if (_dirty) notifyClients(widget as StateScope);
    return super.build();
  }
}

// --- Value --- //

final class _StateScope$Value extends StateScope {
  const _StateScope$Value(
    this.controller, {
    super.child,
    super.key, // ignore: unused_element
  }) : super._();

  final IStateController controller;

  @override
  bool updateShouldNotify(covariant _StateScope$Value oldWidget) =>
      !identical(controller, oldWidget.controller);

  @override
  InheritedElement createElement() => _StateScope$Value$Element(this);
}

final class _StateScope$Value$Element extends InheritedElement {
  _StateScope$Value$Element(_StateScope$Value widget)
      : _controller = widget.controller,
        _widget = widget,
        super(widget);

  IStateController _controller;
  _StateScope$Value _widget;
  late Object _state;
  bool _dirty = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    _state = _controller.state;
    _controller.addListener(_handleUpdate);
    super.mount(parent, newSlot);
  }

  @override
  void update(covariant _StateScope$Value newWidget) {
    final oldController = _widget.controller;
    final newController = newWidget.controller;
    _widget = newWidget;
    if (!identical(oldController, newController)) {
      oldController.removeListener(_handleUpdate);
      newController.addListener(_handleUpdate);
      _controller = newController;
    }
    super.update(newWidget);
  }

  void _handleUpdate() {
    if (identical(_state, _controller.state)) return; // Do nothing
    _state = _controller.state;
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(covariant StateScope oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    _controller.removeListener(_handleUpdate);
    super.unmount();
  }

  @override
  Widget build() {
    if (_dirty) notifyClients(widget as StateScope);
    return super.build();
  }
}
