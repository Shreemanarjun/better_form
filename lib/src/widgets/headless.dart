import 'package:flutter/widgets.dart';
import '../controllers/validation.dart';
import 'base_form_field.dart';

/// Snapshot of the current state of a form field
class FormixFieldStateSnapshot<T> {
  /// Creates a [FormixFieldStateSnapshot].
  const FormixFieldStateSnapshot({
    required this.value,
    required this.validation,
    required this.isDirty,
    required this.isTouched,
    required this.isSubmitting,
    required this.focusNode,
    required this.didChange,
    required this.markAsTouched,
    required this.valueNotifier,
    required this.enabled,
    this.errorBuilder,
  });

  /// Current value of the field
  final T? value;

  /// Current validation result
  final ValidationResult validation;

  /// Whether the field has been modified
  final bool isDirty;

  /// Whether the field has been touched (blurred)
  final bool isTouched;

  /// Whether the form is currently submitting
  final bool isSubmitting;

  /// Focus node for the field
  final FocusNode focusNode;

  /// Function to update the value
  final ValueChanged<T?> didChange;

  /// Function to manually mark as touched
  final VoidCallback markAsTouched;

  /// Value notifier for the field value.
  ///
  /// Provides granular reactivity for optimizing rebuilds. Use this with
  /// [ValueListenableBuilder] to listen to value changes without triggering
  /// full widget rebuilds.
  ///
  /// Example:
  /// ```dart
  /// FormixRawFormField<String>(
  ///   fieldId: nameField,
  ///   builder: (context, state) {
  ///     return ValueListenableBuilder<String?>(
  ///       valueListenable: state.valueNotifier,
  ///       builder: (context, value, _) {
  ///         // Only this builder rebuilds when value changes
  ///         return Text('Current value: $value');
  ///       },
  ///     );
  ///   },
  /// )
  /// ```
  ///
  /// See also:
  ///  * [FormixRawNotifierField], which is specifically designed to emphasize
  ///    the use of [valueNotifier] for granular updates.
  final ValueNotifier<T?> valueNotifier;

  /// Whether the field is enabled
  final bool enabled;

  /// Custom error builder
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Helper to check if error should be shown (touched or submitting)
  bool get shouldShowError {
    // This is a bit simplified, but essentially we want to show if it's invalid AND (touched OR submitting)
    return !validation.isValid && (isTouched || isSubmitting);
  }

  /// Helper to check if field is invalid
  bool get hasError => !validation.isValid;
}

/// A headless form field widget that delegates UI building to a builder
class FormixRawFormField<T> extends FormixFieldWidget<T> {
  /// Creates a [FormixRawFormField].
  const FormixRawFormField({
    super.key,
    required super.fieldId,
    required this.builder,
    super.controller,
    super.validator,
    super.initialValue,
    super.enabled,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
  });

  /// Builder function to create the widget tree.
  final Widget Function(BuildContext context, FormixFieldStateSnapshot<T> state) builder;

  @override
  FormixRawFormFieldState<T> createState() => FormixRawFormFieldState<T>();
}

/// State for [FormixRawFormField].
class FormixRawFormFieldState<T> extends FormixFieldWidgetState<T> {
  @override
  void onFieldChanged(T? value) {
    // We don't call super.onFieldChanged() to avoid full widget rebuilds via setState.
    // Instead, we rely on ValueListenableBuilders for granular updates.
    // However, we still want to notify other potential listeners if needed.
  }

  @override
  Widget build(BuildContext context) {
    final rawWidget = widget as FormixRawFormField<T>;

    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.fieldValueListenable(widget.fieldId),
        controller.fieldValidationNotifier(widget.fieldId),
        controller.fieldDirtyNotifier(widget.fieldId),
        controller.fieldTouchedNotifier(widget.fieldId),
        controller.isSubmittingNotifier,
      ]),
      builder: (context, _) {
        final snapshot = FormixFieldStateSnapshot<T>(
          value: controller.getValue(widget.fieldId),
          validation: controller.getValidation(widget.fieldId),
          isDirty: controller.isFieldDirty(widget.fieldId),
          isTouched: controller.isFieldTouched(widget.fieldId),
          isSubmitting: controller.isSubmitting,
          focusNode: focusNode,
          didChange: didChange,
          markAsTouched: markAsTouched,
          valueNotifier: controller.getFieldNotifier(widget.fieldId),
          enabled: widget.enabled,
          errorBuilder: widget.errorBuilder,
        );

        return wrapSemantics(rawWidget.builder(context, snapshot));
      },
    );
  }
}

/// Snapshot for text fields, including text controller
class FormixTextFieldStateSnapshot<T> extends FormixFieldStateSnapshot<T> {
  /// Creates a [FormixTextFieldStateSnapshot].
  const FormixTextFieldStateSnapshot({
    required super.value,
    required super.validation,
    required super.isDirty,
    required super.isTouched,
    required super.isSubmitting,
    required super.focusNode,
    required super.didChange,
    required super.markAsTouched,
    required super.valueNotifier,
    required super.enabled,
    super.errorBuilder,
    required this.textController,
  });

