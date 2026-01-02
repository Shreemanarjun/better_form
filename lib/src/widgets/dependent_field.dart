import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'riverpod_form_fields.dart';

/// A widget that rebuilds when a dependent field's value changes.
/// Useful for showing/hiding fields or changing available options based on another field.
class BetterDependentField<T> extends ConsumerWidget {
  const BetterDependentField({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controllerProvider,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value) builder;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider =
        controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const BetterFormParameter(initialValue: {}));

    // We use select to only rebuild when this specific field's value changes
    final value = ref.watch(
      provider.select((state) => state.getValue(fieldId)),
    );

    return builder(context, value);
  }
}
