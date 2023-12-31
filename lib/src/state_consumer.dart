import 'package:control/src/controller_scope.dart';
import 'package:control/src/state_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Fire when the state changes.
typedef StateConsumerListener<C extends IStateController<S>, S extends Object>
    = void Function(BuildContext context, C controller, S previous, S current);

/// Build when the method returns true.
typedef StateConsumerCondition<S extends Object> = bool Function(
    S previous, S current);

/// Rebuild the widget when the state changes.
typedef StateConsumerBuilder<S extends Object> = Widget Function(
    BuildContext context, S state, Widget? child);

/// {@template state_consumer}
/// StateConsumer widget.
///
/// Call [listener] and rebuild with [builder] when the state changes.
/// {@endtemplate}
class StateConsumer<C extends IStateController<S>, S extends Object>
    extends StatefulWidget {
  /// {@macro state_builder}
  const StateConsumer({
    this.controller,
    this.listener,
    this.buildWhen,
    this.builder,
    this.child,
    super.key,
  });

  /// The controller responsible for processing the logic.
  /// If omitted, the controller will be obtained
  /// using `ControllerScope.of<StateControllerType>(context)`.
  final C? controller;

  /// Takes the `BuildContext` along with the `state`
  /// and is responsible for executing in response to `state` changes.
  final StateConsumerListener<C, S>? listener;

  /// Takes the previous `state` and the current `state` and is responsible for
  /// returning a [bool] which determines whether or not to trigger
  /// [builder] with the current `state`.
  final StateConsumerCondition<S>? buildWhen;

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final StateConsumerBuilder<S>? builder;

  /// The child widget which will be passed to the [builder].
  final Widget? child;

  @override
  State<StatefulWidget> createState() => _StateConsumerState<C, S>();
}

class _StateConsumerState<C extends IStateController<S>, S extends Object>
    extends State<StateConsumer<C, S>> {
  late C _controller;
  late S _previousState;

  @override
  void didChangeDependencies() {
    _controller =
        widget.controller ?? ControllerScope.of<C>(context, listen: false);
    _previousState = _controller.state;
    _subscribe();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant StateConsumer<C, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldController = oldWidget.controller,
        newController = widget.controller;
    if (identical(oldController, newController) ||
        oldController == newController) return;
    _unsubscribe();
    _controller =
        newController ?? ControllerScope.of<C>(context, listen: false);
    _previousState = _controller.state;
    _subscribe();
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() => _controller.addListener(_valueChanged);

  void _unsubscribe() {
    if (_controller.isDisposed) return;
    _controller.removeListener(_valueChanged);
  }

  void _valueChanged() {
    final oldState = _previousState, newState = _controller.state;
    if (!mounted || identical(oldState, newState)) return;
    _previousState = newState;
    widget.listener?.call(context, _controller, oldState, newState);
    if (widget.buildWhen?.call(oldState, newState) ?? true) {
      // Rebuild the widget when the state changes.
      switch (SchedulerBinding.instance.schedulerPhase) {
        case SchedulerPhase.idle:
        case SchedulerPhase.transientCallbacks:
        case SchedulerPhase.postFrameCallbacks:
          setState(() {});
        case SchedulerPhase.persistentCallbacks:
        case SchedulerPhase.midFrameMicrotasks:
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {});
          });
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) =>
      super.debugFillProperties(properties
        ..add(
            DiagnosticsProperty<IStateController<S>>('Controller', _controller))
        ..add(DiagnosticsProperty<S>('State', _controller.state))
        ..add(FlagProperty('isProcessing',
            value: _controller.isProcessing,
            ifTrue: 'Processing',
            ifFalse: 'Idle')));

  @override
  Widget build(BuildContext context) =>
      widget.builder?.call(context, _controller.state, widget.child) ??
      widget.child ??
      const SizedBox.shrink();
}
