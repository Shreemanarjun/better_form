import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'formix.dart';
import 'form_group.dart';
import 'riverpod_form_fields.dart';

/// Riverpod-based number form field
class RiverpodNumberFormField extends ConsumerStatefulWidget {
  const RiverpodNumberFormField({
    super.key,
    required this.fieldId,
    this.decoration,
    this.min,
    this.max,
    this.controllerProvider,
  });

  final FormixFieldID<num> fieldId;
  final InputDecoration? decoration;
  final num? min;
  final num? max;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormixState>?
  controllerProvider;

  @override
  ConsumerState<RiverpodNumberFormField> createState() =>
      _RiverpodNumberFormFieldState();
}

class _RiverpodNumberFormFieldState
    extends ConsumerState<RiverpodNumberFormField> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider =
        widget.controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    final controller = ref.read(provider.notifier);
    final resolvedId = FormixGroup.resolve(context, widget.fieldId);

    if (controller is FormixController) {
      controller.registerFocusNode(resolvedId, _focusNode);
      controller.registerContext(resolvedId, context);
    }
  }

  void _onFocusChange() {
    if (mounted) {
      if (!_focusNode.hasFocus) {
        final provider =
            widget.controllerProvider ??
            Formix.of(context) ??
            formControllerProvider(const FormixParameter(initialValue: {}));
        final resolvedId = FormixGroup.resolve(context, widget.fieldId);
        ref.read(provider.notifier).markAsTouched(resolvedId);
      }
      setState(() {});
    }
  }

  /// Ensure the parsed number matches the expected type based on the current value
  num _ensureCorrectType(num parsedNumber, num? currentValue) {
    if (currentValue == null) {
      // If no current value, check the field type from the initial value
      // For now, default to double for decimal support
      return parsedNumber.toDouble();
    }

    // Match the type of the current value
    if (currentValue is int) {
      return parsedNumber.toInt();
    } else if (currentValue is double) {
      return parsedNumber.toDouble();
    } else {
      // Default to double for maximum compatibility
      return parsedNumber.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerProvider =
        widget.controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    final resolvedId = FormixGroup.resolve(context, widget.fieldId);

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final controller = ref.read(controllerProvider.notifier);
          final value = ref.watch(fieldValueProvider(resolvedId));
          final validation = ref.watch(fieldValidationProvider(resolvedId));
          final isDirty = ref.watch(fieldDirtyProvider(resolvedId));

          // Sync text if not focused to handle initial value and external updates
          if (!_focusNode.hasFocus) {
            final displayValue = value?.toString() ?? '';
            // Only update if different to avoid cursor/selection issues (though less relevant when not focused)
            if (_textController.text != displayValue) {
              _textController.text = displayValue;
            }
          }

          Widget? suffixIcon;
          if (validation.isValidating) {
            suffixIcon = const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (isDirty) {
            suffixIcon = const Icon(Icons.edit, size: 16);
          }

          return TextFormField(
            controller: _textController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            decoration: (widget.decoration ?? const InputDecoration()).copyWith(
              errorText: validation.isValid ? null : validation.errorMessage,
              suffixIcon: suffixIcon,
            ),
            onChanged: (text) {
              // Allow empty text - set to 0 or current value
              if (text.isEmpty) {
                final defaultValue = value ?? 0.0;
                final typedDefault = _ensureCorrectType(defaultValue, value);
                controller.setValue(resolvedId, typedDefault);
                return;
              }

              // Try to parse the number
              final number = num.tryParse(text);
              if (number != null) {
                // Validate range if specified
                if ((widget.min != null && number < widget.min!) ||
                    (widget.max != null && number > widget.max!)) {
                  // Invalid range - don't update the value, but keep the text as-is
                  // The validation error will still show
                  return;
                }

                // Ensure the number type matches the field type
                final typedNumber = _ensureCorrectType(number, value);
                controller.setValue(resolvedId, typedNumber);
              } else {
                // For invalid input (like partial decimals), don't update the value
                // but allow the text to remain. This prevents cursor jumping.
                // The field will show validation errors when appropriate.
              }
            },
          );
        },
      ),
    );
  }
}
