import '../i18n.dart';

/// German implementation of [FormixMessages].
class GermanFormixMessages extends FormixMessages {
  const GermanFormixMessages();

  @override
  String required(String label) => '$label ist erforderlich';

  @override
  String invalidFormat() => 'Ungültiges Format';

  @override
  String minLength(int minLength) => 'Mindestlänge ist $minLength Zeichen';

  @override
  String maxLength(int maxLength) => 'Maximale Länge ist $maxLength Zeichen';

  @override
  String minValue(num min) => 'Mindestwert ist $min';

  @override
  String maxValue(num max) => 'Maximalwert ist $max';

  @override
  String minDate(DateTime minDate) =>
      'Datum muss nach dem ${_formatDate(minDate)} liegen';

  @override
  String maxDate(DateTime maxDate) =>
      'Datum muss vor dem ${_formatDate(maxDate)} liegen';

  @override
  String invalidSelection() => 'Ungültige Auswahl';

  @override
  String validationFailed(String error) => 'Validierung fehlgeschlagen: $error';

  @override
  String validating() => 'Validierung läuft...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
