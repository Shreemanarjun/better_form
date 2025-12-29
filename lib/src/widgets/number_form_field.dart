import 'package:flutter/material.dart';

import 'base_form_field.dart';

/// Number form field with type safety
class BetterNumberFormField extends BetterNumberFormFieldWidget {
  const BetterNumberFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    super.decoration = const InputDecoration(),
    super.enabled,
  });

  @override
  BetterNumberFormFieldWidgetState createState() =>
      _BetterNumberFormFieldState();
}

class _BetterNumberFormFieldState extends BetterNumberFormFieldWidgetState {
  @override
  Widget build(BuildContext context) {
    final widget = this.widget as BetterNumberFormField;

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
  }
}
