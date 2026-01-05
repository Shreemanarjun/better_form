import 'package:formix/src/controllers/field_id.dart';
import 'package:formix/src/controllers/riverpod_controller.dart';
import 'package:formix/src/widgets/field_selector/formix_field_selector.dart';
import 'package:flutter/material.dart';

/// A simplified version that only listens to value changes
class FormixFieldValueSelector<T> extends StatelessWidget {
  const FormixFieldValueSelector({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final FormixFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value, Widget? child) builder;
  final FormixController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FormixFieldSelector<T>(
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
