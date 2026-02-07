// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

class MinimalFormField extends FormixFieldWidget<String> {
  const MinimalFormField({super.key, required super.fieldId});
  @override
  MinimalFormFieldState createState() => MinimalFormFieldState();
}

class MinimalFormFieldState extends FormixFieldWidgetState<String> {
  @override
  Widget build(BuildContext context) {
    return Text(value ?? '');
  }
}

class _BenchmarkContainer extends StatefulWidget {
  final Widget child;
  final void Function(VoidCallback) onRebuildCallback;

  const _BenchmarkContainer({
    required this.child,
    required this.onRebuildCallback,
  });

  @override
  State<_BenchmarkContainer> createState() => _BenchmarkContainerState();
}

class _BenchmarkContainerState extends State<_BenchmarkContainer> {
  @override
  void initState() {
    super.initState();
    widget.onRebuildCallback(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  group('Formix Pure Overhead Benchmarks', () {
    testWidgets('Benchmark: Minimal Field Rebuild Cost (Optimized)', (tester) async {
      const fieldId = FormixFieldID<String>('pure_field');
      late VoidCallback triggerRebuild;

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Formix(
              child: _BenchmarkContainer(
                onRebuildCallback: (callback) => triggerRebuild = callback,
                child: const MinimalFormField(fieldId: fieldId),
              ),
            ),
          ),
        ),
      );

      // Warmup to eliminate JIT compilation overhead
      for (int i = 0; i < 100; i++) {
        triggerRebuild();
        await tester.pump();
      }

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;
      for (int i = 0; i < iterations; i++) {
        triggerRebuild();
        await tester.pump();
      }
      stopwatch.stop();

      print('--- Optimized Pure Formix Overhead (Rebuild Only) ---');
      print('Total time for $iterations rebuilds: ${stopwatch.elapsedMilliseconds}ms');
      print('Average time per rebuild: ${(stopwatch.elapsedMilliseconds / iterations).toStringAsFixed(2)}ms');
      print('------------------------------------------------------');
    });

    testWidgets('Benchmark: Mount/Unmount Overhead', (tester) async {
      const fieldId = FormixFieldID<String>('mount_field');
      int rebuildCount = 0;
      late VoidCallback triggerRebuild;

      await tester.pumpWidget(
        ProviderScope(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Formix(
              child: _BenchmarkContainer(
                onRebuildCallback: (callback) => triggerRebuild = callback,
                child: Builder(
                  builder: (context) {
                    rebuildCount++;
                    return MinimalFormField(
                      fieldId: fieldId,
                      key: ValueKey('field_$rebuildCount'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Warmup
      for (int i = 0; i < 100; i++) {
        triggerRebuild();
        await tester.pump();
      }

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;
      for (int i = 0; i < iterations; i++) {
        triggerRebuild();
        await tester.pump();
      }
      stopwatch.stop();

      print('--- Pure Formix Overhead (Mount+Unmount+Build) ---');
      print('Total time for $iterations cycles: ${stopwatch.elapsedMilliseconds}ms');
      print('Average time per cycle: ${(stopwatch.elapsedMilliseconds / iterations).toStringAsFixed(2)}ms');
      print('--------------------------------------------------');
    });
  });
}
