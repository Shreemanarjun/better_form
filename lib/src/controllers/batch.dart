import 'field_id.dart';
import 'field.dart';

/// Represents the result of a batch update operation in Formix.
class FormixBatchResult {
  /// Creates a batch update result.
  const FormixBatchResult({
    required this.success,
    this.updatedFields = const {},
    this.typeMismatches = const {},
    this.missingFields = const {},
  });

  /// Whether all updates were applied successfully.
  final bool success;

  /// Keys of fields that were successfully updated.
  final Set<String> updatedFields;

  /// Map of field keys to error messages where a type mismatch occurred.
  final Map<String, String> typeMismatches;

  /// Set of field keys that were provided but not registered in the form.
  final Set<String> missingFields;

  /// Merged errors from mismatches and missing fields.
  Map<String, String> get errors {
    final result = <String, String>{};
    result.addAll(typeMismatches);
    for (final key in missingFields) {
      result[key] = 'Field not registered';
    }
    return result;
  }

  @override
  String toString() {
    if (success) return 'FormixBatchResult(Success: $updatedFields)';
    return 'FormixBatchResult(Failed: $errors)';
  }
}

/// A type-safe builder for batch updates.
class FormixBatch {
  final Map<String, dynamic> _updates = {};

  /// Adds an update for a specific field.
  ///
  /// **Note**: If T is not explicitly provided, Dart may infer it as Object
  /// allowing mismatched types. Use [setValue] for better lint enforcement.
  void set<T>(FormixFieldID<T> fieldId, T value) {
    _updates[fieldId.key] = value;
  }

  /// Adds an update for a specific field with guaranteed lint enforcement.
  ///
  /// Example:
  /// ```dart
  /// batch.setValue(nameFieldId).to('John'); // Correct
  /// batch.setValue(nameFieldId).to(123);    // Lint Error!
  /// ```
  FormixBatchUpdate<T> setValue<T>(FormixFieldID<T> fieldId) => FormixBatchUpdate._(this, fieldId.key);

  /// Adds an update for a specific field using the field definition.
  void setField<T>(FormixField<T> field, T value) {
    _updates[field.id.key] = value;
  }

  /// Adds an update for a specific field using the field definition with lint enforcement.
  FormixBatchUpdate<T> forField<T>(FormixField<T> field) => FormixBatchUpdate._(this, field.id.key);

  /// Adds all updates from a raw map.
  void addAll(Map<String, dynamic> rawUpdates) {
    _updates.addAll(rawUpdates);
  }

  /// Returns the collected updates.
  Map<String, dynamic> get updates => Map.unmodifiable(_updates);

  /// Whether there are any updates in this batch.
  bool get isEmpty => _updates.isEmpty;

  /// The number of updates in this batch.
  int get length => _updates.length;
}

/// Helper for type-safe batch updates.
class FormixBatchUpdate<T> {
  final FormixBatch _batch;
  final String _key;

  FormixBatchUpdate._(this._batch, this._key);

  /// Sets the value for the field.
  void to(T value) {
    _batch._updates[_key] = value;
  }
}
