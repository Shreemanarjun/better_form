import 'package:better_form/src/controllers/field_id.dart';
import 'package:better_form/src/controllers/riverpod_controller.dart';
import 'package:better_form/src/widgets/field_selector.dart';
import 'package:better_form/src/widgets/field_selector/better_form_field_selector.dart';
import 'package:flutter/material.dart';

/// A widget that shows performance metrics for field rebuilding
class BetterFormFieldPerformanceMonitor<T> extends StatefulWidget {
  const BetterFormFieldPerformanceMonitor({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(
    BuildContext context,
    FieldChangeInfo<T> info,
    int rebuildCount,
  )
  builder;
  final BetterFormController? controller;

  @override
  State<BetterFormFieldPerformanceMonitor<T>> createState() =>
      _BetterFormFieldPerformanceMonitorState<T>();
}

class _BetterFormFieldPerformanceMonitorState<T>
    extends State<BetterFormFieldPerformanceMonitor<T>> {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    return BetterFormFieldSelector<T>(
      fieldId: widget.fieldId,
      controller: widget.controller,
      builder: (context, info, child) {
        _rebuildCount++;
        return widget.builder(context, info, _rebuildCount);
      },
    );
  }
}
