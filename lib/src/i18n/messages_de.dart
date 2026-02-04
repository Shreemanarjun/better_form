import '../i18n.dart';

/// German implementation of [FormixMessages].
class GermanFormixMessages extends FormixMessages {
  const GermanFormixMessages();

  @override
  String required(String label) => '$label ist erforderlich';

  @override
  String invalidFormat() => 'Ungültiges Format';

  @override
  String minLength(String label, int minLength) => '$label muss mindestens $minLength Zeichen lang sein';

  @override
  String maxLength(String label, int maxLength) => '$label darf höchstens $maxLength Zeichen lang sein';

  @override
  String minValue(String label, num min) => '$label muss mindestens $min sein';

  @override
  String maxValue(String label, num max) => '$label darf höchstens $max sein';

  @override
  String minDate(String label, DateTime minDate) => '$label muss nach dem ${_formatDate(minDate)} liegen';

  @override
  String maxDate(String label, DateTime maxDate) => '$label muss vor dem ${_formatDate(maxDate)} liegen';

  @override
  String invalidSelection(String label) => 'Ungültige Auswahl für $label';

  @override
  String validationFailed(String error) => 'Validierung fehlgeschlagen: $error';

  @override
  String validating() => 'Validierung läuft...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
