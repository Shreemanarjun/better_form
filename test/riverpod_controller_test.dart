import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

// Mock persistence for testing
class MockPersistence implements BetterFormPersistence {
  @override
  Future<Map<String, dynamic>?> getSavedState(String formId) async => null;

  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> data) async {}

  @override
  Future<void> clearSavedState(String formId) async {}
}

void main() {
  group('FormState', () {
    test('constructor creates correct initial state', () {
      final state = FormState(
        values: {'field1': 'value1'},
        validations: {'field1': ValidationResult.valid},
        dirtyStates: {'field1': false},
        touchedStates: {'field1': false},
        isSubmitting: false,
      );

      expect(state.values, {'field1': 'value1'});
      expect(state.validations, {'field1': ValidationResult.valid});
      expect(state.dirtyStates, {'field1': false});
      expect(state.touchedStates, {'field1': false});
      expect(state.isSubmitting, false);
    });

    test('copyWith creates new instance with updated values', () {
      final original = FormState(
        values: {'field1': 'value1'},
        validations: {'field1': ValidationResult.valid},
        dirtyStates: {'field1': false},
        touchedStates: {'field1': false},
        isSubmitting: false,
      );

      final copy = original.copyWith(
        values: {'field1': 'value2'},
        isSubmitting: true,
      );

      expect(copy.values, {'field1': 'value2'});
      expect(copy.isSubmitting, true);
      expect(copy.validations, original.validations); // Unchanged
    });

    test('isValid returns true when all validations pass', () {
      final state = FormState(
        validations: {
          'field1': ValidationResult.valid,
          'field2': ValidationResult.valid,
        },
      );

      expect(state.isValid, true);
    });

    test('isValid returns false when any validation fails', () {
      final state = FormState(
        validations: {
          'field1': ValidationResult.valid,
          'field2': ValidationResult(isValid: false, errorMessage: 'Error'),
        },
      );

      expect(state.isValid, false);
    });

    test('isDirty returns true when any field is dirty', () {
      final state = FormState(
        dirtyStates: {
          'field1': false,
          'field2': true,
        },
      );

      expect(state.isDirty, true);
    });

    test('isDirty returns false when no fields are dirty', () {
      final state = FormState(
        dirtyStates: {
          'field1': false,
          'field2': false,
        },
      );

      expect(state.isDirty, false);
    });

    test('getValue returns typed value when type matches', () {
      final state = FormState(values: {'field1': 'test'});

      expect(state.getValue<String>(BetterFormFieldID<String>('field1')), 'test');
    });

    test('getValue returns null when type does not match', () {
      final state = FormState(values: {'field1': 'test'});

      expect(state.getValue<int>(BetterFormFieldID<int>('field1')), null);
    });

    test('getValidation returns validation result for field', () {
      final validation = ValidationResult(isValid: false, errorMessage: 'Error');
      final state = FormState(validations: {'field1': validation});

      expect(state.getValidation(BetterFormFieldID<String>('field1')), validation);
    });

    test('getValidation returns valid result for unregistered field', () {
      final state = FormState();

      expect(state.getValidation(BetterFormFieldID<String>('field1')).isValid, true);
    });

    test('isFieldDirty returns dirty state for field', () {
      final state = FormState(dirtyStates: {'field1': true});

      expect(state.isFieldDirty(BetterFormFieldID<String>('field1')), true);
      expect(state.isFieldDirty(BetterFormFieldID<String>('field2')), false);
    });

    test('isFieldTouched returns touched state for field', () {
      final state = FormState(touchedStates: {'field1': true});

      expect(state.isFieldTouched(BetterFormFieldID<String>('field1')), true);
      expect(state.isFieldTouched(BetterFormFieldID<String>('field2')), false);
    });
  });

  group('BetterFormFieldConfig', () {
    test('constructor creates config correctly', () {
      final id = BetterFormFieldID<String>('test');
      final config = BetterFormFieldConfig<String>(
        id: id,
        initialValue: 'initial',
        validator: (v) => v.isEmpty ? 'Required' : null,
        label: 'Test Field',
        hint: 'Enter value',
        debounceDuration: const Duration(milliseconds: 500),
      );

      expect(config.id, id);
      expect(config.initialValue, 'initial');
      expect(config.label, 'Test Field');
      expect(config.hint, 'Enter value');
      expect(config.debounceDuration, const Duration(milliseconds: 500));
    });

    test('toField converts config to field correctly', () {
      final id = BetterFormFieldID<String>('test');
      final config = BetterFormFieldConfig<String>(
        id: id,
        initialValue: 'initial',
        validator: (v) => v.isEmpty ? 'Required' : null,
        label: 'Test Field',
      );

      final field = config.toField();

      expect(field.id, id);
      expect(field.initialValue, 'initial');
      expect(field.label, 'Test Field');
      expect(field.validator, isNotNull);
    });

    test('equality works correctly', () {
      final id1 = BetterFormFieldID<String>('test');
      final id2 = BetterFormFieldID<String>('test');

      final config1 = BetterFormFieldConfig<String>(id: id1, initialValue: 'test');
      final config2 = BetterFormFieldConfig<String>(id: id2, initialValue: 'test');
      final config3 = BetterFormFieldConfig<String>(id: id1, initialValue: 'different');

      expect(config1 == config2, true);
      expect(config1 == config3, false);
    });

    test('hashCode works correctly', () {
      final id = BetterFormFieldID<String>('test');
      final config1 = BetterFormFieldConfig<String>(id: id, initialValue: 'test');
      final config2 = BetterFormFieldConfig<String>(id: id, initialValue: 'test');

      expect(config1.hashCode, config2.hashCode);
    });
  });

  group('RiverpodFormController', () {
    late BetterFormFieldID<String> stringField;
    late BetterFormFieldID<int> intField;

    setUp(() {
      stringField = BetterFormFieldID<String>('string_field');
      intField = BetterFormFieldID<int>('int_field');
    });

    test('constructor initializes with correct state', () {
      final controller = RiverpodFormController(
        initialValue: {'field1': 'value1'},
        fields: [
          BetterFormField<String>(
            id: BetterFormFieldID<String>('field1'),
            initialValue: 'value1',
          ),
        ],
      );

      expect(controller.state.values['field1'], 'value1');
      expect(controller.initialValue['field1'], 'value1');
      expect(controller.isFieldRegistered(BetterFormFieldID<String>('field1')), true);
    });



    test('getValue returns correct typed value', () {
      final controller = RiverpodFormController(
        initialValue: {'field1': 'test'},
      );

      expect(controller.getValue(BetterFormFieldID<String>('field1')), 'test');
    });

    test('setValue updates value and triggers validation', () {
      final controller = RiverpodFormController(
        fields: [
          BetterFormField<String>(
            id: stringField,
            initialValue: '',
            validator: (v) => v.isEmpty ? 'Required' : null,
          ),
        ],
      );

      controller.setValue(stringField, 'valid');

      expect(controller.getValue(stringField), 'valid');
      expect(controller.getValidation(stringField).isValid, true);
      expect(controller.isFieldDirty(stringField), true);
    });

    test('setValue throws on type mismatch', () {
      final controller = RiverpodFormController(
        initialValue: {'field1': 'string'},
      );

      expect(
        () => controller.setValue(BetterFormFieldID<int>('field1'), 123),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('registerField adds field definition and initializes state', () {
      final controller = RiverpodFormController();

      final field = BetterFormField<String>(
        id: stringField,
        initialValue: 'initial',
        validator: (v) => v.isEmpty ? 'Required' : null,
      );

      controller.registerField(field);

      expect(controller.isFieldRegistered(stringField), true);
      expect(controller.getValue(stringField), 'initial');
      expect(controller.getValidation(stringField).isValid, true);
    });

    test('unregisterField removes field from state', () {
      final controller = RiverpodFormController(
        fields: [
          BetterFormField<String>(id: stringField, initialValue: 'test'),
        ],
      );

      expect(controller.isFieldRegistered(stringField), true);

      controller.unregisterField(stringField);

      expect(controller.isFieldRegistered(stringField), false);
      expect(controller.state.values.containsKey('string_field'), false);
    });

    test('markAsTouched updates touched state', () {
      final controller = RiverpodFormController();

      expect(controller.isFieldTouched(stringField), false);

      controller.markAsTouched(stringField);

      expect(controller.isFieldTouched(stringField), true);
    });

    test('setSubmitting updates submitting state', () {
      final controller = RiverpodFormController();

      expect(controller.isSubmitting, false);

      controller.setSubmitting(true);

      expect(controller.isSubmitting, true);
    });

    test('validate runs validation on all fields', () {
      final controller = RiverpodFormController(
        fields: [
          BetterFormField<String>(
            id: stringField,
            initialValue: '',
            validator: (v) => v.isEmpty ? 'Required' : null,
          ),
          BetterFormField<int>(
            id: intField,
            initialValue: 5,
            validator: (v) => (v) < 10 ? 'Must be at least 10' : null,
          ),
        ],
      );

      final isValid = controller.validate();

      expect(isValid, false);
      expect(controller.getValidation(stringField).isValid, false);
      expect(controller.getValidation(intField).isValid, false);
    });

    test('reset restores initial values', () {
      final controller = RiverpodFormController(
        initialValue: {'field1': 'initial'},
        fields: [
          BetterFormField<String>(
            id: BetterFormFieldID<String>('field1'),
            initialValue: 'initial',
          ),
        ],
      );

      controller.setValue(BetterFormFieldID<String>('field1'), 'changed');
      expect(controller.getValue(BetterFormFieldID<String>('field1')), 'changed');

      controller.reset();

      expect(controller.getValue(BetterFormFieldID<String>('field1')), 'initial');
      expect(controller.isFieldDirty(BetterFormFieldID<String>('field1')), false);
    });

    test('resetFields resets specific fields', () {
      final field1 = BetterFormFieldID<String>('field1');
      final field2 = BetterFormFieldID<String>('field2');

      final controller = RiverpodFormController(
        initialValue: {'field1': 'initial1', 'field2': 'initial2'},
        fields: [
          BetterFormField<String>(id: field1, initialValue: 'initial1'),
          BetterFormField<String>(id: field2, initialValue: 'initial2'),
        ],
      );

      controller.setValue(field1, 'changed1');
      controller.setValue(field2, 'changed2');

      controller.resetFields([field1]);

      expect(controller.getValue(field1), 'initial1');
      expect(controller.getValue(field2), 'changed2');
    });

    test('async validation works with debouncing', () async {
      final controller = RiverpodFormController(
        fields: [
          BetterFormField<String>(
            id: stringField,
            initialValue: '',
            asyncValidator: (v) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return v.isEmpty ? 'Async required' : null;
            },
            debounceDuration: const Duration(milliseconds: 50),
          ),
        ],
      );

      controller.setValue(stringField, 'test');

      // Should initially be validating
      expect(controller.getValidation(stringField).isValidating, true);

      // Wait for async validation to complete
      await Future.delayed(const Duration(milliseconds: 200));

      expect(controller.getValidation(stringField).isValid, true);
    });


  });

  group('BetterFormController', () {
    test('extends RiverpodFormController correctly', () {
      final controller = BetterFormController(
        initialValue: {'field1': 'value1'},
      );

      expect(controller.values, {'field1': 'value1'});
      expect(controller.isDirty, false);
      expect(controller.isSubmitting, false);
    });

    test('getFieldNotifier creates and caches notifiers', () {
      final controller = BetterFormController();
      final fieldId = BetterFormFieldID<String>('test');

      final notifier1 = controller.getFieldNotifier(fieldId);
      final notifier2 = controller.getFieldNotifier(fieldId);

      expect(notifier1, same(notifier2));
      expect(notifier1.value, null);
    });

    test('fieldValidationNotifier creates and caches notifiers', () {
      final controller = BetterFormController();
      final fieldId = BetterFormFieldID<String>('test');

      final notifier1 = controller.fieldValidationNotifier(fieldId);
      final notifier2 = controller.fieldValidationNotifier(fieldId);

      expect(notifier1, same(notifier2));
      expect(notifier1.value.isValid, true);
    });

    test('fieldDirtyNotifier creates and caches notifiers', () {
      final controller = BetterFormController();
      final fieldId = BetterFormFieldID<String>('test');

      final notifier1 = controller.fieldDirtyNotifier(fieldId);
      final notifier2 = controller.fieldDirtyNotifier(fieldId);

      expect(notifier1, same(notifier2));
      expect(notifier1.value, false);
    });

    test('fieldTouchedNotifier creates and caches notifiers', () {
      final controller = BetterFormController();
      final fieldId = BetterFormFieldID<String>('test');

      final notifier1 = controller.fieldTouchedNotifier(fieldId);
      final notifier2 = controller.fieldTouchedNotifier(fieldId);

      expect(notifier1, same(notifier2));
      expect(notifier1.value, false);
    });

    test('global notifiers are created lazily', () {
      final controller = BetterFormController();

      expect(controller.isDirtyNotifier.value, false);
      expect(controller.isValidNotifier.value, true);
      expect(controller.isSubmittingNotifier.value, false);
    });

    test('toMap returns unmodifiable copy of values', () {
      final controller = BetterFormController(
        initialValue: {'field1': 'value1'},
      );

      final map = controller.toMap();
      expect(map, {'field1': 'value1'});

      // Should be unmodifiable
      expect(() => map['field1'] = 'modified', throwsUnsupportedError);
    });

    test('getChangedValues returns only dirty fields', () {
      final field1 = BetterFormFieldID<String>('field1');
      final field2 = BetterFormFieldID<String>('field2');

      final controller = BetterFormController(
        initialValue: {'field1': 'initial1', 'field2': 'initial2'},
        fields: [
          BetterFormField<String>(id: field1, initialValue: 'initial1'),
          BetterFormField<String>(id: field2, initialValue: 'initial2'),
        ],
      );

      controller.setValue(field1, 'changed1');

      final changed = controller.getChangedValues();
      expect(changed, {'field1': 'changed1'});
      expect(changed.containsKey('field2'), false);
    });

    test('updateFromMap updates registered fields', () {
      final field1 = BetterFormFieldID<String>('field1');
      final field2 = BetterFormFieldID<String>('field2');

      final controller = BetterFormController(
        fields: [
          BetterFormField<String>(id: field1, initialValue: ''),
          BetterFormField<String>(id: field2, initialValue: ''),
        ],
      );

      controller.updateFromMap({'field1': 'updated', 'field3': 'ignored'});

      expect(controller.getValue(field1), 'updated');
      expect(controller.getValue(field2), ''); // Unchanged
    });

    test('resetToValues updates initial values and resets', () {
      final controller = BetterFormController(
        initialValue: {'field1': 'old'},
      );

      controller.resetToValues({'field1': 'new'});

      expect(controller.initialValue['field1'], 'new');
      expect(controller.getValue(BetterFormFieldID<String>('field1')), 'new');
    });

    test('focus management registers focus nodes', () {
      final controller = BetterFormController();
      final fieldId = BetterFormFieldID<String>('test');
      final focusNode = FocusNode();

      controller.registerFocusNode(fieldId, focusNode);
      controller.focusField(fieldId);

      // In test environment, focus might not work, but registration should work
      expect(() => controller.focusField(fieldId), returnsNormally);

      focusNode.dispose();
    });

    test('focusFirstError works with registered nodes', () {
      final field1 = BetterFormFieldID<String>('field1');
      final field2 = BetterFormFieldID<String>('field2');

      final controller = BetterFormController(
        fields: [
          BetterFormField<String>(
            id: field1,
            initialValue: '',
            validator: (v) => v.isEmpty ? 'Required' : null,
          ),
          BetterFormField<String>(
            id: field2,
            initialValue: '',
            validator: (v) => v.isEmpty ? 'Required' : null,
          ),
        ],
      );

      final focusNode1 = FocusNode();
      final focusNode2 = FocusNode();

      controller.registerFocusNode(field1, focusNode1);
      controller.registerFocusNode(field2, focusNode2);

      controller.validate();

      // Should not throw error
      expect(() => controller.focusFirstError(), returnsNormally);

      focusNode1.dispose();
      focusNode2.dispose();
    });

    test('dispose works without errors', () {
      final controller = BetterFormController();

      // Create some notifiers
      controller.getFieldNotifier(BetterFormFieldID<String>('test'));
      controller.fieldValidationNotifier(BetterFormFieldID<String>('test'));

      // Dispose should work without errors
      expect(() => controller.dispose(), returnsNormally);
    });
  });

  group('BetterFormParameter', () {
    test('constructor creates parameter correctly', () {
      final param = BetterFormParameter(
        initialValue: {'field1': 'value1'},
        fields: [BetterFormFieldConfig(id: BetterFormFieldID<String>('field1'))],
        persistence: MockPersistence(),
        formId: 'test_form',
      );

      expect(param.initialValue, {'field1': 'value1'});
      expect(param.fields.length, 1);
      expect(param.formId, 'test_form');
    });

    test('equality works correctly', () {
      final param1 = BetterFormParameter(
        initialValue: {'field1': 'value1'},
        fields: [BetterFormFieldConfig(id: BetterFormFieldID<String>('field1'))],
      );

      final param2 = BetterFormParameter(
        initialValue: {'field1': 'value1'},
        fields: [BetterFormFieldConfig(id: BetterFormFieldID<String>('field1'))],
      );

      final param3 = BetterFormParameter(
        initialValue: {'field1': 'value2'},
      );

      expect(param1 == param2, true);
      expect(param1 == param3, false);
    });

    test('hashCode works correctly', () {
      final param1 = BetterFormParameter(initialValue: {'field1': 'value1'});
      final param2 = BetterFormParameter(initialValue: {'field1': 'value1'});

      expect(param1.hashCode, param2.hashCode);
    });
  });

  group('Providers', () {
    test('formControllerProvider creates controller correctly', () {
      final param = BetterFormParameter(
        initialValue: {'field1': 'value1'},
        fields: [BetterFormFieldConfig(id: BetterFormFieldID<String>('field1'))],
      );

      final container = ProviderContainer();
      final provider = formControllerProvider(param);
      final controller = container.read(provider.notifier);

      expect(controller.getValue(BetterFormFieldID<String>('field1')), 'value1');
      container.dispose();
    });

    test('currentControllerProvider provides default controller', () {
      final container = ProviderContainer();
      final provider = container.read(currentControllerProvider);

      expect(provider, isNotNull);
      container.dispose();
    });
  });
}
