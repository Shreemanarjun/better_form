import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/riverpod_controller.dart';
import '../controllers/field.dart';
import '../controllers/field_id.dart';
import '../controllers/validation.dart';
import '../enums.dart';

/// Base class for custom form field widgets that automatically handle controller
/// registration and value synchronization.
///
/// Most built-in fields like [FormixTextFormField] extend this.
abstract class FormixFieldWidget<T> extends ConsumerStatefulWidget {
  const FormixFieldWidget({
    super.key,
    required this.fieldId,
    this.controller,
    this.validator,
    this.asyncValidator,
    this.initialValue,
    this.focusNode,
    this.onChanged,
    this.onSaved,
    this.onReset,
    this.forceErrorText,
    this.errorBuilder,
    this.enabled = true,
    this.autovalidateMode,
    this.restorationId,
  });

  /// The unique identifier for this field in the [Formix] tree.
  final FormixFieldID<T> fieldId;

  /// Optional explicit controller. If not provided, it will be looked up
  /// from the nearest [Formix] ancestor.
  final FormixController? controller;

  /// Synchronous validator for this field.
  final String? Function(T? value)? validator;

  /// Asynchronous validator for this field.
  final Future<String?> Function(T? value)? asyncValidator;

  /// Initial value for this field.
  final T? initialValue;

  /// Optional explicit focus node.
  final FocusNode? focusNode;

  /// Callback triggered whenever the field value changes within this widget.
  final ValueChanged<T?>? onChanged;

  /// Called when the form is saved.
  final ValueChanged<T?>? onSaved;

  /// Called when the field is reset.
  final VoidCallback? onReset;

  /// Manual error text to display, overriding validation.
  final String? forceErrorText;

  /// Custom builder for error display.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Whether the field is interactive.
  final bool enabled;

  /// Autovalidate mode for this field, overrides the form's mode.
  final FormixAutovalidateMode? autovalidateMode;

  /// Restoration ID for state restoration.
  final String? restorationId;

  @override
  FormixFieldWidgetState<T> createState();
}

