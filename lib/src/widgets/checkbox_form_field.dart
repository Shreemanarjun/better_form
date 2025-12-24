import 'package:flutter/material.dart';

import 'base_form_field.dart';

/// Checkbox form field with type safety
class BetterCheckboxFormField extends BetterFormFieldWidget<bool> {
  const BetterCheckboxFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.title,
    this.enabled,
  });

  final Widget? title;
  final bool? enabled;

  @override
  BetterFormFieldWidgetState<bool> createState() => _BetterCheckboxFormFieldState();
}

class _BetterCheckboxFormFieldState extends BetterFormFieldWidgetState<bool> {
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: (widget as BetterCheckboxFormField).title,
      value: value,
      onChanged: (widget as BetterCheckboxFormField).enabled == false ? null : (newValue) {
        if (newValue != null) {
          didChange(newValue);
        }
      },
      secondary: isDirty ? const Icon(Icons.edit, size: 16) : null,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
