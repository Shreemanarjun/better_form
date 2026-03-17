import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  test('type mismatch test', () {
    const nameField = FormixFieldID<String>('name');
    final controller = FormixController(
      fields: [const FormixField<String>(id: nameField, initialValue: 'initial')],
    );

    final FormixField<String> field = controller.formFieldDefinitions['name'] as FormixField<String>;
    print('field.isTypeValid(123): ${field.isTypeValid(123)}');
    print('field type: ${field.runtimeType}');

    final res = controller.setValues({nameField: 123}, strict: false);
    print('res success: ${res.success}, type mismatches: ${res.typeMismatches}');
  });
}
