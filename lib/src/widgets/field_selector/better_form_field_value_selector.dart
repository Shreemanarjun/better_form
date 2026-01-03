import 'package:better_form/src/controllers/field_id.dart';
import 'package:better_form/src/controllers/riverpod_controller.dart';
import 'package:better_form/src/widgets/field_selector/better_form_field_selector.dart';
import 'package:flutter/material.dart';

/// A simplified version that only listens to value changes
class BetterFormFieldValueSelector<T> extends StatelessWidget {
  const BetterFormFieldValueSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: fieldId,
      controller: controller,
      listenToValue: true,
      listenToValidation: false,
      listenToDirty: false,
      builder: (context, info, child) => builder(context, info.value, child),
      child: child,
    );
  }
}



