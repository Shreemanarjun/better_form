import '../i18n.dart';

/// Hindi implementation of [FormixMessages].
class HindiFormixMessages extends FormixMessages {
  const HindiFormixMessages();

  @override
  String required(String label) => '$label आवश्यक है';

  @override
  String invalidFormat() => 'अमान्य प्रारूप';

  @override
  String minLength(int minLength) => 'न्यूनतम लंबाई $minLength अक्षर है';

  @override
  String maxLength(int maxLength) => 'अधिकतम लंबाई $maxLength अक्षर है';

  @override
  String minValue(num min) => 'न्यूनतम मान $min है';

  @override
  String maxValue(num max) => 'अधिकतम मान $max है';

  @override
  String minDate(DateTime minDate) =>
      'तारीख ${_formatDate(minDate)} के बाद होनी चाहिए';

  @override
  String maxDate(DateTime maxDate) =>
      'तारीख ${_formatDate(maxDate)} से पहले होनी चाहिए';

  @override
  String invalidSelection() => 'अमान्य चयन';

  @override
  String validationFailed(String error) => 'सत्यापन विफल: $error';

  @override
  String validating() => 'सत्यापित हो रहा है...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
