import 'package:flutter/material.dart';
import '../../formix.dart';
import 'ancestor_validator.dart';

/// A comprehensive toolset for interacting with [Formix] state and logic.
///
/// [FormixScope] provides reactive accessors (for watching changes) and
/// action methods (for triggering logic). It abstracts away the complexity
/// of Riverpod providers while maintaining high performance through granular
/// selectors.
class FormixScope {
  /// The [BuildContext] of the widget.
  final BuildContext context;

  /// The [WidgetRef] used to watch and read providers.
  final WidgetRef ref;

  /// The [FormixController] instance for the current form.
  final FormixController controller;

  /// Creates a [FormixScope].
  FormixScope({
    required this.context,
    required this.ref,
    required this.controller,
  });

  // --- Reactive Accessors (These call ref.watch) ---

  /// Watch a specific field's value.
  ///
  /// Only rebuilds the widget when this specific field's value changes.
  T? watchValue<T>(FormixFieldID<T> id) {
    final dynamic val = ref.watch(fieldValueProvider(id));
    return val as T?;
  }

  /// Watch a specific field's validation state.
  ValidationResult watchValidation<T>(FormixFieldID<T> id) => ref.watch(fieldValidationProvider(id));

  /// Watch only the error message of a field. Returns null if valid.
  ///
  /// More efficient than [watchValidation] if you only need the message.
  String? watchError<T>(FormixFieldID<T> id) => ref.watch(fieldErrorProvider(id));

  /// Watch if a field is currently being validated (async).
  bool watchIsValidating<T>(FormixFieldID<T> id) => ref.watch(fieldValidatingProvider(id));

  /// Watch if a specific field is valid.
  bool watchFieldIsValid<T>(FormixFieldID<T> id) => ref.watch(fieldIsValidProvider(id));

  /// Watch if a specific field is dirty (its value differs from initial).
  bool watchIsDirty<T>(FormixFieldID<T> id) => ref.watch(fieldDirtyProvider(id));

  /// Watch if a specific field has been touched (focused or modified).
  bool watchIsTouched<T>(FormixFieldID<T> id) => ref.watch(fieldTouchedProvider(id));

  /// Watch if a specific field is pending (optimistic update or async).
  bool watchIsPending<T>(FormixFieldID<T> id) => ref.watch(fieldPendingProvider(id));

  /// Watch the overall validity of the form.
  bool get watchIsValid => ref.watch(formValidProvider);

  /// Watch if the form has any modifications at all.
  bool get watchIsFormDirty => ref.watch(formDirtyProvider);

  /// Watch if the form is currently submitting or performing async validation.
  bool get watchIsSubmitting => ref.watch(formSubmittingProvider);

  /// Watch the current step in a multi-step form.
  int get watchCurrentStep => ref.watch(formCurrentStepProvider);

  /// Get the current form state (watches the entire state object).
  ///
  /// WARNING: Using this will cause the widget to rebuild whenever ANY field
  /// in the form changes. For better performance, use field-specific watchers
  /// like [watchValue] or [watchValidation].
  FormixData get watchState {
    var provider = Formix.of(context);
    if (provider == null) {
      try {
        provider = ref.watch(currentControllerProvider);
      } catch (_) {}
    }
    if (provider != null) {
      return ref.watch(provider);
    }
    throw StateError('No Formix provider found');
  }

  /// Watch if a specific group of fields is valid.
  bool watchGroupIsValid(String prefix) => ref.watch(groupValidProvider(prefix));

  /// Watch if a specific group of fields contains any modifications.
  bool watchGroupIsDirty(String prefix) => ref.watch(groupDirtyProvider(prefix));

  // --- Action Methods (Non-reactive) ---

  /// Returns a nested representation of the current form values.
  Map<String, dynamic> toNestedMap() => controller.currentState.toNestedMap();

  /// Checks if a specific group of fields is valid (non-reactive).
  bool isGroupValid(String prefix) => controller.currentState.isGroupValid(prefix);

  /// Checks if a specific group of fields is dirty (non-reactive).
  bool isGroupDirty(String prefix) => controller.currentState.isGroupDirty(prefix);

  /// Update a field's value and trigger validation.
  void setValue<T>(FormixFieldID<T> id, T value) => controller.setValue(id, value);

  /// Mark a field as touched (usually called when a field loses focus).
  void markAsTouched<T>(FormixFieldID<T> id) => controller.markAsTouched(id);

  /// Checks if a field is pending (non-reactive).
  bool isFieldPending<T>(FormixFieldID<T> id) => controller.currentState.isFieldPending(id);

  /// Request focus for a specific field.
  void focusField<T>(FormixFieldID<T> id) => controller.focusField(id);

