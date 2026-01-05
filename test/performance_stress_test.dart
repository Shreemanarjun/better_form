import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Performance Stress Tests', () {
    test('Handles 1000 fields gracefully', () {
      final fields = List.generate(
        1000,
        (i) => FormixFieldConfig<String>(
          id: FormixFieldID<String>('field_$i'),
          initialValue: '',
          validator: (value) => value.isEmpty ? 'Required' : null,
        ),
      );

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      final stopwatch = Stopwatch()..start();

      // Batch register & initial validation
      expect(controller.currentState.validations.length, 1000);

      // Bulk update
      for (var i = 0; i < 1000; i++) {
        controller.setValue(FormixFieldID<String>('field_$i'), 'Value $i');
      }

      expect(controller.currentState.isValid, true);
      stopwatch.stop();

      // ignore: avoid_print
      print('Updated 1000 fields in ${stopwatch.elapsedMilliseconds}ms');
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Should be well under 1s
    });

    test('Cross-field dependency chain performance', () {
      // Create a chain of 100 fields where each depends on the previous one
      final fields = <FormixFieldConfig<String>>[];
      fields.add(
        FormixFieldConfig<String>(
          id: const FormixFieldID<String>('field_0'),
          initialValue: '0',
        ),
      );

      for (var i = 1; i < 100; i++) {
        final prevId = FormixFieldID<String>('field_${i - 1}');
        fields.add(
          FormixFieldConfig<String>(
            id: FormixFieldID<String>('field_$i'),
            initialValue: '$i',
            dependsOn: [prevId],
            crossFieldValidator: (value, state) {
              final prevVal = state.getValue(prevId);
              if (prevVal == null) return 'Previous missing';
              return null;
            },
          ),
        );
      }

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      final stopwatch = Stopwatch()..start();

      // Changing the first field should trigger validation for the second,
      // but we don't have transitive dependency triggering yet (it only triggers immediate dependents).
      // Wait, let's check _validateFieldInternal - it triggers dependents of the field that was valid.
      // If field_0 changes, field_1 validates. If field_1 is valid, field_2 validates... wait, no.
      // It only triggers dependents of the field currently being set.

      controller.setValue(const FormixFieldID<String>('field_0'), 'New Value');

      stopwatch.stop();
      // ignore: avoid_print
      print(
        'Triggered dependency update in ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}
