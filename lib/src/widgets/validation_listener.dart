import 'package:flutter/material.dart';

import '../form.dart';

/// Widget that rebuilds when the form's validation state changes
class BetterFormValidationListener extends StatelessWidget {
  const BetterFormValidationListener({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext context, bool isValid, Widget? child)
  builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final controller = BetterForm.of(context);
    if (controller == null) {
      throw FlutterError(
        'BetterFormValidationListener must be used within a BetterForm',
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: controller.isValidNotifier,
      builder: (context, isValid, child) {
        return builder(context, isValid, child);
      },
      child: child,
    );
  }
}
