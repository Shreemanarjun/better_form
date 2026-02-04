import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based checkbox form field that is lifecycle aware.
class FormixCheckboxFormField extends FormixFieldWidget<bool> {
  const FormixCheckboxFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    super.focusNode,
    this.title,
    this.validatingWidget,
    super.enabled = true,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
    this.activeColor,
    this.checkColor,
    this.tileColor,
    this.secondary,
    this.isThreeLine = false,
    this.dense,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
    this.autofocus = false,
    this.contentPadding,
    this.tristate = false,
    this.shape,
    this.checkboxShape,
    this.side,
    super.onChanged,
    this.visualDensity,
  });

  final Widget? title;
  final Widget? validatingWidget;
  final Color? activeColor;
  final Color? checkColor;
  final Color? tileColor;
  final Widget? secondary;
  final bool isThreeLine;
  final bool? dense;
  final bool selected;
  final ListTileControlAffinity controlAffinity;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final bool tristate;
  final ShapeBorder? shape;
  final OutlinedBorder? checkboxShape;
  final BorderSide? side;
  final VisualDensity? visualDensity;

  @override
  FormixCheckboxFormFieldState createState() => FormixCheckboxFormFieldState();
}

class FormixCheckboxFormFieldState extends FormixFieldWidgetState<bool> {
  @override
  Widget build(BuildContext context) {
    final checkboxWidget = widget as FormixCheckboxFormField;

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
        final validationMode = controller.getValidationMode(widget.fieldId);

        final showImmediate = validationMode == FormixAutovalidateMode.always;

        final shouldShowError =
            (isTouched || isSubmitting || showImmediate) && !validation.isValid;

        return MergeSemantics(
          child: Semantics(
            validationResult: validation.isValid
                ? SemanticsValidationResult.valid
                : SemanticsValidationResult.invalid,
            child: CheckboxListTile(
              value: value ?? false,
              title: checkboxWidget.title,
              enabled: checkboxWidget.enabled,
              focusNode: focusNode,
              activeColor: checkboxWidget.activeColor,
              checkColor: checkboxWidget.checkColor,
              tileColor: checkboxWidget.tileColor,
              secondary: checkboxWidget.secondary,
              isThreeLine: checkboxWidget.isThreeLine,
              dense: checkboxWidget.dense,
              selected: checkboxWidget.selected,
              controlAffinity: checkboxWidget.controlAffinity,
              autofocus: checkboxWidget.autofocus,
              contentPadding: checkboxWidget.contentPadding,
              tristate: checkboxWidget.tristate,
              shape: checkboxWidget.shape,
              checkboxShape: checkboxWidget.checkboxShape,
              side: checkboxWidget.side,
              visualDensity: checkboxWidget.visualDensity,
              subtitle: validation.isValidating
                  ? (checkboxWidget.validatingWidget ??
                        const Text(
                          'Validating...',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ))
                  : (shouldShowError
                        ? Text(
                            validation.errorMessage ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          )
                        : (isDirty
                              ? const Text(
                                  'Modified',
                                  style: TextStyle(fontSize: 12),
                                )
                              : null)),
              onChanged: checkboxWidget.enabled
                  ? (newValue) {
                      didChange(newValue ?? false);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}