  /// Scroll to a specific field.
  void scrollToField<T>(
    FormixFieldID<T> id, {
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

  /// Sets the current step in a multi-step form.
  void goToStep(int step) => controller.goToStep(step);

  /// Increments the current step if the provided [fields] (or all current fields) are valid.
  bool nextStep({List<FormixFieldID>? fields, int? targetStep}) => controller.nextStep(fields: fields, targetStep: targetStep);

  /// Decrements the current step.
  void previousStep({int? targetStep}) => controller.previousStep(targetStep: targetStep);

  /// Validates a specific step by checking the validity of a list of fields.
  bool validateStep(List<FormixFieldID> fields) => controller.validateStep(fields);

  /// Get current values (non-reactive). useful for submissions.
  Map<String, dynamic> get values => controller.currentState.values;

  // --- Array Helpers ---

  /// Watch a form array.
  List<T> watchArray<T>(FormixArrayID<T> id) => watchValue(id) ?? <T>[];

  /// Add an item to a form array.
  void addArrayItem<T>(FormixArrayID<T> id, T item) => controller.addArrayItem(id, item);

  /// Remove an item at index from a form array.
  void removeArrayItemAt<T>(FormixArrayID<T> id, int index) => controller.removeArrayItemAt(id, index);

  /// Replace an item at index in a form array.
  void replaceArrayItem<T>(FormixArrayID<T> id, int index, T item) => controller.replaceArrayItem(id, index, item);

  /// Move an item in a form array.
  void moveArrayItem<T>(FormixArrayID<T> id, int oldIndex, int newIndex) => controller.moveArrayItem(id, oldIndex, newIndex);

  /// Clear a form array.
  void clearArray<T>(FormixArrayID<T> id) => controller.clearArray(id);

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

/// A builder widget that provides a [FormixScope] for easy form interaction.
///
/// This is the preferred way to build custom form controls or status displays
/// without creating a separate class.
///
/// Example:
/// ```dart
/// FormixBuilder(
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
class FormixBuilder extends ConsumerStatefulWidget {
  /// Creates a [FormixBuilder].
  const FormixBuilder({super.key, required this.builder});

  /// The builder function that receives the [FormixScope].
  final Widget Function(BuildContext context, FormixScope scope) builder;

  @override
  ConsumerState<FormixBuilder> createState() => _FormixBuilderState();
}

class _FormixBuilderState extends ConsumerState<FormixBuilder> {
  @override
  void dispose() {
    // Clean up any resources if necessary.
    // Riverpod providers will auto-dispose when this widget is removed
    // if there are no other listeners.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorWidget = FormixAncestorValidator.validate(
      context,
      widgetName: 'FormixBuilder',
    );

    if (errorWidget != null) return errorWidget;

    final provider = Formix.of(context)!;

    try {
      // We watch the notifier so we get the new controller if it's recreated.
      final controller = ref.watch(provider.notifier);

      final scope = FormixScope(
        context: context,
        ref: ref,
        controller: controller,
      );

      return widget.builder(context, scope);
    } catch (e) {
      return FormixConfigurationErrorWidget(
        message: 'Failed to initialize FormixBuilder',
        details: e.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.\n\nExample:\nvoid main() {\n  runApp(ProviderScope(child: MyApp()));\n}'
            : 'Error: $e',
      );
    }
  }
}

/// A base class for creating modular, reusable form components.
///
/// By extending [FormixWidget], you get safe, easy access to the form's
/// [FormixScope] without manually looking up the controller or state.
///
/// Example:
/// ```dart
/// class ErrorSummary extends FormixWidget {
///   const ErrorSummary({super.key});
///
///   @override
///   Widget buildForm(BuildContext context, FormixScope scope) {
///     if (scope.watchIsValid) return const SizedBox.shrink();
///
///     return Text(
///       'Please fix the errors before submitting.',
///       style: TextStyle(color: Colors.red),
///     );
///   }
/// }
/// ```
abstract class FormixWidget extends ConsumerStatefulWidget {
  /// Creates a [FormixWidget].
  const FormixWidget({super.key});

  @override
  @mustCallSuper
  ConsumerState<FormixWidget> createState() => _FormixWidgetState();

  /// Build the widget based on the provided [FormixScope].
  Widget buildForm(BuildContext context, FormixScope scope);
}

class _FormixWidgetState extends ConsumerState<FormixWidget> {
  @override
  Widget build(BuildContext context) {
    final errorWidget = FormixAncestorValidator.validate(
      context,
      widgetName: widget.runtimeType.toString(),
    );

    if (errorWidget != null) return errorWidget;

    final provider = Formix.of(context)!;

    try {
      final controller = ref.watch(provider.notifier);

      final scope = FormixScope(
        context: context,
        ref: ref,
        controller: controller,
      );

      return widget.buildForm(context, scope);
    } catch (e) {
      return FormixConfigurationErrorWidget(
        message: 'Failed to initialize ${widget.runtimeType}',
        details: e.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.\n\nExample:\nvoid main() {\n  runApp(ProviderScope(child: MyApp()));\n}'
            : 'Error: $e',
      );
    }
  }
}
