import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

sealed class MySealed {}

class SubA extends MySealed {}

class SubB extends MySealed {}

void main() {
  test('FormixFieldID with sealed class should allow subclass in setValue', () {
    const fieldId = FormixFieldID<MySealed>('test');
    final controller = FormixController(
      initialValue: {'test': SubA()},
    );

    // This should work because SubB is a MySealed
    controller.setValue(fieldId, SubB());

    expect(controller.getValue(fieldId), isA<SubB>());
  });

  test('FormixFieldID with sealed class should allow subclass in setValue when field is registered', () {
    const fieldId = FormixFieldID<MySealed>('test');
    final controller = FormixController();

    controller.registerFields([
      FormixField<MySealed>(
        id: fieldId,
        initialValue: SubA(),
      ),
    ]);

    // This should work because SubB is a MySealed
    controller.setValue(fieldId, SubB());

    expect(controller.getValue(fieldId), isA<SubB>());
  });

  test('FormixBatch with sealed class should allow subclass in applyBatch', () {
    const fieldId = FormixFieldID<MySealed>('test');
    final controller = FormixController(
      initialValue: {'test': SubA()},
    );

    final batch = FormixBatch();
    batch.set(fieldId, SubB());
    controller.applyBatch(batch);

    expect(controller.getValue(fieldId), isA<SubB>());
  });
}
