import 'dart:async';
import 'package:flutter/material.dart';

import '../controllers/riverpod_controller.dart';
import '../controllers/field.dart';
import '../controllers/field_id.dart';
import '../controllers/validation.dart';
import 'riverpod_form_fields.dart';

/// Base class for custom form field widgets that automatically handles
/// controller management, listeners, and value synchronization
abstract class FormixFieldWidget<T> extends StatefulWidget {
  const FormixFieldWidget({
    super.key,
    required this.fieldId,
    this.controller,
    this.validator,
    this.initialValue,
  });

  final FormixFieldID<T> fieldId;
  final FormixController? controller;
  final String? Function(T value)? validator;
  final T? initialValue;

  @override
  FormixFieldWidgetState<T> createState();
}

/// State class that provides simplified APIs for form field management
abstract class FormixFieldWidgetState<T> extends State<FormixFieldWidget<T>> {
  late FormixController _controller;
  T? _currentValue;
  late FocusNode _focusNode;
  bool _isMounted = false;

  /// Get the current field value
  T? get value => _currentValue;

  /// Get the focus node
  FocusNode get focusNode => _focusNode;

  /// Get the controller
  FormixController get controller => _controller;

  /// Check if the field is dirty
  bool get isDirty => _controller.isFieldDirty(widget.fieldId);

  /// Check if the field is touched
  bool get isTouched => _controller.isFieldTouched(widget.fieldId);

  /// Get validation result
  ValidationResult get validation => _controller.getValidation(widget.fieldId);

  /// Check if widget is mounted (safe to call setState)
  @override
  bool get mounted => _isMounted;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = widget.controller ?? Formix.controllerOf(context)!;

    // Auto-register the field if it's not already registered
    _ensureFieldRegistered();

    // Register focus node
    _controller.registerFocusNode(widget.fieldId, _focusNode);
    // Register context for scrolling
    _controller.registerContext(widget.fieldId, context);

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

      // Allow null initial values - the field can start with null
      _controller.registerField(
        FormixField<T>(
          id: widget.fieldId,
          initialValue: initialValue,
          validator: widget.validator,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(FormixFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.fieldId != oldWidget.fieldId) {
      _controller.removeFieldListener(oldWidget.fieldId, _onFieldChanged);
      _controller = widget.controller ?? Formix.controllerOf(context)!;
      _controller.registerFocusNode(widget.fieldId, _focusNode);
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
      _currentValue =
          _controller.getValue(widget.fieldId) ?? widget.initialValue;
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final newValue = _controller.getValue(widget.fieldId);
    setState(() {
      _currentValue = newValue;
    });
    if (_controller.isFieldRegistered(widget.fieldId)) {
      onFieldChanged(newValue);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Lost focus -> touched
      _controller.markAsTouched(widget.fieldId);
    }
  }

  /// Called when the field value changes externally
  /// Override this to react to external value changes
  void onFieldChanged(T? value) {}

  /// Update the field value and notify the form
  /// This is the primary way to update field values
  void didChange(T? value) {
    _controller.setValue(widget.fieldId, value);
  }

  /// Alias for didChange - update the field value
  void setField(T? value) => didChange(value);

  /// Patch multiple field values at once
  /// Useful for complex form fields that control multiple values
  void patchValue(Map<FormixFieldID<dynamic>, dynamic> updates) {
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
    _controller.markAsTouched(widget.fieldId);
  }

  /// Focus the field (if it has focus capability)
  void focus() {
    _focusNode.requestFocus();
  }

  /// Build the widget - override this to provide your UI
  @override
  Widget build(BuildContext context);
}

/// Mixin for form fields that need text input capabilities
mixin FormixFieldTextMixin<T> on FormixFieldWidgetState<T> {
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
  void didUpdateWidget(FormixFieldWidget<T> oldWidget) {
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
  void onFieldChanged(T? value) {
    super.onFieldChanged(value);
    final textValue = value != null ? valueToString(value) : '';
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
  String valueToString(T? value);

  /// Convert string back to value
  T? stringToValue(String text);
}

/// Simplified text form field base class
abstract class FormixTextFormFieldWidget extends FormixFieldWidget<String> {
  const FormixTextFormFieldWidget({
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
  FormixTextFormFieldWidgetState createState();
}

abstract class FormixTextFormFieldWidgetState
    extends FormixFieldWidgetState<String>
    with FormixFieldTextMixin<String> {
  @override
  String valueToString(String? value) => value ?? '';

  @override
  String? stringToValue(String text) => text;

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as FormixTextFormFieldWidget;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: _controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            final shouldShowError =
                validation.isValidating ||
                (_controller.isFieldTouched(widget.fieldId) ||
                    _controller.isSubmitting);

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: widget.decoration.copyWith(
                errorText: shouldShowError && !validation.isValidating
                    ? validation.errorMessage
                    : null,
                helperText: validation.isValidating ? 'Validating...' : null,
                suffixIcon: validation.isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : isDirty
                    ? const Icon(Icons.edit, size: 16)
                    : null,
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
abstract class FormixNumberFormFieldWidget extends FormixFieldWidget<int> {
  const FormixNumberFormFieldWidget({
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
  FormixNumberFormFieldWidgetState createState();
}

abstract class FormixNumberFormFieldWidgetState
    extends FormixFieldWidgetState<int>
    with FormixFieldTextMixin<int> {
  @override
  String valueToString(int? value) => value?.toString() ?? '';

  @override
  int? stringToValue(String text) => int.tryParse(text);

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as FormixNumberFormFieldWidget;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: _controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            final shouldShowError =
                validation.isValidating ||
                (_controller.isFieldTouched(widget.fieldId) ||
                    _controller.isSubmitting);

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: widget.decoration.copyWith(
                errorText: shouldShowError && !validation.isValidating
                    ? validation.errorMessage
                    : null,
                helperText: validation.isValidating ? 'Validating...' : null,
                suffixIcon: validation.isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : isDirty
                    ? const Icon(Icons.edit, size: 16)
                    : null,
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
