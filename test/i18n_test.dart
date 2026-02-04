import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixMessages Interface', () {
    test('FormixMessages is abstract and cannot be instantiated', () {
      // This should not compile if we try to instantiate it directly
      // We test this by ensuring the concrete implementation works
      const messages = DefaultFormixMessages();
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
      expect(
        messages.minLength('Field', 5),
        'Field must be at least 5 characters',
      );
      expect(
        messages.minLength('Field', 1),
        'Field must be at least 1 characters',
      );
      expect(
        messages.minLength('Field', 100),
        'Field must be at least 100 characters',
      );
      expect(
        messages.minLength('Field', 0),
        'Field must be at least 0 characters',
      );
    });

    test('maxLength returns correct message with parameter', () {
      expect(
        messages.maxLength('Field', 10),
        'Field must be at most 10 characters',
      );
      expect(
        messages.maxLength('Field', 255),
        'Field must be at most 255 characters',
      );
      expect(
        messages.maxLength('Field', 1),
        'Field must be at most 1 characters',
      );
    });

    test('minValue returns correct message with numeric parameter', () {
      expect(messages.minValue('Field', 0), 'Field must be at least 0');
      expect(messages.minValue('Field', 18), 'Field must be at least 18');
      expect(messages.minValue('Field', -5), 'Field must be at least -5');
      expect(messages.minValue('Field', 3.14), 'Field must be at least 3.14');
      expect(
        messages.minValue('Field', 1000000),
        'Field must be at least 1000000',
      );
    });

    test('maxValue returns correct message with numeric parameter', () {
      expect(messages.maxValue('Field', 100), 'Field must be at most 100');
      expect(messages.maxValue('Field', 0), 'Field must be at most 0');
      expect(messages.maxValue('Field', -1), 'Field must be at most -1');
      expect(messages.maxValue('Field', 99.99), 'Field must be at most 99.99');
    });

    test('minDate returns correct message with DateTime parameter', () {
      final date = DateTime(2023, 12, 25);
      expect(messages.minDate('Date', date), 'Date must be after 2023-12-25');

      final today = DateTime.now();
      final dateString = today.toString().split(' ')[0];
      expect(messages.minDate('Date', today), 'Date must be after $dateString');
    });

    test('minDate formats date correctly', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 12, 31);
      final date3 = DateTime(2000, 2, 29); // Leap year

      expect(messages.minDate('Date', date1), 'Date must be after 2023-01-01');
      expect(messages.minDate('Date', date2), 'Date must be after 2023-12-31');
      expect(messages.minDate('Date', date3), 'Date must be after 2000-02-29');
    });

    test('maxDate returns correct message with DateTime parameter', () {
      final date = DateTime(2023, 6, 15);
      expect(messages.maxDate('Date', date), 'Date must be before 2023-06-15');

      final futureDate = DateTime(2030, 1, 1);
      expect(
        messages.maxDate('Date', futureDate),
        'Date must be before 2030-01-01',
      );
    });

    test('maxDate formats date correctly', () {
      final date1 = DateTime(2022, 3, 10);
      final date2 = DateTime(1999, 12, 31);

      expect(messages.maxDate('Date', date1), 'Date must be before 2022-03-10');
      expect(messages.maxDate('Date', date2), 'Date must be before 1999-12-31');
    });

    test('invalidSelection returns correct message', () {
      expect(
        messages.invalidSelection('Selection'),
        'Invalid selection for Selection',
      );
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
      expect(messages.minLength('Field', 5).isNotEmpty, true);
      expect(messages.maxLength('Field', 10).isNotEmpty, true);
      expect(messages.minValue('Field', 0).isNotEmpty, true);
      expect(messages.maxValue('Field', 100).isNotEmpty, true);
      expect(messages.minDate('Field', DateTime.now()).isNotEmpty, true);
      expect(messages.maxDate('Field', DateTime.now()).isNotEmpty, true);
      expect(messages.invalidSelection('Field').isNotEmpty, true);
      expect(messages.validationFailed('error').isNotEmpty, true);
      expect(messages.validating().isNotEmpty, true);
    });

    test('messages contain expected keywords', () {
      expect(messages.required('Email').contains('Email'), true);
      expect(messages.required('Email').contains('required'), true);

      expect(messages.minLength('Field', 5).contains('5'), true);
      expect(messages.minLength('Field', 5).contains('least'), true);
      expect(messages.minLength('Field', 5).contains('characters'), true);

      expect(messages.maxLength('Field', 20).contains('20'), true);
      expect(messages.maxLength('Field', 20).contains('most'), true);

      expect(messages.minValue('Field', 10).contains('10'), true);
      expect(messages.minValue('Field', 10).contains('least'), true);

      expect(messages.maxValue('Field', 50).contains('50'), true);
      expect(messages.maxValue('Field', 50).contains('most'), true);

      expect(
        messages.minDate('Field', DateTime(2023, 1, 1)).contains('2023-01-01'),
        true,
      );
      expect(
        messages.minDate('Field', DateTime(2023, 1, 1)).contains('after'),
        true,
      );

      expect(
        messages
            .maxDate('Field', DateTime(2023, 12, 31))
            .contains('2023-12-31'),
        true,
      );
      expect(
        messages.maxDate('Field', DateTime(2023, 12, 31)).contains('before'),
        true,
      );

      expect(messages.validationFailed('test').contains('test'), true);
      expect(
        messages.validationFailed('test').contains('Validation failed'),
        true,
      );

      expect(messages.validating().contains('Validating'), true);
    });

    test('messages handle edge case parameters', () {
      // Very large numbers
      expect(
        messages.minValue('Field', 999999999),
        'Field must be at least 999999999',
      );
      expect(
        messages.maxLength('Field', 999999),
        'Field must be at most 999999 characters',
      );

      // Very small numbers
      expect(
        messages.minValue('Field', -999999),
        'Field must be at least -999999',
      );
      expect(
        messages.maxValue('Field', -999999),
        'Field must be at most -999999',
      );

      // Zero values
      expect(
        messages.minLength('Field', 0),
        'Field must be at least 0 characters',
      );
      expect(messages.maxValue('Field', 0), 'Field must be at most 0');

      // Decimal numbers
      expect(messages.minValue('Field', 1.5), 'Field must be at least 1.5');
      expect(messages.maxValue('Field', 99.99), 'Field must be at most 99.99');
    });

    test('date formatting handles different date formats consistently', () {
      final dates = [
        DateTime(2023, 1, 1),
        DateTime(2023, 12, 31),
        DateTime(2000, 2, 29),
        DateTime(1999, 12, 31, 23, 59, 59), // With time component
      ];

      for (final date in dates) {
        final minMessage = messages.minDate('Field', date);
        final maxMessage = messages.maxDate('Field', date);

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
      const customMessages = CustomTestMessages();
      expect(customMessages, isA<FormixMessages>());
      expect(customMessages.required('Test'), 'CUSTOM: Test is required!');
      expect(customMessages.invalidFormat(), 'CUSTOM: Invalid format!');
    });

    test('custom implementation can override all methods', () {
      const customMessages = CustomTestMessages();

      expect(customMessages.minLength('F', 5), 'CUSTOM: At least 5 characters');
      expect(
        customMessages.maxLength('F', 10),
        'CUSTOM: At most 10 characters',
      );
      expect(customMessages.minValue('F', 18), 'CUSTOM: Must be at least 18');
      expect(customMessages.maxValue('F', 65), 'CUSTOM: Must be at most 65');
      expect(
        customMessages.invalidSelection('F'),
        'CUSTOM: Invalid selection!',
      );
      expect(customMessages.validating(), 'CUSTOM: Checking...');
    });

    test('custom implementation handles dates', () {
      const customMessages = CustomTestMessages();
      final date = DateTime(2023, 6, 15);

      expect(
        customMessages.minDate('F', date),
        'CUSTOM: Must be after 2023-06-15',
      );
      expect(
        customMessages.maxDate('F', date),
        'CUSTOM: Must be before 2023-06-15',
      );
    });

    test('custom implementation handles validation errors', () {
      const customMessages = CustomTestMessages();

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
      const messages1 = DefaultFormixMessages();
      const messages2 = DefaultFormixMessages();

      expect(messages1.required('Test'), equals(messages2.required('Test')));
      expect(messages1.minLength('F', 5), equals(messages2.minLength('F', 5)));
      expect(messages1.validating(), equals(messages2.validating()));
    });

    test('messages handle null or empty parameters gracefully', () {
      const messages = DefaultFormixMessages();

      // These should not crash
      expect(() => messages.required(''), returnsNormally);
      expect(() => messages.minLength('F', 0), returnsNormally);
      expect(() => messages.maxLength('F', 0), returnsNormally);
      expect(() => messages.minValue('F', 0), returnsNormally);
      expect(() => messages.maxValue('F', 0), returnsNormally);
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
  String minLength(String label, int minLength) =>
      'CUSTOM: At least $minLength characters';

  @override
  String maxLength(String label, int maxLength) =>
      'CUSTOM: At most $maxLength characters';

  @override
  String minValue(String label, num min) => 'CUSTOM: Must be at least $min';

  @override
  String maxValue(String label, num max) => 'CUSTOM: Must be at most $max';

  @override
  String minDate(String label, DateTime minDate) =>
      'CUSTOM: Must be after ${minDate.toString().split(' ')[0]}';

  @override
  String maxDate(String label, DateTime maxDate) =>
      'CUSTOM: Must be before ${maxDate.toString().split(' ')[0]}';

  @override
  String invalidSelection(String label) => 'CUSTOM: Invalid selection!';

  @override
  String validationFailed(String error) => 'CUSTOM: Validation error: $error';

  @override
  String validating() => 'CUSTOM: Checking...';
}
