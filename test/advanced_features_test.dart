import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

// Test-specific helper for waiting (mimics async behavior)
Future<void> pumpAsync(WidgetTester tester) async {
  await tester.pump(
    const Duration(milliseconds: 100),
  ); // drain debouncer/timers
  await tester.pump(const Duration(milliseconds: 100)); // drain animations
}

void main() {
  group('Advanced Features', () {
    testWidgets('FormixDependentField responds to dependency changes', (
      tester,
    ) async {
      const visibilityField = FormixFieldID<bool>('visible');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: const {'name': 'John', 'visible': false},
                child: Column(
                  children: [
                    FormixDependentField<bool>(
                      fieldId: visibilityField,
                      builder: (context, value) {
                        return value == true ? const Text('Visible Content') : const SizedBox.shrink();
                      },
                    ),
                    const FormixCheckboxFormField(
                      fieldId: visibilityField,
                      title: Text('Check me'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Initially hidden
      expect(find.text('Visible Content'), findsNothing);

      // Toggle checkbox
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      // Now visible
      expect(find.text('Visible Content'), findsOneWidget);
    });

    testWidgets('Async validation shows loading indicator', (tester) async {
      const usernameField = FormixFieldID<String>('username');

      // Mock async validator
      Future<String?> asyncValidator(String? value) async {
        // Return null (valid) for 'valid', error for others
        await Future.delayed(const Duration(milliseconds: 200));
        if (value == 'taken') return 'Username taken';
        return null;
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                fields: [
                  FormixFieldConfig<String>(
                    id: usernameField,
                    label: 'Username',
                    initialValue: '',
                    asyncValidator: asyncValidator,
                    debounceDuration: const Duration(milliseconds: 50),
                  ),
                ],
                child: const FormixTextFormField(fieldId: usernameField),
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Initial render

      // Type 'taken'
      await tester.enterText(find.byType(TextFormField), 'taken');

      // Wait for debounce logic to trigger loading state, but not finish
      await tester.pump(const Duration(milliseconds: 60));

      // Should show loading indicator (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pump(
        const Duration(milliseconds: 200),
      ); // Wait for validator
      await tester.pumpAndSettle();

      // Should show error and no loading indicator
      expect(find.text('Username taken'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Persistence saves and restores state', (tester) async {
      // Use in-memory persistence
      final persistence = InMemoryFormPersistence();
      const formId = 'test_form';
      const nameField = FormixFieldID<String>('name');

      // Pre-save state
      await persistence.saveFormState(formId, {'name': 'Saved Name'});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                formId: formId,
                persistence: persistence,
                initialValue: const {'name': 'Initial'},
                // We must register the field to populate it
                fields: const [
                  FormixFieldConfig<String>(
                    id: nameField,
                    initialValue: 'Initial',
                  ),
                ],
                child: const FormixTextFormField(fieldId: nameField),
              ),
            ),
          ),
        ),
      );

      // Should show initial value first
      await tester.pump();
      // Need to wait for the future in controller constructor to complete.
      await tester.pumpAndSettle();

      expect(find.text('Saved Name'), findsOneWidget);

      // Enter new text
      await tester.enterText(find.byType(TextFormField), 'New Name');
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Debounce/Processing

      // Verify persistence updated
      final savedInfo = await persistence.getSavedState(formId);
      expect(savedInfo?['name'], 'New Name');
    });
  });
}
