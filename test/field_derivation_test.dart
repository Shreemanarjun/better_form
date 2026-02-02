import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FieldDerivationConfig', () {
    test('equality works correctly', () {
      final fieldId1 = FormixFieldID<String>('field1');
      final fieldId2 = FormixFieldID<String>('field2');
      final targetId = FormixFieldID<String>('target');

      final config1 = FieldDerivationConfig(
        dependencies: [fieldId1, fieldId2],
        derive: (values) => 'derived',
        targetField: targetId,
      );

      final config2 = FieldDerivationConfig(
        dependencies: [fieldId1, fieldId2],
        derive: (values) => 'derived',
        targetField: targetId,
      );

      final config3 = FieldDerivationConfig(
        dependencies: [fieldId2, fieldId1], // Different order
        derive: (values) => 'derived',
        targetField: targetId,
      );

      expect(config1 == config2, true);
      expect(config1 == config3, false); // Order matters for listEquals
    });

    test('hashCode works correctly', () {
      final fieldId1 = FormixFieldID<String>('field1');
      final fieldId2 = FormixFieldID<String>('field2');
      final targetId = FormixFieldID<String>('target');

      final config1 = FieldDerivationConfig(
        dependencies: [fieldId1, fieldId2],
        derive: (values) => 'derived',
        targetField: targetId,
      );

      final config2 = FieldDerivationConfig(
        dependencies: [fieldId1, fieldId2],
        derive: (values) => 'derived',
        targetField: targetId,
      );

      expect(config1.hashCode == config2.hashCode, true);
    });
  });

  group('FormixFieldDerivation', () {
    late FormixFieldID<String> sourceField;
    late FormixFieldID<String> targetField;
    late FormixFieldID<int> ageField;
    late FormixFieldID<DateTime> dobField;

    setUp(() {
      sourceField = FormixFieldID<String>('source');
      targetField = FormixFieldID<String>('target');
      ageField = FormixFieldID<int>('age');
      dobField = FormixFieldID<DateTime>('dob');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      final widget = FormixFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      expect(find.byWidget(widget), findsOneWidget);
      // The widget should render as a SizedBox.shrink
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('derives value on dependency change', (tester) async {
      final widget = FormixFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      // Get controller to check values
      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivation)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivation)),
      );
      final controller = container.read(provider.notifier);

      // Initial value should be derived
      expect(controller.getValue(targetField), 'INITIAL');

      // Change source value
      controller.setValue(sourceField, 'new value');
      await tester.pump();

      expect(controller.getValue(targetField), 'NEW VALUE');
    });

    testWidgets('handles multiple dependencies', (tester) async {
      final firstNameField = FormixFieldID<String>('firstName');
      final lastNameField = FormixFieldID<String>('lastName');
      final fullNameField = FormixFieldID<String>('fullName');

      final widget = FormixFieldDerivation(
        dependencies: [firstNameField, lastNameField],
        derive: (values) =>
            '${values[firstNameField]} ${values[lastNameField]}',
        targetField: fullNameField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'firstName': 'John',
                'lastName': 'Doe',
                'fullName': '',
              },
              fields: [
                FormixFieldConfig(id: firstNameField),
                FormixFieldConfig(id: lastNameField),
                FormixFieldConfig(id: fullNameField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivation)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivation)),
      );
      final controller = container.read(provider.notifier);

      expect(controller.getValue(fullNameField), 'John Doe');

      controller.setValue(firstNameField, 'Jane');
      await tester.pump();
      expect(controller.getValue(fullNameField), 'Jane Doe');
    });

    testWidgets('handles age calculation from date of birth', (tester) async {
      final widget = FormixFieldDerivation(
        dependencies: [dobField],
        derive: (values) {
          final dob = values[dobField] as DateTime?;
          if (dob == null) return 0; // Return 0 instead of null

          final now = DateTime.now();
          int age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
          return age;
        },
        targetField: ageField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'age': 0},
              fields: [
                FormixFieldConfig(
                  id: dobField,
                  initialValue: DateTime(2000, 1, 1),
                ),
                FormixFieldConfig(id: ageField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivation)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivation)),
      );
      final controller = container.read(provider.notifier);

      final expectedAge = DateTime.now().year - 2000;
      expect(controller.getValue(ageField), expectedAge);
    });

    testWidgets('handles errors gracefully in debug mode', (tester) async {
      final widget = FormixFieldDerivation(
        dependencies: [sourceField],
        derive: (values) {
          throw Exception('Test error');
        },
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivation)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivation)),
      );
      final controller = container.read(provider.notifier);

      // Should not crash, target field should keep its initial value
      expect(controller.getValue(targetField), 'target_initial');
    });

    testWidgets('updates listeners when dependencies change', (tester) async {
      final newSourceField = FormixFieldID<String>('newSource');

      final widget = FormixFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
                'newSource': 'new source',
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
                FormixFieldConfig(id: newSourceField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivation)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivation)),
      );
      final controller = container.read(provider.notifier);

      expect(controller.getValue(targetField), 'INITIAL');

      // Update widget with new dependencies
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
                'newSource': 'new source',
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
                FormixFieldConfig(id: newSourceField),
              ],
              child: FormixFieldDerivation(
                dependencies: [newSourceField],
                derive: (values) => values[newSourceField]?.toUpperCase(),
                targetField: targetField,
              ),
            ),
          ),
        ),
      );

      expect(controller.getValue(targetField), 'NEW SOURCE');
    });
  });

  group('FormixFieldDerivations', () {
    late FormixFieldID<String> firstNameField;
    late FormixFieldID<String> lastNameField;
    late FormixFieldID<String> fullNameField;
    late FormixFieldID<String> emailField;
    late FormixFieldID<String> displayNameField;

    setUp(() {
      firstNameField = FormixFieldID<String>('firstName');
      lastNameField = FormixFieldID<String>('lastName');
      fullNameField = FormixFieldID<String>('fullName');
      emailField = FormixFieldID<String>('email');
      displayNameField = FormixFieldID<String>('displayName');
    });

    testWidgets('handles multiple derivations', (tester) async {
      final configs = [
        FieldDerivationConfig(
          dependencies: [firstNameField, lastNameField],
          derive: (values) =>
              '${values[firstNameField]} ${values[lastNameField]}',
          targetField: fullNameField,
        ),
        FieldDerivationConfig(
          dependencies: [firstNameField, emailField],
          derive: (values) =>
              '${values[firstNameField]} <${values[emailField]}>',
          targetField: displayNameField,
        ),
      ];

      final widget = FormixFieldDerivations(derivations: configs);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'firstName': 'John',
                'lastName': 'Doe',
                'fullName': '',
                'email': 'john@example.com',
                'displayName': '',
              },
              fields: [
                FormixFieldConfig(id: firstNameField),
                FormixFieldConfig(id: lastNameField),
                FormixFieldConfig(id: fullNameField),
                FormixFieldConfig(id: emailField),
                FormixFieldConfig(id: displayNameField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldDerivations)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldDerivations)),
      );
      final controller = container.read(provider.notifier);

      expect(controller.getValue(fullNameField), 'John Doe');
      expect(controller.getValue(displayNameField), 'John <john@example.com>');

      controller.setValue(firstNameField, 'Jane');
      await tester.pump();

      expect(controller.getValue(fullNameField), 'Jane Doe');
      expect(controller.getValue(displayNameField), 'Jane <john@example.com>');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      final widget = FormixFieldDerivations(derivations: []);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(initialValue: const {}, fields: [], child: widget),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
