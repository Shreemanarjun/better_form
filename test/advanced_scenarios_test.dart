import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Advanced Dependency Scenarios', () {
    test('Linear Transitive Chain (A -> B -> C)', () {
      final a = FormixFieldID<String>('a');
      final b = FormixFieldID<String>('b');
      final c = FormixFieldID<String>('c');

      final fields = [
        FormixFieldConfig<String>(id: a, initialValue: 'valid'),
        FormixFieldConfig<String>(
          id: b,
          initialValue: 'valid',
          dependsOn: [a],
          crossFieldValidator: (val, state) {
            return state.getValue(a) == 'invalid' ? 'Error caused by A' : null;
          },
        ),
        FormixFieldConfig<String>(
          id: c,
          initialValue: 'valid',
          dependsOn: [b],
          crossFieldValidator: (val, state) {
            // C is invalid if B has an error
            final bValid = state.validations[b.key]?.isValid ?? true;
            return !bValid ? 'Error caused by B' : null;
          },
        ),
      ];

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      // 1. Initial State
      expect(controller.currentState.isValid, isTrue);

      // 2. Trigger Chain: A -> B -> C
      controller.setValue(a, 'invalid');

      // Verify B updated
      expect(
        controller.currentState.validations[b.key]?.isValid,
        isFalse,
        reason: 'B should fail when A is invalid',
      );

      // Verify C updated (Transitive)
      expect(
        controller.currentState.validations[c.key]?.isValid,
        isFalse,
        reason: 'C should fail when B fails (transitive dependency)',
      );
    });

    test('Diamond Dependency (A -> B -> D, A -> C -> D)', () {
      //      A
      //    /   \
      //   B     C
      //    \   /
      //      D
      final a = FormixFieldID<int>('a');
      final b = FormixFieldID<int>('b');
      final c = FormixFieldID<int>('c');
      final d = FormixFieldID<int>('d');

      final fields = [
        FormixFieldConfig<int>(id: a, initialValue: 1),
        FormixFieldConfig<int>(
          id: b,
          initialValue: 1,
          dependsOn: [a],
          crossFieldValidator: (_, state) {
            // B = A + 1
            return null; // Logic in value transformation typically, but utilizing validator for state check
          },
        ),
        FormixFieldConfig<int>(id: c, initialValue: 1, dependsOn: [a]),
        FormixFieldConfig<int>(
          id: d,
          initialValue: 0,
          dependsOn: [b, c],
          crossFieldValidator: (_, state) {
            // D validates that B + C > 5
            final valA = state.getValue(a) ?? 0;
            // Simulating "derived" logic via validation for this test
            if (valA > 5) return 'A too high';
            return null;
          },
        ),
      ];

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      // Update A.
      // BFS should queue B and C.
      // Then processing B queues D.
      // Processing C queues D (again).
      // Visited set should ensure D is only queued/processed once (or optimized).
      controller.setValue(a, 10);

      expect(
        controller.currentState.validations[d.key]?.errorMessage,
        'A too high',
        reason:
            'D should re-validate when A changes, propagating through both paths',
      );
    });

    test('Circular Dependency Safety (A <-> B)', () {
      final a = FormixFieldID<String>('a');
      final b = FormixFieldID<String>('b');

      final fields = [
        FormixFieldConfig<String>(id: a, initialValue: 'a', dependsOn: [b]),
        FormixFieldConfig<String>(id: b, initialValue: 'b', dependsOn: [a]),
      ];

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      // Should complete without stack overflow
      controller.setValue(a, 'newA');

      expect(controller.currentState.getValue(a), 'newA');
    });

    test('Self-Dependency Safety (A -> A)', () {
      final a = FormixFieldID<String>('a');
      final fields = [
        FormixFieldConfig<String>(id: a, initialValue: 'a', dependsOn: [a]),
      ];

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      controller.setValue(a, 'new');
      expect(controller.currentState.isValid, isTrue);
    });
  });

  group('Complex Data Structures', () {
    test('Form Array Item Validation triggers Aggregate', () {
      final totalField = FormixFieldID<int>('total');
      final itemsArray = FormixArrayID<int>('items');

      final fields = [
        FormixFieldConfig<int>(
          id: totalField,
          initialValue: 0,
          dependsOn: [itemsArray],
          crossFieldValidator: (val, state) {
            final items = state.getValue(itemsArray) ?? [];
            final total = items.fold(0, (sum, item) => sum + item);
            if (total > 100) return 'Total exceeds 100';
            return null;
          },
        ),
      ];

      final container = ProviderContainer();
      final controller = container.read(
        formControllerProvider(FormixParameter(fields: fields)).notifier,
      );

      // 1. Add items using array manipulation
      controller.addArrayItem(itemsArray, 50);
      controller.addArrayItem(itemsArray, 40); // Sum = 90 (Valid)

      // array updates via addArrayItem trigger setValue for the array
      // so dependents should fire.

      // Verify total is valid
      expect(
        controller.currentState.validations[totalField.key]?.isValid,
        isTrue,
      );

      // 2. Add item to exceed limit
      controller.addArrayItem(itemsArray, 20); // Sum = 110 (Invalid)

      // Verify total is invalid
      expect(
        controller.currentState.validations[totalField.key]?.isValid,
        isFalse,
        reason: 'Total field should re-validate when array items change',
      );
      expect(
        controller.currentState.validations[totalField.key]?.errorMessage,
        'Total exceeds 100',
      );
    });
  });
}
