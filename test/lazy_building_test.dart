import 'package:formix/formix.dart';
import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FormixSection registers fields when built', (tester) async {
    final field1 = FormixFieldConfig(
      id: FormixFieldID<String>('field1'),
      initialValue: 'value1',
      label: 'Field 1',
    );

    final field2 = FormixFieldConfig(
      id: FormixFieldID<String>('field2'),
      initialValue: 'value2',
      label: 'Field 2',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              fields: [field1], // Only field1 is registered initially
              child: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: field1.id,
                    decoration: const InputDecoration(labelText: 'Field 1'),
                  ),
                  // Field 2 is not in the tree yet
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify field 1 is registered and present
    expect(find.text('Field 1'), findsOneWidget); // label

    // Now add Section 2
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              fields: [field1],
              child: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: field1.id,
                    decoration: const InputDecoration(labelText: 'Field 1'),
                  ),
                  FormixSection(
                    fields: [field2],
                    child: RiverpodTextFormField(
                      fieldId: field2.id,
                      decoration: const InputDecoration(labelText: 'Field 2'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // Allow state update from microtask to propagate

    // Verify field 2 is now present
    expect(find.text('Field 2'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'value2'), findsOneWidget);
  });

  testWidgets('FormixSection with keepAlive=false unregisters fields', (
    tester,
  ) async {
    final field1 = FormixFieldConfig(
      id: FormixFieldID<String>('field1'),
      initialValue: 'one',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              child: FormixSection(
                keepAlive: false,
                fields: [field1],
                child: RiverpodTextFormField(fieldId: field1.id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // Allow state update

    expect(find.byType(RiverpodTextFormField), findsOneWidget);

    // Remove the section
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              child: Container(), // Empty
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // Allow microtask unregistration

    expect(find.byType(RiverpodTextFormField), findsNothing);

    // If we add it back, it should re-register with initial value
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Formix(
              child: FormixSection(
                keepAlive: false,
                fields: [field1],
                child: RiverpodTextFormField(fieldId: field1.id),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // Allow state update

    expect(find.widgetWithText(TextFormField, 'one'), findsOneWidget);
  });
}
