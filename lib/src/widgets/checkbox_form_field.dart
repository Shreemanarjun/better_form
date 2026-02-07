import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based checkbox form field that is lifecycle aware.
class FormixCheckboxFormField extends FormixFieldWidget<bool> {
  /// Creates a [FormixCheckboxFormField].
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
    super.initialValueStrategy,
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
    this.mouseCursor,
  });

  /// The primary content of the list tile.
  final Widget? title;

  /// Optional widget to display while validating.
  final Widget? validatingWidget;

  /// The color to use when this checkbox is checked.
  final Color? activeColor;

  /// The color to use for the check icon itself.
  final Color? checkColor;

  /// The color of the tile.
  final Color? tileColor;

  /// A widget to display on the opposite side of the checkbox.
  final Widget? secondary;

  /// Whether the subtitle should be three lines high.
  final bool isThreeLine;

  /// Whether this list tile is part of a dense layout.
  final bool? dense;

  /// Whether to render the tile as selected.
  final bool selected;

  /// Where to place the control relative to the text.
  final ListTileControlAffinity controlAffinity;

  /// Whether this widget should attempt to focus itself.
  final bool autofocus;

  /// The padding around the tile's content.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the checkbox can be into a third "indeterminate" state.
  final bool tristate;

  /// The shape of the tile's ink well.
  final ShapeBorder? shape;

  /// The shape of the checkbox's background.
  final OutlinedBorder? checkboxShape;

  /// The color and width of the checkbox's border.
  final BorderSide? side;

  /// The density of the tile's layout.
  final VisualDensity? visualDensity;

  /// The mouse cursor to use.
  final MouseCursor? mouseCursor;

  @override
  FormixCheckboxFormFieldState createState() => FormixCheckboxFormFieldState();
}

/// State for [FormixCheckboxFormField].
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

        final shouldShowError = (isTouched || isSubmitting || showImmediate) && !validation.isValid;

        return MergeSemantics(
          child: Semantics(
            validationResult: validation.isValid ? SemanticsValidationResult.valid : SemanticsValidationResult.invalid,
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
              mouseCursor: checkboxWidget.mouseCursor,
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
