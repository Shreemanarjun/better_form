import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based text form field that is lifecycle aware.
class FormixTextFormField extends FormixFieldWidget<String> {
  const FormixTextFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    super.focusNode,
    super.onChanged,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.obscureText = false,
    this.style,
    this.loadingIcon,
    super.enabled = true,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
    this.autocorrect = true,
    this.autofillHints,
    this.autofocus = false,
    this.buildCounter,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.enableInteractiveSelection = true,
    this.enableSuggestions = true,
    this.keyboardAppearance,
    this.maxLengthEnforcement,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.scrollPhysics,
    this.selectionControls,
    this.showCursor,
    this.smartDashesType,
    this.smartQuotesType,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
  });

  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final bool obscureText;
  final TextStyle? style;
  final Widget? loadingIcon;
  final bool autocorrect;
  final Iterable<String>? autofillHints;
  final bool autofocus;
  final InputCounterWidgetBuilder? buildCounter;
  final Color? cursorColor;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final double cursorWidth;
  final bool enableInteractiveSelection;
  final bool enableSuggestions;
  final Brightness? keyboardAppearance;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final ScrollController? scrollController;
  final EdgeInsets scrollPadding;
  final ScrollPhysics? scrollPhysics;
  final TextSelectionControls? selectionControls;
  final bool? showCursor;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextCapitalization textCapitalization;
  final TextDirection? textDirection;

  @override
  FormixTextFormFieldState createState() => FormixTextFormFieldState();
}

class FormixTextFormFieldState extends FormixFieldWidgetState<String> with FormixFieldTextMixin<String> {
  @override
  String valueToString(String? value) => value ?? '';

  @override
  String? stringToValue(String text) => text;

  @override
  Widget build(BuildContext context) {
    final fieldWidget = widget as FormixTextFormField;

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

        Widget? suffixIcon;
        if (validation.isValidating) {
          suffixIcon =
              fieldWidget.loadingIcon ??
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

        final formatters = [
          ...?controller.getField(widget.fieldId)?.inputFormatters,
          ...?fieldWidget.inputFormatters,
        ];

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: fieldWidget.decoration.copyWith(
            errorText: shouldShowError ? validation.errorMessage : null,
            suffixIcon: suffixIcon,
            helperText: validation.isValidating ? 'Validating...' : null,
          ),
          keyboardType: fieldWidget.keyboardType,
          maxLength: fieldWidget.maxLength,
          inputFormatters: formatters,
          textInputAction: fieldWidget.textInputAction,
          onFieldSubmitted: (val) {
            fieldWidget.onFieldSubmitted?.call(val);
          },
          readOnly: fieldWidget.readOnly,
          maxLines: fieldWidget.maxLines,
          minLines: fieldWidget.minLines,
          expands: fieldWidget.expands,
          obscureText: fieldWidget.obscureText,
          style: fieldWidget.style,
          enabled: fieldWidget.enabled,
          autocorrect: fieldWidget.autocorrect,
          autofillHints: fieldWidget.autofillHints,
          autofocus: fieldWidget.autofocus,
          buildCounter: fieldWidget.buildCounter,
          cursorColor: fieldWidget.cursorColor,
          cursorHeight: fieldWidget.cursorHeight,
          cursorRadius: fieldWidget.cursorRadius,
          cursorWidth: fieldWidget.cursorWidth,
          enableInteractiveSelection: fieldWidget.enableInteractiveSelection,
          enableSuggestions: fieldWidget.enableSuggestions,
          keyboardAppearance: fieldWidget.keyboardAppearance,
          maxLengthEnforcement: fieldWidget.maxLengthEnforcement,
          onChanged: (val) {
            didChange(val);
          },
          onEditingComplete: fieldWidget.onEditingComplete,
          onTap: fieldWidget.onTap,
          onTapOutside: fieldWidget.onTapOutside,
          scrollController: fieldWidget.scrollController,
          scrollPadding: fieldWidget.scrollPadding,
          scrollPhysics: fieldWidget.scrollPhysics,
          selectionControls: fieldWidget.selectionControls,
          showCursor: fieldWidget.showCursor,
          smartDashesType: fieldWidget.smartDashesType,
          smartQuotesType: fieldWidget.smartQuotesType,
          strutStyle: fieldWidget.strutStyle,
          textAlign: fieldWidget.textAlign,
          textAlignVertical: fieldWidget.textAlignVertical,
          textCapitalization: fieldWidget.textCapitalization,
          textDirection: fieldWidget.textDirection,
          restorationId: fieldWidget.restorationId,
        );
      },
    );
  }
}
