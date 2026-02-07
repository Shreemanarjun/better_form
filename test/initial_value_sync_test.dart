import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  testWidgets('initialValue from widget should be adopted if field was pre-registered with null', (tester) async {
    const emailField = FormixFieldID<String>('email');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              fields: const [
                FormixFieldConfig<String>(id: emailField), // initial value is null
              ],
              child: FormixRawFormField<String>(
                fieldId: emailField,
                initialValue: 'saved-email@example.com',
                builder: (context, snapshot) {
                  return Text('Value: ${snapshot.value}');
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // According to the bug report, this will fail and show 'Value: null'
    expect(find.text('Value: saved-email@example.com'), findsOneWidget);
  });

  testWidgets('initialValue from widget should NOT override if field already has a non-null value', (tester) async {
    const emailField = FormixFieldID<String>('email');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              initialValue: const {'email': 'pre-existing@example.com'},
              fields: const [
                FormixFieldConfig<String>(id: emailField, initialValue: 'pre-existing@example.com'),
              ],
              child: FormixRawFormField<String>(
                fieldId: emailField,
                initialValue: 'this-should-be-ignored@example.com',
                builder: (context, snapshot) {
                  return Text('Value: ${snapshot.value}');
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Existing value should be preserved
    expect(find.text('Value: pre-existing@example.com'), findsOneWidget);
  });
}
