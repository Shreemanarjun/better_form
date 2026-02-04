/// Interface for receiving analytics events from Formix.
abstract class FormixAnalytics {
  /// Base constructor for [FormixAnalytics].
  const FormixAnalytics();

  /// Called when a form session starts (controller initialized).
  void onFormStarted(String? formId);

  /// Called when a field value changes.
  void onFieldChanged(String? formId, String fieldKey, dynamic newValue);

  /// Called when a field gains focus/is touched.
  void onFieldTouched(String? formId, String fieldKey);

  /// Called when form submission is attempted.
  void onSubmitAttempt(String? formId, Map<String, dynamic> values);

  /// Called when form submission succeeds.
  void onSubmitSuccess(String? formId);

  /// Called when form submission fails (validation or error callback).
  void onSubmitFailure(String? formId, Map<String, dynamic> errors);

  /// Called when the form is disposed/abandoned without successful submission.
  void onFormAbandoned(String? formId, Duration timeSpent);
}
