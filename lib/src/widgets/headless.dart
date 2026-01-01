import 'package:flutter/widgets.dart';
import '../controllers/validation.dart';
import 'base_form_field.dart';

/// Snapshot of the current state of a form field
class BetterFieldStateSnapshot<T> {
  const BetterFieldStateSnapshot({
    required this.value,
    required this.validation,
    required this.isDirty,
    required this.isTouched,
    required this.isSubmitting,
    required this.focusNode,
    required this.didChange,
    required this.markAsTouched,
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

  /// Helper to check if error should be shown (touched or submitting)
  bool get shouldShowError =>
      (isTouched || isSubmitting) && !validation.isValidating;

  /// Helper to check if field is invalid
  bool get hasError => !validation.isValid;
}

/// A headless form field widget that delegates UI building to a builder
class BetterRawFormField<T> extends BetterFormFieldWidget<T> {
  const BetterRawFormField({
    super.key,
    required super.fieldId,
    required this.builder,
    super.controller,
    super.validator,
    super.initialValue,
  });

  final Widget Function(BuildContext context, BetterFieldStateSnapshot<T> state)
  builder;

  @override
  BetterRawFormFieldState<T> createState() => BetterRawFormFieldState<T>();
}

class BetterRawFormFieldState<T> extends BetterFormFieldWidgetState<T> {
  @override
  Widget build(BuildContext context) {
    // We need to listen to all the notifiers to rebuild when they change
    return ValueListenableBuilder<ValidationResult>(
      valueListenable: controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: controller.fieldTouchedNotifier(widget.fieldId),
              builder: (context, isTouched, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: controller.isSubmittingNotifier,
                  builder: (context, isSubmitting, child) {
                    final rawWidget = widget as BetterRawFormField<T>;

                    final snapshot = BetterFieldStateSnapshot<T>(
                      value: value,
                      validation: validation,
                      isDirty: isDirty,
                      isTouched: isTouched,
                      isSubmitting: isSubmitting,
                      focusNode: focusNode,
                      didChange: didChange,
                      markAsTouched: markAsTouched,
                    );

                    return rawWidget.builder(context, snapshot);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Snapshot for text fields, including text controller
class BetterTextFieldStateSnapshot<T> extends BetterFieldStateSnapshot<T> {
  const BetterTextFieldStateSnapshot({
    required super.value,
    required super.validation,
    required super.isDirty,
    required super.isTouched,
    required super.isSubmitting,
    required super.focusNode,
    required super.didChange,
    required super.markAsTouched,
    required this.textController,
  });

  /// Text editing controller for the field
  final TextEditingController textController;
}

/// A headless text field widget
class BetterRawTextField<T> extends BetterFormFieldWidget<T> {
  const BetterRawTextField({
    super.key,
    required super.fieldId,
    required this.builder,
    super.controller,
    super.validator,
    super.initialValue,
    required this.valueToString,
    required this.stringToValue,
  });

  final Widget Function(
    BuildContext context,
    BetterTextFieldStateSnapshot<T> state,
  )
  builder;

  final String Function(T? value) valueToString;
  final T? Function(String text) stringToValue;

  @override
  BetterRawTextFieldState<T> createState() => BetterRawTextFieldState<T>();
}

class BetterRawTextFieldState<T> extends BetterFormFieldWidgetState<T>
    with BetterFormFieldTextMixin<T> {
  @override
  String valueToString(T? value) =>
      (widget as BetterRawTextField<T>).valueToString(value);

  @override
  T? stringToValue(String text) =>
      (widget as BetterRawTextField<T>).stringToValue(text);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ValidationResult>(
      valueListenable: controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: controller.fieldTouchedNotifier(widget.fieldId),
              builder: (context, isTouched, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: controller.isSubmittingNotifier,
                  builder: (context, isSubmitting, child) {
                    final rawWidget = widget as BetterRawTextField<T>;

                    final snapshot = BetterTextFieldStateSnapshot<T>(
                      value: value,
                      validation: validation,
                      isDirty: isDirty,
                      isTouched: isTouched,
                      isSubmitting: isSubmitting,
                      focusNode: focusNode,
                      didChange: didChange,
                      markAsTouched: markAsTouched,
                      textController: textController,
                    );

                    return rawWidget.builder(context, snapshot);
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
