import 'package:collection/collection.dart';
import 'validation.dart';
import 'field_id.dart';

/// Immutable state of the entire form at a given point in time.
///
/// This includes all field values, validation results, and metadata like
/// dirty and touched states.
class FormixData {
  /// Map of field keys to their current values.
  final Map<String, dynamic> values;

  /// Map of field keys to their current validation results.
  final Map<String, ValidationResult> validations;

  /// Map of field keys to their dirty status (if they have been modified).
  final Map<String, bool> dirtyStates;

  /// Map of field keys to their touched status (if they have been interacted with).
  final Map<String, bool> touchedStates;

  /// Map of field keys to their pending status (e.g. validatng, syncing).
  final Map<String, bool> pendingStates;

  /// Whether the form is currently in the process of being submitted.
  final bool isSubmitting;

  /// Number of times the form has been reset.
  final int resetCount;

  /// The set of field keys that changed in the last update.
  ///
  /// This is used for delta updates to optimize notification performance.
  /// If null, consumers should assume all fields might have changed.
  final Set<String>? changedFields;

  /// Creates a new form state.
  const FormixData({
    this.values = const {},
    this.validations = const {},
    this.dirtyStates = const {},
    this.touchedStates = const {},
    this.pendingStates = const {},
    this.isSubmitting = false,
    this.resetCount = 0,
    this.changedFields,
  });

  /// Creates a copy of this state with some properties replaced.
  FormixData copyWith({
    Map<String, dynamic>? values,
    Map<String, ValidationResult>? validations,
    Map<String, bool>? dirtyStates,
    Map<String, bool>? touchedStates,
    Map<String, bool>? pendingStates,
    bool? isSubmitting,
    int? resetCount,
    Set<String>? changedFields,
  }) {
    return FormixData(
      values: values ?? this.values,
      validations: validations ?? this.validations,
      dirtyStates: dirtyStates ?? this.dirtyStates,
      touchedStates: touchedStates ?? this.touchedStates,
      pendingStates: pendingStates ?? this.pendingStates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      resetCount: resetCount ?? this.resetCount,
      changedFields: changedFields ?? this.changedFields,
    );
  }

  /// returns `true` if all registered fields are valid.
  bool get isValid => validations.values.every((v) => v.isValid);

  /// returns `true` if any registered field has been modified.
  bool get isDirty => dirtyStates.values.any((d) => d);

  /// returns `true` if any registered field is currently pending (e.g. async operation).
  bool get isPending => pendingStates.values.any((p) => p);

  /// Retrieves the current value for a specific field with type safety.
  T? getValue<T>(FormixFieldID<T> fieldId) {
    final value = values[fieldId.key];
    return value is T ? value : null;
  }

  /// Retrieves the current validation result for a specific field.
  ValidationResult getValidation<T>(FormixFieldID<T> fieldId) {
    return validations[fieldId.key] ?? ValidationResult.valid;
  }

  /// Returns `true` if the field has been modified.
  bool isFieldDirty<T>(FormixFieldID<T> fieldId) {
    return dirtyStates[fieldId.key] ?? false;
  }

  /// Returns `true` if the field has been interacted with.
  bool isFieldTouched<T>(FormixFieldID<T> id) {
    return touchedStates[id.key] ?? false;
  }

  /// Returns `true` if the field is pending (e.g. async validation or sync).
  bool isFieldPending<T>(FormixFieldID<T> id) {
    return pendingStates[id.key] ?? false;
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FormixData) return false;
    final mapEquals = const DeepCollectionEquality().equals;
    final setEquals = const SetEquality().equals;

    return mapEquals(values, other.values) &&
        mapEquals(validations, other.validations) &&
        mapEquals(dirtyStates, other.dirtyStates) &&
        mapEquals(touchedStates, other.touchedStates) &&
        mapEquals(pendingStates, other.pendingStates) &&
        isSubmitting == other.isSubmitting &&
        ((changedFields == null && other.changedFields == null) ||
            (changedFields != null &&
                other.changedFields != null &&
                setEquals(changedFields, other.changedFields)));
  }

  @override
  int get hashCode {
    final mapHash = const DeepCollectionEquality().hash;
    final setHash = const SetEquality().hash;
    return Object.hash(
      mapHash(values),
      mapHash(validations),
      mapHash(dirtyStates),
      mapHash(touchedStates),
      mapHash(pendingStates),
      isSubmitting,
      changedFields == null ? null : setHash(changedFields),
    );
  }
}
