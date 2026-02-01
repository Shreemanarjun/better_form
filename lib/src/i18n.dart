// No imports needed for this file as of now.

/// Interface for all validation messages used in the formix library.
/// Developers can implement this class to provide translations.
abstract class FormixMessages {
  const FormixMessages();

  /// Default error message for required fields
  String required(String label);

  /// Default error message for invalid format (pattern)
  String invalidFormat();

  /// Error for min length validation
  String minLength(int minLength);

  /// Error for max length validation
  String maxLength(int maxLength);

  /// Error for min value validation
  String minValue(num min);

  /// Error for max value validation
  String maxValue(num max);

  /// Error for min date validation
  String minDate(DateTime minDate);

  /// Error for max date validation
  String maxDate(DateTime maxDate);

  /// Error for invalid selection
  String invalidSelection();

  /// Error message when async validation fails unexpectedly
  String validationFailed(String error);

  /// Helper text when async validation is in progress
  String validating();

  /// Resolve a template string with placeholders.
  /// Example: format('{label} must be {min}', {'label': 'Age', 'min': 18})
  String format(String template, Map<String, dynamic> params) {
    var result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}

/// Default implementation of [FormixMessages] in English.
class DefaultFormixMessages extends FormixMessages {
  const DefaultFormixMessages();

  @override
  String required(String label) => '$label is required';

  @override
  String invalidFormat() => 'Invalid format';

  @override
  String minLength(int minLength) => 'Minimum length is $minLength characters';

  @override
  String maxLength(int maxLength) => 'Maximum length is $maxLength characters';

  @override
  String minValue(num min) => 'Minimum value is $min';

  @override
  String maxValue(num max) => 'Maximum value is $max';

  @override
  String minDate(DateTime minDate) =>
      'Date must be after ${minDate.toString().split(' ')[0]}';

  @override
  String maxDate(DateTime maxDate) =>
      'Date must be before ${maxDate.toString().split(' ')[0]}';

  @override
  String invalidSelection() => 'Invalid selection';

  @override
  String validationFailed(String error) => 'Validation failed: $error';

  @override
  String validating() => 'Validating...';
}
