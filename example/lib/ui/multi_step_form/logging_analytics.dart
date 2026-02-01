import 'package:flutter/foundation.dart';
import 'package:formix/formix.dart';

// Simple Analytics implementation for demonstration
class LoggingFormixAnalytics extends FormixAnalytics {
  const LoggingFormixAnalytics();

  @override
  void onFormStarted(String? formId) {
    debugPrint('ANALYTICS: Form "$formId" started.');
  }

  @override
  void onFieldChanged(String? formId, String fieldKey, dynamic newValue) {
    debugPrint('ANALYTICS: Field "$fieldKey" changed to "$newValue"');
  }

  @override
  void onFieldTouched(String? formId, String fieldKey) {
    debugPrint('ANALYTICS: Field "$fieldKey" touched.');
  }

  @override
  void onSubmitAttempt(String? formId, Map<String, dynamic> values) {
    debugPrint(
      'ANALYTICS: Submit attempt for "$formId" with ${values.length} values.',
    );
  }

  @override
  void onSubmitSuccess(String? formId) {
    debugPrint('ANALYTICS: Form "$formId" submitted successfully!');
  }

  @override
  void onSubmitFailure(String? formId, Map<String, dynamic> errors) {
    debugPrint(
      'ANALYTICS: Form "$formId" failed validation. Errors: ${errors.keys.join(', ')}',
    );
  }

  @override
  void onFormAbandoned(String? formId, Duration timeSpent) {
    debugPrint(
      'ANALYTICS: Form "$formId" abandoned after ${timeSpent.inSeconds}s.',
    );
  }
}
