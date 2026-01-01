/// Validation result
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  static const ValidationResult valid = ValidationResult(isValid: true);
}
