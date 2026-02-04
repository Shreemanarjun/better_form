import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based number form field that is lifecycle aware.
class FormixNumberFormField<T extends num> extends FormixFieldWidget<T> {
  /// Creates a [FormixNumberFormField].
  const FormixNumberFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    super.focusNode,
    this.decoration = const InputDecoration(),
    super.enabled = true,
    this.loadingIcon,
    this.min,
    this.max,
    this.style,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLength,
    super.onChanged,
    super.onSaved,
    super.onReset,
    super.forceErrorText,
    super.errorBuilder,
    super.autovalidateMode,
    super.restorationId,
    this.onEditingComplete,
    this.onTap,
    this.onTapOutside,
    this.inputFormatters,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.buildCounter,
    this.scrollPhysics,
    this.autofillHints,
    this.scrollController,
    this.cursorColor,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorWidth = 2.0,
    this.keyboardAppearance,
    this.textAlignVertical,
    this.textDirection,
    this.maxLengthEnforcement,
  });

  /// The decoration to show around the text field.
  final InputDecoration decoration;

  /// Optional widget to display while validating.
  final Widget? loadingIcon;

  /// Minimum value allowed.
  final T? min;

  /// Maximum value allowed.
  final T? max;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// Alignment of the text.
  final TextAlign textAlign;

  /// The type of action button to use for the keyboard.
  final TextInputAction? textInputAction;

  /// Callback when the user finishes editing.
  final void Function(T?)? onFieldSubmitted;

  /// Whether to autofocus this field.
  final bool autofocus;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Whether to show the cursor.
  final bool? showCursor;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Whether to show suggestions.
  final bool enableSuggestions;

  /// The maximum number of characters allowed.
  final int? maxLength;

  /// Callback when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Callback when the field is tapped.
  final GestureTapCallback? onTap;

  /// Callback when the user taps outside.
  final TapRegionCallback? onTapOutside;

  /// Optional input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Padding around the text field when scrolling into view.
  final EdgeInsets scrollPadding;

  /// Whether to enable interactive selection.
  final bool enableInteractiveSelection;

  /// Custom selection controls.
  final TextSelectionControls? selectionControls;

  /// Custom builder for the counter.
  final InputCounterWidgetBuilder? buildCounter;

  /// Physics for the scrollable.
  final ScrollPhysics? scrollPhysics;

  /// Autofill hints for the text field.
  final Iterable<String>? autofillHints;

  /// Optional scroll controller.
  final ScrollController? scrollController;

  /// The color of the cursor.
  final Color? cursorColor;

  /// The height of the cursor.
  final double? cursorHeight;

  /// The radius of the cursor corners.
  final Radius? cursorRadius;

  /// The width of the cursor.
  final double cursorWidth;

  /// The appearance of the keyboard.
  final Brightness? keyboardAppearance;

  /// Vertical alignment of the text.
  final TextAlignVertical? textAlignVertical;

  /// Directionality of the text.
  final TextDirection? textDirection;

  /// Strategy for enforcing the maximum length.
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  FormixNumberFormFieldState<T> createState() => FormixNumberFormFieldState<T>();
}

/// State for [FormixNumberFormField].
class FormixNumberFormFieldState<T extends num> extends FormixFieldWidgetState<T> with FormixFieldTextMixin<T> {
  @override
  String valueToString(T? value) {
    if (value == null) return '';
    // Avoid trailing .0 for integers stored in double/num fields
    if (value is double && value == value.toInt().toDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  T? stringToValue(String text) {
    if (text.isEmpty) return null;
    final d = double.tryParse(text);
    if (d == null) return null;

    final T? parsed;
    if (T == int) {
      parsed = d.toInt() as T?;
    } else {
      parsed = d as T?;
    }

    if (parsed != null) {
      final fieldWidget = widget as FormixNumberFormField<T>;
      if (fieldWidget.min != null && parsed < fieldWidget.min!) {
        return null; // Enforce minimum constraint by rejecting input
      }
      if (fieldWidget.max != null && parsed > fieldWidget.max!) {
        return null; // Enforce maximum constraint by rejecting input
      }
    }

    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final fieldWidget = widget as FormixNumberFormField<T>;

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

        return MergeSemantics(
          child: Semantics(
            validationResult: validation.isValid ? SemanticsValidationResult.valid : SemanticsValidationResult.invalid,
            child: TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: fieldWidget.decoration.copyWith(
                errorText: shouldShowError ? validation.errorMessage : null,
                suffixIcon: suffixIcon,
                helperText: validation.isValidating ? 'Validating...' : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              style: fieldWidget.style,
              textAlign: fieldWidget.textAlign,
              textInputAction: fieldWidget.textInputAction,
              onFieldSubmitted: (val) {
                fieldWidget.onFieldSubmitted?.call(stringToValue(val));
              },
              autofocus: fieldWidget.autofocus,
              readOnly: fieldWidget.readOnly,
              showCursor: fieldWidget.showCursor,
              obscureText: fieldWidget.obscureText,
              autocorrect: fieldWidget.autocorrect,
              enableSuggestions: fieldWidget.enableSuggestions,
              maxLength: fieldWidget.maxLength,
              onChanged: (val) {
                final parsed = stringToValue(val);
                if (parsed != null) {
                  didChange(parsed);
                }
              },
              onEditingComplete: fieldWidget.onEditingComplete,
              onTap: fieldWidget.onTap,
              onTapOutside: fieldWidget.onTapOutside,
              inputFormatters: [
                ...?controller.getField(widget.fieldId)?.inputFormatters,
                ...?fieldWidget.inputFormatters,
              ],
              scrollPadding: fieldWidget.scrollPadding,
              enableInteractiveSelection: fieldWidget.enableInteractiveSelection,
              selectionControls: fieldWidget.selectionControls,
              buildCounter: fieldWidget.buildCounter,
              scrollPhysics: fieldWidget.scrollPhysics,
              autofillHints: fieldWidget.autofillHints,
              scrollController: fieldWidget.scrollController,
              cursorColor: fieldWidget.cursorColor,
              cursorHeight: fieldWidget.cursorHeight,
              cursorRadius: fieldWidget.cursorRadius,
              cursorWidth: fieldWidget.cursorWidth,
              keyboardAppearance: fieldWidget.keyboardAppearance,
              textAlignVertical: fieldWidget.textAlignVertical,
              textDirection: fieldWidget.textDirection,
              maxLengthEnforcement: fieldWidget.maxLengthEnforcement,
              enabled: fieldWidget.enabled,
            ),
          ),
        );
      },
    );
  }
}
