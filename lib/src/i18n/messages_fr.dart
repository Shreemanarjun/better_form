import '../i18n.dart';

/// French implementation of [FormixMessages].
class FrenchFormixMessages extends FormixMessages {
  const FrenchFormixMessages();

  @override
  String required(String label) => '$label est requis';

  @override
  String invalidFormat() => 'Format invalide';

  @override
  String minLength(int minLength) =>
      'La longueur minimale est de $minLength caractères';

  @override
  String maxLength(int maxLength) =>
      'La longueur maximale est de $maxLength caractères';

  @override
  String minValue(num min) => 'La valeur minimale est $min';

  @override
  String maxValue(num max) => 'La valeur maximale est $max';

  @override
  String minDate(DateTime minDate) =>
      'La date doit être après le ${_formatDate(minDate)}';

  @override
  String maxDate(DateTime maxDate) =>
      'La date doit être avant le ${_formatDate(maxDate)}';

  @override
  String invalidSelection() => 'Sélection invalide';

  @override
  String validationFailed(String error) => 'Échec de la validation: $error';

  @override
  String validating() => 'Validation en cours...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
