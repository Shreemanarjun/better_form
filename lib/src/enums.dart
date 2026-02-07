/// Auto validation modes for the entire form or specific fields.
enum FormixAutovalidateMode {
  /// Use the form's global validation mode.
  auto,

  /// Validation is only performed manually via [validate()].
  disabled,

  /// Validation is performed immediately on every change.
  always,

  /// Validation starts after the user first interacts with the field.
  onUserInteraction,

  /// Validation only happens when the field loses focus.
  onBlur,
}

/// Defines when validation should be triggered for a field.
enum ValidationTrigger {
  /// Validate whenever the value changes.
  onChange,

  /// Validate when the field loses focus.
  onBlur,

  /// Only validate when the form is submitted or [validate()] is called.
  manual,
}

/// Strategies for resetting a form
enum ResetStrategy {
  /// Reset all fields to their initial values
  initialValues,

  /// Clear all fields (set to null or empty default)
  clear,
}

/// Strategies for handling initial values when a field is registered or updated.
enum FormixInitialValueStrategy {
  /// Prefer the local initial value (from the widget) if the field is currently
  /// uninitialized or null in the controller.
  preferLocal,

  /// Prefer the global initial value (from the root Formix widget or config).
  /// The value will not be updated from widgets after initial registration.
  preferGlobal,
}
