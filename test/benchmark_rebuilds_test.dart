// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Formix Rebuild Benchmarks', () {
    testWidgets('Benchmark: Single Field Rebuild Cost', (tester) async {
      const fieldId = FormixFieldID<String>('bench_field');
      int rebuildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    rebuildCount++;
                    return Column(
                      children: [
                        FormixTextFormField(
                          fieldId: fieldId,
                          key: ValueKey('field_$rebuildCount'), // Force new widget instance
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Rebuild'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;
      for (int i = 0; i < iterations; i++) {
        await tester.tap(find.text('Rebuild'));
        await tester.pump();
      }
      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perRebuildMs = totalMs / iterations;

      print('--- Benchmark Results ---');
      print('Total time for $iterations rebuilds: ${totalMs}ms');
      print('Average time per rebuild: ${perRebuildMs.toStringAsFixed(2)}ms');
      print('-------------------------');
    });

    testWidgets('Benchmark: Passive Rebuild Cost (No mount/unmount)', (tester) async {
      const fieldId = FormixFieldID<String>('bench_field');
      int rebuildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    rebuildCount++;
                    return Column(
                      children: [
                        FormixTextFormField(
                          fieldId: fieldId,
                          decoration: InputDecoration(
                            hintText: 'Rebuild $rebuildCount',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Rebuild'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;
      for (int i = 0; i < iterations; i++) {
        await tester.tap(find.text('Rebuild'));
        await tester.pump();
      }
      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perRebuildMs = totalMs / iterations;

      print('--- Passive Rebuild Results ---');
      print('Total time for $iterations rebuilds: ${totalMs}ms');
      print('Average time per rebuild: ${perRebuildMs.toStringAsFixed(2)}ms');
      print('-------------------------------');
    });

    testWidgets('Benchmark: Field mount/unmount overhead', (tester) async {
      const fieldId = FormixFieldID<String>('mount_field');
      final showField = ValueNotifier(true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: ValueListenableBuilder<bool>(
                  valueListenable: showField,
                  builder: (context, show, _) {
                    return show ? const FormixTextFormField(fieldId: fieldId) : const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      const iterations = 1000; // 1000 cycles (2000 total mount/unmount)
      for (int i = 0; i < iterations; i++) {
        showField.value = false;
        await tester.pump();
        showField.value = true;
        await tester.pump();
      }
      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;

      print('--- Mount/Unmount Benchmark ---');
      print('Total time for $iterations cycles: ${totalMs}ms');
      print('Average time per cycle: ${(totalMs / iterations).toStringAsFixed(2)}ms');
      print('-------------------------------');
    });
  });
}
