import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

/// Custom Date Form Field for the example
class FormixDateFormField extends FormixFieldWidget<DateTime> {
  const FormixDateFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.label,
  });

  final String? label;

  @override
  FormixFieldWidgetState<DateTime> createState() => _FormixDateFormFieldState();
}

class _FormixDateFormFieldState extends FormixFieldWidgetState<DateTime> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text((widget as FormixDateFormField).label ?? 'Select Date'),
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
