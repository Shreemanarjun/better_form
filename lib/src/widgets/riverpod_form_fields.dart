export 'formix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'formix.dart';
import '../controllers/riverpod_controller.dart';
import '../controllers/field_id.dart';
import 'form_group.dart';

/// Riverpod-based checkbox form field
class RiverpodCheckboxFormField extends ConsumerWidget {
  const RiverpodCheckboxFormField({
    super.key,
    required this.fieldId,
    this.title,
    this.controllerProvider,
  });

  final FormixFieldID<bool> fieldId;
  final Widget? title;
  final AutoDisposeStateNotifierProvider<FormixController, FormixData>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    final resolvedId = FormixGroup.resolve(context, fieldId);

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

          return CheckboxListTile(
            value: value ?? false,
            title: title,
            subtitle: validation.isValidating
                ? const Text(
                    'Validating...',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  )
                : (validation.isValid
                      ? (isDirty
                            ? const Text(
                                'Modified',
                                style: TextStyle(fontSize: 12),
                              )
                            : null)
                      : Text(
                          validation.errorMessage ?? '',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        )),
            onChanged: (newValue) =>
                controller.setValue(resolvedId, newValue ?? false),
          );
        },
      ),
    );
  }
}

/// Riverpod-based dropdown form field
class RiverpodDropdownFormField<T> extends ConsumerWidget {
  const RiverpodDropdownFormField({
    super.key,
    required this.fieldId,
    required this.items,
    this.decoration,
    this.controllerProvider,
  });

  final FormixFieldID<T> fieldId;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration? decoration;
  final AutoDisposeStateNotifierProvider<FormixController, FormixData>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    final resolvedId = FormixGroup.resolve(context, fieldId);

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

          return DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: validation.isValid ? null : validation.errorMessage,
              suffixIcon: suffixIcon,
            ),
            onChanged: (newValue) {
              if (newValue != null) {
                controller.setValue(resolvedId, newValue);
              }
            },
          );
        },
      ),
    );
  }
}

/// Riverpod-based form status widget
class RiverpodFormStatus extends ConsumerWidget {
  const RiverpodFormStatus({super.key, this.controllerProvider});

  final AutoDisposeStateNotifierProvider<FormixController, FormixData>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final isDirty = ref.watch(formDirtyProvider);
          final isValid = ref.watch(formValidProvider);
          final isSubmitting = ref.watch(formSubmittingProvider);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(isDirty ? 'Form is dirty' : 'Form is clean'),
                  Text('Is Valid: $isValid'),
                  if (isSubmitting) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    const Text('Submitting...'),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
