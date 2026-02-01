/// The result of a field's validation.
class ValidationResult {
  /// Creates a validation result.
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isValidating = false,
  });

  /// Whether the field is considered valid.
  final bool isValid;

  /// The error message if [isValid] is false.
  final String? errorMessage;

  /// Whether the field is currently undergoing asynchronous validation.
  final bool isValidating;

  /// Constant for a successful validation result.
  static const ValidationResult valid = ValidationResult(isValid: true);

  static const ValidationResult validating = ValidationResult(
    isValid: true,
    isValidating: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage &&
          isValidating == other.isValidating;

  @override
  int get hashCode =>
      isValid.hashCode ^ errorMessage.hashCode ^ isValidating.hashCode;
}
