import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';
import 'package:formix/src/widgets/dropdown_form_field.dart';

void main() {
  testWidgets('FormixDropdownFormField reports invalid semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final fieldId = FormixFieldID<String>('role');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              autovalidateMode: FormixAutovalidateMode.always,
              fields: [
                FormixFieldConfig<String>(
                  id: fieldId,
                  initialValue: '',
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
              ],
              child: FormixDropdownFormField<String>(
                fieldId: fieldId,
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Find the dropdown semantics.
    // DropdownButton creates a button.
    final finder = find.byType(DropdownButton<String>);
    expect(finder, findsOneWidget);

    // We often need to find the specific semantic node that represents the interactive element (the button).
    // DropdownButton usually implements Semantics.
    final semantics = tester.getSemantics(finder);
    final data = semantics.getSemanticsData();

    // Check validation result
    // Note: DropdownButton might not automatically inherit InputDecorator's error semantics
    // into its own 'validationResult' property unless explicitly wired or if InputDecorator covers it.
    // Usually InputDecorator wraps the Dropdown.

    // We want to see if the semantic node representing the dropdown indicates an error.
    if (data.validationResult != SemanticsValidationResult.invalid) {
      // It might be on a parent node (InputDecorator?)
      // distinct from the button. But users interact with the button.
      print('Dropdown semantics validationResult: ${data.validationResult}');
    }

    expect(data.validationResult, equals(SemanticsValidationResult.invalid));

    handle.dispose();
  });
}
