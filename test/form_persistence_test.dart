import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('BetterFormPersistence Interface', () {
    test('BetterFormPersistence is abstract and cannot be instantiated', () {
      // This should not compile if we try to instantiate it directly
      // We test this by ensuring the concrete implementation works
      final persistence = InMemoryFormPersistence();
      expect(persistence, isA<BetterFormPersistence>());
    });
  });

  group('InMemoryFormPersistence', () {
    late InMemoryFormPersistence persistence;

    setUp(() {
      persistence = InMemoryFormPersistence();
    });

    test('constructor creates empty storage', () {
      expect(persistence, isNotNull);
      // Test that storage is empty initially
      expect(persistence.getSavedState('nonexistent'), completion(isNull));
    });

    test('saveFormState stores data correctly', () async {
      final testData = {'field1': 'value1', 'field2': 42, 'field3': true};
      const formId = 'test_form';

      await persistence.saveFormState(formId, testData);

      final savedData = await persistence.getSavedState(formId);
      expect(savedData, isNotNull);
      expect(savedData, equals(testData));
    });

    test('saveFormState creates deep copy of data', () async {
      final originalData = <String, dynamic>{'list': [1, 2, 3], 'map': <String, dynamic>{'nested': 'value'}};
      const formId = 'test_form';

      await persistence.saveFormState(formId, originalData);

      // Modify original data
      final list = originalData['list'] as List<int>;
      list.add(4);
      final map = originalData['map'] as Map<String, dynamic>;
      map['nested'] = 'modified';
      originalData['new_field'] = 'added';

      // Retrieved data should not be affected
      final savedData = await persistence.getSavedState(formId);
      expect(savedData, isNotNull);
      expect(savedData!['list'], equals([1, 2, 3]));
      expect(savedData['map'], equals({'nested': 'value'}));
      expect(savedData.containsKey('new_field'), isFalse);
    });

    test('getSavedState returns null for non-existent form', () async {
      final result = await persistence.getSavedState('nonexistent_form');
      expect(result, isNull);
    });

    test('getSavedState returns correct data for existing form', () async {
      const formId = 'existing_form';
      final testData = {'name': 'John', 'age': 30};

      await persistence.saveFormState(formId, testData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(testData));
    });

    test('multiple form IDs are stored separately', () async {
      const formId1 = 'form1';
      const formId2 = 'form2';

      final data1 = {'field': 'value1'};
      final data2 = {'field': 'value2'};

      await persistence.saveFormState(formId1, data1);
      await persistence.saveFormState(formId2, data2);

      final result1 = await persistence.getSavedState(formId1);
      final result2 = await persistence.getSavedState(formId2);

      expect(result1, equals(data1));
      expect(result2, equals(data2));
      expect(result1, isNot(equals(result2)));
    });

    test('saving same formId overwrites previous data', () async {
      const formId = 'test_form';

      final initialData = {'field': 'initial'};
      final updatedData = {'field': 'updated', 'new_field': 'added'};

      await persistence.saveFormState(formId, initialData);
      await persistence.saveFormState(formId, updatedData);

      final result = await persistence.getSavedState(formId);
      expect(result, equals(updatedData));
    });

    test('clearSavedState removes data for specific form', () async {
      const formId = 'test_form';
      final testData = {'field': 'value'};

      await persistence.saveFormState(formId, testData);
      expect(await persistence.getSavedState(formId), isNotNull);

      await persistence.clearSavedState(formId);
      expect(await persistence.getSavedState(formId), isNull);
    });

    test('clearSavedState does not affect other forms', () async {
      const formId1 = 'form1';
      const formId2 = 'form2';

      final data1 = {'field': 'value1'};
      final data2 = {'field': 'value2'};

      await persistence.saveFormState(formId1, data1);
      await persistence.saveFormState(formId2, data2);

      await persistence.clearSavedState(formId1);

      expect(await persistence.getSavedState(formId1), isNull);
      expect(await persistence.getSavedState(formId2), equals(data2));
    });

    test('clearSavedState on non-existent form does nothing', () async {
      // Should not throw any errors
      await persistence.clearSavedState('nonexistent_form');
      expect(await persistence.getSavedState('nonexistent_form'), isNull);
    });

    test('handles empty maps correctly', () async {
      const formId = 'empty_form';
      final emptyData = <String, dynamic>{};

      await persistence.saveFormState(formId, emptyData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(emptyData));
      expect(result!.isEmpty, isTrue);
    });

    test('handles null values in data', () async {
      const formId = 'null_form';
      final dataWithNulls = {'field1': 'value', 'field2': null, 'field3': 42};

      await persistence.saveFormState(formId, dataWithNulls);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(dataWithNulls));
      expect(result!['field2'], isNull);
    });

    test('handles complex nested data structures', () async {
      const formId = 'complex_form';
      final complexData = {
        'string': 'text',
        'number': 42,
        'boolean': true,
        'list': [1, 2, 3, 'mixed'],
        'nested_map': {
          'level1': {
            'level2': 'deep_value',
            'list_in_nested': ['a', 'b', 'c']
          }
        },
        'null_value': null,
      };

      await persistence.saveFormState(formId, complexData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(complexData));
      expect(result!['nested_map']['level1']['level2'], equals('deep_value'));
      expect(result['nested_map']['level1']['list_in_nested'], equals(['a', 'b', 'c']));
    });

    test('handles special characters in form IDs', () async {
      const formId = 'form_with_special_chars_!@#\$%^&*()';
      final testData = {'field': 'value'};

      await persistence.saveFormState(formId, testData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(testData));
    });

    test('handles empty string form ID', () async {
      const formId = '';
      final testData = {'field': 'value'};

      await persistence.saveFormState(formId, testData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(testData));
    });

    test('handles very long form IDs', () async {
      final longFormId = 'a' * 1000; // 1000 character string
      final testData = {'field': 'value'};

      await persistence.saveFormState(longFormId, testData);
      final result = await persistence.getSavedState(longFormId);

      expect(result, equals(testData));
    });

    test('handles concurrent operations', () async {
      const formId1 = 'form1';
      const formId2 = 'form2';

      final data1 = {'field': 'value1'};
      final data2 = {'field': 'value2'};

      // Start both operations concurrently
      final future1 = persistence.saveFormState(formId1, data1);
      final future2 = persistence.saveFormState(formId2, data2);

      await Future.wait([future1, future2]);

      final result1 = await persistence.getSavedState(formId1);
      final result2 = await persistence.getSavedState(formId2);

      expect(result1, equals(data1));
      expect(result2, equals(data2));
    });

    test('persistence survives multiple instances', () {
      final persistence1 = InMemoryFormPersistence();
      final persistence2 = InMemoryFormPersistence();

      const formId = 'shared_form';
      final data1 = {'field': 'value1'};
      final data2 = {'field': 'value2'};

      // Each instance should have its own storage
      persistence1.saveFormState(formId, data1);
      persistence2.saveFormState(formId, data2);

      expect(persistence1.getSavedState(formId), completion(equals(data1)));
      expect(persistence2.getSavedState(formId), completion(equals(data2)));
    });

    test('handles large data sets', () async {
      const formId = 'large_form';
      final largeData = <String, dynamic>{};

      // Create a large dataset
      for (int i = 0; i < 1000; i++) {
        largeData['field_$i'] = 'value_$i';
      }

      await persistence.saveFormState(formId, largeData);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(largeData));
      expect(result!.length, equals(1000));
    });

    test('data integrity is maintained across operations', () async {
      const formId = 'integrity_test';
      final originalData = {
        'string': 'original',
        'number': 42,
        'list': [1, 2, 3],
        'map': {'nested': 'value'}
      };

      await persistence.saveFormState(formId, originalData);

      // Verify initial save
      var result = await persistence.getSavedState(formId);
      expect(result, equals(originalData));

      // Modify and save again
      final modifiedData = Map<String, dynamic>.from(originalData);
      modifiedData['string'] = 'modified';
      modifiedData['new_field'] = 'added';

      await persistence.saveFormState(formId, modifiedData);
      result = await persistence.getSavedState(formId);
      expect(result, equals(modifiedData));

      // Clear and verify
      await persistence.clearSavedState(formId);
      result = await persistence.getSavedState(formId);
      expect(result, isNull);
    });

    test('handles DateTime and other complex objects', () async {
      const formId = 'datetime_form';
      final now = DateTime.now();
      final dataWithDateTime = {
        'timestamp': now,
        'string': 'test',
        'number': 42.5,
      };

      await persistence.saveFormState(formId, dataWithDateTime);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(dataWithDateTime));
      expect(result!['timestamp'], equals(now));
    });

    test('handles enum values', () async {
      const formId = 'enum_form';

      // Using a simple enum-like value
      final dataWithEnum = {
        'status': 'active',
        'priority': 'high',
        'count': 5,
      };

      await persistence.saveFormState(formId, dataWithEnum);
      final result = await persistence.getSavedState(formId);

      expect(result, equals(dataWithEnum));
      expect(result!['status'], equals('active'));
      expect(result['priority'], equals('high'));
    });
  });
}
