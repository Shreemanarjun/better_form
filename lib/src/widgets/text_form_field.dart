import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'riverpod_form_fields.dart';

/// Riverpod-based text form field
class RiverpodTextFormField extends ConsumerStatefulWidget {
  const RiverpodTextFormField({
    super.key,
    required this.fieldId,
    this.decoration,
    this.keyboardType,
    this.maxLength,
    this.controllerProvider,
  });

  final BetterFormFieldID<String> fieldId;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLength;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  ConsumerState<RiverpodTextFormField> createState() =>
      _RiverpodTextFormFieldState();
}

class _RiverpodTextFormFieldState extends ConsumerState<RiverpodTextFormField> {
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
          if (_textController.text != (value ?? '')) {
            _textController.text = value ?? '';
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
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            decoration: (widget.decoration ?? const InputDecoration()).copyWith(
              errorText: validation.isValid ? null : validation.errorMessage,
              suffixIcon: suffixIcon,
            ),
            onChanged: (newValue) =>
                controller.setValue(widget.fieldId, newValue),
          );
        },
      ),
    );
  }
}
