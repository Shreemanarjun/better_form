import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/field_id.dart';
import '../controllers/formix_controller.dart';
import '../enums.dart';
import 'text_form_field.dart';
import 'cupertino_text_form_field.dart';

/// A text form field that automatically switches between Material and Cupertino
/// styling based on the current platform.
///
/// On iOS and macOS, it uses [FormixCupertinoTextFormField].
/// On other platforms, it uses [FormixTextFormField].
class FormixAdaptiveTextFormField extends StatelessWidget {
  /// Creates a [FormixAdaptiveTextFormField].
  const FormixAdaptiveTextFormField({
    super.key,
    required this.fieldId,
    this.controller,
    this.validator,
    this.initialValue,
    this.focusNode,
    this.onChanged,
    this.decoration = const InputDecoration(),
    this.placeholder,
    this.prefix,
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
    this.enabled = true,
    this.onSaved,
    this.onReset,
    this.forceErrorText,
    this.errorBuilder,
    this.autovalidateMode,
    this.restorationId,
  });

  /// The unique identifier for this field.
  final FormixFieldID<String> fieldId;

  /// Optional explicit controller.
  final FormixController? controller;

  /// Synchronous validator for this field.
  final String? Function(String? value)? validator;

  /// Initial value for this field.
  final String? initialValue;

  /// Optional explicit focus node.
  final FocusNode? focusNode;

  /// Callback when the value changes.
  final ValueChanged<String?>? onChanged;

  /// Material-specific decoration.
  final InputDecoration decoration;

  /// Cupertino-specific placeholder.
  final String? placeholder;

  /// Cupertino-specific prefix.
  final Widget? prefix;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Max length.
  final int? maxLength;

  /// Input formatters (Material only).
  final List<TextInputFormatter>? inputFormatters;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Callback when submitted (Material only).
  final void Function(String)? onFieldSubmitted;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Max lines.
  final int? maxLines;

  /// Min lines.
  final int? minLines;

  /// Whether to expand.
  final bool expands;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// The style to use for the text being edited.
  final TextStyle? style;

  /// Widget to show while validating.
  final Widget? loadingIcon;

  /// Whether the field is interactive.
  final bool enabled;

  /// Called when the form is saved.
  final ValueChanged<String?>? onSaved;

  /// Called when the field is reset.
  final VoidCallback? onReset;

  /// Manual error text to display, overriding validation.
  final String? forceErrorText;

  /// Custom builder for error display.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Autovalidate mode for this field, overrides the form's mode.
  final FormixAutovalidateMode? autovalidateMode;

  /// Restoration ID for state restoration.
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

    if (isApple) {
      return FormixCupertinoTextFormField(
        fieldId: fieldId,
        controller: controller,
        validator: validator,
        initialValue: initialValue,
        focusNode: focusNode,
        onChanged: onChanged,
        placeholder: placeholder ?? (decoration.labelText ?? decoration.hintText),
        prefix: prefix ?? (decoration.icon ?? decoration.prefixIcon),
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        readOnly: readOnly,
        maxLines: maxLines,
        minLines: minLines,
        expands: expands,
        obscureText: obscureText,
        style: style,
        loadingIcon: loadingIcon,
        enabled: enabled,
        onSaved: onSaved,
        onReset: onReset,
        forceErrorText: forceErrorText,
        errorBuilder: errorBuilder,
        autovalidateMode: autovalidateMode,
        restorationId: restorationId,
      );
    }

    return FormixTextFormField(
      fieldId: fieldId,
      controller: controller,
      validator: validator,
      initialValue: initialValue,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? placeholder,
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      obscureText: obscureText,
      style: style,
      loadingIcon: loadingIcon,
      enabled: enabled,
      onSaved: onSaved,
      onReset: onReset,
      forceErrorText: forceErrorText,
      errorBuilder: errorBuilder,
      autovalidateMode: autovalidateMode,
      restorationId: restorationId,
    );
  }
}
