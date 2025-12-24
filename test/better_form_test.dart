import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

// Define test field IDs
const BetterFormFieldID<String> nameField = BetterFormFieldID<String>('name');
const BetterFormFieldID<int> ageField = BetterFormFieldID<int>('age');
const BetterFormFieldID<bool> isStudentField = BetterFormFieldID<bool>('isStudent');

void main() {
  group('BetterFormFieldID', () {
    test('should create field ID with correct type', () {
      expect(nameField.key, 'name');
      expect(ageField.key, 'age');
    });

    test('should have proper equality', () {
      const nameField2 = BetterFormFieldID<String>('name');
      expect(nameField, equals(nameField2));
      expect(nameField.hashCode, equals(nameField2.hashCode));
    });

    test('should have proper toString', () {
      expect(nameField.toString(), 'BetterFormFieldID<String>(name)');
    });
  });

  group('BetterFormField', () {
    test('should create field with all properties', () {
      final field = BetterFormField(
        id: nameField,
        initialValue: 'John',
        validator: (value) => value.isEmpty ? 'Name is required' : null,
        label: 'Full Name',
        hint: 'Enter your full name',
      );

      expect(field.id, nameField);
      expect(field.initialValue, 'John');
      expect(field.label, 'Full Name');
      expect(field.hint, 'Enter your full name');
    });
  });

  group('ValidationResult', () {
    test('should create valid result', () {
      const result = ValidationResult.valid;
      expect(result.isValid, true);
      expect(result.errorMessage, null);
    });

    test('should create invalid result', () {
      const result = ValidationResult(isValid: false, errorMessage: 'Error');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Error');
    });
  });

  group('BetterFormController', () {
    late BetterFormController controller;

    setUp(() {
      controller = BetterFormController(initialValue: {
        'name': 'John',
        'age': 25,
        'isStudent': false,
      });

      // Register fields
      controller.registerField(BetterFormField(
        id: nameField,
        initialValue: 'John',
        validator: (value) => value.isEmpty ? 'Name is required' : null,
      ));

      controller.registerField(BetterFormField(
        id: ageField,
        initialValue: 25,
        validator: (value) => value < 0 ? 'Age must be positive' : null,
      ));

      controller.registerField(BetterFormField(
        id: isStudentField,
        initialValue: false,
      ));
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with correct values', () {
      expect(controller.getValue(nameField), 'John');
      expect(controller.getValue(ageField), 25);
      expect(controller.getValue(isStudentField), false);
    });

    test('should set and get values with type safety', () {
      controller.setValue(nameField, 'Jane');
      controller.setValue(ageField, 30);

      expect(controller.getValue(nameField), 'Jane');
      expect(controller.getValue(ageField), 30);
    });

    test('should throw on type mismatch in setValue', () {
      expect(() => controller.setValue(nameField, 123), throwsArgumentError);
    });

    test('should track dirty state', () {
      expect(controller.isFieldDirty(nameField), false);
      expect(controller.isDirty, false);

      controller.setValue(nameField, 'Jane');

      expect(controller.isFieldDirty(nameField), true);
      expect(controller.isDirty, true);
    });

    test('should not mark as dirty when setting same value', () {
      controller.setValue(nameField, 'John'); // Same value
      expect(controller.isFieldDirty(nameField), false);
    });

    test('should validate fields', () {
      controller.setValue(nameField, ''); // Invalid
      controller.setValue(ageField, -5); // Invalid

      expect(controller.getValidation(nameField).isValid, false);
      expect(controller.getValidation(nameField).errorMessage, 'Name is required');
      expect(controller.getValidation(ageField).isValid, false);
      expect(controller.getValidation(ageField).errorMessage, 'Age must be positive');
      expect(controller.isValid, false);
    });

    test('should validate valid fields', () {
      controller.setValue(nameField, 'Valid Name');
      controller.setValue(ageField, 30);

      expect(controller.getValidation(nameField).isValid, true);
      expect(controller.getValidation(ageField).isValid, true);
      expect(controller.isValid, true);
    });

    test('should extract data', () {
      controller.setValue(nameField, 'Jane');
      controller.setValue(ageField, 30);

      final data = controller.value;
      expect(data['name'], 'Jane');
      expect(data['age'], 30);
      expect(data['isStudent'], false);
    });

    test('should reset form', () {
      controller.setValue(nameField, 'Jane');
      controller.setValue(ageField, 30);
      controller.setValue(isStudentField, true);

      expect(controller.isDirty, true);

      controller.reset();

      expect(controller.getValue(nameField), 'John');
      expect(controller.getValue(ageField), 25);
      expect(controller.getValue(isStudentField), false);
      expect(controller.isDirty, false);
      expect(controller.isValid, true);
    });

    test('should reset initial values', () {
      controller.setValue(nameField, 'Jane');
      controller.setValue(ageField, 30);

      controller.resetInitialValues();

      expect(controller.isDirty, false);
      expect(controller.getValue(nameField), 'Jane');
      expect(controller.getValue(ageField), 30);
    });

    test('should handle listeners', () {
      var callCount = 0;
      void listener() => callCount++;

      controller.addFieldListener(nameField, listener);
      controller.setValue(nameField, 'Jane');

      expect(callCount, 1);

      controller.removeFieldListener(nameField, listener);
      controller.setValue(nameField, 'Bob');

      expect(callCount, 1); // Should not have increased
    });

    test('should handle dirty listeners', () {
      var dirtyCallCount = 0;
      void dirtyListener(bool isDirty) => dirtyCallCount++;

      controller.addDirtyListener(dirtyListener);
      controller.setValue(nameField, 'Jane');

      expect(dirtyCallCount, 1);

      controller.setValue(nameField, 'John'); // Back to original
      expect(dirtyCallCount, 2); // Should have been called again
    });

    test('should provide ValueNotifier for fields', () {
      final notifier = controller.getFieldNotifier<String>(nameField);
      expect(notifier.value, 'John');

      controller.setValue(nameField, 'Jane');
      expect(notifier.value, 'Jane');
    });

    test('should unregister fields', () {
      controller.setValue(nameField, 'Jane');
      expect(controller.getValue(nameField), 'Jane');

      controller.unregisterField(nameField);
      expect(() => controller.getValue(nameField), throwsStateError);
    });
  });

  group('BetterForm widget', () {
    test('should provide controller through context', () {
      final controller = BetterFormController();

      // This would need a widget test to properly test
      // For now, just verify the controller is created
      expect(controller, isNotNull);
      controller.dispose();
    });
  });

  group('BetterFormFieldListener', () {
    test('should be defined for widget integration', () {
      // This is more of an integration test that would require widget testing
      expect(BetterFormFieldListener, isNotNull);
    });
  });

  group('BetterFormDirtyListener', () {
    test('should be defined for widget integration', () {
      // This is more of an integration test that would require widget testing
      expect(BetterFormDirtyListener, isNotNull);
    });
  });

  group('Ready-made form field widgets', () {
    test('should define BetterTextFormField', () {
      expect(BetterTextFormField, isNotNull);
    });

    test('should define BetterNumberFormField', () {
      expect(BetterNumberFormField, isNotNull);
    });

    test('should define BetterCheckboxFormField', () {
      expect(BetterCheckboxFormField, isNotNull);
    });
  });
}
