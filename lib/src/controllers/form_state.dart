import 'validation.dart';
import 'field_id.dart';

/// Immutable state of the entire form at a given point in time.
///
/// This includes all field values, validation results, and metadata like
/// dirty and touched states.
class BetterFormState {
  /// Map of field keys to their current values.
  final Map<String, dynamic> values;

  /// Map of field keys to their current validation results.
  final Map<String, ValidationResult> validations;

  /// Map of field keys to their dirty status (if they have been modified).
  final Map<String, bool> dirtyStates;

  /// Map of field keys to their touched status (if they have been interacted with).
  final Map<String, bool> touchedStates;

  /// Whether the form is currently in the process of being submitted.
  final bool isSubmitting;

  /// Creates a new form state.
  const BetterFormState({
    this.values = const {},
    this.validations = const {},
    this.dirtyStates = const {},
    this.touchedStates = const {},
    this.isSubmitting = false,
  });

  /// Creates a copy of this state with some properties replaced.
  BetterFormState copyWith({
    Map<String, dynamic>? values,
    Map<String, ValidationResult>? validations,
    Map<String, bool>? dirtyStates,
    Map<String, bool>? touchedStates,
    bool? isSubmitting,
  }) {
    return BetterFormState(
      values: values ?? this.values,
      validations: validations ?? this.validations,
      dirtyStates: dirtyStates ?? this.dirtyStates,
      touchedStates: touchedStates ?? this.touchedStates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  /// returns `true` if all registered fields are valid.
  bool get isValid => validations.values.every((v) => v.isValid);

  /// returns `true` if any registered field has been modified.
  bool get isDirty => dirtyStates.values.any((d) => d);

  /// Retrieves the current value for a specific field with type safety.
  T? getValue<T>(BetterFormFieldID<T> fieldId) {
    final value = values[fieldId.key];
    return value is T ? value : null;
  }

  /// Retrieves the current validation result for a specific field.
  ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId) {
    return validations[fieldId.key] ?? ValidationResult.valid;
  }

  /// Returns `true` if the field has been modified.
  bool isFieldDirty<T>(BetterFormFieldID<T> fieldId) {
    return dirtyStates[fieldId.key] ?? false;
  }

  /// Returns `true` if the field has been interacted with.
  bool isFieldTouched<T>(BetterFormFieldID<T> id) {
    return touchedStates[id.key] ?? false;
  }

  /// Returns a nested representation of the form values.
  ///
  /// This converts flat keys like 'user.name' and 'addresses[0].city' into
  /// nested maps and lists.
  Map<String, dynamic> toNestedMap() {
    final result = <String, dynamic>{};
    for (final entry in values.entries) {
      _setNestedValue(result, entry.key, entry.value);
    }
    return result;
  }

  /// Checks if a specific group of fields is valid.
  ///
  /// A group is identified by its key prefix (e.g., 'user').
  bool isGroupValid(String prefix) {
    return validations.entries
        .where((e) => e.key.startsWith('$prefix.'))
        .every((e) => e.value.isValid);
  }

  /// Checks if a specific group of fields contains any modifications.
  bool isGroupDirty(String prefix) {
    return dirtyStates.entries
        .where((e) => e.key.startsWith('$prefix.'))
        .any((e) => e.value);
  }

  void _setNestedValue(Map<String, dynamic> map, String path, dynamic value) {
    // Basic implementation for dot notation.
    // Logic for arrays (brackets) can be added if needed for auto-serialization.
    final parts = path.split('.');
    dynamic current = map;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (i == parts.length - 1) {
        if (current is Map) {
          current[part] = value;
        }
      } else {
        if (current is Map) {
          current = current[part] ??= <String, dynamic>{};
        }
      }
    }
  }
}
