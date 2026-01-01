import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
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

  final BetterFormFieldID<num> fieldId;
  final InputDecoration? decoration;
  final num? min;
  final num? max;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  ConsumerState<RiverpodNumberFormField> createState() =>
      _RiverpodNumberFormFieldState();
}

class _RiverpodNumberFormFieldState
    extends ConsumerState<RiverpodNumberFormField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerProvider =
        widget.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const BetterFormParameter(initialValue: {}));

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final controller = ref.read(controllerProvider.notifier);
          final value = ref.watch(fieldValueProvider(widget.fieldId));
          final validation = ref.watch(fieldValidationProvider(widget.fieldId));
          final isDirty = ref.watch(fieldDirtyProvider(widget.fieldId));

          // Update controller text when value changes externally
          final displayValue = value?.toString() ?? '0';
          if (_textController.text != displayValue) {
            _textController.text = displayValue;
          }

          return TextFormField(
            controller: _textController,
            keyboardType: TextInputType.number,
            decoration: (widget.decoration ?? const InputDecoration()).copyWith(
              errorText: validation.isValid ? null : validation.errorMessage,
              suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
            ),
            onChanged: (text) {
              final number = num.tryParse(text);
              if (number != null) {
                // Validate range if specified
                if ((widget.min != null && number < widget.min!) ||
                    (widget.max != null && number > widget.max!)) {
                  // Invalid range - revert to current value
                  _textController.text = value?.toString() ?? '0';
                  return;
                }
                controller.setValue(widget.fieldId, number);
              } else if (text.isEmpty) {
                // Allow empty input, but don't update value yet
                return;
              } else {
                // Invalid number - revert to current value
                _textController.text = value?.toString() ?? '0';
              }
            },
          );
        },
      ),
    );
  }
}
