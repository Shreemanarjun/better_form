import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('Form Utilities', () {
    late BetterFormController controller;

    setUp(() {
      controller = BetterFormController(initialValue: {
        'name': 'John',
        'email': 'john@example.com',
        'age': 25,
        'active': true,
      });

      // Register fields
      controller.registerField(BetterFormField<String>(
        id: BetterFormFieldID<String>('name'),
        initialValue: 'John',
      ));

      controller.registerField(BetterFormField<String>(
        id: BetterFormFieldID<String>('email'),
        initialValue: 'john@example.com',
        validator: (value) => value.contains('@') ? null : 'Invalid email',
      ));

      controller.registerField(BetterFormField<num>(
        id: BetterFormFieldID<num>('age'),
        initialValue: 25,
      ));

      controller.registerField(BetterFormField<bool>(
        id: BetterFormFieldID<bool>('active'),
        initialValue: true,
      ));
    });

    tearDown(() {
      controller.dispose();
    });

    group('Form Serialization - Dirty State Detection', () {
      test('should return empty map when form is clean', () {
        final changedValues = controller.getChangedValues();
        expect(changedValues, isEmpty);
      });

      test('should return only changed values when form is dirty', () {
        // Modify some fields
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');
        controller.setValue(BetterFormFieldID<num>('age'), 30);

        final changedValues = controller.getChangedValues();

        expect(changedValues.length, 2);
        expect(changedValues['name'], 'Jane');
        expect(changedValues['age'], 30);
        expect(changedValues.containsKey('email'), false);
        expect(changedValues.containsKey('active'), false);
      });

      test('should detect when field changes back to initial value', () {
        // Modify field
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');
        expect(controller.getChangedValues()['name'], 'Jane');

        // Change back to initial value
        controller.setValue(BetterFormFieldID<String>('name'), 'John');
        final changedValues = controller.getChangedValues();
        expect(changedValues.containsKey('name'), false);
      });

      test('should handle different data types', () {
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');
        controller.setValue(BetterFormFieldID<num>('age'), 30);
        controller.setValue(BetterFormFieldID<bool>('active'), false);

        final changedValues = controller.getChangedValues();

        expect(changedValues['name'], isA<String>());
        expect(changedValues['age'], isA<num>());
        expect(changedValues['active'], isA<bool>());
      });
    });

    group('Reset Options', () {
      test('should reset to initial values by default', () {
        // Modify fields
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');
        controller.setValue(BetterFormFieldID<num>('age'), 30);
        controller.setValue(BetterFormFieldID<bool>('active'), false);

        expect(controller.isDirty, true);

        // Reset to initial values
        controller.reset();

        expect(controller.getValue(BetterFormFieldID<String>('name')), 'John');
        expect(controller.getValue(BetterFormFieldID<num>('age')), 25);
        expect(controller.getValue(BetterFormFieldID<bool>('active')), true);
        expect(controller.isDirty, false);
      });

      test('should reset to initial values when explicitly specified', () {
        // Modify fields
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');

        // Reset with explicit strategy
        controller.reset(strategy: ResetStrategy.initialValues);

        expect(controller.getValue(BetterFormFieldID<String>('name')), 'John');
        expect(controller.isDirty, false);
      });

      test('should clear all fields when using clear strategy', () {
        // Modify fields
        controller.setValue(BetterFormFieldID<String>('name'), 'Jane');
        controller.setValue(BetterFormFieldID<num>('age'), 30);

        // Reset with clear strategy
        controller.reset(strategy: ResetStrategy.clear);

        // Fields should be cleared to their empty values
        expect(controller.getValue(BetterFormFieldID<String>('name')), '');
        expect(controller.getValue(BetterFormFieldID<num>('age')), 0);
        expect(controller.getValue(BetterFormFieldID<bool>('active')), false);
        expect(controller.isDirty, false);
      });

      test('should reset validation state when resetting', () {
        // Set invalid value
        controller.setValue(BetterFormFieldID<String>('email'), 'invalid-email');

        // Should be invalid
        expect(controller.getValidation(BetterFormFieldID<String>('email')).isValid, false);

        // Reset
        controller.reset();

        // Should be valid again (back to initial valid value)
        expect(controller.getValidation(BetterFormFieldID<String>('email')).isValid, true);
      });

      test('should reset touched state when resetting', () {
        final nameField = BetterFormFieldID<String>('name');

        // Mark as touched
        controller.markAsTouched(nameField);
        expect(controller.isFieldTouched(nameField), true);

        // Reset
        controller.reset();

        // Should not be touched anymore
        expect(controller.isFieldTouched(nameField), false);
      });
    });

    group('Dirty State Tracking', () {
      test('should track dirty state correctly', () {
        final nameField = BetterFormFieldID<String>('name');

        expect(controller.isFieldDirty(nameField), false);
        expect(controller.isDirty, false);

        // Modify field
        controller.setValue(nameField, 'Jane');

        expect(controller.isFieldDirty(nameField), true);
        expect(controller.isDirty, true);

        // Reset
        controller.reset();

        expect(controller.isFieldDirty(nameField), false);
        expect(controller.isDirty, false);
      });

      test('should handle null vs non-null changes', () {
        // Add a field that can be null
        final optionalField = BetterFormFieldID<String?>('optional');
        controller.registerField(BetterFormField<String?>(
          id: optionalField,
          initialValue: null,
        ));

        expect(controller.isFieldDirty(optionalField), false);

        // Set to non-null
        controller.setValue(optionalField, 'value');
        expect(controller.isFieldDirty(optionalField), true);

        // Set back to null
        controller.setValue(optionalField, null);
        expect(controller.isFieldDirty(optionalField), false);
      });
    });
  });
}
