import 'package:flutter/material.dart';

import '../../formix.dart';

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
///       return FormixTextFormField(fieldId: petNameField);
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
  final AutoDisposeStateNotifierProvider<FormixController, FormixData>? controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = controllerProvider ?? Formix.of(context);

    if (provider == null) {
      return const FormixConfigurationErrorWidget(
        message: 'FormixDependentField used outside of Formix',
        details: 'FormixDependentField requires a Formix ancestor or an explicit controllerProvider to function.',
      );
    }

    // We use ProviderScope override to ensure we are watching the correct controller
    // if we are using the global fieldValueProvider
    return ProviderScope(
      overrides: [currentControllerProvider.overrideWithValue(provider)],
      child: Consumer(
        builder: (context, ref, _) {
          try {
            final value = ref.watch(fieldValueProvider(fieldId));
            return builder(context, value);
          } catch (e) {
            return FormixConfigurationErrorWidget(
              message: 'Failed to initialize FormixDependentField',
              details: e.toString().contains('No ProviderScope found')
                  ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.'
                  : 'Error: $e',
            );
          }
        },
      ),
    );
  }
}
