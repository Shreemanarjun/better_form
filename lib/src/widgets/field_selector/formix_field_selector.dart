import 'package:formix/formix.dart';
import 'package:flutter/material.dart';

/// A highly optimized, declarative widget that rebuilds only when a specific field changes
/// Provides granular performance and detailed change information
class FormixFieldSelector<T> extends StatefulWidget {
  /// Creates a [FormixFieldSelector].
  const FormixFieldSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.listenToValue = true,
    this.listenToValidation = true,
    this.listenToDirty = true,
    this.child,
  });

  /// The ID of the field to listen to.
  final FormixFieldID<T> fieldId;

  /// Builder function that returns the widget tree based on field changes.
  final Widget Function(
    BuildContext context,
    FieldChangeInfo<T> info,
    Widget? child,
  )
  builder;

  /// Optional controller. If not provided, it will be looked up in the context.
  final FormixController? controller;

  /// Whether to rebuild when the field value changes.
  final bool listenToValue;

  /// Whether to rebuild when the validation result changes.
  final bool listenToValidation;

  /// Whether to rebuild when the dirty state changes.
  final bool listenToDirty;

  /// Optional child widget that is passed to the builder to optimize rebuilds.
  final Widget? child;

  @override
  State<FormixFieldSelector<T>> createState() => _FormixFieldSelectorState<T>();
}

class _FormixFieldSelectorState<T> extends State<FormixFieldSelector<T>> {
  late FormixController _controller;
  late T? _currentValue;
  late ValidationResult _currentValidation;
  late bool _currentIsDirty;
  late bool _hasInitialValueChanged;

  T? _previousValue;
  ValidationResult? _previousValidation;
  bool? _previousIsDirty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = widget.controller ?? Formix.controllerOf(context)!;

    // Initialize current state
    _updateCurrentState();

    // Listen to field changes
    _controller.addFieldListener(widget.fieldId, _onFieldChanged);
  }

  @override
  void didUpdateWidget(FormixFieldSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller ||
        oldWidget.fieldId != widget.fieldId ||
        oldWidget.listenToValue != widget.listenToValue ||
        oldWidget.listenToValidation != widget.listenToValidation ||
        oldWidget.listenToDirty != widget.listenToDirty) {
      // Remove old listener
      oldWidget.controller?.removeFieldListener(
        oldWidget.fieldId,
        _onFieldChanged,
      );

      // Add new listener
      _controller = widget.controller ?? Formix.controllerOf(context)!;
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);

      // Update state
      _updateCurrentState();
    }
  }

  @override
  void dispose() {
    _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    super.dispose();
  }

  void _updateCurrentState() {
    _currentValue = _controller.getValue(widget.fieldId) ?? _controller.initialValue[widget.fieldId.key] as T?;
    _currentValidation = _controller.getValidation(widget.fieldId);
    _currentIsDirty = _controller.isFieldDirty(widget.fieldId);

    // Check if initial value has changed
    final initialValue = _controller.initialValue[widget.fieldId.key];
    _hasInitialValueChanged = initialValue != null && _currentValue != initialValue;
  }

  void _onFieldChanged() {
    // Store previous state
    _previousValue = _currentValue;
    _previousValidation = _currentValidation;
    _previousIsDirty = _currentIsDirty;

    // Update current state
    _updateCurrentState();

    // Check if we should rebuild based on listen flags
    bool shouldRebuild = false;

    if (widget.listenToValue && _currentValue != _previousValue) {
      shouldRebuild = true;
    }

    if (widget.listenToValidation && _currentValidation != _previousValidation) {
      shouldRebuild = true;
    }

    if (widget.listenToDirty && _currentIsDirty != _previousIsDirty) {
      shouldRebuild = true;
    }

    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = FieldChangeInfo<T>(
      fieldId: widget.fieldId,
      value: _currentValue,
      validation: _currentValidation,
      isDirty: _currentIsDirty,
      hasInitialValueChanged: _hasInitialValueChanged,
      previousValue: _previousValue,
      previousValidation: _previousValidation,
      previousIsDirty: _previousIsDirty,
    );

    return widget.builder(context, info, widget.child);
  }
}
