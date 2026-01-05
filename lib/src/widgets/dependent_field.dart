import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'formix.dart';
import 'riverpod_form_fields.dart';

/// A widget that rebuilds when a dependent field's value changes.
///
/// Use [FormixDependentField] to conditionally show or hide parts of your UI
/// based on the current value of another field. This is highly optimized and
/// only rebuilds when the specific dependent field changes.
///
/// Example:
/// ```dart
/// FormixDependentField<bool>(
///   fieldId: hasPetField,
///   builder: (context, hasPet) {
///     if (hasPet == true) {
///       return RiverpodTextFormField(fieldId: petNameField);
///     }
///     return const SizedBox.shrink();
///   },
/// )
/// ```
class FormixDependentField<T> extends ConsumerWidget {
  /// Creates a dependent field widget.
  const FormixDependentField({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controllerProvider,
  });

  /// The ID of the field to watch for changes.
  final FormixFieldID<T> fieldId;

  /// Builder function that receives the current [value] of the dependent field.
  final Widget Function(BuildContext context, T? value) builder;

  /// Optional explicit controller provider. If null, it looks up the nearest [Formix].
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormixState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider =
        controllerProvider ??
        Formix.of(context) ??
        formControllerProvider(const FormixParameter(initialValue: {}));

    // We use ProviderScope override to ensure we are watching the correct controller
    // if we are using the global fieldValueProvider
    return ProviderScope(
      overrides: [currentControllerProvider.overrideWithValue(provider)],
      child: Consumer(
        builder: (context, ref, _) {
          final value = ref.watch(fieldValueProvider(fieldId));
          return builder(context, value);
        },
      ),
    );
  }
}
