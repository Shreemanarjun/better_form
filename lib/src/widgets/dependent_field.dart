import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'better_form.dart';
import 'riverpod_form_fields.dart';

/// A widget that rebuilds when a dependent field's value changes.
///
/// Use [BetterDependentField] to conditionally show or hide parts of your UI
/// based on the current value of another field. This is highly optimized and
/// only rebuilds when the specific dependent field changes.
///
/// Example:
/// ```dart
/// BetterDependentField<bool>(
///   fieldId: hasPetField,
///   builder: (context, hasPet) {
///     if (hasPet == true) {
///       return RiverpodTextFormField(fieldId: petNameField);
///     }
///     return const SizedBox.shrink();
///   },
/// )
/// ```
class BetterDependentField<T> extends ConsumerWidget {
  /// Creates a dependent field widget.
  const BetterDependentField({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controllerProvider,
  });

  /// The ID of the field to watch for changes.
  final BetterFormFieldID<T> fieldId;

  /// Builder function that receives the current [value] of the dependent field.
  final Widget Function(BuildContext context, T? value) builder;

  /// Optional explicit controller provider. If null, it looks up the nearest [BetterForm].
  final AutoDisposeStateNotifierProvider<
    RiverpodFormController,
    BetterFormState
  >?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider =
        controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const BetterFormParameter(initialValue: {}));

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
