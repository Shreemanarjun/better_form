import 'package:flutter/material.dart';

import '../controller.dart';
import '../field_id.dart';
import '../field.dart';
import '../form.dart';
import '../validation.dart';

/// Text form field with type safety and reactive signals
class BetterTextFormField extends StatefulWidget {
  const BetterTextFormField({
    super.key,
    required this.fieldId,
    this.controller,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.enabled,
    this.validator,
    this.initialValue,
  });

  final BetterFormFieldID<String> fieldId;
  final BetterFormController? controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;
  final bool? enabled;
  final String? Function(String value)? validator;
  final String? initialValue;

  @override
  State<BetterTextFormField> createState() => _BetterTextFormFieldState();
}

class _BetterTextFormFieldState extends State<BetterTextFormField> {
  late BetterFormController _controller;
  late final TextEditingController _textController;
  bool _isInitialized = false;
  late final VoidCallback _valueListener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _controller = widget.controller ?? BetterForm.of(context)!;

      // Register the field first before trying to get its value
      if (!_controller.isFieldRegistered(widget.fieldId)) {
        _controller.registerField(
          BetterFormField(
            id: widget.fieldId,
            initialValue: widget.initialValue ?? '',
            validator: widget.validator,
          ),
        );
      }

      // Now we can safely get the value
      _textController = TextEditingController(
        text: _controller.getValue(widget.fieldId) ?? '',
      );

      // Set up listener for external value changes
      _valueListener = () {
        final currentValue = _controller.getValue(widget.fieldId) ?? '';
        if (_textController.text != currentValue) {
          _textController.text = currentValue;
        }
      };
      _controller.fieldValueListenable(widget.fieldId).addListener(_valueListener);

      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(BetterTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.fieldId != oldWidget.fieldId) {
      // Remove old listener
      _controller.fieldValueListenable(oldWidget.fieldId).removeListener(_valueListener);

      _controller = widget.controller ?? BetterForm.of(context)!;
      final newText = _controller.getValue(widget.fieldId) ?? '';
      if (_textController.text != newText) {
        _textController.text = newText;
      }

      // Add listener to new controller/field
      _controller.fieldValueListenable(widget.fieldId).addListener(_valueListener);
    }
  }

  @override
  void dispose() {
    _controller.fieldValueListenable(widget.fieldId).removeListener(_valueListener);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ValidationResult>(
      valueListenable: _controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            return TextFormField(
              controller: _textController,
              decoration: widget.decoration.copyWith(
                errorText: validation.errorMessage,
                suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
              ),
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              onChanged: (value) => _controller.setValue(widget.fieldId, value),
            );
          },
        );
      },
    );
  }
}
