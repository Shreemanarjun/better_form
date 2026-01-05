/// Core form field identifier with compile-time type safety.
///
/// Use this class to define unique keys for your form fields. By providing a
/// type argument [T], you ensure that all interactions with this field
/// (getting/setting values) are type-safe.
///
/// Example:
/// ```dart
/// final nameField = FormixFieldID<String>('name');
/// final ageField = FormixFieldID<int>('age');
/// ```
class FormixFieldID<T> {
  /// Creates a new field identifier with the given [key].
  const FormixFieldID(this.key);

  /// The unique string key for this field.
  final String key;

  /// Returns a new identifier with the given [prefix] prepended to the key.
  /// Useful for namespacing fields within groups.
  FormixFieldID<T> withPrefix(String prefix) =>
      FormixFieldID<T>('$prefix.$key');

  /// Returns the parent path if this is a nested field, null otherwise.
  String? get parentKey {
    final lastDot = key.lastIndexOf('.');
    return lastDot == -1 ? null : key.substring(0, lastDot);
  }

  /// Returns the local name of the field (last segment of the path).
  String get localName {
    final lastDot = key.lastIndexOf('.');
    return lastDot == -1 ? key : key.substring(lastDot + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FormixFieldID && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'FormixFieldID<$T>($key)';
}

/// A specialized identifier for form fields that store a list of items.
///
/// This provides extra context for array-specific operations.
class FormixArrayID<T> extends FormixFieldID<List<T>> {
  /// Creates a new array identifier with the given [key].
  const FormixArrayID(super.key);

  /// Get a field ID for a specific item in the array.
  FormixFieldID<T> item(int index) => FormixFieldID<T>('$key[$index]');

  @override
  FormixArrayID<T> withPrefix(String prefix) =>
      FormixArrayID<T>('$prefix.$key');

  @override
  String toString() => 'FormixArrayID<$T>($key)';
}
