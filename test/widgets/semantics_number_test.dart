import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';
import 'package:formix/src/widgets/number_form_field.dart';

void main() {
  testWidgets('FormixNumberFormField reports invalid semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final fieldId = FormixFieldID<int>('age');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              autovalidateMode: FormixAutovalidateMode.always,
              fields: [
                FormixFieldConfig<int>(
                  id: fieldId,
                  // Use non-null invalid value to trigger validation in Formix
                  initialValue: -1,
                  validator: (val) =>
                      (val == null || val < 0) ? 'Must be positive' : null,
                ),
              ],
              child: FormixNumberFormField<int>(
                fieldId: fieldId,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify error text is visible
    expect(find.text('Must be positive'), findsOneWidget);

    // Find InputDecorator, which often holds the decoration semantics including error
    final finder = find.descendant(
      of: find.byType(FormixNumberFormField<int>),
      matching: find.byType(InputDecorator),
    );
    expect(finder, findsOneWidget);

    final semantics = tester.getSemantics(finder);
    final data = semantics.getSemanticsData();

    if (data.validationResult != SemanticsValidationResult.invalid) {
      print('Number field validation result: ${data.validationResult}');
    }

    expect(data.validationResult, equals(SemanticsValidationResult.invalid));

    handle.dispose();
  });
}
