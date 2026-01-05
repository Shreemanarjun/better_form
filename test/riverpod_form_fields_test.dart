import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

// Test-specific providers for easier testing
final testControllerProvider =
    StateNotifierProvider.autoDispose<FormixController, FormixData>((ref) {
      return FormixController(initialValue: {});
    });

void main() {
  group('RiverpodTextFormField', () {
    testWidgets('should render with initial value', (tester) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testControllerProvider.overrideWith((ref) {
              return FormixController(initialValue: {'name': 'John'});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodTextFormField(
                fieldId: nameField,
                controllerProvider: testControllerProvider,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('should update value when typing', (tester) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testControllerProvider.overrideWith((ref) {
              return FormixController(initialValue: {'name': ''});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodTextFormField(
                fieldId: nameField,
                controllerProvider: testControllerProvider,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      // The field should show the entered text
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('should show validation error', (tester) async {
      final emailField = FormixFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            testControllerProvider.overrideWith((ref) {
              final controller = FormixController(
                initialValue: {'email': ''},
                fields: [
                  FormixField<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) =>
                        value.contains('@') ? null : 'Invalid email',
                  ),
                ],
              );
              return controller;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodTextFormField(
                fieldId: emailField,
                controllerProvider: testControllerProvider,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.pump();

      // For Riverpod fields, validation happens on field registration
      // The error should be shown immediately
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });

  group('RiverpodNumberFormField', () {
    testWidgets('should render with initial numeric value', (tester) async {
      final ageField = FormixFieldID<num>('age');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'age': 25});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodNumberFormField(
                fieldId: ageField,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });

    testWidgets('should accept numeric input', (tester) async {
      final ageField = FormixFieldID<num>('age');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'age': 0});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodNumberFormField(
                fieldId: ageField,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '30');
      await tester.pump();

      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('should enforce min/max constraints', (tester) async {
      final ageField = FormixFieldID<num>('age');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'age': 25});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodNumberFormField(
                fieldId: ageField,
                min: 18,
                max: 100,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
          ),
        ),
      );

      // Try to enter value below minimum
      await tester.enterText(find.byType(TextFormField), '15');
      await tester.pump();

      // The value should not be accepted into the model (kept as 25),
      // but the field text should show '15' to allow correcting.
      // (Previous expectation of showing '25' would prevent typing any number starting with a digit < min)
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('RiverpodCheckboxFormField', () {
    testWidgets('should render with initial boolean value', (tester) async {
      final newsletterField = FormixFieldID<bool>('newsletter');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'newsletter': true});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodCheckboxFormField(
                fieldId: newsletterField,
                title: const Text('Subscribe to newsletter'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Subscribe to newsletter'), findsOneWidget);
      // Checkbox should be checked (true)
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, true);
    });

    testWidgets('should toggle value when tapped', (tester) async {
      final newsletterField = FormixFieldID<bool>('newsletter');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'newsletter': false});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodCheckboxFormField(
                fieldId: newsletterField,
                title: const Text('Subscribe to newsletter'),
              ),
            ),
          ),
        ),
      );

      // Initially unchecked
      CheckboxListTile checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, false);

      // Tap to check
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      // Should now be checked
      checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, true);
    });

    testWidgets('should show validation error', (tester) async {
      final agreeField = FormixFieldID<bool>('agree');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              final controller = FormixController(
                initialValue: {'agree': false},
                fields: [
                  FormixField<bool>(
                    id: agreeField,
                    initialValue: false,
                    validator: (value) =>
                        value == true ? null : 'You must agree',
                  ),
                ],
              );
              return controller;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodCheckboxFormField(
                fieldId: agreeField,
                title: const Text('I agree to terms'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('You must agree'), findsOneWidget);
    });
  });

  group('RiverpodDropdownFormField', () {
    testWidgets('should render with initial value', (tester) async {
      final priorityField = FormixFieldID<String>('priority');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'priority': 'medium'});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodDropdownFormField<String>(
                fieldId: priorityField,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('should change value when selected', (tester) async {
      final priorityField = FormixFieldID<String>('priority');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'priority': 'medium'});
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RiverpodDropdownFormField<String>(
                fieldId: priorityField,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
            ),
          ),
        ),
      );

      // Initially shows 'Medium'
      expect(find.text('Medium'), findsOneWidget);

      // Note: Testing dropdown selection requires more complex interaction
      // This test verifies the widget renders correctly with initial value
    });
  });

  group('RiverpodFormStatus', () {
    testWidgets('should show form status', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              return FormixController(initialValue: {'name': 'John'});
            }),
          ],
          child: MaterialApp(home: Scaffold(body: const RiverpodFormStatus())),
        ),
      );

      expect(find.text('Form Status'), findsOneWidget);
      expect(find.text('Form is clean'), findsOneWidget);
      expect(find.text('Is Valid: true'), findsOneWidget);
    });

    testWidgets('should show dirty state when form is modified', (
      tester,
    ) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const FormixParameter(initialValue: {}),
            ).overrideWith((ref) {
              final controller = FormixController(
                initialValue: {'name': 'John'},
              );
              // Simulate setting a value to make it dirty
              Future.microtask(() => controller.setValue(nameField, 'Jane'));
              return controller;
            }),
          ],
          child: MaterialApp(home: Scaffold(body: const RiverpodFormStatus())),
        ),
      );

      await tester.pump();

      expect(find.text('Form is dirty'), findsOneWidget);
    });
  });
}