  /// Text editing controller for the field
  final TextEditingController textController;
}

/// A headless text field widget
class FormixRawTextField<T> extends FormixFieldWidget<T> {
  /// Creates a [FormixRawTextField].
  const FormixRawTextField({
    super.key,
    required super.fieldId,
    required this.builder,
    super.controller,
    super.validator,
    super.initialValue,
    required this.valueToString,
    required this.stringToValue,
    super.enabled,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
  });

  /// Builder function to create the widget tree.
  final Widget Function(
    BuildContext context,
    FormixTextFieldStateSnapshot<T> state,
  )
  builder;

  /// Function to convert value to string for text field.
  final String Function(T? value) valueToString;

  /// Function to convert string back to value.
  final T? Function(String text) stringToValue;

  @override
  FormixRawTextFieldState<T> createState() => FormixRawTextFieldState<T>();
}

/// State for [FormixRawTextField].
class FormixRawTextFieldState<T> extends FormixFieldWidgetState<T> with FormixFieldTextMixin<T> {
  @override
  String valueToString(T? value) => (widget as FormixRawTextField<T>).valueToString(value);

  @override
  T? stringToValue(String text) => (widget as FormixRawTextField<T>).stringToValue(text);

  @override
  void onFieldChanged(T? value) {
    // We rely on FormixFieldTextMixin and AnimatedBuilder
    super.onFieldChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final rawWidget = widget as FormixRawTextField<T>;

    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.fieldValueListenable(widget.fieldId),
        controller.fieldValidationNotifier(widget.fieldId),
        controller.fieldDirtyNotifier(widget.fieldId),
        controller.fieldTouchedNotifier(widget.fieldId),
        controller.isSubmittingNotifier,
      ]),
      builder: (context, _) {
        final snapshot = FormixTextFieldStateSnapshot<T>(
          value: controller.getValue(widget.fieldId),
          validation: controller.getValidation(widget.fieldId),
          isDirty: controller.isFieldDirty(widget.fieldId),
          isTouched: controller.isFieldTouched(widget.fieldId),
          isSubmitting: controller.isSubmitting,
          focusNode: focusNode,
          didChange: didChange,
          markAsTouched: markAsTouched,
          valueNotifier: controller.getFieldNotifier(widget.fieldId),
          enabled: widget.enabled,
          errorBuilder: widget.errorBuilder,
          textController: textController,
        );

        return rawWidget.builder(context, snapshot);
      },
    );
  }
}

/// A headless text field widget specialized for String values
class FormixRawStringField extends FormixRawTextField<String> {
  /// Creates a [FormixRawStringField].
  const FormixRawStringField({
    super.key,
    required super.fieldId,
    required super.builder,
    super.controller,
    super.validator,
    super.initialValue,
    super.enabled,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
  }) : super(
         valueToString: _defaultToString,
         stringToValue: _defaultFromString,
       );

  static String _defaultToString(String? v) => v ?? '';
  static String? _defaultFromString(String s) => s;
}

/// A headless field widget that specifically emphasizes the ValueNotifier pattern.
///
/// This is a specialized version of [FormixRawFormField] that highlights the use
/// of [FormixFieldStateSnapshot.valueNotifier] for granular reactivity. It's
/// functionally identical to [FormixRawFormField] but serves as a semantic
/// indicator that you're building a widget optimized for ValueNotifier-based updates.
///
/// Use this when you want to minimize rebuilds by using [ValueListenableBuilder]
/// to listen only to value changes, rather than rebuilding on every state change.
///
/// Example:
/// ```dart
/// FormixRawNotifierField<int>(
///   fieldId: counterField,
///   builder: (context, state) {
///     return Column(
///       children: [
///         // This part rebuilds on ANY state change (validation, dirty, etc.)
///         Text('Field Status: ${state.isDirty ? "Modified" : "Pristine"}'),
///
///         // This part ONLY rebuilds when the value changes
///         ValueListenableBuilder<int?>(
///           valueListenable: state.valueNotifier,
///           builder: (context, value, _) {
///             return Text('Count: ${value ?? 0}');
///           },
///         ),
///
///         ElevatedButton(
///           onPressed: () => state.didChange((state.value ?? 0) + 1),
///           child: Text('Increment'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
///
/// See also:
///  * [FormixRawFormField], the base headless field widget.
///  * [FormixFieldStateSnapshot.valueNotifier], for details on the ValueNotifier.
class FormixRawNotifierField<T> extends FormixRawFormField<T> {
  /// Creates a [FormixRawNotifierField].
  const FormixRawNotifierField({
    super.key,
    required super.fieldId,
    required super.builder,
    super.controller,
    super.validator,
    super.initialValue,
    super.enabled,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
  });
}
