import 'dart:async';
import 'package:flutter/material.dart';

import '../controllers/controller.dart';
import '../controllers/field.dart';
import '../controllers/field_id.dart';
import '../controllers/validation.dart';
import 'riverpod_form_fields.dart';

/// Base class for custom form field widgets that automatically handles
/// controller management, listeners, and value synchronization
abstract class BetterFormFieldWidget<T> extends StatefulWidget {
  const BetterFormFieldWidget({
    super.key,
    required this.fieldId,
    this.controller,
    this.validator,
    this.initialValue,
  });

  final BetterFormFieldID<T> fieldId;
  final BetterFormController? controller;
  final String? Function(T value)? validator;
  final T? initialValue;

  @override
  BetterFormFieldWidgetState<T> createState();
}

/// State class that provides simplified APIs for form field management
abstract class BetterFormFieldWidgetState<T>
    extends State<BetterFormFieldWidget<T>> {
  late BetterFormController _controller;
  T? _currentValue;
  bool _isMounted = false;

  /// Get the current field value
  T get value {
    if (_currentValue == null) {
      throw StateError(
        'Field value not initialized. Make sure to access this after didChangeDependencies.',
      );
    }
    return _currentValue!;
  }

  /// Get the controller
  BetterFormController get controller => _controller;

  /// Check if the field is dirty
  bool get isDirty => _controller.isFieldDirty(widget.fieldId);

  /// Get validation result
  ValidationResult get validation => _controller.getValidation(widget.fieldId);

  /// Check if widget is mounted (safe to call setState)
  @override
  bool get mounted => _isMounted;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = widget.controller ?? BetterForm.controllerOf(context)!;

    // Auto-register the field if it's not already registered
    _ensureFieldRegistered();

    _currentValue = _controller.getValue(widget.fieldId) ?? widget.initialValue;
    _controller.addFieldListener(widget.fieldId, _onFieldChanged);
  }

  void _ensureFieldRegistered() {
    // Check if the field is already registered using the public API
    if (!_controller.isFieldRegistered(widget.fieldId)) {
      // Field not registered, try to get initial value from controller or widget
      T? initialValue = widget.initialValue;

      // If no initial value provided in widget, try to get it from controller's initial values
      initialValue ??= _controller.initialValue[widget.fieldId.key] as T?;

      // If still no initial value, throw error
      if (initialValue == null) {
        throw StateError(
          'Field ${widget.fieldId} must have an initialValue. '
          'Please provide an initialValue explicitly or ensure the field exists in the controller.',
        );
      }

      _controller.registerField(
        BetterFormField<T>(
          id: widget.fieldId,
          initialValue: initialValue,
          validator: widget.validator,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(BetterFormFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.fieldId != oldWidget.fieldId) {
      _controller.removeFieldListener(oldWidget.fieldId, _onFieldChanged);
      _controller = widget.controller ?? BetterForm.controllerOf(context)!;
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
      _currentValue = _controller.getValue(widget.fieldId) ?? widget.initialValue;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    super.dispose();
  }

  void _onFieldChanged() {
    final newValue = _controller.getValue(widget.fieldId);
    setState(() {
      _currentValue = newValue;
    });
    if (newValue != null) {
      onFieldChanged(newValue);
    }
  }

  /// Called when the field value changes externally
  /// Override this to react to external value changes
  void onFieldChanged(T value) {}

  /// Update the field value and notify the form
  /// This is the primary way to update field values
  void didChange(T value) {
    _controller.setValue(widget.fieldId, value);
  }

  /// Alias for didChange - update the field value
  void setField(T value) => didChange(value);

  /// Patch multiple field values at once
  /// Useful for complex form fields that control multiple values
  void patchValue(Map<BetterFormFieldID<dynamic>, dynamic> updates) {
    for (final entry in updates.entries) {
      _controller.setValue(entry.key, entry.value);
    }
  }

  /// Reset this field to its initial value
  void resetField() {
    // This would need access to initial values
    // For now, we'll reset the entire form
    _controller.reset();
  }

  /// Mark field as touched (for validation purposes)
  void markAsTouched() {
    // Could be used to trigger validation on touch
    // Currently, validation happens on value change
  }

  /// Focus the field (if it has focus capability)
  void focus() {
    // Override in subclasses that support focusing
  }

  /// Build the widget - override this to provide your UI
  @override
  Widget build(BuildContext context);
}

/// Mixin for form fields that need text input capabilities
mixin BetterFormFieldTextMixin<T> on BetterFormFieldWidgetState<T> {
  late final TextEditingController _textController;

  TextEditingController get textController => _textController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textController = TextEditingController(
      text: _currentValue != null ? valueToString(_currentValue as T) : '',
    );
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(BetterFormFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = _currentValue != null
        ? valueToString(_currentValue as T)
        : '';
    if (_textController.text != newText) {
      scheduleMicrotask(() {
        if (mounted && _textController.text != newText) {
          _textController.text = newText;
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void onFieldChanged(T value) {
    super.onFieldChanged(value);
    final textValue = valueToString(value);
    if (_textController.text != textValue) {
      _textController.value = TextEditingValue(
        text: textValue,
        selection: TextSelection.collapsed(offset: textValue.length),
      );
    }
  }

  void _onTextChanged() {
    final newValue = stringToValue(_textController.text);
    if (newValue != null && newValue != _currentValue) {
      didChange(newValue);
    }
  }

  /// Convert value to string for text controller
  String valueToString(T value);

  /// Convert string back to value
  T? stringToValue(String text);
}

/// Simplified text form field base class
abstract class BetterTextFormFieldWidget extends BetterFormFieldWidget<String> {
  const BetterTextFormFieldWidget({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled,
  });

  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final bool? enabled;

  @override
  BetterTextFormFieldWidgetState createState();
}

abstract class BetterTextFormFieldWidgetState
    extends BetterFormFieldWidgetState<String>
    with BetterFormFieldTextMixin<String> {
  @override
  String valueToString(String value) => value;

  @override
  String? stringToValue(String text) => text;

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as BetterTextFormFieldWidget;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: _controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            return TextFormField(
              controller: textController,
              decoration: widget.decoration.copyWith(
                errorText: validation.errorMessage,
                suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
              ),
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              onChanged: (value) => didChange(value),
            );
          },
        );
      },
    );
  }
}

/// Simplified number form field base class
abstract class BetterNumberFormFieldWidget extends BetterFormFieldWidget<int> {
  const BetterNumberFormFieldWidget({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.decoration = const InputDecoration(),
    this.enabled,
  });

  final InputDecoration decoration;
  final bool? enabled;

  @override
  BetterNumberFormFieldWidgetState createState();
}

abstract class BetterNumberFormFieldWidgetState
    extends BetterFormFieldWidgetState<int>
    with BetterFormFieldTextMixin<int> {
  @override
  String valueToString(int value) => value.toString();

  @override
  int? stringToValue(String text) => int.tryParse(text);

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as BetterNumberFormFieldWidget;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: _controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            return TextFormField(
              controller: textController,
              decoration: widget.decoration.copyWith(
                errorText: validation.errorMessage,
                suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
              ),
              keyboardType: TextInputType.number,
              enabled: widget.enabled,
              onChanged: (value) => didChange(int.tryParse(value) ?? 0),
            );
          },
        );
      },
    );
  }
}
