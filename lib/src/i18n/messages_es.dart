import '../i18n.dart';

/// Spanish implementation of [FormixMessages].
class SpanishFormixMessages extends FormixMessages {
  const SpanishFormixMessages();

  @override
  String required(String label) => '$label es requerido';

  @override
  String invalidFormat() => 'Formato inválido';

  @override
  String minLength(String label, int minLength) => '$label debe tener al menos $minLength caracteres';

  @override
  String maxLength(String label, int maxLength) => '$label debe tener como máximo $maxLength caracteres';

  @override
  String minValue(String label, num min) => '$label debe ser al menos $min';

  @override
  String maxValue(String label, num max) => '$label debe ser como máximo $max';

  @override
  String minDate(String label, DateTime minDate) => '$label debe ser posterior a ${_formatDate(minDate)}';

  @override
  String maxDate(String label, DateTime maxDate) => '$label debe ser anterior a ${_formatDate(maxDate)}';

  @override
  String invalidSelection(String label) => 'Selección inválida para $label';

  @override
  String validationFailed(String error) => 'Validación falló: $error';

  @override
  String validating() => 'Validando...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
