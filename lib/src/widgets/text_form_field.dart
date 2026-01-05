import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'formix.dart';
import 'form_group.dart';
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
    this.focusNode,
  });

  final FormixFieldID<String> fieldId;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLength;
  final AutoDisposeStateNotifierProvider<FormixController, FormixData>?
  controllerProvider;
  final FocusNode? focusNode;

  @override
  ConsumerState<RiverpodTextFormField> createState() =>
      _RiverpodTextFormFieldState();
}

class _RiverpodTextFormFieldState extends ConsumerState<RiverpodTextFormField> {
  late final TextEditingController _textController;
  FocusNode? _internalFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
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

    controller.registerFocusNode(resolvedId, _focusNode);
    controller.registerContext(resolvedId, context);
  }

  @override
  void dispose() {
    _textController.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
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

          return Focus(
            onFocusChange: (focused) {
              if (!focused) {
                controller.markAsTouched(resolvedId);
              }
            },
            child: TextFormField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              decoration: (widget.decoration ?? const InputDecoration())
                  .copyWith(
                    errorText: validation.isValid
                        ? null
                        : validation.errorMessage,
                    suffixIcon: suffixIcon,
                  ),
              onChanged: (newValue) =>
                  controller.setValue(resolvedId, newValue),
            ),
          );
        },
      ),
    );
  }
}
