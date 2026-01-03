import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('BetterDependentField', () {
    testWidgets('rebuilds when watched field value changes', (tester) async {
      final watchedField = BetterFormFieldID<String>('watched_field');
      int buildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'watched_field': 'initial'},
                fields: [
                  BetterFormFieldConfig(
                    id: watchedField,
                    initialValue: 'initial',
                  ),
                ],
                child: BetterDependentField<String>(
                  fieldId: watchedField,
                  builder: (context, value) {
                    buildCount++;
                    return Text('Value: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: initial'), findsOneWidget);
      expect(buildCount, 1);

      // Change the watched field value
      final provider = BetterForm.of(
        tester.element(find.text('Value: initial')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Value: initial')),
      );
      container.read(provider.notifier).setValue(watchedField, 'updated');

      await tester.pump();

      expect(find.text('Value: updated'), findsOneWidget);
      expect(buildCount, 2); // Should have rebuilt
      container.read(provider.notifier).setValue(watchedField, 'updated');
      await tester.pump();
      await tester.pump();
      expect(
        buildCount,
        2,
      ); // should not rebuild as value is same before as it is
    });

    testWidgets('does not rebuild when unwatched field changes', (
      tester,
    ) async {
      final watchedField = BetterFormFieldID<String>('watched_field');
      final otherField = BetterFormFieldID<String>('other_field');
      int buildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {
                  'watched_field': 'initial',
                  'other_field': 'other',
                },
                fields: [
                  BetterFormFieldConfig(
                    id: watchedField,
                    initialValue: 'initial',
                  ),
                  BetterFormFieldConfig(id: otherField, initialValue: 'other'),
                ],
                child: BetterDependentField<String>(
                  fieldId: watchedField,
                  builder: (context, value) {
                    buildCount++;
                    return Text('Watched: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Watched: initial'), findsOneWidget);
      expect(buildCount, 1);

      // Change the unwatched field
      final provider = BetterForm.of(
        tester.element(find.text('Watched: initial')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Watched: initial')),
      );
      container.read(provider.notifier).setValue(otherField, 'changed');

      await tester.pump();

      // Should still show the same value and not have rebuilt
      expect(find.text('Watched: initial'), findsOneWidget);
      expect(buildCount, 1); // Should not have rebuilt
    });

    testWidgets('works with different field types - int', (tester) async {
      final intField = BetterFormFieldID<int>('int_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'int_field': 42},
                fields: [BetterFormFieldConfig(id: intField, initialValue: 42)],
                child: BetterDependentField<int>(
                  fieldId: intField,
                  builder: (context, value) {
                    return Text('Number: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Number: 42'), findsOneWidget);

      // Change value
      final provider = BetterForm.of(tester.element(find.text('Number: 42')))!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Number: 42')),
      );
      container.read(provider.notifier).setValue(intField, 99);

      await tester.pump();

      expect(find.text('Number: 99'), findsOneWidget);
    });

    testWidgets('works with different field types - bool', (tester) async {
      final boolField = BetterFormFieldID<bool>('bool_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'bool_field': true},
                fields: [
                  BetterFormFieldConfig(id: boolField, initialValue: true),
                ],
                child: BetterDependentField<bool>(
                  fieldId: boolField,
                  builder: (context, value) {
                    return Text('Boolean: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Boolean: true'), findsOneWidget);

      // Change value
      final provider = BetterForm.of(
        tester.element(find.text('Boolean: true')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Boolean: true')),
      );
      container.read(provider.notifier).setValue(boolField, false);

      await tester.pump();

      expect(find.text('Boolean: false'), findsOneWidget);
    });

    testWidgets('works with different field types - double', (tester) async {
      final doubleField = BetterFormFieldID<double>('double_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'double_field': 3.14},
                fields: [
                  BetterFormFieldConfig(id: doubleField, initialValue: 3.14),
                ],
                child: BetterDependentField<double>(
                  fieldId: doubleField,
                  builder: (context, value) {
                    return Text('Double: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Double: 3.14'), findsOneWidget);

      // Change value
      final provider = BetterForm.of(
        tester.element(find.text('Double: 3.14')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Double: 3.14')),
      );
      container.read(provider.notifier).setValue(doubleField, 2.71);

      await tester.pump();

      expect(find.text('Double: 2.71'), findsOneWidget);
    });

    testWidgets('handles null values correctly', (tester) async {
      final nullableField = BetterFormFieldID<String>('nullable_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                fields: [BetterFormFieldConfig(id: nullableField)],
                child: BetterDependentField<String>(
                  fieldId: nullableField,
                  builder: (context, value) {
                    return Text('Value: ${value ?? "null"}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: null'), findsOneWidget);

      // Set a value
      final provider = BetterForm.of(tester.element(find.text('Value: null')))!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Value: null')),
      );
      container.read(provider.notifier).setValue(nullableField, 'not null');

      await tester.pump();

      expect(find.text('Value: not null'), findsOneWidget);

      // Set back to null
      container.read(provider.notifier).setValue(nullableField, null);

      await tester.pump();

      expect(find.text('Value: null'), findsOneWidget);
    });

    testWidgets('uses custom controller provider when provided', (
      tester,
    ) async {
      final customField = BetterFormFieldID<String>('custom_field');
      final customProvider =
          StateNotifierProvider.autoDispose<RiverpodFormController, FormState>((
            ref,
          ) {
            return RiverpodFormController(
              initialValue: {'custom_field': 'custom_value'},
            );
          });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterDependentField<String>(
                fieldId: customField,
                controllerProvider: customProvider,
                builder: (context, value) {
                  return Text('Custom: $value');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom: custom_value'), findsOneWidget);
    });

    testWidgets(
      'falls back to BetterForm.of(context) when no controller provider',
      (tester) async {
        final contextField = BetterFormFieldID<String>('context_field');

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BetterForm(
                  initialValue: const {'context_field': 'from_context'},
                  fields: [
                    BetterFormFieldConfig(
                      id: contextField,
                      initialValue: 'from_context',
                    ),
                  ],
                  child: BetterDependentField<String>(
                    fieldId: contextField,
                    builder: (context, value) {
                      return Text('Context: $value');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Context: from_context'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to default provider when no context or custom provider',
      (tester) async {
        final defaultField = BetterFormFieldID<String>('default_field');

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              formControllerProvider(
                const BetterFormParameter(initialValue: {}),
              ).overrideWith((ref) {
                return RiverpodFormController(
                  initialValue: {'default_field': 'from_default'},
                );
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: BetterDependentField<String>(
                  fieldId: defaultField,
                  builder: (context, value) {
                    return Text('Default: $value');
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('Default: from_default'), findsOneWidget);
      },
    );

    testWidgets('builder receives correct BuildContext', (tester) async {
      final contextField = BetterFormFieldID<String>('context_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'context_field': 'test'},
                fields: [
                  BetterFormFieldConfig(id: contextField, initialValue: 'test'),
                ],
                child: BetterDependentField<String>(
                  fieldId: contextField,
                  builder: (context, value) {
                    final mediaQuery = MediaQuery.maybeOf(context);

                    final hasMediaQuery = mediaQuery != null;
                    return Text(
                      'Has MediaQuery: $hasMediaQuery, Value: $value',
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Has MediaQuery: true, Value: test'), findsOneWidget);
    });

    testWidgets('handles complex data types', (tester) async {
      final listField = BetterFormFieldID<List<String>>('list_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {
                  'list_field': ['a', 'b', 'c'],
                },
                fields: [
                  BetterFormFieldConfig(
                    id: listField,
                    initialValue: ['a', 'b', 'c'],
                  ),
                ],
                child: BetterDependentField<List<String>>(
                  fieldId: listField,
                  builder: (context, value) {
                    return Text('List length: ${value?.length ?? 0}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('List length: 3'), findsOneWidget);

      // Change the list
      final provider = BetterForm.of(
        tester.element(find.text('List length: 3')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('List length: 3')),
      );
      container.read(provider.notifier).setValue(listField, ['x', 'y']);

      await tester.pump();

      expect(find.text('List length: 2'), findsOneWidget);
    });

    testWidgets('works with enum-like string values', (tester) async {
      final statusField = BetterFormFieldID<String>('status');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'status': 'active'},
                fields: [
                  BetterFormFieldConfig(
                    id: statusField,
                    initialValue: 'active',
                  ),
                ],
                child: BetterDependentField<String>(
                  fieldId: statusField,
                  builder: (context, value) {
                    return Text('Status: ${value?.toUpperCase()}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Status: ACTIVE'), findsOneWidget);

      // Change status
      final provider = BetterForm.of(
        tester.element(find.text('Status: ACTIVE')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Status: ACTIVE')),
      );
      container.read(provider.notifier).setValue(statusField, 'inactive');

      await tester.pump();

      expect(find.text('Status: INACTIVE'), findsOneWidget);
    });

    testWidgets('handles rapid consecutive changes', (tester) async {
      final counterField = BetterFormFieldID<int>('counter');
      int buildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'counter': 0},
                fields: [
                  BetterFormFieldConfig(id: counterField, initialValue: 0),
                ],
                child: BetterDependentField<int>(
                  fieldId: counterField,
                  builder: (context, value) {
                    buildCount++;
                    return Text('Count: $value');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(buildCount, 1);

      // Make rapid changes
      final provider = BetterForm.of(tester.element(find.text('Count: 0')))!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Count: 0')),
      );
      final controller = container.read(provider.notifier);

      controller.setValue(counterField, 1);
      await tester.pump();
      controller.setValue(counterField, 2);
      await tester.pump();
      controller.setValue(counterField, 3);
      await tester.pump();

      expect(find.text('Count: 3'), findsOneWidget);
      expect(
        buildCount,
        greaterThanOrEqualTo(2),
      ); // At least initial + final change
    });

    testWidgets('works with validation state changes', (tester) async {
      final validatedField = BetterFormFieldID<String>('validated_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                fields: [
                  BetterFormFieldConfig(
                    id: validatedField,
                    validator: (v) => (v?.length ?? 0) < 3 ? 'Too short' : null,
                  ),
                ],
                child: BetterDependentField<String>(
                  fieldId: validatedField,
                  builder: (context, value) {
                    return Text('Value: ${value ?? "null"}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Value: null'), findsOneWidget);

      // Set invalid value
      final provider = BetterForm.of(tester.element(find.text('Value: null')))!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Value: null')),
      );
      container.read(provider.notifier).setValue(validatedField, 'ab');

      await tester.pump();

      expect(find.text('Value: ab'), findsOneWidget);

      // Set valid value
      container.read(provider.notifier).setValue(validatedField, 'valid');

      await tester.pump();

      expect(find.text('Value: valid'), findsOneWidget);
    });

    testWidgets(
      'works with multiple dependent fields watching different fields',
      (tester) async {
        final field1 = BetterFormFieldID<String>('field1');
        final field2 = BetterFormFieldID<String>('field2');

        int buildCount1 = 0;
        int buildCount2 = 0;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: BetterForm(
                  initialValue: const {'field1': 'value1', 'field2': 'value2'},
                  fields: [
                    BetterFormFieldConfig(id: field1, initialValue: 'value1'),
                    BetterFormFieldConfig(id: field2, initialValue: 'value2'),
                  ],
                  child: Column(
                    children: [
                      BetterDependentField<String>(
                        fieldId: field1,
                        builder: (context, value) {
                          buildCount1++;
                          return Text('Field1: $value');
                        },
                      ),
                      BetterDependentField<String>(
                        fieldId: field2,
                        builder: (context, value) {
                          buildCount2++;
                          return Text('Field2: $value');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Field1: value1'), findsOneWidget);
        expect(find.text('Field2: value2'), findsOneWidget);
        expect(buildCount1, 1);
        expect(buildCount2, 1);

        // Change field1
        final provider = BetterForm.of(
          tester.element(find.text('Field1: value1')),
        )!;
        final container = ProviderScope.containerOf(
          tester.element(find.text('Field1: value1')),
        );
        container.read(provider.notifier).setValue(field1, 'changed1');

        await tester.pump();

        expect(find.text('Field1: changed1'), findsOneWidget);
        expect(find.text('Field2: value2'), findsOneWidget); // Unchanged
        expect(buildCount1, 2);
        expect(buildCount2, 1); // Should not have rebuilt
      },
    );

    testWidgets('handles field removal gracefully', (tester) async {
      final tempField = BetterFormFieldID<String>('temp_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'temp_field': 'exists'},
                fields: [
                  BetterFormFieldConfig(id: tempField, initialValue: 'exists'),
                ],
                child: BetterDependentField<String>(
                  fieldId: tempField,
                  builder: (context, value) {
                    return Text('Temp: ${value ?? "gone"}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Temp: exists'), findsOneWidget);

      // Remove the field
      final provider = BetterForm.of(
        tester.element(find.text('Temp: exists')),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.text('Temp: exists')),
      );
      (container.read(provider.notifier) as BetterFormController)
          .unregisterField(tempField);

      await tester.pump();

      expect(find.text('Temp: gone'), findsOneWidget);
    });
  });
}
