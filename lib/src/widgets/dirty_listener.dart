import 'package:flutter/material.dart';

import '../form.dart';

/// Widget that rebuilds when form dirty state changes
class BetterFormDirtyListener extends StatelessWidget {
  const BetterFormDirtyListener({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext context, bool isDirty, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = BetterForm.of(context);
    if (controller == null) {
      throw FlutterError('BetterFormDirtyListener must be used within a BetterForm');
    }

    return ValueListenableBuilder<bool>(
      valueListenable: controller.isDirtyNotifier,
      builder: (context, isDirty, child) {
        return builder(context, isDirty, child);
      },
      child: child,
    );
  }
}
