import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Multi-Form Integration Tests', () {
    testWidgets('Parallel forms should have independent states', (
      tester,
    ) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Formix(
                    key: const Key('form_1'),
                    initialValue: {'name': 'Form 1'},
                    child: Column(
                      children: [
                        const Text('Form One'),
                        RiverpodTextFormField(fieldId: nameField),
                      ],
                    ),
                  ),
                  Formix(
                    key: const Key('form_2'),
                    initialValue: {'name': 'Form 2'},
                    child: Column(
                      children: [
                        const Text('Form Two'),
                        RiverpodTextFormField(fieldId: nameField),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check initial values
      expect(find.text('Form 1'), findsOneWidget);
      expect(find.text('Form 2'), findsOneWidget);

      // Update Form 1
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('form_1')),
          matching: find.byType(TextField),
        ),
        'Updated 1',
      );
      await tester.pump();

      expect(find.text('Updated 1'), findsOneWidget);
      expect(find.text('Form 2'), findsOneWidget);
      expect(find.text('Form 1'), findsNothing);

      // Update Form 2
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('form_2')),
          matching: find.byType(TextField),
        ),
        'Updated 2',
      );
      await tester.pump();

      expect(find.text('Updated 1'), findsOneWidget);
      expect(find.text('Updated 2'), findsOneWidget);
    });

    testWidgets('Nested forms should isolate inner scopes', (tester) async {
      final outerField = FormixFieldID<String>('outer');
      final innerField = FormixFieldID<String>('inner');
      final sharedField = FormixFieldID<String>('shared');

      FormixController? innerController;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                key: const Key('outer_form'),
                initialValue: {'outer': 'O', 'shared': 'Outer Shared'},
                child: Column(
                  children: [
                    RiverpodTextFormField(fieldId: outerField),
                    RiverpodTextFormField(fieldId: sharedField),
                    const Divider(),
                    Formix(
                      key: const Key('inner_form'),
                      initialValue: {'inner': 'I', 'shared': 'Inner Shared'},
                      child: FormixBuilder(
                        builder: (context, scope) {
                          innerController = scope.controller;
                          return Column(
                            children: [
                              RiverpodTextFormField(fieldId: innerField),
                              RiverpodTextFormField(fieldId: sharedField),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('O'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('Outer Shared'), findsOneWidget);
      expect(find.text('Inner Shared'), findsOneWidget);

      expect(innerController, isNotNull);
      expect(innerController!.getValue(sharedField), 'Inner Shared');
      expect(innerController!.getValue(outerField), null);

      // Update shared field in inner form
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('inner_form')),
          matching: find.widgetWithText(TextField, 'Inner Shared'),
        ),
        'Modified Inner',
      );
      await tester.pump();

      expect(find.text('Outer Shared'), findsOneWidget);
      expect(find.text('Modified Inner'), findsOneWidget);
    });

    testWidgets('Validation remains independent across multiple forms', (
      tester,
    ) async {
      final fieldId = FormixFieldID<String>('field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Formix(
                    key: const Key('form_valid'),
                    fields: [
                      FormixFieldConfig<String>(
                        id: fieldId,
                        validator: (v) => null, // Always valid
                      ),
                    ],
                    child: FormixBuilder(
                      builder: (context, scope) {
                        return Text('Form 1 Valid: ${scope.watchIsValid}');
                      },
                    ),
                  ),
                  Formix(
                    key: const Key('form_invalid'),
                    fields: [
                      FormixFieldConfig<String>(
                        id: fieldId,
                        initialValue: '',
                        validator: (v) =>
                            (v?.isEmpty ?? true) ? 'Required' : null,
                      ),
                    ],
                    child: FormixBuilder(
                      builder: (context, scope) {
                        return Column(
                          children: [
                            Text('Form 2 Valid: ${scope.watchIsValid}'),
                            RiverpodTextFormField(fieldId: fieldId),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Form 1 should be valid, Form 2 should be invalid (initially empty)
      expect(find.text('Form 1 Valid: true'), findsOneWidget);
      expect(find.text('Form 2 Valid: false'), findsOneWidget);

      // Make Form 2 valid
      await tester.enterText(find.byType(TextField), 'Value');
      await tester.pump();

      expect(find.text('Form 1 Valid: true'), findsOneWidget);
      expect(find.text('Form 2 Valid: true'), findsOneWidget);
    });

    testWidgets('Formix.of returns null when no form is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final provider = Formix.of(context);
                return Text('No Form: ${provider == null}');
              },
            ),
          ),
        ),
      );

      expect(find.text('No Form: true'), findsOneWidget);
    });

    testWidgets('Dynamic form replacement works seamlessly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: _DynamicFormSwitcher())),
        ),
      );

      expect(find.text('A'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(find.text('B'), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });
  });
}

class _DynamicFormSwitcher extends StatefulWidget {
  const _DynamicFormSwitcher();

  @override
  State<_DynamicFormSwitcher> createState() => _DynamicFormSwitcherState();
}

class _DynamicFormSwitcherState extends State<_DynamicFormSwitcher> {
  bool useFormA = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (useFormA)
          Formix(
            key: const ValueKey('form_a'),
            initialValue: {'field': 'A'},
            child: RiverpodTextFormField(
              fieldId: FormixFieldID<String>('field'),
            ),
          )
        else
          Formix(
            key: const ValueKey('form_b'),
            initialValue: {'field': 'B'},
            child: RiverpodTextFormField(
              fieldId: FormixFieldID<String>('field'),
            ),
          ),
        ElevatedButton(
          onPressed: () => setState(() => useFormA = !useFormA),
          child: const Text('Switch'),
        ),
      ],
    );
  }
}
