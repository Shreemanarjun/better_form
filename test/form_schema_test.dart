import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormFieldSchema', () {
    late FormixFieldID<String> nameField;
    late FormixFieldID<num> ageField;
    late FormixFieldID<bool> newsletterField;

    setUp(() {
      nameField = FormixFieldID<String>('name');
      ageField = FormixFieldID<num>('age');
      newsletterField = FormixFieldID<bool>('newsletter');
    });

    group('TextFieldSchema', () {
      test('should create with basic properties', () {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: 'John',
          label: 'Full Name',
          hint: 'Enter your name',
          isRequired: true,
        );

        expect(schema.id, nameField);
        expect(schema.initialValue, 'John');
        expect(schema.label, 'Full Name');
        expect(schema.hint, 'Enter your name');
        expect(schema.isRequired, true);
        expect(schema.isVisible, true);
        expect(schema.dependencies, isEmpty);
      });

      test('should validate required field', () async {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: '',
          isRequired: true,
          label: 'Name',
        );

        final errors = await schema.validate('', {});
        expect(errors, contains('Name is required'));
      });

      test('should validate minimum length', () async {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: '',
          minLength: 3,
        );

        final errors = await schema.validate('Hi', {});
        expect(errors, contains('Minimum length is 3 characters'));
      });

      test('should validate maximum length', () async {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: '',
          maxLength: 5,
        );

        final errors = await schema.validate('Hello World', {});
        expect(errors, contains('Maximum length is 5 characters'));
      });

      test('should validate pattern', () async {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: '',
          pattern: r'^\d+$', // Only digits
        );

        final errors = await schema.validate('abc123', {});
        expect(errors, contains('Invalid format'));
      });

      test('should pass validation with valid input', () async {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: '',
          minLength: 2,
          maxLength: 10,
          pattern: r'^\w+$',
        );

        final errors = await schema.validate('Hello', {});
        expect(errors, isEmpty);
      });

      test('should convert to field definition', () {
        final schema = TextFieldSchema(
          id: nameField,
          initialValue: 'John',
          label: 'Name',
          validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
        );

        final field = schema.toFieldDefinition();
        expect(field.id, nameField);
        expect(field.initialValue, 'John');
        expect(field.label, 'Name');
        expect(field.validator, isNotNull);
      });
    });

    group('NumberFieldSchema', () {
      test('should validate minimum value', () async {
        final schema = NumberFieldSchema(id: ageField, initialValue: 0, min: 0);

        final errors = await schema.validate(-1, {});
        expect(errors, contains('Minimum value is 0'));
      });

      test('should validate maximum value', () async {
        final schema = NumberFieldSchema(
          id: ageField,
          initialValue: 0,
          max: 120,
        );

        final errors = await schema.validate(150, {});
        expect(errors, contains('Maximum value is 120'));
      });

      test('should pass validation with valid number', () async {
        final schema = NumberFieldSchema(
          id: ageField,
          initialValue: 25,
          min: 0,
          max: 120,
        );

        final errors = await schema.validate(30, {});
        expect(errors, isEmpty);
      });
    });

    group('BooleanFieldSchema', () {
      test('should handle boolean validation', () async {
        final schema = BooleanFieldSchema(
          id: newsletterField,
          initialValue: false,
          validator: (value) => value == true ? null : 'Must agree',
        );

        final errors = await schema.validate(false, {});
        expect(errors, contains('Must agree'));
      });
    });

    group('ConditionalFieldSchema', () {
      test('should be visible when condition is true', () {
        final schema = ConditionalFieldSchema<String>(
          id: nameField,
          initialValue: '',
          visibilityCondition: (formState) => formState['showName'] == true,
        );

        expect(schema.shouldBeVisible({'showName': true}), true);
        expect(schema.shouldBeVisible({'showName': false}), false);
        expect(schema.shouldBeVisible({}), false);
      });
    });

    group('SelectionFieldSchema', () {
      test('should validate selection from options', () async {
        final schema = SelectionFieldSchema<String>(
          id: FormixFieldID<String>('priority'),
          initialValue: 'medium',
          options: ['low', 'medium', 'high'],
        );

        final validErrors = await schema.validate('high', {});
        expect(validErrors, isEmpty);

        final invalidErrors = await schema.validate('urgent', {});
        expect(invalidErrors, contains('Invalid selection'));
      });
    });

    group('FormSchema', () {
      late FormSchema formSchema;

      setUp(() {
        formSchema = FormSchema(
          name: 'User Registration',
          description: 'Register a new user account',
          fields: [
            TextFieldSchema(
              id: nameField,
              initialValue: '',
              isRequired: true,
              minLength: 2,
            ),
            NumberFieldSchema(id: ageField, initialValue: 18, min: 0, max: 120),
            BooleanFieldSchema(id: newsletterField, initialValue: false),
          ],
          submitButtonText: 'Create Account',
          resetButtonText: 'Clear Form',
        );
      });

      test('should initialize with properties', () {
        expect(formSchema.name, 'User Registration');
        expect(formSchema.description, 'Register a new user account');
        expect(formSchema.fields, hasLength(3));
        expect(formSchema.submitButtonText, 'Create Account');
        expect(formSchema.resetButtonText, 'Clear Form');
      });

      test('should get field by ID', () {
        final field = formSchema.getField<String>(nameField);
        expect(field, isNotNull);
        expect(field!.id, nameField);

        final nonExistent = formSchema.getField<String>(
          FormixFieldID<String>('email'),
        );
        expect(nonExistent, isNull);
      });

      test('should get visible fields', () {
        final visibleFields = formSchema.getVisibleFields({});
        expect(
          visibleFields,
          hasLength(3),
        ); // All fields are visible by default
      });

      test('should validate entire form', () async {
        // Valid form data
        final validData = {'name': 'John Doe', 'age': 25, 'newsletter': true};

        final validResult = await formSchema.validate(validData);
        expect(validResult.isValid, true);
        expect(validResult.fieldErrors, isEmpty);
        expect(validResult.customErrors, isEmpty);

        // Invalid form data
        final invalidData = {
          'name': '', // Required but empty
          'age': -5, // Below minimum
          'newsletter': false,
        };

        final invalidResult = await formSchema.validate(invalidData);
        expect(invalidResult.isValid, false);
        expect(invalidResult.fieldErrors, hasLength(2)); // name and age errors
        expect(
          invalidResult.allErrors,
          hasLength(3),
        ); // name has 2 errors, age has 1
      });

      test('should submit form successfully', () async {
        final formData = {'name': 'John Doe', 'age': 25, 'newsletter': true};

        final result = await formSchema.submit(formData);
        expect(result.success, true);
        expect(result.data, formData);
      });

      test('should fail submission with validation errors', () async {
        final invalidData = {
          'name': '', // Required field empty
          'age': 25,
          'newsletter': false,
        };

        final result = await formSchema.submit(invalidData);
        expect(result.success, false);
        expect(result.error, 'Validation failed');
        expect(result.validationResult, isNotNull);
        expect(result.validationResult!.isValid, false);
      });

      test('should handle custom validation', () async {
        final schemaWithCustomValidation = FormSchema(
          fields: [TextFieldSchema(id: nameField, initialValue: 'John')],
          onValidate: (values) async {
            if (values['name'] == 'Admin') {
              return ['Admin username not allowed'];
            }
            return [];
          },
        );

        final validResult = await schemaWithCustomValidation.validate({
          'name': 'John',
        });
        expect(validResult.isValid, true);

        final invalidResult = await schemaWithCustomValidation.validate({
          'name': 'Admin',
        });
        expect(invalidResult.isValid, false);
        expect(
          invalidResult.customErrors,
          contains('Admin username not allowed'),
        );
      });

      test('should handle async validation', () async {
        final schemaWithAsyncValidation = FormSchema(
          fields: [
            TextFieldSchema(
              id: nameField,
              initialValue: '',
              asyncValidator: (value) async {
                // Simulate API call
                await Future.delayed(const Duration(milliseconds: 10));
                return value == 'taken' ? 'Username already taken' : null;
              },
            ),
          ],
        );

        final validResult = await schemaWithAsyncValidation.validate({
          'name': 'available',
        });
        expect(validResult.isValid, true);

        final invalidResult = await schemaWithAsyncValidation.validate({
          'name': 'taken',
        });
        expect(invalidResult.isValid, false);
        expect(invalidResult.allErrors, contains('Username already taken'));
      });
    });

    group('SchemaBasedFormController', () {
      late FormSchema testSchema;
      late SchemaBasedFormController controller;

      setUp(() {
        testSchema = FormSchema(
          fields: [
            TextFieldSchema(
              id: nameField,
              initialValue: 'John',
              isRequired: true,
            ),
            NumberFieldSchema(id: ageField, initialValue: 25, min: 0, max: 120),
          ],
        );

        controller = SchemaBasedFormController(schema: testSchema);
      });

      tearDown(() {
        controller.dispose();
      });

      test('should initialize with schema values', () {
        expect(controller.getValue(nameField), 'John');
        expect(controller.getValue(ageField), 25);
      });

      test('should register all schema fields', () {
        expect(controller.isFieldRegistered(nameField), true);
        expect(controller.isFieldRegistered(ageField), true);
      });

      test('should get visible fields', () {
        final visibleFields = controller.visibleFields;
        expect(visibleFields, hasLength(2));
        expect(visibleFields.map((f) => f.id), contains(nameField));
        expect(visibleFields.map((f) => f.id), contains(ageField));
      });

      test('should validate form using schema', () async {
        // Set valid values
        controller.setValue(nameField, 'Jane');
        controller.setValue(ageField, 30);

        final result = await controller.validateForm();
        expect(result.isValid, true);

        // Set invalid values
        controller.setValue(nameField, ''); // Required field empty
        controller.setValue(ageField, -5); // Below minimum

        final invalidResult = await controller.validateForm();
        expect(invalidResult.isValid, false);
        expect(invalidResult.fieldErrors, hasLength(2));
      });

      test('should submit form using schema', () async {
        // Set valid values
        controller.setValue(nameField, 'Jane');
        controller.setValue(ageField, 30);

        final result = await controller.submitForm();
        expect(result.success, true);
        expect(result.data['name'], 'Jane');
        expect(result.data['age'], 30);
      });
    });

    group('FormValidationResult', () {
      test('should handle valid results', () {
        final result = FormValidationResult(isValid: true);
        expect(result.isValid, true);
        expect(result.fieldErrors, isEmpty);
        expect(result.customErrors, isEmpty);
        expect(result.allErrors, isEmpty);
      });

      test('should handle invalid results', () {
        final fieldErrors = {
          nameField: ['Name is required', 'Too short'],
          ageField: ['Invalid age'],
        };

        final customErrors = ['Form has errors'];

        final result = FormValidationResult(
          isValid: false,
          fieldErrors: fieldErrors,
          customErrors: customErrors,
        );

        expect(result.isValid, false);
        expect(result.fieldErrors, hasLength(2));
        expect(result.customErrors, hasLength(1));
        expect(
          result.allErrors,
          hasLength(4),
        ); // 2 from name, 1 from age, 1 custom
        expect(result.getFieldErrors(nameField), hasLength(2));
        expect(result.getFieldErrors(ageField), hasLength(1));
      });
    });

    group('FormSubmissionResult', () {
      test('should create success result', () {
        final result = FormSubmissionResult.success(data: {'key': 'value'});
        expect(result.success, true);
        expect(result.data, {'key': 'value'});
        expect(result.error, isNull);
      });

      test('should create failure result', () {
        final validationResult = FormValidationResult(isValid: false);
        final result = FormSubmissionResult.failure(
          error: 'Validation failed',
          validationResult: validationResult,
        );

        expect(result.success, false);
        expect(result.error, 'Validation failed');
        expect(result.validationResult, validationResult);
      });
    });
  });
}
