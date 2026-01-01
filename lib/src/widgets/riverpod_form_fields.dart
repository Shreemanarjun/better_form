import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/controller.dart';
import '../controllers/riverpod_controller.dart';
import '../controllers/field.dart';
import '../controllers/field_id.dart';

/// Configuration for a form field
class BetterFormFieldConfig<T> {
  const BetterFormFieldConfig({
    required this.id,
    this.initialValue,
    this.validator,
    this.label,
    this.hint,
  });

  final BetterFormFieldID<T> id;
  final T? initialValue;
  final String? Function(T? value)? validator;
  final String? label;
  final String? hint;

  BetterFormField<T> toField() {
    return BetterFormField<T>(
      id: id,
      initialValue: initialValue as T,
      validator: validator,
      label: label,
      hint: hint,
    );
  }
}

/// A form widget that automatically manages a Riverpod controller provider
/// and makes it available to all child Riverpod form fields
class BetterForm extends ConsumerWidget {
  const BetterForm({
    super.key,
    this.initialValue = const {},
    this.fields = const [],
    required this.child,
  });

  final Map<String, dynamic> initialValue;
  final List<BetterFormFieldConfig> fields;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a unique controller provider for this form instance
    final controllerProvider = formControllerProvider(initialValue);
    final controller = ref.read(controllerProvider.notifier) as BetterFormController;

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: _FieldRegistrar(
        controllerProvider: controllerProvider,
        fields: fields,
        child: _BetterFormScope(
          controller: controller,
          controllerProvider: controllerProvider,
          fields: fields,
          child: child,
        ),
      ),
    );
  }

  /// Get the controller provider from the nearest BetterForm ancestor
  static AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>? of(
    BuildContext context,
  ) {
    final _BetterFormScope? scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controllerProvider;
  }

  /// Get the controller from the nearest BetterForm ancestor (for compatibility)
  static BetterFormController? controllerOf(BuildContext context) {
    final _BetterFormScope? scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controller;
  }
}

class _BetterFormScope extends InheritedWidget {
  const _BetterFormScope({
    required super.child,
    required this.controller,
    required this.controllerProvider,
    required this.fields,
  });

  final BetterFormController controller;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>
  controllerProvider;
  final List<BetterFormFieldConfig> fields;

  @override
  bool updateShouldNotify(_BetterFormScope oldWidget) {
    return controller != oldWidget.controller ||
           controllerProvider != oldWidget.controllerProvider ||
           !const ListEquality().equals(fields, oldWidget.fields);
  }
}

/// Automatically registers fields with the controller
class _FieldRegistrar extends ConsumerWidget {
  const _FieldRegistrar({
    required this.controllerProvider,
    required this.fields,
    required this.child,
  });

  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState> controllerProvider;
  final List<BetterFormFieldConfig> fields;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(controllerProvider.notifier);

    // Register all fields with the controller
    for (final fieldConfig in fields) {
      if (!controller.isFieldRegistered(fieldConfig.id)) {
        controller.registerField(fieldConfig.toField());
      }
    }

    return child;
  }
}



/// Riverpod-based checkbox form field
class RiverpodCheckboxFormField extends ConsumerWidget {
  const RiverpodCheckboxFormField({
    super.key,
    required this.fieldId,
    this.title,
    this.controllerProvider,
  });

  final BetterFormFieldID<bool> fieldId;
  final Widget? title;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final controller = ref.read(controllerProvider.notifier);
          final value = ref.watch(fieldValueProvider(fieldId));
          final validation = ref.watch(fieldValidationProvider(fieldId));
          final isDirty = ref.watch(fieldDirtyProvider(fieldId));

          return CheckboxListTile(
            value: value ?? false,
            title: title,
            subtitle: validation.isValid
                ? (isDirty
                      ? const Text('Modified', style: TextStyle(fontSize: 12))
                      : null)
                : Text(
                    validation.errorMessage ?? '',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
            onChanged: (newValue) => controller.setValue(fieldId, newValue ?? false),
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

  final BetterFormFieldID<T> fieldId;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration? decoration;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final controller = ref.read(controllerProvider.notifier);
          final value = ref.watch(fieldValueProvider(fieldId));
          final validation = ref.watch(fieldValidationProvider(fieldId));
          final isDirty = ref.watch(fieldDirtyProvider(fieldId));

          return DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            decoration: (decoration ?? const InputDecoration()).copyWith(
              errorText: validation.isValid ? null : validation.errorMessage,
              suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
            ),
            onChanged: (newValue) {
              if (newValue != null) {
                controller.setValue(fieldId, newValue);
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

  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});

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
                  Text('Form Status', style: Theme.of(context).textTheme.titleMedium),
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
