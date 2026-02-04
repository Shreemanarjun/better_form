import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('RiverpodFormController Bulk Updates', () {
    test(
      'setValues updates multiple fields and triggers dependent validation in one round',
      () {
        final nameField = FormixFieldID<String>('name');
        final emailField = FormixFieldID<String>('email');

        final controller = FormixController(
          fields: [
            FormixField<String>(id: nameField, initialValue: ''),
            FormixField<String>(id: emailField, initialValue: ''),
          ],
        );

        int listenerCount = 0;
        controller.addListener((state) {
          listenerCount++;
        });

        controller.setValues({
          nameField: 'John',
          emailField: 'john@example.com',
        });

        expect(controller.getValue(nameField), 'John');
        expect(controller.getValue(emailField), 'john@example.com');
        // Should trigger TWO calls: one immediate call upon adding listener,
        // and one for the batch update.
        expect(listenerCount, 2);
      },
    );

    test('setValues triggers dependent validations', () {
      final priceField = FormixFieldID<double>('price');
      final taxField = FormixFieldID<double>('tax');
      final totalField = FormixFieldID<double>('total');

      final controller = FormixController(
        fields: [
          FormixField<double>(id: priceField, initialValue: 0.0),
          FormixField<double>(id: taxField, initialValue: 0.0),
          FormixField<double>(
            id: totalField,
            initialValue: 0.0,
            dependsOn: [priceField, taxField],
            validator: (val) {
              // This is just a dummy to ensure it runs
              return null;
            },
            // We'll use a derivation or just check if it re-validated via a transformer or something.
            // Actually, we can just check if changedFields contains it.
          ),
        ],
      );

      controller.setValues({priceField: 100.0, taxField: 10.0});

      expect(controller.state.changedFields, contains(totalField.key));
    });

    test('setValues with strict: false returns result with error details', () {
      final nameField = FormixFieldID<String>('name');
      final ageField = FormixFieldID<int>('age');
      final controller = FormixController(
        fields: [
          FormixField<String>(id: nameField, initialValue: 'initial'),
          FormixField<int>(id: ageField, initialValue: 0),
        ],
      );

      final result = controller.setValues({
        nameField: 'John',
        ageField: 'wrong type', // Should fail
        FormixFieldID<String>('unknown'): 'value', // Should fail (missing)
      });

      expect(result.success, isFalse);
      expect(result.updatedFields, contains(nameField.key));
      expect(result.typeMismatches, contains(ageField.key));
      expect(result.missingFields, contains('unknown'));
      expect(controller.getValue(nameField), 'John');
    });

    test('FormixBatch provides a type-safe way to collect updates', () {
      final nameField = FormixFieldID<String>('name');
      final ageField = FormixFieldID<int>('age');
      final controller = FormixController(
        fields: [
          FormixField<String>(id: nameField, initialValue: ''),
          FormixField<int>(id: ageField, initialValue: 0),
        ],
      );

      final batch = FormixBatch()
        ..setValue(nameField).to('Alice')
        ..setValue(ageField).to(30);

      final result = controller.applyBatch(batch);

      expect(result.success, isTrue);
      expect(controller.getValue(nameField), 'Alice');
      expect(controller.getValue(ageField), 30);
    });

    test('FormixBatch.forField provides convenience with lint enforcement', () {
      final nameFieldId = FormixFieldID<String>('name');
      final nameField = FormixField<String>(id: nameFieldId, initialValue: '');

      final controller = FormixController(fields: [nameField]);

      final batch = FormixBatch()..forField(nameField).to('Bob');
      controller.applyBatch(batch);

      expect(controller.getValue(nameFieldId), 'Bob');
    });

    test(
      'type mismatch in setValues with strict: true still throws ArgumentError',
      () {
        final nameField = FormixFieldID<String>('name');
        final controller = FormixController(
          fields: [FormixField<String>(id: nameField, initialValue: 'initial')],
        );

        expect(
          () => controller.setValues({nameField: 123}, strict: true),
          throwsArgumentError,
        );
      },
    );
  });
}
