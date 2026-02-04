import '../controllers/field_id.dart';
import '../controllers/validation.dart';

/// Information about what changed in a field
class FieldChangeInfo<T> {
  /// Creates a [FieldChangeInfo].
  const FieldChangeInfo({
    required this.fieldId,
    required this.value,
    required this.validation,
    required this.isDirty,
    required this.hasInitialValueChanged,
    required this.previousValue,
    required this.previousValidation,
    required this.previousIsDirty,
  });

  /// The ID of the field that changed.
  final FormixFieldID<T> fieldId;

  /// The current value of the field.
  final T? value;

  /// The current validation result.
  final ValidationResult validation;

  /// Whether the field is currently dirty.
  final bool isDirty;

  /// Whether the initial value has changed.
  final bool hasInitialValueChanged;

  /// The previous value of the field.
  final T? previousValue;

  /// The previous validation result.
  final ValidationResult? previousValidation;

  /// The previous dirty state.
  final bool? previousIsDirty;

  /// Whether the value changed
  bool get valueChanged => previousValue != null && value != previousValue;

  /// Whether the validation changed
  bool get validationChanged => previousValidation != null && validation != previousValidation;

  /// Whether the dirty state changed
  bool get dirtyStateChanged => previousIsDirty != null && isDirty != previousIsDirty;

  /// Whether any aspect changed
  bool get hasChanged => valueChanged || validationChanged || dirtyStateChanged;
}
