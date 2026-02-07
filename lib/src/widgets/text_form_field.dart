import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_form_field.dart';
import '../enums.dart';
import 'form_theme.dart';

/// A Formix-based text form field that is lifecycle aware.
class FormixTextFormField extends FormixFieldWidget<String> {
  /// Creates a [FormixTextFormField].
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
    super.initialValueStrategy,
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
    this.mouseCursor,
  });

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// The maximum number of characters to allow in the text field.
  final int? maxLength;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Callback when the user finishes editing.
  final void Function(String)? onFieldSubmitted;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// The maximum number of lines for the text field.
  final int? maxLines;

  /// The minimum number of lines for the text field.
  final int? minLines;

  /// Whether the text field should expand to fill its parent.
  final bool expands;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// Widget to show while validating.
  final Widget? loadingIcon;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Autofill hints for the text field.
  final Iterable<String>? autofillHints;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Custom builder for the counter.
  final InputCounterWidgetBuilder? buildCounter;

  /// The color of the cursor.
  final Color? cursorColor;

  /// The height of the cursor.
  final double? cursorHeight;

  /// The radius of the cursor corners.
  final Radius? cursorRadius;

  /// The width of the cursor.
  final double cursorWidth;

  /// Whether to enable interactive selection.
  final bool enableInteractiveSelection;

  /// Whether to show suggestions.
  final bool enableSuggestions;

  /// The appearance of the keyboard.
  final Brightness? keyboardAppearance;

  /// Strategy for enforcing the maximum length.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Callback when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Callback when the field is tapped.
  final GestureTapCallback? onTap;

  /// Callback when the user taps outside.
  final TapRegionCallback? onTapOutside;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// Padding around the text field when scrolling into view.
  final EdgeInsets scrollPadding;

  /// Physics for the scrollable.
  final ScrollPhysics? scrollPhysics;

  /// Custom selection controls.
  final TextSelectionControls? selectionControls;

  /// Whether to show the cursor.
  final bool? showCursor;

  /// Type of smart dashes to use.
  final SmartDashesType? smartDashesType;

  /// Type of smart quotes to use.
  final SmartQuotesType? smartQuotesType;

  /// Strut style for the text.
  final StrutStyle? strutStyle;

  /// Alignment of the text.
  final TextAlign textAlign;

  /// Vertical alignment of the text.
  final TextAlignVertical? textAlignVertical;

  /// Capitalization strategy for the text.
  final TextCapitalization textCapitalization;

  /// Directionality of the text.
  final TextDirection? textDirection;

  /// The mouse cursor to use.
  final MouseCursor? mouseCursor;

  @override
  FormixTextFormFieldState createState() => FormixTextFormFieldState();
}

/// State for [FormixTextFormField].
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

        final formTheme = FormixTheme.of(context);

        Widget? suffixIcon;
        if (validation.isValidating) {
          suffixIcon =
              fieldWidget.loadingIcon ??
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

        final formatters = [
          ...?controller.getField(widget.fieldId)?.inputFormatters,
          ...?fieldWidget.inputFormatters,
        ];

        final baseDecoration = formTheme.enabled
            ? fieldWidget.decoration.applyDefaults(
                formTheme.decorationTheme ?? Theme.of(context).inputDecorationTheme,
              )
            : fieldWidget.decoration;

        final effectiveDecoration = baseDecoration.copyWith(
          errorText: shouldShowError ? validation.errorMessage : null,
          suffixIcon: suffixIcon,
          helperText: validation.isValidating ? 'Validating...' : null,
        );

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: effectiveDecoration,
          mouseCursor: fieldWidget.mouseCursor ?? (fieldWidget.readOnly ? SystemMouseCursors.basic : null),
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
