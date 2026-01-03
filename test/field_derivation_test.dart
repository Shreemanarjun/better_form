import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/src/controllers/field_id.dart';
import 'package:better_form/src/controllers/riverpod_controller.dart';
import 'package:better_form/src/widgets/field_derivation.dart';
import 'package:better_form/src/widgets/riverpod_form_fields.dart';

void main() {
  group('FieldDerivationConfig', () {
    test('equality works correctly', () {
      final fieldId1 = BetterFormFieldID<String>('field1');
      final fieldId2 = BetterFormFieldID<String>('field2');
      final targetId = BetterFormFieldID<String>('target');

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
      final fieldId1 = BetterFormFieldID<String>('field1');
      final fieldId2 = BetterFormFieldID<String>('field2');
      final targetId = BetterFormFieldID<String>('target');

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

  group('BetterFormFieldDerivation', () {
    late BetterFormFieldID<String> sourceField;
    late BetterFormFieldID<String> targetField;
    late BetterFormFieldID<int> ageField;
    late BetterFormFieldID<DateTime> dobField;

    setUp(() {
      sourceField = BetterFormFieldID<String>('source');
      targetField = BetterFormFieldID<String>('target');
      ageField = BetterFormFieldID<int>('age');
      dobField = BetterFormFieldID<DateTime>('dob');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      final widget = BetterFormFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {'source': 'initial', 'target': 'target_initial'},
              fields: [
                BetterFormFieldConfig(id: sourceField),
                BetterFormFieldConfig(id: targetField),
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
      final widget = BetterFormFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {'source': 'initial', 'target': 'target_initial'},
              fields: [
                BetterFormFieldConfig(id: sourceField),
                BetterFormFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      // Get controller to check values
      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivation)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivation)));
      final controller = container.read(provider.notifier) as BetterFormController;

      // Initial value should be derived
      expect(controller.getValue(targetField), 'INITIAL');

      // Change source value
      controller.setValue(sourceField, 'new value');
      await tester.pump();

      expect(controller.getValue(targetField), 'NEW VALUE');
    });

    testWidgets('handles multiple dependencies', (tester) async {
      final firstNameField = BetterFormFieldID<String>('firstName');
      final lastNameField = BetterFormFieldID<String>('lastName');
      final fullNameField = BetterFormFieldID<String>('fullName');

      final widget = BetterFormFieldDerivation(
        dependencies: [firstNameField, lastNameField],
        derive: (values) =>
            '${values[firstNameField]} ${values[lastNameField]}',
        targetField: fullNameField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {
                'firstName': 'John',
                'lastName': 'Doe',
                'fullName': '',
              },
              fields: [
                BetterFormFieldConfig(id: firstNameField),
                BetterFormFieldConfig(id: lastNameField),
                BetterFormFieldConfig(id: fullNameField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivation)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivation)));
      final controller = container.read(provider.notifier) as BetterFormController;

      expect(controller.getValue(fullNameField), 'John Doe');

      controller.setValue(firstNameField, 'Jane');
      await tester.pump();
      expect(controller.getValue(fullNameField), 'Jane Doe');
    });

    testWidgets('handles age calculation from date of birth', (tester) async {
      final widget = BetterFormFieldDerivation(
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
            home: BetterForm(
              initialValue: const {
                'age': 0,
              },
              fields: [
                BetterFormFieldConfig(id: dobField, initialValue: DateTime(2000, 1, 1)),
                BetterFormFieldConfig(id: ageField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivation)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivation)));
      final controller = container.read(provider.notifier) as BetterFormController;

      final expectedAge = DateTime.now().year - 2000;
      expect(controller.getValue(ageField), expectedAge);
    });

    testWidgets('handles errors gracefully in debug mode', (tester) async {
      final widget = BetterFormFieldDerivation(
        dependencies: [sourceField],
        derive: (values) {
          throw Exception('Test error');
        },
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {'source': 'initial', 'target': 'target_initial'},
              fields: [
                BetterFormFieldConfig(id: sourceField),
                BetterFormFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivation)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivation)));
      final controller = container.read(provider.notifier) as BetterFormController;

      // Should not crash, target field should keep its initial value
      expect(controller.getValue(targetField), 'target_initial');
    });

    testWidgets('updates listeners when dependencies change', (tester) async {
      final newSourceField = BetterFormFieldID<String>('newSource');

      final widget = BetterFormFieldDerivation(
        dependencies: [sourceField],
        derive: (values) => values[sourceField]?.toUpperCase(),
        targetField: targetField,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
                'newSource': 'new source',
              },
              fields: [
                BetterFormFieldConfig(id: sourceField),
                BetterFormFieldConfig(id: targetField),
                BetterFormFieldConfig(id: newSourceField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivation)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivation)));
      final controller = container.read(provider.notifier) as BetterFormController;

      expect(controller.getValue(targetField), 'INITIAL');

      // Update widget with new dependencies
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {
                'source': 'initial',
                'target': 'target_initial',
                'newSource': 'new source',
              },
              fields: [
                BetterFormFieldConfig(id: sourceField),
                BetterFormFieldConfig(id: targetField),
                BetterFormFieldConfig(id: newSourceField),
              ],
              child: BetterFormFieldDerivation(
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

  group('BetterFormFieldDerivations', () {
    late BetterFormFieldID<String> firstNameField;
    late BetterFormFieldID<String> lastNameField;
    late BetterFormFieldID<String> fullNameField;
    late BetterFormFieldID<String> emailField;
    late BetterFormFieldID<String> displayNameField;

    setUp(() {
      firstNameField = BetterFormFieldID<String>('firstName');
      lastNameField = BetterFormFieldID<String>('lastName');
      fullNameField = BetterFormFieldID<String>('fullName');
      emailField = BetterFormFieldID<String>('email');
      displayNameField = BetterFormFieldID<String>('displayName');
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

      final widget = BetterFormFieldDerivations(derivations: configs);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {
                'firstName': 'John',
                'lastName': 'Doe',
                'fullName': '',
                'email': 'john@example.com',
                'displayName': '',
              },
              fields: [
                BetterFormFieldConfig(id: firstNameField),
                BetterFormFieldConfig(id: lastNameField),
                BetterFormFieldConfig(id: fullNameField),
                BetterFormFieldConfig(id: emailField),
                BetterFormFieldConfig(id: displayNameField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = BetterForm.of(tester.element(find.byType(BetterFormFieldDerivations)))!;
      final container = ProviderScope.containerOf(tester.element(find.byType(BetterFormFieldDerivations)));
      final controller = container.read(provider.notifier) as BetterFormController;

      expect(controller.getValue(fullNameField), 'John Doe');
      expect(controller.getValue(displayNameField), 'John <john@example.com>');

      controller.setValue(firstNameField, 'Jane');
      await tester.pump();

      expect(controller.getValue(fullNameField), 'Jane Doe');
      expect(controller.getValue(displayNameField), 'Jane <john@example.com>');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      final widget = BetterFormFieldDerivations(derivations: []);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BetterForm(
              initialValue: const {},
              fields: [],
              child: widget,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });
}
