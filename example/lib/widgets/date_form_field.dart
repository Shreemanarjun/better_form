import 'package:flutter/material.dart';
import 'package:better_form/better_form.dart';

/// Custom Date Form Field for the example
class BetterDateFormField extends BetterFormFieldWidget<DateTime> {
  const BetterDateFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.label,
  });

  final String? label;

  @override
  BetterFormFieldWidgetState<DateTime> createState() =>
      _BetterDateFormFieldState();
}

class _BetterDateFormFieldState extends BetterFormFieldWidgetState<DateTime> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text((widget as BetterDateFormField).label ?? 'Select Date'),
      subtitle: Text(value.toString().split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          didChange(picked);
        }
      },
    );
  }
}
