import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Native State Restoration', () {
    test('FormixData toMap and fromMap preserve all state', () {
      // Create initial form data with various states
      final originalData = FormixData.withCalculatedCounts(
        values: {'name': 'John Doe', 'email': 'john@example.com', 'age': 25},
        validations: {
          'name': ValidationResult.valid,
          'email': const ValidationResult(isValid: false, errorMessage: 'Invalid email'),
          'age': ValidationResult.validating,
        },
        dirtyStates: {'name': true, 'email': false, 'age': true},
        touchedStates: {'name': true, 'email': true, 'age': false},
        pendingStates: {'name': false, 'email': false, 'age': true},
        isSubmitting: false,
        resetCount: 2,
        currentStep: 1,
      );

      // Serialize to map
      final map = originalData.toMap();

      // Verify map structure
      expect(map['values'], isA<Map>());
      expect(map['validations'], isA<Map>());
      expect(map['dirtyStates'], isA<Map>());
      expect(map['touchedStates'], isA<Map>());
      expect(map['pendingStates'], isA<Map>());
      expect(map['isSubmitting'], false);
      expect(map['resetCount'], 2);
      expect(map['currentStep'], 1);

      // Deserialize from map
      final restoredData = FormixData.fromMap(map);

      // Verify all values are restored correctly
      expect(restoredData.values['name'], 'John Doe');
      expect(restoredData.values['email'], 'john@example.com');
      expect(restoredData.values['age'], 25);

      // Verify validation states
      expect(restoredData.validations['name']?.isValid, true);
      expect(restoredData.validations['email']?.isValid, false);
      expect(restoredData.validations['email']?.errorMessage, 'Invalid email');
      expect(restoredData.validations['age']?.isValidating, true);

      // Verify dirty states
      expect(restoredData.dirtyStates['name'], true);
      expect(restoredData.dirtyStates['email'], false);
      expect(restoredData.dirtyStates['age'], true);

      // Verify touched states
      expect(restoredData.touchedStates['name'], true);
      expect(restoredData.touchedStates['email'], true);
      expect(restoredData.touchedStates['age'], false);

      // Verify pending states
      expect(restoredData.pendingStates['name'], false);
      expect(restoredData.pendingStates['email'], false);
      expect(restoredData.pendingStates['age'], true);

      // Verify metadata
      expect(restoredData.isSubmitting, false);
      expect(restoredData.resetCount, 2);
      expect(restoredData.currentStep, 1);

      // Verify calculated counts
      expect(restoredData.errorCount, 1); // Only email is invalid
      expect(restoredData.dirtyCount, 2); // name and age are dirty
      expect(restoredData.pendingCount, 2); // age is pending + validating
    });

    test('ValidationResult toMap and fromMap work correctly', () {
      // Test valid result
      const validResult = ValidationResult.valid;
      final validMap = validResult.toMap();
      final restoredValid = ValidationResult.fromMap(validMap);
      expect(restoredValid.isValid, true);
      expect(restoredValid.errorMessage, null);
      expect(restoredValid.isValidating, false);

      // Test invalid result with error
      const invalidResult = ValidationResult(
        isValid: false,
        errorMessage: 'This field is required',
      );
      final invalidMap = invalidResult.toMap();
      final restoredInvalid = ValidationResult.fromMap(invalidMap);
      expect(restoredInvalid.isValid, false);
      expect(restoredInvalid.errorMessage, 'This field is required');
      expect(restoredInvalid.isValidating, false);

      // Test validating result
      const validatingResult = ValidationResult.validating;
      final validatingMap = validatingResult.toMap();
      final restoredValidating = ValidationResult.fromMap(validatingMap);
      expect(restoredValidating.isValid, true);
      expect(restoredValidating.isValidating, true);
    });
  });
}
