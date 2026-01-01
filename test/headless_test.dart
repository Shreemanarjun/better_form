import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('Headless Widgets (Standalone)', () {
    testWidgets('BetterRawTextField finds child after registration', (
      tester,
    ) async {
      final id = BetterFormFieldID<String>('standalone');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'standalone': 'Initial'},
                fields: <BetterFormFieldConfig<dynamic>>[
                  BetterFormFieldConfig<String>(
                    id: id,
                    initialValue: 'Initial',
                  ),
                ],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  initialValue: 'Initial',
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, state) {
                    return Container(
                      key: const Key('my_headless_container'),
                      child: Text('Value: ${state.value}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Pump to process the widget tree
      await tester.pump();
      // Pump again to process the microtask for field registration
      await tester.pump();

      // Now the widget should be rendered
      expect(find.byKey(const Key('my_headless_container')), findsOneWidget);
      expect(find.text('Value: Initial'), findsOneWidget);

      // Verify value update
      final element = tester.element(
        find.byKey(const Key('my_headless_container')),
      );
      final controller = BetterForm.controllerOf(element)!;

      controller.setValue(id, 'Alex');
      await tester.pump();

      expect(find.text('Value: Alex'), findsOneWidget);
    });
  });
}
