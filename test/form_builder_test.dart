import 'package:better_form/better_form.dart';
import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// A custom widget extending BetterFormWidget
class CustomStatusDisplay extends BetterFormWidget {
  const CustomStatusDisplay({super.key});

  @override
  Widget buildForm(BuildContext context, BetterFormScope scope) {
    return Column(
      children: [
        Text('State: ${scope.watchIsFormDirty ? "Dirty" : "Clean"}'),
        Text('Valid: ${scope.watchIsValid}'),
      ],
    );
  }
}

void main() {
  testWidgets('BetterFormBuilder provides scope with reactive watchValue', (
    tester,
  ) async {
    final field1 = BetterFormFieldID<String>('field1');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BetterForm(
              initialValue: const {'field1': 'initial'},
              fields: [BetterFormFieldConfig(id: field1)],
              child: BetterFormBuilder(
                builder: (context, scope) {
                  final value = scope.watchValue(field1);
                  return Column(
                    children: [
                      Text('Value: $value'),
                      ElevatedButton(
                        onPressed: () => scope.setValue(field1, 'changed'),
                        child: const Text('Change'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Value: initial'), findsOneWidget);

    await tester.tap(find.text('Change'));
    await tester.pump();

    expect(find.text('Value: changed'), findsOneWidget);
  });

  testWidgets(
    'BetterFormWidget extension provides scope with reactive getters',
    (tester) async {
      final field1 = BetterFormFieldID<String>('field1');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'field1': 'initial'},
                fields: [BetterFormFieldConfig(id: field1)],
                child: const CustomStatusDisplay(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('State: Clean'), findsOneWidget);
      expect(find.text('Valid: true'), findsOneWidget);

      // Trigger a change
      final provider = BetterForm.of(
        tester.element(find.byType(CustomStatusDisplay)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomStatusDisplay)),
      );
      container.read(provider.notifier).setValue(field1, 'dirty');

      await tester.pump();

      expect(find.text('State: Dirty'), findsOneWidget);
    },
  );

  testWidgets('BetterFormScope.submit helper works correctly', (tester) async {
    final field1 = BetterFormFieldID<String>('field1');
    bool submitted = false;
    Map<String, dynamic>? submittedValues;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BetterForm(
              fields: [
                BetterFormFieldConfig(
                  id: field1,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Error' : null,
                ),
              ],
              child: BetterFormBuilder(
                builder: (context, scope) {
                  return ElevatedButton(
                    onPressed: () => scope.submit(
                      onValid: (values) async {
                        submitted = true;
                        submittedValues = values;
                      },
                    ),
                    child: Text(
                      scope.watchIsSubmitting ? 'Submitting' : 'Submit',
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial click should fail validation
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(submitted, isFalse);

    // Set valid value
    final provider = BetterForm.of(tester.element(find.text('Submit')))!;
    final container = ProviderScope.containerOf(
      tester.element(find.text('Submit')),
    );
    container.read(provider.notifier).setValue(field1, 'valid');
    await tester.pump();

    // Click again
    await tester.tap(find.text('Submit'));
    // We don't pump yet to check submitting state if it was async,
    // but here it's immediate async.
    await tester.pump();

    expect(submitted, isTrue);
    expect(submittedValues?[field1.key], 'valid');
  });
}
