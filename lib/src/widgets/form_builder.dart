import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/riverpod_controller.dart';
import '../controllers/field_id.dart';
import '../controllers/validation.dart';
import 'riverpod_form_fields.dart';

/// A comprehensive toolset for interacting with [BetterForm] state and logic.
///
/// [BetterFormScope] provides reactive accessors (for watching changes) and
/// action methods (for triggering logic). It abstracts away the complexity
/// of Riverpod providers while maintaining high performance through granular
/// selectors.
class BetterFormScope {
  /// The [BuildContext] of the widget.
  final BuildContext context;

  /// The [WidgetRef] used to watch and read providers.
  final WidgetRef ref;

  /// The [BetterFormController] instance for the current form.
  final BetterFormController controller;

  BetterFormScope({
    required this.context,
    required this.ref,
    required this.controller,
  });

  // --- Reactive Accessors (These call ref.watch) ---

  /// Watch a specific field's value.
  ///
  /// Only rebuilds the widget when this specific field's value changes.
  T? watchValue<T>(BetterFormFieldID<T> id) {
    final dynamic val = ref.watch(fieldValueProvider(id));
    return val as T?;
  }

  /// Watch a specific field's validation state.
  ValidationResult watchValidation<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldValidationProvider(id));

  /// Watch only the error message of a field. Returns null if valid.
  ///
  /// More efficient than [watchValidation] if you only need the message.
  String? watchError<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldErrorProvider(id));

  /// Watch if a field is currently being validated (async).
  bool watchIsValidating<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldValidatingProvider(id));

  /// Watch if a specific field is valid.
  bool watchFieldIsValid<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldIsValidProvider(id));

  /// Watch if a specific field is dirty (its value differs from initial).
  bool watchIsDirty<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldDirtyProvider(id));

  /// Watch if a specific field has been touched (focused or modified).
  bool watchIsTouched<T>(BetterFormFieldID<T> id) =>
      ref.watch(fieldTouchedProvider(id));

  /// Watch the overall validity of the form.
  bool get watchIsValid => ref.watch(formValidProvider);

  /// Watch if the form has any modifications at all.
  bool get watchIsFormDirty => ref.watch(formDirtyProvider);

  /// Watch if the form is currently submitting or performing async validation.
  bool get watchIsSubmitting => ref.watch(formSubmittingProvider);

  /// Get the current form state (watches the entire state object).
  ///
  /// WARNING: Using this will cause the widget to rebuild whenever ANY field
  /// in the form changes. For better performance, use field-specific watchers
  /// like [watchValue] or [watchValidation].
  BetterFormState get watchState => ref.watch(BetterForm.of(context)!);

  /// Watch if a specific group of fields is valid.
  bool watchGroupIsValid(String prefix) =>
      ref.watch(groupValidProvider(prefix));

  /// Watch if a specific group of fields contains any modifications.
  bool watchGroupIsDirty(String prefix) =>
      ref.watch(groupDirtyProvider(prefix));

  // --- Action Methods (Non-reactive) ---

  /// Returns a nested representation of the current form values.
  Map<String, dynamic> toNestedMap() => controller.currentState.toNestedMap();

  /// Checks if a specific group of fields is valid (non-reactive).
  bool isGroupValid(String prefix) =>
      controller.currentState.isGroupValid(prefix);

  /// Checks if a specific group of fields is dirty (non-reactive).
  bool isGroupDirty(String prefix) =>
      controller.currentState.isGroupDirty(prefix);

  /// Update a field's value and trigger validation.
  void setValue<T>(BetterFormFieldID<T> id, T value) =>
      controller.setValue(id, value);

  /// Mark a field as touched (usually called when a field loses focus).
  void markAsTouched<T>(BetterFormFieldID<T> id) =>
      controller.markAsTouched(id);

  /// Request focus for a specific field.
  void focusField<T>(BetterFormFieldID<T> id) => controller.focusField(id);

  /// Scroll to a specific field.
  void scrollToField<T>(
    BetterFormFieldID<T> id, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.5,
  }) {
    controller.scrollToField(
      id,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  }

  /// Focus the first field that currently has a validation error.
  void focusFirstError() => controller.focusFirstError();

  /// Manually trigger form-wide validation. Returns true if all fields are valid.
  bool validate() => controller.validate();

  /// Reset the form to its initial values and clear all error states.
  void reset() => controller.reset();

  // --- Array Helpers ---

  /// Watch a form array.
  List<T> watchArray<T>(BetterFormArrayID<T> id) => watchValue(id) ?? <T>[];

  /// Add an item to a form array.
  void addArrayItem<T>(BetterFormArrayID<T> id, T item) =>
      controller.addArrayItem(id, item);

  /// Remove an item at index from a form array.
  void removeArrayItemAt<T>(BetterFormArrayID<T> id, int index) =>
      controller.removeArrayItemAt(id, index);

  /// Replace an item at index in a form array.
  void replaceArrayItem<T>(BetterFormArrayID<T> id, int index, T item) =>
      controller.replaceArrayItem(id, index, item);

  /// Move an item in a form array.
  void moveArrayItem<T>(BetterFormArrayID<T> id, int oldIndex, int newIndex) =>
      controller.moveArrayItem(id, oldIndex, newIndex);

  /// Clear a form array.
  void clearArray<T>(BetterFormArrayID<T> id) => controller.clearArray(id);

  /// High-level helper for form submission.
  ///
  /// workflow:
  /// 1. Runs [validate()].
  /// 2. If valid, sets [isSubmitting] to true.
  /// 3. Executes [onValid] with current form values.
  /// 4. Resets [isSubmitting] when finished.
  /// 5. If invalid, executes [onError].
  Future<void> submit({
    required Future<void> Function(Map<String, dynamic> values) onValid,
    void Function(Map<String, ValidationResult> errors)? onError,
    Duration? debounce,
    Duration? throttle,
    bool optimistic = false,
  }) async {
    return controller.submit(
      onValid: onValid,
      onError: onError,
      debounce: debounce,
      throttle: throttle,
      optimistic: optimistic,
    );
  }
}

