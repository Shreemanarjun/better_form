import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'base_form_field.dart';
import '../enums.dart';
import 'form_theme.dart';

/// A Formix-based dropdown form field that is lifecycle aware.
class FormixDropdownFormField<T> extends FormixFieldWidget<T> {
  /// Creates a [FormixDropdownFormField].
  const FormixDropdownFormField({
    super.key,
    required super.fieldId,
    required this.items,
    super.controller,
    super.validator,
    super.initialValue,
    this.decoration,
    this.loadingIcon,
    this.hint,
    this.disabledHint,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.enabled = true,
    super.autovalidateMode,
    super.initialValueStrategy,
    super.restorationId,
    this.textInputAction,
    this.onSubmitted,
    this.mouseCursor,
  });

  /// The list of items the user can select.
  final List<DropdownMenuItem<T>> items;

  /// The decoration to show around the dropdown.
  final InputDecoration? decoration;

  /// Optional widget to display while validating.
  final Widget? loadingIcon;

  /// A placeholder to show when no item is selected.
  final Widget? hint;

  /// A placeholder to show when the dropdown is disabled.
  final Widget? disabledHint;

  /// Keyboard action (e.g. next, done)
  final TextInputAction? textInputAction;

  /// Callback when field is submitted
  final void Function(T?)? onSubmitted;

  /// The mouse cursor to use.
  final MouseCursor? mouseCursor;

  @override
  FormixDropdownFormFieldState<T> createState() => FormixDropdownFormFieldState<T>();
}

/// State for [FormixDropdownFormField].
class FormixDropdownFormFieldState<T> extends FormixFieldWidgetState<T> {
  @override
  Widget build(BuildContext context) {
    final dropdownWidget = widget as FormixDropdownFormField<T>;

    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.fieldValidationNotifier(widget.fieldId),
        controller.fieldTouchedNotifier(widget.fieldId),
        controller.fieldDirtyNotifier(widget.fieldId),
        controller.isSubmittingNotifier,
      ]),
      builder: (context, _) {
        final validation = this.validation;
        final isTouched = this.isTouched;
        final isDirty = this.isDirty;
        final isSubmitting = controller.isSubmitting;

        final formTheme = FormixTheme.of(context);

        Widget? suffixIcon;
        if (validation.isValidating) {
          suffixIcon =
              dropdownWidget.loadingIcon ??
              (formTheme.enabled ? formTheme.loadingIcon : null) ??
              const SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        } else if (isDirty) {
          suffixIcon = (formTheme.enabled ? formTheme.editIcon : null) ?? const Icon(Icons.edit, size: 16);
        }

        final validationMode = controller.getValidationMode(widget.fieldId);
        final showImmediate = validationMode == FormixAutovalidateMode.always;

        final shouldShowError = (isTouched || isSubmitting || showImmediate) && !validation.isValid;

        final baseDecoration = formTheme.enabled
            ? (dropdownWidget.decoration ?? const InputDecoration()).applyDefaults(
                formTheme.decorationTheme ?? Theme.of(context).inputDecorationTheme,
              )
            : (dropdownWidget.decoration ?? const InputDecoration());

        final effectiveDecoration = baseDecoration.copyWith(
          errorText: shouldShowError ? validation.errorMessage : null,
          suffixIcon: suffixIcon,
          helperText: validation.isValidating ? 'Validating...' : null,
        );

        return MergeSemantics(
          child: Semantics(
            validationResult: validation.isValid ? SemanticsValidationResult.valid : SemanticsValidationResult.invalid,
            child: InputDecorator(
              decoration: effectiveDecoration,
              child: MouseRegion(
                cursor: dropdownWidget.mouseCursor ?? MouseCursor.defer,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: dropdownWidget.items.any((item) => item.value == value) ? value : null,
                    items: dropdownWidget.items,
                    focusNode: focusNode,
                    hint: dropdownWidget.hint,
                    disabledHint: dropdownWidget.disabledHint,
                    onChanged: widget.enabled
                        ? (newValue) {
                            if (newValue != null) {
                              didChange(newValue);
                              if (dropdownWidget.textInputAction == TextInputAction.next) {
                                controller.focusNextField(widget.fieldId);
                              }
                              dropdownWidget.onSubmitted?.call(newValue);
                            }
                          }
                        : null,
                    isExpanded: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
