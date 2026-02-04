import '../i18n.dart';

/// Hindi implementation of [FormixMessages].
class HindiFormixMessages extends FormixMessages {
  /// Creates a [HindiFormixMessages].
  const HindiFormixMessages();

  @override
  String required(String label) => '$label आवश्यक है';

  @override
  String invalidFormat() => 'अमान्य प्रारूप';

  @override
  String minLength(String label, int minLength) => '$label की न्यूनतम लंबाई $minLength अक्षर होनी चाहिए'; // Adapted

  @override
  String maxLength(String label, int maxLength) => '$label की अधिकतम लंबाई $maxLength अक्षर हो सकती है';

  @override
  String minValue(String label, num min) => '$label का न्यूनतम मान $min होना चाहिए';

  @override
  String maxValue(String label, num max) => '$label का अधिकतम मान $max हो सकता है';

  @override
  String minDate(String label, DateTime minDate) => '$label की तारीख ${_formatDate(minDate)} के बाद होनी चाहिए';

  @override
  String maxDate(String label, DateTime maxDate) => '$label की तारीख ${_formatDate(maxDate)} से पहले होनी चाहिए';

  @override
  String invalidSelection(String label) => '$label के लिए अमान्य चयन';

  @override
  String validationFailed(String error) => 'सत्यापन विफल: $error';

  @override
  String validating() => 'सत्यापित हो रहा है...';

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
