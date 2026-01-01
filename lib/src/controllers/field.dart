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
    this.asyncValidator,
    this.debounceDuration,
    this.emptyValue,
  });

  final BetterFormFieldID<T> id;
  final T initialValue;
  final T? emptyValue;
  final String? Function(T value)? validator;
  final String? label;
  final String? hint;
  final T Function(dynamic value)? transformer;

  /// Asynchronous validator
  final Future<String?> Function(T value)? asyncValidator;

  /// Debounce duration for async validation
  final Duration? debounceDuration;
}
