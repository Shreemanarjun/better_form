import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based dropdown form field that is lifecycle aware.
class FormixDropdownFormField<T> extends FormixFieldWidget<T> {
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
    super.restorationId,
  });

  final List<DropdownMenuItem<T>> items;
  final InputDecoration? decoration;
  final Widget? loadingIcon;
  final Widget? hint;
  final Widget? disabledHint;

  @override
  FormixDropdownFormFieldState<T> createState() => FormixDropdownFormFieldState<T>();
}

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

        Widget? suffixIcon;
        if (validation.isValidating) {
          suffixIcon =
              dropdownWidget.loadingIcon ??
              const SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        } else if (isDirty) {
          suffixIcon = const Icon(Icons.edit, size: 16);
        }

        final validationMode = controller.getValidationMode(widget.fieldId);
        final showImmediate = validationMode == FormixAutovalidateMode.always;

        final shouldShowError = (isTouched || isSubmitting || showImmediate) && !validation.isValid;

        return MergeSemantics(
          child: Semantics(
            validationResult: validation.isValid ? SemanticsValidationResult.valid : SemanticsValidationResult.invalid,
            child: InputDecorator(
              decoration: (dropdownWidget.decoration ?? const InputDecoration()).copyWith(
                errorText: shouldShowError ? validation.errorMessage : null,
                suffixIcon: suffixIcon,
                helperText: validation.isValidating ? 'Validating...' : null,
              ),
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
                          }
                        }
                      : null,
                  isExpanded: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
