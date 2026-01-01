import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('RiverpodFormController', () {
    late RiverpodFormController controller;

    setUp(() {
      controller = RiverpodFormController(
        initialValue: {
          'name': 'John',
          'email': 'john@example.com',
          'age': 25,
          'newsletter': false,
        },
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with provided values', () {
      expect(controller.getValue(BetterFormFieldID<String>('name')), 'John');
      expect(
        controller.getValue(BetterFormFieldID<String>('email')),
        'john@example.com',
      );
      expect(controller.getValue(BetterFormFieldID<num>('age')), 25);
      expect(controller.getValue(BetterFormFieldID<bool>('newsletter')), false);
    });

    test('should set and get values correctly', () {
      final nameField = BetterFormFieldID<String>('name');
      controller.setValue(nameField, 'Jane');
      expect(controller.getValue(nameField), 'Jane');
    });

    test('should track dirty state', () {
      final nameField = BetterFormFieldID<String>('name');
      expect(controller.isFieldDirty(nameField), false);

      controller.setValue(nameField, 'Jane');
      expect(controller.isFieldDirty(nameField), true);
      expect(controller.state.isDirty, true);
    });

    test('should validate fields with validators', () {
      final emailField = BetterFormFieldID<String>('email');

      // Register field with validator
      controller.registerField(
        BetterFormField<String>(
          id: emailField,
          initialValue: 'john@example.com',
          validator: (value) => value.contains('@') ? null : 'Invalid email',
        ),
      );

      // Valid email
      controller.setValue(emailField, 'jane@example.com');
      expect(controller.getValidation(emailField).isValid, true);

      // Invalid email
      controller.setValue(emailField, 'invalid-email');
      expect(controller.getValidation(emailField).isValid, false);
      expect(
        controller.getValidation(emailField).errorMessage,
        'Invalid email',
      );
    });

    test('should reset to initial values', () {
      final nameField = BetterFormFieldID<String>('name');
      controller.setValue(nameField, 'Jane');
      expect(controller.getValue(nameField), 'Jane');

      controller.reset();
      expect(controller.getValue(nameField), 'John');
      expect(controller.state.isDirty, false);
    });

    test('should validate entire form', () {
      final emailField = BetterFormFieldID<String>('email');

      controller.registerField(
        BetterFormField<String>(
          id: emailField,
          initialValue: 'john@example.com',
          validator: (value) => value.contains('@') ? null : 'Invalid email',
        ),
      );

      controller.setValue(emailField, 'invalid-email');
      final isValid = controller.validate();

      expect(isValid, false);
      expect(controller.state.isValid, false);
    });

    test('should handle field registration', () {
      final phoneField = BetterFormFieldID<String>('phone');

      expect(controller.isFieldRegistered(phoneField), false);

      controller.registerField(
        BetterFormField<String>(id: phoneField, initialValue: '123-456-7890'),
      );

      expect(controller.isFieldRegistered(phoneField), true);
      expect(controller.getValue(phoneField), '123-456-7890');
    });

    test('should handle field unregistration', () {
      final phoneField = BetterFormFieldID<String>('phone');

      controller.registerField(
        BetterFormField<String>(id: phoneField, initialValue: '123-456-7890'),
      );

      expect(controller.isFieldRegistered(phoneField), true);

      controller.unregisterField(phoneField);
      expect(controller.isFieldRegistered(phoneField), false);
    });
  });

  group('BetterFormController (Clean Riverpod API)', () {
    late BetterFormController controller;

    setUp(() {
      controller = BetterFormController(
        initialValue: {
          'name': 'John',
          'email': 'john@example.com',
          'age': 25,
          'newsletter': false,
        },
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should initialize with provided values', () {
      expect(controller.getValue(BetterFormFieldID<String>('name')), 'John');
      expect(
        controller.getValue(BetterFormFieldID<String>('email')),
        'john@example.com',
      );
      expect(controller.getValue(BetterFormFieldID<num>('age')), 25);
      expect(controller.getValue(BetterFormFieldID<bool>('newsletter')), false);
    });

    test('should set and get values correctly', () {
      final nameField = BetterFormFieldID<String>('name');
      controller.setValue(nameField, 'Jane');
      expect(controller.getValue(nameField), 'Jane');
    });

    test('should track dirty state', () {
      final nameField = BetterFormFieldID<String>('name');
      expect(controller.isFieldDirty(nameField), false);

      controller.setValue(nameField, 'Jane');
      expect(controller.isFieldDirty(nameField), true);
      expect(controller.state.isDirty, true);
    });

    test('should validate fields with validators', () {
      final emailField = BetterFormFieldID<String>('email');

      // Register field with validator
      controller.registerField(
        BetterFormField<String>(
          id: emailField,
          initialValue: 'john@example.com',
          validator: (value) => value.contains('@') ? null : 'Invalid email',
        ),
      );

      // Valid email
      controller.setValue(emailField, 'jane@example.com');
      expect(controller.getValidation(emailField).isValid, true);

      // Invalid email
      controller.setValue(emailField, 'invalid-email');
      expect(controller.getValidation(emailField).isValid, false);
      expect(
        controller.getValidation(emailField).errorMessage,
        'Invalid email',
      );
    });

    test('should reset to initial values', () {
      final nameField = BetterFormFieldID<String>('name');
      controller.setValue(nameField, 'Jane');
      expect(controller.getValue(nameField), 'Jane');

      controller.reset();
      expect(controller.getValue(nameField), 'John');
      expect(controller.state.isDirty, false);
    });

    test('should validate entire form', () {
      final emailField = BetterFormFieldID<String>('email');

      controller.registerField(
        BetterFormField<String>(
          id: emailField,
          initialValue: 'john@example.com',
          validator: (value) => value.contains('@') ? null : 'Invalid email',
        ),
      );

      controller.setValue(emailField, 'invalid-email');
      final isValid = controller.validate();

      expect(isValid, false);
      expect(controller.state.isValid, false);
    });

    test('should handle field registration', () {
      final phoneField = BetterFormFieldID<String>('phone');

      expect(controller.isFieldRegistered(phoneField), false);

      controller.registerField(
        BetterFormField<String>(id: phoneField, initialValue: '123-456-7890'),
      );

      expect(controller.isFieldRegistered(phoneField), true);
      expect(controller.getValue(phoneField), '123-456-7890');
    });

    test('should handle field unregistration', () {
      final phoneField = BetterFormFieldID<String>('phone');

      controller.registerField(
        BetterFormField<String>(id: phoneField, initialValue: '123-456-7890'),
      );

      expect(controller.isFieldRegistered(phoneField), true);

      controller.unregisterField(phoneField);
      expect(controller.isFieldRegistered(phoneField), false);
    });
  });

  group('Form Controller Provider Behavior', () {
    test(
      'should create new controller instances for different initial values',
      () {
        final container = ProviderContainer();

        final controller1 = container.read(
          formControllerProvider(
            const BetterFormParameter(initialValue: {'name': 'John'}),
          ).notifier,
        );
        final controller2 = container.read(
          formControllerProvider(
            const BetterFormParameter(initialValue: {'name': 'Jane'}),
          ).notifier,
        );

        expect(controller1.getValue(BetterFormFieldID<String>('name')), 'John');
        expect(controller2.getValue(BetterFormFieldID<String>('name')), 'Jane');

        // They should be different instances
        expect(controller1, isNot(same(controller2)));
      },
    );

    test('should reuse controller instances for same initial values', () {
      final container = ProviderContainer();

      final initialValue = {'name': 'John'};
      final controller1 = container.read(
        formControllerProvider(
          BetterFormParameter(initialValue: initialValue),
        ).notifier,
      );
      final controller2 = container.read(
        formControllerProvider(
          BetterFormParameter(initialValue: initialValue),
        ).notifier,
      );

      // They should be the same instance (Riverpod caches family providers)
      expect(controller1, same(controller2));
    });
  });
}
