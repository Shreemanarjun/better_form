import 'field_id.dart';
import 'field.dart';
import '../enums.dart';
import 'form_state.dart';

/// Configuration for a form field
class BetterFormFieldConfig<T> {
  const BetterFormFieldConfig({
    required this.id,
    this.initialValue,
    this.validator,
    this.crossFieldValidator,
    this.dependsOn = const [],
    this.label,
    this.hint,
    this.asyncValidator,
    this.debounceDuration,
    this.validationMode = BetterAutovalidateMode.always,
  });

  /// Unique identifier for this field
  final BetterFormFieldID<T> id;

  /// Initial value of the field
  final T? initialValue;

  /// Synchronous validator function
  final String? Function(T value)? validator;

  /// Cross-field validator that can access the entire form state
  final String? Function(T value, BetterFormState state)? crossFieldValidator;

  /// List of fields that this field depends on for validation
  final List<BetterFormFieldID<dynamic>> dependsOn;

  /// Label for the field (UI hint)
  final String? label;

  /// Hint text for the field (UI hint)
  final String? hint;

  /// Asynchronous validator
  final Future<String?> Function(T value)? asyncValidator;

  /// Debounce duration for async validation
  final Duration? debounceDuration;

  /// Validation mode for this field
  final BetterAutovalidateMode validationMode;

  BetterFormField<T> toField() {
    // Capture values to avoid type inference issues
    final localValidator = validator;
    final localCrossFieldValidator = crossFieldValidator;
    final localAsyncValidator = asyncValidator;

    return BetterFormField<T>(
      id: id,
      initialValue: initialValue,
      validator: localValidator,
      crossFieldValidator: localCrossFieldValidator,
      dependsOn: dependsOn,
      label: label,
      hint: hint,
      asyncValidator: localAsyncValidator != null
          ? (T value) => localAsyncValidator(value)
          : null,
      debounceDuration: debounceDuration,
      validationMode: validationMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BetterFormFieldConfig<T> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          initialValue == other.initialValue &&
          validator == other.validator &&
          label == other.label &&
          hint == other.hint &&
          asyncValidator == other.asyncValidator &&
          debounceDuration == other.debounceDuration;

  @override
  int get hashCode =>
      id.hashCode ^
      initialValue.hashCode ^
      validator.hashCode ^
      label.hashCode ^
      hint.hashCode ^
      asyncValidator.hashCode ^
      debounceDuration.hashCode;
}
