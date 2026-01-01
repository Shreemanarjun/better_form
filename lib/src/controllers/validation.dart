/// Validation result
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.isValidating = false,
  });

  final bool isValid;
  final String? errorMessage;
  final bool isValidating;

  static const ValidationResult valid = ValidationResult(isValid: true);
  static const ValidationResult validating = ValidationResult(
    isValid: true,
    isValidating: true,
  );
}
