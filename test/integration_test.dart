import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('Complete Form Integration Tests', () {
    testWidgets('should handle complete user registration form', (
      tester,
    ) async {
      // Define form fields
      final nameField = BetterFormFieldID<String>('name');
      final emailField = BetterFormFieldID<String>('email');
      final ageField = BetterFormFieldID<num>('age');
      final newsletterField = BetterFormFieldID<bool>('newsletter');
      final agreeField = BetterFormFieldID<bool>('agree');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const BetterFormParameter(initialValue: {}),
            ).overrideWith((ref) {
              final controller = RiverpodFormController(
                initialValue: {
                  'name': '',
                  'email': '',
                  'age': 18,
                  'newsletter': false,
                  'agree': false,
                },
                fields: [
                  BetterFormField<String>(
                    id: nameField,
                    initialValue: '',
                    validator: (value) =>
                        value.isEmpty ? 'Name is required' : null,
                  ),
                  BetterFormField<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) =>
                        value.contains('@') ? null : 'Invalid email',
                  ),
                  BetterFormField<num>(
                    id: ageField,
                    initialValue: 18,
                    validator: (value) =>
                        value >= 18 ? null : 'Must be 18 or older',
                  ),
                  BetterFormField<bool>(
                    id: agreeField,
                    initialValue: false,
                    validator: (value) =>
                        value == true ? null : 'You must agree to terms',
                  ),
                ],
              );
              return controller;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: nameField,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    RiverpodTextFormField(
                      fieldId: emailField,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    RiverpodNumberFormField(
                      fieldId: ageField,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: 'Enter your age',
                      ),
                      min: 0,
                      max: 120,
                    ),
                    const SizedBox(height: 16),
                    RiverpodCheckboxFormField(
                      fieldId: newsletterField,
                      title: const Text('Subscribe to newsletter'),
                    ),
                    const SizedBox(height: 16),
                    RiverpodCheckboxFormField(
                      fieldId: agreeField,
                      title: const Text('I agree to terms and conditions'),
                    ),
                    const SizedBox(height: 24),
                    Consumer(
                      builder: (context, ref, child) {
                        final formState = ref.watch(
                          formControllerProvider(
                            const BetterFormParameter(initialValue: {}),
                          ),
                        );
                        final isValid = formState.isValid;
                        final isDirty = formState.isDirty;

                        return Column(
                          children: [
                            Text(
                              'Form Status: ${isDirty ? 'Modified' : 'Unchanged'}',
                            ),
                            Text(
                              'Validation: ${isValid ? 'Valid' : 'Invalid'}',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isValid
                                  ? () {
                                      final values = ref
                                          .read(
                                            formControllerProvider(
                                              const BetterFormParameter(
                                                initialValue: {},
                                              ),
                                            ),
                                          )
                                          .values;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Form submitted: ${values.length} fields',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text('Submit'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially form should be invalid (missing required fields)
      expect(find.text('Validation: Invalid'), findsOneWidget);
      expect(find.text('Form Status: Unchanged'), findsOneWidget);

      // Fill in the form
      await tester.enterText(
        find.byType(TextFormField).first, // Name field
        'John Doe',
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).at(1), // Email field
        'john@example.com',
      );
      await tester.pump();

      // Check the agreement checkbox
      await tester.tap(find.text('I agree to terms and conditions'));
      await tester.pump();

      // Now form should be valid
      expect(find.text('Validation: Valid'), findsOneWidget);
      expect(find.text('Form Status: Modified'), findsOneWidget);

      // Submit the form
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Form submitted: 5 fields'), findsOneWidget);
    });

    testWidgets('should handle form reset functionality', (tester) async {
      final nameField = BetterFormFieldID<String>('name');
      final emailField = BetterFormFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const BetterFormParameter(initialValue: {}),
            ).overrideWith((ref) {
              return RiverpodFormController(
                initialValue: {
                  'name': 'Initial Name',
                  'email': 'initial@example.com',
                },
              );
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: nameField,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  RiverpodTextFormField(
                    fieldId: emailField,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: () {
                          ref
                              .read(
                                formControllerProvider(
                                  const BetterFormParameter(initialValue: {}),
                                ).notifier,
                              )
                              .reset();
                        },
                        child: const Text('Reset'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially should show initial values
      expect(find.text('Initial Name'), findsOneWidget);
      expect(find.text('initial@example.com'), findsOneWidget);

      // Modify the fields
      await tester.enterText(find.byType(TextFormField).first, 'Modified Name');
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).last,
        'modified@example.com',
      );
      await tester.pump();

      expect(find.text('Modified Name'), findsOneWidget);
      expect(find.text('modified@example.com'), findsOneWidget);

      // Reset the form
      await tester.tap(find.text('Reset'));
      await tester.pump();

      // Should be back to initial values
      expect(find.text('Initial Name'), findsOneWidget);
      expect(find.text('initial@example.com'), findsOneWidget);
    });

    testWidgets('should handle complex validation scenarios', (tester) async {
      final passwordField = BetterFormFieldID<String>('password');
      final confirmPasswordField = BetterFormFieldID<String>('confirmPassword');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const BetterFormParameter(initialValue: {}),
            ).overrideWith((ref) {
              late final RiverpodFormController controller;
              controller = RiverpodFormController(
                initialValue: {'password': '', 'confirmPassword': ''},
                fields: [
                  BetterFormField<String>(
                    id: passwordField,
                    initialValue: '',
                    validator: (value) {
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  BetterFormField<String>(
                    id: confirmPasswordField,
                    initialValue: '',
                    validator: (value) {
                      try {
                        final password = controller.getValue(passwordField);
                        if (value != password) return 'Passwords do not match';
                      } catch (_) {
                        // During initial state creation, controller is not yet initialized
                      }
                      return null;
                    },
                  ),
                ],
              );
              return controller;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: passwordField,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  RiverpodTextFormField(
                    fieldId: confirmPasswordField,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final formState = ref.watch(
                        formControllerProvider(
                          const BetterFormParameter(initialValue: {}),
                        ),
                      );
                      return Text('Form Valid: ${formState.isValid}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initially invalid
      expect(find.text('Form Valid: false'), findsOneWidget);

      // Enter password
      await tester.enterText(find.byType(TextFormField).first, 'password123');
      await tester.pump();

      // Enter matching confirmation
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.pump();

      // Should be valid now
      expect(find.text('Form Valid: true'), findsOneWidget);

      // Change confirmation to not match
      await tester.enterText(find.byType(TextFormField).last, 'different');
      await tester.pump();

      // Should be invalid again
      expect(find.text('Form Valid: false'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should handle dynamic field visibility', (tester) async {
      final showExtraField = BetterFormFieldID<bool>('showExtra');
      final extraField = BetterFormFieldID<String>('extra');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            formControllerProvider(
              const BetterFormParameter(initialValue: {}),
            ).overrideWith((ref) {
              return RiverpodFormController(
                initialValue: {'showExtra': false, 'extra': ''},
                fields: [
                  BetterFormField<bool>(
                    id: showExtraField,
                    initialValue: false,
                  ),
                  BetterFormField<String>(id: extraField, initialValue: ''),
                ],
              );
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  final formState = ref.watch(
                    formControllerProvider(
                      const BetterFormParameter(initialValue: {}),
                    ),
                  );
                  final showExtra = formState.getValue(showExtraField) ?? false;

                  return Column(
                    children: [
                      RiverpodCheckboxFormField(
                        fieldId: showExtraField,
                        title: const Text('Show extra field'),
                      ),
                      if (showExtra) ...[
                        const SizedBox(height: 16),
                        RiverpodTextFormField(
                          fieldId: extraField,
                          decoration: const InputDecoration(
                            labelText: 'Extra Information',
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially extra field should not be visible
      expect(find.text('Extra Information'), findsNothing);

      // Check the checkbox
      await tester.tap(find.text('Show extra field'));
      await tester.pump();

      // Extra field should now be visible
      expect(find.text('Extra Information'), findsOneWidget);

      // Uncheck the checkbox
      await tester.tap(find.text('Show extra field'));
      await tester.pump();

      // Extra field should be hidden again
      expect(find.text('Extra Information'), findsNothing);
    });
  });

  group('BetterForm Widget Integration', () {
    testWidgets('should work with dedicated BetterForm widget', (tester) async {
      final nameField = BetterFormFieldID<String>('name');
      final emailField = BetterFormFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: {'name': 'Jane Doe', 'email': 'jane@example.com'},
                fields: [
                  BetterFormFieldConfig<String>(
                    id: nameField,
                    initialValue: '',
                    validator: (value) => value.isEmpty ? 'Required' : null,
                  ),
                  BetterFormFieldConfig<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) =>
                        value.contains('@') ? null : 'Invalid',
                  ),
                ],
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: nameField,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    RiverpodTextFormField(
                      fieldId: emailField,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final provider = BetterForm.of(context)!;
                        final formState = ref.watch(provider);
                        return Text('Form Valid: ${formState.isValid}');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.text('Form Valid: true'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();
      expect(find.text('Form Valid: false'), findsOneWidget);
    });
  });
}
