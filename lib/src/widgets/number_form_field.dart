import 'package:flutter/material.dart';

import 'base_form_field.dart';

/// Number form field with type safety
class BetterNumberFormField extends BetterFormFieldWidget<int> {
  const BetterNumberFormField({
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
  BetterFormFieldWidgetState<int> createState() =>
      _BetterNumberFormFieldState();
}

class _BetterNumberFormFieldState extends BetterFormFieldWidgetState<int>
    with BetterFormFieldTextMixin<int> {
  @override
  String valueToString(int value) => value.toString();

  @override
  int? stringToValue(String text) => int.tryParse(text);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textController,
      decoration: (widget as BetterNumberFormField).decoration.copyWith(
        errorText: validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      keyboardType: TextInputType.number,
      enabled: (widget as BetterNumberFormField).enabled,
      onChanged: (value) => didChange(int.tryParse(value) ?? 0),
    );
  }
}
