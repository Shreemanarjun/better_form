import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Reset with Clear Errors', () {
    late FormixFieldID<String> field1;

    setUp(() {
      field1 = const FormixFieldID<String>('field1');
    });

    test('reset() with clearErrors: true avoids showing errors for invalid initial values', () {
      final controller = FormixController(
        fields: [
          FormixField<String>(
            id: field1,
            initialValue: '',
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
        ],
      );

      // Initially it should have an error because the initial value is empty and it validates by default in reset/constructor
      expect(controller.getValidation(field1).isValid, false);

      // Reset without clearErrors (default)
      controller.setValue(field1, 'temp');
      controller.reset();
      expect(controller.getValidation(field1).isValid, false);

      // Reset with clearErrors: true
      controller.setValue(field1, 'temp');
      controller.reset(clearErrors: true);
      expect(controller.getValidation(field1).isValid, true);
    });

    test('resetToValues() with clearErrors: true avoids showing errors for new empty values', () {
      final controller = FormixController(
        fields: [
          FormixField<String>(
            id: field1,
            initialValue: 'initial',
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
        ],
      );

      // Reset to a value that would be invalid (empty string)
      controller.resetToValues({'field1': ''}, clearErrors: true);

      expect(controller.getValue(field1), '');
      expect(controller.getValidation(field1).isValid, true);
    });

    test('resetFields() with clearErrors: true avoids showing errors for specific fields', () {
      const field2 = FormixFieldID<String>('field2');
      final controller = FormixController(
        fields: [
          FormixField<String>(
            id: field1,
            initialValue: '',
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
          FormixField<String>(
            id: field2,
            initialValue: '',
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
        ],
      );

      // Change both and reset only field1 with clearErrors
      controller.setValue(field1, 'val1');
      controller.setValue(field2, 'val2');

      controller.resetFields([field1, field2], clearErrors: true);

      expect(controller.getValidation(field1).isValid, true);
      expect(controller.getValidation(field2).isValid, true);
    });

    test('resetFields() without clearErrors: false should show errors for invalid values', () {
      final controller = FormixController(
        fields: [
          FormixField<String>(
            id: field1,
            initialValue: '',
            validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
          ),
        ],
      );

      controller.setValue(field1, 'val1');
      controller.resetFields([field1], clearErrors: false);

      expect(controller.getValidation(field1).isValid, false);
    });

    test('reset(clearErrors: true) cancels pending async validation', () async {
      final completer = Completer<String?>();
      final controller = FormixController(
        fields: [
          FormixField<String>(
            id: field1,
            initialValue: '',
            asyncValidator: (v) => completer.future,
          ),
        ],
      );

      // Start async validation
      controller.setValue(field1, 'typing...');
      expect(controller.getValidation(field1).isValidating, true);

      // Reset with clearErrors
      controller.reset(clearErrors: true);
      expect(controller.getValidation(field1).isValid, true);
      expect(controller.getValidation(field1).isValidating, false);

      // Complete the future - should NOT affect state because it was cancelled
      completer.complete('Error');
      await Future.delayed(const Duration(milliseconds: 500));

      expect(controller.getValidation(field1).isValid, true);
      expect(controller.getValidation(field1).isValidating, false);
    });
  });
}
