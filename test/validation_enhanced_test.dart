import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('Cross-field Validation', () {
    test('crossFieldValidator works and reacts to dependencies', () async {
      final passwordId = BetterFormFieldID<String>('password');
      final confirmPasswordId = BetterFormFieldID<String>('confirmPassword');

      final controller = RiverpodFormController(
        fields: [
          BetterFormField(id: passwordId, initialValue: ''),
          BetterFormField(
            id: confirmPasswordId,
            initialValue: '',
            dependsOn: [passwordId],
            crossFieldValidator: (value, state) {
              final password = state.getValue(passwordId);
              if (value != password) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      );

      // Initially valid (both empty)
      expect(controller.getValidation(confirmPasswordId).isValid, true);

      // Update password -> confirmPassword should re-validate and become invalid
      controller.setValue(passwordId, 'password123');
      expect(controller.getValidation(confirmPasswordId).isValid, false);
      expect(
        controller.getValidation(confirmPasswordId).errorMessage,
        'Passwords do not match',
      );

      // Update confirmPassword to match -> should become valid
      controller.setValue(confirmPasswordId, 'password123');
      expect(controller.getValidation(confirmPasswordId).isValid, true);
    });

    test('BetterAutovalidateMode.onBlur only validates on touch', () {
      final fieldId = BetterFormFieldID<String>('email');
      final controller = RiverpodFormController(
        fields: [
          BetterFormField(
            id: fieldId,
            initialValue: '',
            validationMode: BetterAutovalidateMode.onBlur,
            validator: (value) => value.isEmpty ? 'Required' : null,
          ),
        ],
      );

      // Should be valid initially (since it's not checked yet in onBlur mode)
      // Wait, initial validation in _createInitialState currently skip if validationMode is not always.
      expect(controller.getValidation(fieldId).isValid, true);

      // Set value to something invalid -> still shouldn't validate
      controller.setValue(fieldId, '');
      expect(controller.getValidation(fieldId).isValid, true);

      // Mark as touched -> should validate
      controller.markAsTouched(fieldId);
      expect(controller.getValidation(fieldId).isValid, false);
    });
  });
}
