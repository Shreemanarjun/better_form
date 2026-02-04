import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Chaining Validator API Tests', () {
    test('StringValidator rules work correctly', () {
      final validator = FormixValidators.string()
          .required('Required')
          .email('Invalid Email')
          .minLength(5, 'Too short')
          .build();

      expect(validator(null), 'Required');
      expect(validator(''), 'Required');
      expect(validator('abc'), 'Invalid Email');
      expect(validator('valid@email.com'), isNull);

      // Test length after email
      final lengthValidator = FormixValidators.string()
          .email()
          .minLength(20, 'Too short')
          .build();
      expect(lengthValidator('test@example.com'), 'Too short');
      expect(lengthValidator('verylongemailaddress@example.com'), isNull);
    });

    test('NumberValidator rules work correctly', () {
      final validator = FormixValidators.number<int>()
          .required('Required')
          .min(10, 'Min 10')
          .max(20, 'Max 20')
          .positive()
          .build();

      expect(validator(null), 'Required');
      expect(validator(5), 'Min 10');
      expect(validator(25), 'Max 20');
      expect(validator(15), isNull);
    });

    test('Async validation chaining works', () async {
      final chain = FormixValidators.string().required().async((val) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return val == 'taken' ? 'Already taken' : null;
      });

      final syncValidator = chain.build();
      final asyncValidator = chain.buildAsync();

      // Sync should stop it early if empty - returns validation key
      expect(syncValidator(''), 'formix_key_required');

      // Async should run if sync passes
      expect(await asyncValidator('available'), isNull);
      expect(await asyncValidator('taken'), 'Already taken');
    });

    test('FormixFieldConfig.chain factory integrates correctly', () {
      final emailField = FormixFieldID<String>('email');
      final config = FormixFieldConfig.chain(
        id: emailField,
        rules: FormixValidators.string().required().email(),
      );

      final field = config.toField();
      // Validators return keys, not resolved messages
      expect(field.validator!('invalid'), 'formix_key_invalid_email');
      expect(field.validator!('test@test.com'), isNull);
    });
  });
}