/// A builder widget that provides a [BetterFormScope] for easy form interaction.
///
/// This is the preferred way to build custom form controls or status displays
/// without creating a separate class.
///
/// Example:
/// ```dart
/// BetterFormBuilder(
///   builder: (context, scope) {
///     final isSubmitting = scope.watchIsSubmitting;
///     final isValid = scope.watchIsValid;
///
///     return ElevatedButton(
///       onPressed: (isValid && !isSubmitting)
///         ? () => scope.submit(onValid: (values) => save(values))
///         : null,
///       child: isSubmitting ? CircularProgressIndicator() : Text('Submit'),
///     );
///   },
/// )
/// ```
class BetterFormBuilder extends ConsumerWidget {
  const BetterFormBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, BetterFormScope scope) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = BetterForm.of(context);
    if (provider == null) {
      throw FlutterError(
        'BetterFormBuilder must be placed inside a BetterForm widget',
      );
    }

    // We use ref.read to get the controller once, as it remains stable.
    final controller = ref.read(provider.notifier) as BetterFormController;

    final scope = BetterFormScope(
      context: context,
      ref: ref,
      controller: controller,
    );

    return builder(context, scope);
  }
}

/// A base class for creating modular, reusable form components.
///
/// By extending [BetterFormWidget], you get safe, easy access to the form's
/// [BetterFormScope] without manually looking up the controller or state.
///
/// Example:
/// ```dart
/// class ErrorSummary extends BetterFormWidget {
///   const ErrorSummary({super.key});
///
///   @override
///   Widget buildForm(BuildContext context, BetterFormScope scope) {
///     if (scope.watchIsValid) return const SizedBox.shrink();
///
///     return Text(
///       'Please fix the errors before submitting.',
///       style: TextStyle(color: Colors.red),
///     );
///   }
/// }
/// ```
abstract class BetterFormWidget extends ConsumerWidget {
  const BetterFormWidget({super.key});

  @override
  @mustCallSuper
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = BetterForm.of(context);
    if (provider == null) {
      throw FlutterError(
        '$runtimeType must be placed inside a BetterForm widget',
      );
    }

    final controller = ref.read(provider.notifier) as BetterFormController;

    final scope = BetterFormScope(
      context: context,
      ref: ref,
      controller: controller,
    );

    return buildForm(context, scope);
  }

  /// Build the widget based on the provided [BetterFormScope].
  Widget buildForm(BuildContext context, BetterFormScope scope);
}
