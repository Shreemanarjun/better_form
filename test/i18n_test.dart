import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixMessages Interface', () {
    test('FormixMessages is abstract and cannot be instantiated', () {
      // This should not compile if we try to instantiate it directly
      // We test this by ensuring the concrete implementation works
      final messages = DefaultFormixMessages();
      expect(messages, isA<FormixMessages>());
    });
  });

  group('DefaultFormixMessages', () {
    late DefaultFormixMessages messages;

    setUp(() {
      messages = const DefaultFormixMessages();
    });

    test('constructor creates instance correctly', () {
      expect(messages, isNotNull);
      expect(messages, isA<DefaultFormixMessages>());
      expect(messages, isA<FormixMessages>());
    });

    test('required returns correct message with label', () {
      expect(messages.required('Email'), 'Email is required');
      expect(messages.required('Password'), 'Password is required');
      expect(messages.required(''), ' is required');
      expect(
        messages.required('Field with spaces'),
        'Field with spaces is required',
      );
    });

    test('required handles special characters in labels', () {
      expect(
        messages.required('Email & Password'),
        'Email & Password is required',
      );
      expect(messages.required('User\'s Name'), 'User\'s Name is required');
      expect(messages.required('Field-Name_123'), 'Field-Name_123 is required');
    });

    test('invalidFormat returns correct message', () {
      expect(messages.invalidFormat(), 'Invalid format');
    });

    test('minLength returns correct message with parameter', () {
      expect(messages.minLength(5), 'Minimum length is 5 characters');
      expect(messages.minLength(1), 'Minimum length is 1 characters');
      expect(messages.minLength(100), 'Minimum length is 100 characters');
      expect(messages.minLength(0), 'Minimum length is 0 characters');
    });

    test('maxLength returns correct message with parameter', () {
      expect(messages.maxLength(10), 'Maximum length is 10 characters');
      expect(messages.maxLength(255), 'Maximum length is 255 characters');
      expect(messages.maxLength(1), 'Maximum length is 1 characters');
    });

    test('minValue returns correct message with numeric parameter', () {
      expect(messages.minValue(0), 'Minimum value is 0');
      expect(messages.minValue(18), 'Minimum value is 18');
      expect(messages.minValue(-5), 'Minimum value is -5');
      expect(messages.minValue(3.14), 'Minimum value is 3.14');
      expect(messages.minValue(1000000), 'Minimum value is 1000000');
    });

    test('maxValue returns correct message with numeric parameter', () {
      expect(messages.maxValue(100), 'Maximum value is 100');
      expect(messages.maxValue(0), 'Maximum value is 0');
      expect(messages.maxValue(-1), 'Maximum value is -1');
      expect(messages.maxValue(99.99), 'Maximum value is 99.99');
    });

    test('minDate returns correct message with DateTime parameter', () {
      final date = DateTime(2023, 12, 25);
      expect(messages.minDate(date), 'Date must be after 2023-12-25');

      final today = DateTime.now();
      final dateString = today.toString().split(' ')[0];
      expect(messages.minDate(today), 'Date must be after $dateString');
    });

    test('minDate formats date correctly', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 12, 31);
      final date3 = DateTime(2000, 2, 29); // Leap year

      expect(messages.minDate(date1), 'Date must be after 2023-01-01');
      expect(messages.minDate(date2), 'Date must be after 2023-12-31');
      expect(messages.minDate(date3), 'Date must be after 2000-02-29');
    });

    test('maxDate returns correct message with DateTime parameter', () {
      final date = DateTime(2023, 6, 15);
      expect(messages.maxDate(date), 'Date must be before 2023-06-15');

      final futureDate = DateTime(2030, 1, 1);
      expect(messages.maxDate(futureDate), 'Date must be before 2030-01-01');
    });

    test('maxDate formats date correctly', () {
      final date1 = DateTime(2022, 3, 10);
      final date2 = DateTime(1999, 12, 31);

      expect(messages.maxDate(date1), 'Date must be before 2022-03-10');
      expect(messages.maxDate(date2), 'Date must be before 1999-12-31');
    });

    test('invalidSelection returns correct message', () {
      expect(messages.invalidSelection(), 'Invalid selection');
    });

    test('validationFailed returns correct message with error parameter', () {
      expect(
        messages.validationFailed('Network error'),
        'Validation failed: Network error',
      );
      expect(
        messages.validationFailed('Timeout'),
        'Validation failed: Timeout',
      );
      expect(messages.validationFailed(''), 'Validation failed: ');
      expect(
        messages.validationFailed('Error with spaces and symbols !@#'),
        'Validation failed: Error with spaces and symbols !@#',
      );
    });

    test('validating returns correct message', () {
      expect(messages.validating(), 'Validating...');
    });

    test('all messages are non-empty strings', () {
      expect(messages.required('test').isNotEmpty, true);
      expect(messages.invalidFormat().isNotEmpty, true);
      expect(messages.minLength(5).isNotEmpty, true);
      expect(messages.maxLength(10).isNotEmpty, true);
      expect(messages.minValue(0).isNotEmpty, true);
      expect(messages.maxValue(100).isNotEmpty, true);
      expect(messages.minDate(DateTime.now()).isNotEmpty, true);
      expect(messages.maxDate(DateTime.now()).isNotEmpty, true);
      expect(messages.invalidSelection().isNotEmpty, true);
      expect(messages.validationFailed('error').isNotEmpty, true);
      expect(messages.validating().isNotEmpty, true);
    });

    test('messages contain expected keywords', () {
      expect(messages.required('Email').contains('Email'), true);
      expect(messages.required('Email').contains('required'), true);

      expect(messages.minLength(5).contains('5'), true);
      expect(messages.minLength(5).contains('Minimum'), true);
      expect(messages.minLength(5).contains('characters'), true);

      expect(messages.maxLength(20).contains('20'), true);
      expect(messages.maxLength(20).contains('Maximum'), true);

      expect(messages.minValue(10).contains('10'), true);
      expect(messages.minValue(10).contains('Minimum'), true);

      expect(messages.maxValue(50).contains('50'), true);
      expect(messages.maxValue(50).contains('Maximum'), true);

      expect(
        messages.minDate(DateTime(2023, 1, 1)).contains('2023-01-01'),
        true,
      );
      expect(messages.minDate(DateTime(2023, 1, 1)).contains('after'), true);

      expect(
        messages.maxDate(DateTime(2023, 12, 31)).contains('2023-12-31'),
        true,
      );
      expect(messages.maxDate(DateTime(2023, 12, 31)).contains('before'), true);

      expect(messages.validationFailed('test').contains('test'), true);
      expect(
        messages.validationFailed('test').contains('Validation failed'),
        true,
      );

      expect(messages.validating().contains('Validating'), true);
    });

    test('messages handle edge case parameters', () {
      // Very large numbers
      expect(messages.minValue(999999999), 'Minimum value is 999999999');
      expect(messages.maxLength(999999), 'Maximum length is 999999 characters');

      // Very small numbers
      expect(messages.minValue(-999999), 'Minimum value is -999999');
      expect(messages.maxValue(-999999), 'Maximum value is -999999');

      // Zero values
      expect(messages.minLength(0), 'Minimum length is 0 characters');
      expect(messages.maxValue(0), 'Maximum value is 0');

      // Decimal numbers
      expect(messages.minValue(1.5), 'Minimum value is 1.5');
      expect(messages.maxValue(99.99), 'Maximum value is 99.99');
    });

    test('date formatting handles different date formats consistently', () {
      final dates = [
        DateTime(2023, 1, 1),
        DateTime(2023, 12, 31),
        DateTime(2000, 2, 29),
        DateTime(1999, 12, 31, 23, 59, 59), // With time component
      ];

      for (final date in dates) {
        final minMessage = messages.minDate(date);
        final maxMessage = messages.maxDate(date);

        // Should contain the date part (YYYY-MM-DD format)
        final dateString = date.toString().split(' ')[0];
        expect(minMessage.contains(dateString), true);
        expect(maxMessage.contains(dateString), true);

        // Should not contain time part
        expect(minMessage.contains(':'), false);
        expect(maxMessage.contains(':'), false);
      }
    });
  });

  group('Custom FormixMessages Implementation', () {
    test('can create custom implementation', () {
      final customMessages = CustomTestMessages();
      expect(customMessages, isA<FormixMessages>());
      expect(customMessages.required('Test'), 'CUSTOM: Test is required!');
      expect(customMessages.invalidFormat(), 'CUSTOM: Invalid format!');
    });

    test('custom implementation can override all methods', () {
      final customMessages = CustomTestMessages();

      expect(customMessages.minLength(5), 'CUSTOM: At least 5 characters');
      expect(customMessages.maxLength(10), 'CUSTOM: At most 10 characters');
      expect(customMessages.minValue(18), 'CUSTOM: Must be at least 18');
      expect(customMessages.maxValue(65), 'CUSTOM: Must be at most 65');
      expect(customMessages.invalidSelection(), 'CUSTOM: Invalid selection!');
      expect(customMessages.validating(), 'CUSTOM: Checking...');
    });

    test('custom implementation handles dates', () {
      final customMessages = CustomTestMessages();
      final date = DateTime(2023, 6, 15);

      expect(customMessages.minDate(date), 'CUSTOM: Must be after 2023-06-15');
      expect(customMessages.maxDate(date), 'CUSTOM: Must be before 2023-06-15');
    });

    test('custom implementation handles validation errors', () {
      final customMessages = CustomTestMessages();

      expect(
        customMessages.validationFailed('Network timeout'),
        'CUSTOM: Validation error: Network timeout',
      );
    });
  });

  group('FormixMessages Integration', () {
    test('DefaultFormixMessages can be used as FormixMessages', () {
      FormixMessages messages = const DefaultFormixMessages();

      expect(messages.required('Field'), contains('Field'));
      expect(messages.invalidFormat(), equals('Invalid format'));
      expect(messages.validating(), equals('Validating...'));
    });

    test('messages are consistent across instances', () {
      final messages1 = const DefaultFormixMessages();
      final messages2 = const DefaultFormixMessages();

      expect(messages1.required('Test'), equals(messages2.required('Test')));
      expect(messages1.minLength(5), equals(messages2.minLength(5)));
      expect(messages1.validating(), equals(messages2.validating()));
    });

    test('messages handle null or empty parameters gracefully', () {
      final messages = const DefaultFormixMessages();

      // These should not crash
      expect(() => messages.required(''), returnsNormally);
      expect(() => messages.minLength(0), returnsNormally);
      expect(() => messages.maxLength(0), returnsNormally);
      expect(() => messages.minValue(0), returnsNormally);
      expect(() => messages.maxValue(0), returnsNormally);
      expect(() => messages.validationFailed(''), returnsNormally);
    });
  });
}

/// Custom implementation for testing purposes
class CustomTestMessages extends FormixMessages {
  const CustomTestMessages();

  @override
  String required(String label) => 'CUSTOM: $label is required!';

  @override
  String invalidFormat() => 'CUSTOM: Invalid format!';

  @override
  String minLength(int minLength) => 'CUSTOM: At least $minLength characters';

  @override
  String maxLength(int maxLength) => 'CUSTOM: At most $maxLength characters';

  @override
  String minValue(num min) => 'CUSTOM: Must be at least $min';

  @override
  String maxValue(num max) => 'CUSTOM: Must be at most $max';

  @override
  String minDate(DateTime minDate) =>
      'CUSTOM: Must be after ${minDate.toString().split(' ')[0]}';

  @override
  String maxDate(DateTime maxDate) =>
      'CUSTOM: Must be before ${maxDate.toString().split(' ')[0]}';

  @override
  String invalidSelection() => 'CUSTOM: Invalid selection!';

  @override
  String validationFailed(String error) => 'CUSTOM: Validation error: $error';

  @override
  String validating() => 'CUSTOM: Checking...';
}
