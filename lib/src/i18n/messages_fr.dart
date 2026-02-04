import '../i18n.dart';

/// French implementation of [FormixMessages].
class FrenchFormixMessages extends FormixMessages {
  /// Creates a [FrenchFormixMessages].
  const FrenchFormixMessages();

  @override
  String required(String label) => '$label est requis';

  @override
  String invalidFormat() => 'Format invalide';

  @override
  String minLength(String label, int minLength) => '$label doit comporter au moins $minLength caractères';

  @override
  String maxLength(String label, int maxLength) => '$label doit comporter au plus $maxLength caractères';

  @override
  String minValue(String label, num min) => '$label doit être au moins $min';

  @override
  String maxValue(String label, num max) => '$label doit être au plus $max';

  @override
  String minDate(String label, DateTime minDate) => '$label doit être après le ${_formatDate(minDate)}';

  @override
  String maxDate(String label, DateTime maxDate) => '$label doit être avant le ${_formatDate(maxDate)}';

  @override
  String invalidSelection(String label) => 'Sélection invalide pour $label';

  @override
  String validationFailed(String error) => 'Échec de la validation: $error';

  @override
  String validating() => 'Validation en cours...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
