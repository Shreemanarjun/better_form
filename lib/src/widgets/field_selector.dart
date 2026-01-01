import 'package:flutter/material.dart';

import '../controllers/controller.dart';
import '../controllers/field_id.dart';
import '../controllers/validation.dart';
import 'riverpod_form_fields.dart';

/// Information about what changed in a field
class FieldChangeInfo<T> {
  const FieldChangeInfo({
    required this.fieldId,
    required this.value,
    required this.validation,
    required this.isDirty,
    required this.hasInitialValueChanged,
    required this.previousValue,
    required this.previousValidation,
    required this.previousIsDirty,
  });

  final BetterFormFieldID<T> fieldId;
  final T? value;
  final ValidationResult validation;
  final bool isDirty;
  final bool hasInitialValueChanged;
  final T? previousValue;
  final ValidationResult? previousValidation;
  final bool? previousIsDirty;

  /// Whether the value changed
  bool get valueChanged => previousValue != null && value != previousValue;

  /// Whether the validation changed
  bool get validationChanged => previousValidation != null && validation != previousValidation;

  /// Whether the dirty state changed
  bool get dirtyStateChanged => previousIsDirty != null && isDirty != previousIsDirty;

  /// Whether any aspect changed
  bool get hasChanged => valueChanged || validationChanged || dirtyStateChanged;
}

/// A highly optimized, declarative widget that rebuilds only when a specific field changes
/// Provides granular performance and detailed change information
class BetterFormFieldSelector<T> extends StatefulWidget {
  const BetterFormFieldSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.listenToValue = true,
    this.listenToValidation = true,
    this.listenToDirty = true,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, FieldChangeInfo<T> info, Widget? child) builder;
  final BetterFormController? controller;
  final bool listenToValue;
  final bool listenToValidation;
  final bool listenToDirty;
  final Widget? child;

  @override
  State<BetterFormFieldSelector<T>> createState() => _BetterFormFieldSelectorState<T>();
}

class _BetterFormFieldSelectorState<T> extends State<BetterFormFieldSelector<T>> {
  late BetterFormController _controller;
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
    _controller = widget.controller ?? BetterForm.controllerOf(context)!;

    // Initialize current state
    _updateCurrentState();

    // Listen to field changes
    _controller.addFieldListener(widget.fieldId, _onFieldChanged);
  }

  @override
  void didUpdateWidget(BetterFormFieldSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller ||
        oldWidget.fieldId != widget.fieldId ||
        oldWidget.listenToValue != widget.listenToValue ||
        oldWidget.listenToValidation != widget.listenToValidation ||
        oldWidget.listenToDirty != widget.listenToDirty) {

      // Remove old listener
      oldWidget.controller?.removeFieldListener(oldWidget.fieldId, _onFieldChanged);

      // Add new listener
      _controller = widget.controller ?? BetterForm.controllerOf(context)!;
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

/// A simplified version that only listens to value changes
class BetterFormFieldValueSelector<T> extends StatelessWidget {
  const BetterFormFieldValueSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: fieldId,
      controller: controller,
      listenToValue: true,
      listenToValidation: false,
      listenToDirty: false,
      builder: (context, info, child) => builder(context, info.value, child),
      child: child,
    );
  }
}

/// A widget that shows performance metrics for field rebuilding
class BetterFormFieldPerformanceMonitor<T> extends StatefulWidget {
  const BetterFormFieldPerformanceMonitor({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, FieldChangeInfo<T> info, int rebuildCount) builder;
  final BetterFormController? controller;

  @override
  State<BetterFormFieldPerformanceMonitor<T>> createState() =>
      _BetterFormFieldPerformanceMonitorState<T>();
}

class _BetterFormFieldPerformanceMonitorState<T> extends State<BetterFormFieldPerformanceMonitor<T>> {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: widget.fieldId,
      controller: widget.controller,
      builder: (context, info, child) {
        _rebuildCount++;
        return widget.builder(context, info, _rebuildCount);
      },
    );
  }
}

/// A widget that provides granular listening control with custom conditions
class BetterFormFieldConditionalSelector<T> extends StatelessWidget {
  const BetterFormFieldConditionalSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    required this.shouldRebuild,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, FieldChangeInfo<T> info, Widget? child) builder;
  final bool Function(FieldChangeInfo<T> info) shouldRebuild;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: fieldId,
      controller: controller,
      builder: (context, info, child) {
        // Only rebuild if the condition is met
        if (shouldRebuild(info)) {
          return builder(context, info, child);
        }
        // Return a placeholder that doesn't rebuild
        return child ?? const SizedBox.shrink();
      },
      child: child,
    );
  }
}
