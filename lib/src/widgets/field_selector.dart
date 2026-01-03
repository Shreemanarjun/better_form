import '../controllers/field_id.dart';
import '../controllers/validation.dart';

/// Information about what changed in a field
class FieldChangeInfo<T> {
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

  final BetterFormFieldID<T> fieldId;
  final T? value;
  final ValidationResult validation;
  final bool isDirty;
  final bool hasInitialValueChanged;
  final T? previousValue;
  final ValidationResult? previousValidation;
  final bool? previousIsDirty;

  /// Whether the value changed
  bool get valueChanged => previousValue != null && value != previousValue;

  /// Whether the validation changed
  bool get validationChanged =>
      previousValidation != null && validation != previousValidation;

  /// Whether the dirty state changed
  bool get dirtyStateChanged =>
      previousIsDirty != null && isDirty != previousIsDirty;

  /// Whether any aspect changed
  bool get hasChanged => valueChanged || validationChanged || dirtyStateChanged;
}
