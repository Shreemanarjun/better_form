import 'package:flutter/material.dart';

import '../controller.dart';
import '../field_id.dart';
import '../field.dart';
import '../form.dart';

/// Text form field with type safety
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
        text: _controller.getValue(widget.fieldId),
      );
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(BetterTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.fieldId != oldWidget.fieldId) {
      _controller.removeFieldListener(oldWidget.fieldId, _onFieldChanged);
      _controller = widget.controller ?? BetterForm.of(context)!;
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
      final newText = _controller.getValue(widget.fieldId);
      if (_textController.text != newText) {
        _textController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final newValue = _controller.getValue(widget.fieldId);
    if (_textController.text != newValue) {
      _textController.text = newValue;
    }
    // Always call setState to update validation state/isDirty even if text didn't change
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final validation = _controller.getValidation(widget.fieldId);
    final isDirty = _controller.isFieldDirty(widget.fieldId);

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
  }
}
