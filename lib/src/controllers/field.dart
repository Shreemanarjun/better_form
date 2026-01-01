import 'field_id.dart';

/// Form field definition with validation and type information
class BetterFormField<T> {
  const BetterFormField({
    required this.id,
    required this.initialValue,
    this.validator,
    this.label,
    this.hint,
    this.transformer,
  });

  final BetterFormFieldID<T> id;
  final T initialValue;
  final String? Function(T value)? validator;
  final String? label;
  final String? hint;
  final T Function(dynamic value)? transformer;
}
