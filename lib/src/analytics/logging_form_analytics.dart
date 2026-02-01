import 'package:flutter/foundation.dart';
import 'form_analytics.dart';

/// A simple implementation of [FormixAnalytics] that logs events to the console.
///
/// Useful for debugging during development.
class LoggingFormAnalytics implements FormixAnalytics {
  const LoggingFormAnalytics({this.prefix = 'Formix', this.enabled = true});

  final String prefix;
  final bool enabled;

  void _log(String message) {
    if (enabled && kDebugMode) {
      debugPrint('[$prefix] $message');
    }
  }

  @override
  void onFormStarted(String? formId) {
    _log('Form Started: ${formId ?? 'unknown'}');
  }

  @override
  void onFieldChanged(String? formId, String fieldKey, dynamic newValue) {
    _log('Field Changed [$fieldKey]: $newValue');
  }

  @override
  void onFieldTouched(String? formId, String fieldKey) {
    _log('Field Touched [$fieldKey]');
  }

  @override
  void onSubmitAttempt(String? formId, Map<String, dynamic> values) {
    _log('Submit Attempt: $values');
  }

  @override
  void onSubmitSuccess(String? formId) {
    _log('Submit Success');
  }

  @override
  void onSubmitFailure(String? formId, Map<String, dynamic> errors) {
    _log('Submit Failure. Errors: $errors');
  }

  @override
  void onFormAbandoned(String? formId, Duration timeSpent) {
    _log(
      'Form Abandoned after ${timeSpent.inSeconds}s (FormId: ${formId ?? 'unknown'})',
    );
  }
}
