import '../i18n.dart';

/// Spanish implementation of [FormixMessages].
class SpanishFormixMessages extends FormixMessages {
  const SpanishFormixMessages();

  @override
  String required(String label) => '$label es requerido';

  @override
  String invalidFormat() => 'Formato inválido';

  @override
  String minLength(int minLength) =>
      'La longitud mínima es $minLength caracteres';

  @override
  String maxLength(int maxLength) =>
      'La longitud máxima es $maxLength caracteres';

  @override
  String minValue(num min) => 'El valor mínimo es $min';

  @override
  String maxValue(num max) => 'El valor máximo es $max';

  @override
  String minDate(DateTime minDate) =>
      'La fecha debe ser después de ${_formatDate(minDate)}';

  @override
  String maxDate(DateTime maxDate) =>
      'La fecha debe ser antes de ${_formatDate(maxDate)}';

  @override
  String invalidSelection() => 'Selección inválida';

  @override
  String validationFailed(String error) => 'Validación falló: $error';

  @override
  String validating() => 'Validando...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
