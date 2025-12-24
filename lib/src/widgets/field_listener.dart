import 'package:flutter/material.dart';

import '../field_id.dart';
import '../form.dart';

/// Widget that rebuilds when a specific field changes
class BetterFormFieldListener<T> extends StatelessWidget {
  const BetterFormFieldListener({
    super.key,
    required this.fieldId,
    required this.builder,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = BetterForm.of(context);
    if (controller == null) {
      throw FlutterError('BetterFormFieldListener must be used within a BetterForm');
    }

    final notifier = controller.getFieldNotifier<T>(fieldId);
    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return builder(context, value, child);
      },
      child: child,
    );
  }
}