/// State class that provides simplified APIs for form field management
abstract class FormixFieldWidgetState<T>
    extends ConsumerState<FormixFieldWidget<T>> {
  FormixController? _controller;
  FormixFieldID<T>? _currentAttachedFieldId;
  T? _currentValue;
  late FocusNode _focusNode;
  bool _isMounted = false;
  bool _createdOwnFocusNode = false;
  ProviderSubscription? _controllerSub;
  bool _wasDirty = false;

  /// The current value of this field from the controller.
  T? get value => _currentValue;

  /// The [FocusNode] managing the focus for this field.
  FocusNode get focusNode => _focusNode;

  /// The [FormixController] managing this field.
  /// Throws an error if accessed before initialization.
  FormixController get controller => _controller!;

  /// Whether the controller has been initialized.
  bool get hasController => _controller != null;

  /// Whether the field has been modified by the user.
  bool get isDirty => controller.isFieldDirty(widget.fieldId);

  /// Whether the field has been interacted with (focused and then blurred).
  bool get isTouched => controller.isFieldTouched(widget.fieldId);

  /// Whether the field is enabled.
  bool get enabled => widget.enabled;

  /// Whether the form is currently submitting.
  bool get isSubmitting => controller.isSubmitting;

  /// Wraps the child with accessibility semantics.
  Widget wrapSemantics(Widget child) {
    return Semantics(
      validationResult: validation.isValid
          ? SemanticsValidationResult.valid
          : SemanticsValidationResult.invalid,
      child: child,
    );
  }

  /// The current validation result for this field.
  ValidationResult get validation {
    if (widget.forceErrorText != null) {
      return ValidationResult(
        isValid: false,
        errorMessage: widget.forceErrorText,
      );
    }
    return controller.getValidation(widget.fieldId);
  }

  /// Check if widget is mounted (safe to call setState)
  @override
  bool get mounted => _isMounted;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initFocusNode();
    _setupControllerSubscription();
  }

  void _setupControllerSubscription() {
    _controllerSub?.close();
    _controllerSub = ref.listenManual(currentControllerProvider, (
      previous,
      next,
    ) {
      final newController = widget.controller ?? ref.read(next.notifier);
      _setupController(newController);
    }, fireImmediately: true);
  }

  void _initFocusNode() {
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _createdOwnFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _createdOwnFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _setupController(FormixController? newController) {
    if (newController == null) return;

    final controllerChanged = _controller != newController;
    final fieldChanged = _currentAttachedFieldId != widget.fieldId;

    if (!controllerChanged && !fieldChanged) return;

    if (_controller != null && _currentAttachedFieldId != null) {
      _controller!.removeFieldListener(
        _currentAttachedFieldId!,
        _onFieldChanged,
      );
    }

    _controller = newController;
    _currentAttachedFieldId = widget.fieldId;

    _ensureFieldRegistered();

    _controller!.registerFocusNode(widget.fieldId, _focusNode);
    _controller!.registerContext(widget.fieldId, context);

    _currentValue =
        _controller!.getValue(widget.fieldId) ?? widget.initialValue;
    _controller!.addFieldListener(widget.fieldId, _onFieldChanged);

    if (_isMounted) {
      _wasDirty = _controller!.isFieldDirty(widget.fieldId);
      onFieldChanged(_currentValue);
    }
  }

  void _ensureFieldRegistered() {
    if (_controller == null) return;

    final existingField = controller.getField(widget.fieldId);

    // If already registered, we should merge widget-provided properties.
    // We avoid overwriting existing properties if the widget doesn't provide them.
    if (existingField == null ||
        widget.validator != null ||
        widget.asyncValidator != null ||
        (widget.autovalidateMode != null &&
            widget.autovalidateMode != existingField.validationMode)) {
      T? initialValue = widget.initialValue;
      initialValue ??=
          existingField?.initialValue ??
          controller.initialValue[widget.fieldId.key] as T?;

      controller.registerField(
        FormixField<T>(
          id: widget.fieldId,
          initialValue: initialValue,
          validator:
              widget.validator ??
              (existingField?.validator as String? Function(T?)?),
          asyncValidator:
              widget.asyncValidator ??
              (existingField?.asyncValidator as Future<String?> Function(T?)?),
          validationMode:
              widget.autovalidateMode ??
              existingField?.validationMode ??
              FormixAutovalidateMode.auto,
          // Preserve other properties from config if they exist
          label: existingField?.label,
          hint: existingField?.hint,
          dependsOn: existingField?.dependsOn ?? const [],
          crossFieldValidator:
              existingField?.crossFieldValidator
                  as String? Function(T?, FormixData)?,
          transformer: existingField?.transformer as T Function(dynamic)?,
          inputFormatters: existingField?.inputFormatters,
          textInputAction: existingField?.textInputAction,
          onSubmitted: existingField?.onSubmitted,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(FormixFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_createdOwnFocusNode) {
        _focusNode.dispose();
      }
      _initFocusNode();
      if (_controller != null) {
        controller.registerFocusNode(widget.fieldId, _focusNode);
      }
    }

    if (widget.controller != oldWidget.controller ||
        widget.fieldId != oldWidget.fieldId) {
      _setupControllerSubscription();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _controllerSub?.close();
    _controller?.removeFieldListener(widget.fieldId, _onFieldChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_createdOwnFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() {
    if (_controller == null) return;

    final newValue = controller.getValue(widget.fieldId);
    final isDirtyNow = controller.isFieldDirty(widget.fieldId);

    if (_wasDirty && !isDirtyNow) {
      onReset();
      widget.onReset?.call();
    }
    _wasDirty = isDirtyNow;

    setState(() {
      _currentValue = newValue;
    });
    if (controller.isFieldRegistered(widget.fieldId)) {
      onFieldChanged(newValue);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _controller != null) {
      controller.markAsTouched(widget.fieldId);
    }
  }

  /// Called when the field value changes externally
  /// Override this to react to external value changes
  void onFieldChanged(T? value) {}

  /// Called when the field is reset to its initial state
  void onReset() {}

  /// Update the field value and notify the form
  /// This is the primary way to update field values
  void didChange(T? value) {
    if (_controller == null) return;
    controller.setValue(widget.fieldId, value);
    controller.markAsTouched(widget.fieldId);
    widget.onChanged?.call(value);
  }

  /// Alias for didChange - update the field value
  void setField(T? value) => didChange(value);

  /// Patch multiple field values at once
  /// Useful for complex form fields that control multiple values
  void patchValue(Map<FormixFieldID<dynamic>, dynamic> updates) {
    if (_controller == null) return;
    for (final entry in updates.entries) {
      controller.setValue(entry.key, entry.value);
    }
  }

  /// Reset this field to its initial value
  void resetField() {
    if (_controller != null) {
      controller.reset();
    }
  }

  /// Mark field as touched (for validation purposes)
  void markAsTouched() {
    if (_controller != null) {
      controller.markAsTouched(widget.fieldId);
    }
  }

  /// Call the onSaved callback with the current value.
  void save() {
    widget.onSaved?.call(value);
  }

  /// Focus the field (if it has focus capability)
  void focus() {
    _focusNode.requestFocus();
  }

  /// Build the widget - override this to provide your UI
  @override
  Widget build(BuildContext context);
}

/// Mixin for form fields that need text input capabilities
mixin FormixFieldTextMixin<T> on FormixFieldWidgetState<T> {
  TextEditingController? _textController;
  bool _isSyncing = false;

  TextEditingController get textController => _textController!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_textController == null) {
      _textController = TextEditingController(
        text: _currentValue != null ? valueToString(_currentValue as T) : '',
      );
      _textController!.addListener(_onTextChanged);
    } else {
      _syncText();
    }
  }

  @override
  void didUpdateWidget(FormixFieldWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncText();
  }

  @override
  void onFieldChanged(T? value) {
    super.onFieldChanged(value);
    _syncText();
  }

  void _syncText() {
    if (_textController == null) return;
    final newText = _currentValue != null
        ? valueToString(_currentValue as T)
        : '';
    if (_textController!.text != newText) {
      _isSyncing = true;
      try {
        _textController!.text = newText;
      } finally {
        _isSyncing = false;
      }
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_textController == null || _isSyncing) return;
    final newValue = stringToValue(_textController!.text);
    if (newValue != null && newValue != _currentValue) {
      didChange(newValue);
    }
  }

  /// Convert value to string for text controller
  String valueToString(T? value);

  /// Convert string back to value
  T? stringToValue(String text);
}

/// Simplified text form field base class
abstract class FormixTextFormFieldWidget extends FormixFieldWidget<String> {
  const FormixTextFormFieldWidget({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    super.enabled,
  });

  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool obscureText;

  @override
  FormixTextFormFieldWidgetState createState();
}

abstract class FormixTextFormFieldWidgetState
    extends FormixFieldWidgetState<String>
    with FormixFieldTextMixin<String> {
  @override
  String valueToString(String? value) => value ?? '';

  @override
  String? stringToValue(String text) => text;

  @override
  Widget build(BuildContext context) {
    final fieldWidget = widget as FormixTextFormFieldWidget;

    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.fieldValidationNotifier(fieldWidget.fieldId),
        controller.fieldTouchedNotifier(fieldWidget.fieldId),
        controller.fieldDirtyNotifier(fieldWidget.fieldId),
        controller.isSubmittingNotifier,
      ]),
      builder: (context, _) {
        final validation = this.validation;
        final isTouched = this.isTouched;
        final isDirty = this.isDirty;
        final isSubmitting = controller.isSubmitting;

        final shouldShowError =
            (isTouched || isSubmitting) && !validation.isValid;

        Widget? suffixIcon;
        if (validation.isValidating) {
          suffixIcon = const SizedBox(
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
          keyboardType: fieldWidget.keyboardType,
          maxLines: fieldWidget.maxLines,
          obscureText: fieldWidget.obscureText,
          enabled: widget.enabled,
        );
      },
    );
  }
}

/// Simplified number form field base class
abstract class FormixNumberFormFieldWidget extends FormixFieldWidget<int> {
  const FormixNumberFormFieldWidget({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.decoration = const InputDecoration(),
    super.enabled,
  });

  final InputDecoration decoration;

  @override
  FormixNumberFormFieldWidgetState createState();
}

abstract class FormixNumberFormFieldWidgetState
    extends FormixFieldWidgetState<int>
    with FormixFieldTextMixin<int> {
  @override
  String valueToString(int? value) => value?.toString() ?? '';

  @override
  int? stringToValue(String text) => int.tryParse(text);

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as FormixNumberFormFieldWidget;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: controller.fieldValidationNotifier(widget.fieldId),
      builder: (context, validation, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: controller.fieldDirtyNotifier(widget.fieldId),
          builder: (context, isDirty, child) {
            final shouldShowError =
                validation.isValidating ||
                (controller.isFieldTouched(widget.fieldId) ||
                    controller.isSubmitting);

            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: widget.decoration.copyWith(
                errorText: shouldShowError && !validation.isValidating
                    ? validation.errorMessage
                    : null,
                helperText: validation.isValidating ? 'Validating...' : null,
                suffixIcon: validation.isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : isDirty
                    ? const Icon(Icons.edit, size: 16)
                    : null,
              ),
              keyboardType: TextInputType.number,
              enabled: widget.enabled,
              onChanged: (value) => didChange(int.tryParse(value) ?? 0),
            );
          },
        );
      },
    );
  }
}
