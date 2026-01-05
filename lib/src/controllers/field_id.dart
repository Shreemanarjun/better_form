/// Core form field identifier with compile-time type safety.
///
/// Use this class to define unique keys for your form fields. By providing a
/// type argument [T], you ensure that all interactions with this field
/// (getting/setting values) are type-safe.
///
/// Example:
/// ```dart
/// final nameField = BetterFormFieldID<String>('name');
/// final ageField = BetterFormFieldID<int>('age');
/// ```
class BetterFormFieldID<T> {
  /// Creates a new field identifier with the given [key].
  const BetterFormFieldID(this.key);

  /// The unique string key for this field.
  final String key;

  /// Returns a new identifier with the given [prefix] prepended to the key.
  /// Useful for namespacing fields within groups.
  BetterFormFieldID<T> withPrefix(String prefix) =>
      BetterFormFieldID<T>('$prefix.$key');

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
      identical(this, other) || other is BetterFormFieldID && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'BetterFormFieldID<$T>($key)';
}

/// A specialized identifier for form fields that store a list of items.
///
/// This provides extra context for array-specific operations.
class BetterFormArrayID<T> extends BetterFormFieldID<List<T>> {
  /// Creates a new array identifier with the given [key].
  const BetterFormArrayID(super.key);

  /// Get a field ID for a specific item in the array.
  BetterFormFieldID<T> item(int index) => BetterFormFieldID<T>('$key[$index]');

  @override
  BetterFormArrayID<T> withPrefix(String prefix) =>
      BetterFormArrayID<T>('$prefix.$key');

  @override
  String toString() => 'BetterFormArrayID<$T>($key)';
}
