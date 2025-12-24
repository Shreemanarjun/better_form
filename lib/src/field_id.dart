/// Core form field identifier with compile-time type safety
class BetterFormFieldID<T> {
  const BetterFormFieldID(this.key);

  final String key;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BetterFormFieldID<T> && runtimeType == other.runtimeType && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'BetterFormFieldID<$T>($key)';
}
