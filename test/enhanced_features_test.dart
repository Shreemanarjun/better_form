import 'package:better_form/better_form.dart';
import 'package:flutter_test/flutter_test.dart';
// Create a mock controller for testing
class TestController extends BetterFormController {
  TestController({super.initialValue, super.messages});
}

// Custom messages for testing
class SpanishMessages extends DefaultBetterFormMessages {
  const SpanishMessages();
  @override
  String required(String label) => '$label es requerido';
}

void main() {
  group('Enhanced Features', () {
    test('Input Transformer transforms value', () {
      final id = BetterFormFieldID<String>('name');
      final field = BetterFormField<String>(
        id: id,
        initialValue: '',
        transformer: (val) => (val as String).toUpperCase(),
      );

      final controller = TestController();
      controller.registerField(field);

      controller.setValue(id, 'hello');

      expect(controller.getValue(id), 'HELLO');
    });

    test('Cross-Field Validation (via Schema)', () async {
      final passwordId = BetterFormFieldID<String>('password');
      final confirmId = BetterFormFieldID<String>('confirm');

      final schema = FormSchema(
        fields: [
          TextFieldSchema(id: passwordId, initialValue: ''),
          TextFieldSchema(
            id: confirmId,
            initialValue: '',
            stateValidator: (value, values) {
              if (value != values[passwordId.key]) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      );

      final controller = SchemaBasedFormController(schema: schema);

      // Initial state
      expect(controller.validate(), true);

      // Set password
      controller.setValue(passwordId, 'secret');
      controller.setValue(confirmId, 'wrong');

      // Validate
      final result = await controller.validateForm();
      expect(result.isValid, false);
      expect(
        result.getFieldErrors(confirmId),
        contains('Passwords do not match'),
      );

      // Fix confirm
      controller.setValue(confirmId, 'secret');
      final result2 = await controller.validateForm();
      expect(result2.isValid, true);
    });

    test('Async Validation (Manual simulation)', () async {
      final id = BetterFormFieldID<String>('username');
      bool asyncCalled = false;

      final field = BetterFormField<String>(
        id: id,
        initialValue: '',
        asyncValidator: (val) async {
          asyncCalled = true;
          await Future.delayed(const Duration(milliseconds: 10));
          return val == 'taken' ? 'Taken' : null;
        },
        debounceDuration: const Duration(milliseconds: 50),
      );

      final controller = TestController();
      controller.registerField(field);

      // Set value
      controller.setValue(id, 'taken');

      // Should be validating
      var validation = controller.getValidation(id);
      expect(validation.isValidating, true);
      expect(asyncCalled, false); // Debounce

      // Wait for debounce + execution
      await Future.delayed(const Duration(milliseconds: 100));

      expect(asyncCalled, true);
      validation = controller.getValidation(id);
      expect(validation.isValid, false);
      expect(validation.errorMessage, 'Taken');
    });

    test('Touched State', () {
      final id = BetterFormFieldID<String>('email');
      final field = BetterFormField<String>(id: id, initialValue: '');

      final controller = TestController();
      controller.registerField(field);

      expect(controller.isFieldTouched(id), false);

      controller.markAsTouched(id);

      expect(controller.isFieldTouched(id), true);
    });

    test('Serialization and Bulk Update', () {
      final id1 = BetterFormFieldID<String>('name');
      final id2 = BetterFormFieldID<int>('age');

      final controller = TestController(
        initialValue: {'name': 'John', 'age': 30},
      );
      controller.registerField(
        BetterFormField<String>(id: id1, initialValue: 'John'),
      );
      controller.registerField(BetterFormField<int>(id: id2, initialValue: 30));

      // toMap
      expect(controller.toMap(), {'name': 'John', 'age': 30});

      // updateFromMap
      controller.updateFromMap({'name': 'Jane', 'age': 25});
      expect(controller.getValue(id1), 'Jane');
      expect(controller.getValue(id2), 25);
      expect(controller.isDirty, true);

      // getChangedValues
      expect(controller.getChangedValues(), {'name': 'Jane', 'age': 25});
    });

    test('Flexible Reset Options (resetFields)', () {
      final id1 = BetterFormFieldID<String>('name');
      final id2 = BetterFormFieldID<String>('city');

      final controller = TestController(
        initialValue: {'name': 'John', 'city': 'NY'},
      );
      controller.registerField(
        BetterFormField<String>(id: id1, initialValue: 'John'),
      );
      controller.registerField(
        BetterFormField<String>(id: id2, initialValue: 'NY'),
      );

      controller.setValue(id1, 'Jane');
      controller.setValue(id2, 'LA');

      expect(controller.isDirty, true);

      // Reset only name
      controller.resetFields([id1]);
      expect(controller.getValue(id1), 'John');
      expect(controller.getValue(id2), 'LA');
      expect(controller.isFieldDirty(id1), false);
      expect(controller.isFieldDirty(id2), true);
    });

    test('i18n Messages in Validation', () {
      final id = BetterFormFieldID<String>('required_field');

      final controller = TestController(messages: const SpanishMessages());
      controller.registerField(
        BetterFormField<String>(
          id: id,
          initialValue: '',
          label: 'Nombre',
          // Validator uses the messages from the controller's property indirectly
          validator: (v) =>
              v.isEmpty ? controller.messages.required('Nombre') : null,
        ),
      );

      // Force validate
      controller.validate();

      final validation = controller.getValidation(id);
      expect(validation.isValid, false);
      expect(validation.errorMessage, 'Nombre es requerido');
    });
  });
}
