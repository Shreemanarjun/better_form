/// Keys used for standard validation errors to support internationalization.
class FormixValidationKeys {
  static const String required = 'formix_key_required';
  static const String invalidFormat = 'formix_key_invalid_format';
  static const String invalidEmail = 'formix_key_invalid_email';
  static const String minLength = 'formix_key_min_length';
  static const String maxLength = 'formix_key_max_length';
  static const String min = 'formix_key_min';
  static const String max = 'formix_key_max';

  // Helper to encode params into the key string if needed,
  // though simple string concatenation with separator might suffice.
  static String withParam(String key, dynamic param) => '$key:$param';
}
