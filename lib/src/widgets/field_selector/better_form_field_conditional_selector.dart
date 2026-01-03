import 'package:better_form/src/controllers/field_id.dart';
import 'package:better_form/src/controllers/riverpod_controller.dart';
import 'package:better_form/src/widgets/field_selector.dart';
import 'package:better_form/src/widgets/field_selector/better_form_field_selector.dart';
import 'package:flutter/material.dart';

/// A widget that provides granular listening control with custom conditions
class BetterFormFieldConditionalSelector<T> extends StatelessWidget {
  const BetterFormFieldConditionalSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    required this.shouldRebuild,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(
    BuildContext context,
    FieldChangeInfo<T> info,
    Widget? child,
  )
  builder;
  final bool Function(FieldChangeInfo<T> info) shouldRebuild;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: fieldId,
      controller: controller,
      builder: (context, info, child) {
        // Only rebuild if the condition is met
        if (shouldRebuild(info)) {
          return builder(context, info, child);
        }
        // Return a placeholder that doesn't rebuild
        return child ?? const SizedBox.shrink();
      },
      child: child,
    );
  }
}
