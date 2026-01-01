/// Auto validation modes
enum BetterAutovalidateMode {
  disabled,
  always,
  onUserInteraction,
  alwaysAfterFirstValidation,
}

/// Strategies for resetting a form
enum ResetStrategy {
  /// Reset all fields to their initial values
  initialValues,

  /// Clear all fields (set to null or empty default)
  clear,
}
