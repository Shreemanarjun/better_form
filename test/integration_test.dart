import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Complete Form Integration Tests', () {
    testWidgets('should handle complete user registration form', (
      tester,
    ) async {
      // Define form fields
      final nameField = FormixFieldID<String>('name');
      final emailField = FormixFieldID<String>('email');
      final ageField = FormixFieldID<num>('age');
      final newsletterField = FormixFieldID<bool>('newsletter');
      final agreeField = FormixFieldID<bool>('agree');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: const {
                  'name': '',
                  'email': '',
                  'age': 18,
                  'newsletter': false,
                  'agree': false,
                },
                fields: [
                  FormixFieldConfig<String>(
                    id: nameField,
                    initialValue: '',
                    validator: (value) =>
                        (value?.isEmpty ?? true) ? 'Name is required' : null,
                  ),
                  FormixFieldConfig<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) => (value?.contains('@') ?? false)
                        ? null
                        : 'Invalid email',
                  ),
                  FormixFieldConfig<num>(
                    id: ageField,
                    initialValue: 18,
                    validator: (value) =>
                        (value ?? 0) >= 18 ? null : 'Must be 18 or older',
                  ),
                  FormixFieldConfig<bool>(
                    id: agreeField,
                    initialValue: false,
                    validator: (value) =>
                        value == true ? null : 'You must agree to terms',
                  ),
                ],
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      FormixTextFormField(
                        fieldId: nameField,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormixTextFormField(
                        fieldId: emailField,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      FormixNumberFormField(
                        fieldId: ageField,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter your age',
                        ),
                        min: 0,
                        max: 120,
                      ),
                      const SizedBox(height: 16),
                      FormixCheckboxFormField(
                        fieldId: newsletterField,
                        title: const Text('Subscribe to newsletter'),
                      ),
                      const SizedBox(height: 16),
                      FormixCheckboxFormField(
                        fieldId: agreeField,
                        title: const Text('I agree to terms and conditions'),
                      ),
                      const SizedBox(height: 24),
                      FormixBuilder(
                        builder: (context, scope) {
                          final isValid = scope.watchIsValid;
                          final isDirty = scope.watchIsFormDirty;

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
                                        final values = scope.values;
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
      final nameField = FormixFieldID<String>('name');
      final emailField = FormixFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: const {
                  'name': 'Initial Name',
                  'email': 'initial@example.com',
                },
                child: Column(
                  children: [
                    FormixTextFormField(
                      fieldId: nameField,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    FormixTextFormField(
                      fieldId: emailField,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    FormixBuilder(
                      builder: (context, scope) {
                        return ElevatedButton(
                          onPressed: () {
                            scope.reset();
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
      final passwordField = FormixFieldID<String>('password');
      final confirmPasswordField = FormixFieldID<String>('confirmPassword');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: const {'password': '', 'confirmPassword': ''},
                child: Column(
                  children: [
                    FormixTextFormField(
                      fieldId: passwordField,
                      initialValue: '',
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    FormixBuilder(
                      builder: (context, scope) {
                        return FormixTextFormField(
                          fieldId: confirmPasswordField,
                          validator: (value) {
                            final password = scope.controller.getValue(
                              passwordField,
                            );
                            if (value != password) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                          ),
                        );
                      },
                    ),
                    FormixBuilder(
                      builder: (context, scope) {
                        return Text('Form Valid: ${scope.watchIsValid}');
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
      final showExtraField = FormixFieldID<bool>('showExtra');
      final extraField = FormixFieldID<String>('extra');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: const {'showExtra': false, 'extra': ''},
                child: FormixBuilder(
                  builder: (context, scope) {
                    final showExtra = scope.watchValue(showExtraField) ?? false;
                    return Column(
                      children: [
                        FormixCheckboxFormField(
                          fieldId: showExtraField,
                          title: const Text('Show extra field'),
                        ),
                        if (showExtra) ...[
                          const SizedBox(height: 16),
                          FormixTextFormField(
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

  group('Formix Widget Integration', () {
    testWidgets('should work with dedicated Formix widget', (tester) async {
      final nameField = FormixFieldID<String>('name');
      final emailField = FormixFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: {'name': 'Jane Doe', 'email': 'jane@example.com'},
                fields: [
                  FormixFieldConfig<String>(
                    id: nameField,
                    initialValue: '',
                    validator: (value) =>
                        (value?.isEmpty ?? true) ? 'Required' : null,
                  ),
                  FormixFieldConfig<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) =>
                        (value?.contains('@') ?? false) ? null : 'Invalid',
                  ),
                ],
                child: Column(
                  children: [
                    FormixTextFormField(
                      fieldId: nameField,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    FormixTextFormField(
                      fieldId: emailField,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final provider = Formix.of(context)!;
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
