import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'base_form_field.dart';
import '../enums.dart';

/// A Formix-based number form field that is lifecycle aware.
class FormixNumberFormField<T extends num> extends FormixFieldWidget<T> {
  const FormixNumberFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    super.focusNode,
    this.decoration = const InputDecoration(),
    this.enabled = true,
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
    this.onChanged,
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

  final InputDecoration decoration;
  final bool enabled;
  final Widget? loadingIcon;
  final T? min;
  final T? max;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final void Function(T?)? onFieldSubmitted;
  final bool autofocus;
  final bool readOnly;
  final bool? showCursor;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLength;
  final ValueChanged<T?>? onChanged;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final ScrollController? scrollController;
  final Color? cursorColor;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final double cursorWidth;
  final Brightness? keyboardAppearance;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final MaxLengthEnforcement? maxLengthEnforcement;

  @override
  FormixNumberFormFieldState<T> createState() =>
      FormixNumberFormFieldState<T>();
}

class FormixNumberFormFieldState<T extends num>
    extends FormixFieldWidgetState<T>
    with FormixFieldTextMixin<T> {
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
        final validation = controller.getValidation(widget.fieldId);
        final isTouched = controller.isFieldTouched(widget.fieldId);
        final isDirty = controller.isFieldDirty(widget.fieldId);
        final isSubmitting = controller.isSubmitting;
        final validationMode = controller.getValidationMode(widget.fieldId);

        final showImmediate = validationMode == FormixAutovalidateMode.always;

        final shouldShowError =
            (isTouched || isSubmitting || showImmediate) && !validation.isValid;

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

        return TextFormField(
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
            fieldWidget.onChanged?.call(stringToValue(val));
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
        );
      },
    );
  }
}
