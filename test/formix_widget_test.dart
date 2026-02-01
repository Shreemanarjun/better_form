import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('Formix Widget Tests', () {
    testWidgets('should render child and provide controller', (tester) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: {'name': 'Default Name'},
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: nameField,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final controller = Formix.controllerOf(context);
                        return Text('Controller Ready: ${controller != null}');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Default Name'), findsOneWidget);
      expect(find.text('Controller Ready: true'), findsOneWidget);
    });

    testWidgets('should register fields passed to Formix constructor', (
      tester,
    ) async {
      final emailField = FormixFieldID<String>('email');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                fields: [
                  FormixFieldConfig<String>(
                    id: emailField,
                    initialValue: '',
                    validator: (value) => (value?.contains('@') ?? false)
                        ? null
                        : 'Invalid email',
                  ),
                ],
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: emailField,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final provider = Formix.of(context);
                        if (provider == null) return const Text('No Provider');
                        final formState = ref.watch(provider);
                        return Text('Is Valid: ${formState.isValid}');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Initially invalid because empty doesn't contain @
      expect(find.text('Is Valid: false'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(find.text('Is Valid: true'), findsOneWidget);
    });

    testWidgets('should handle reset via controller from Formix.of', (
      tester,
    ) async {
      final nameField = FormixFieldID<String>('name');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                initialValue: {'name': 'Original'},
                child: Column(
                  children: [
                    RiverpodTextFormField(fieldId: nameField),
                    Consumer(
                      builder: (context, ref, child) {
                        return ElevatedButton(
                          onPressed: () {
                            final provider = Formix.of(context);
                            if (provider != null) {
                              ref.read(provider.notifier).reset();
                            }
                          },
                          child: const Text('Reset Form'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Original'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Modified');
      await tester.pump();
      expect(find.text('Modified'), findsOneWidget);

      await tester.tap(find.text('Reset Form'));
      await tester.pump();

      expect(find.text('Original'), findsOneWidget);
    });

    testWidgets('should support nested Formixs with independent states', (
      tester,
    ) async {
      final fieldA = FormixFieldID<String>('field');
      final fieldB = FormixFieldID<String>('field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Formix(
                    key: const Key('form_a'),
                    initialValue: {'field': 'Form A'},
                    child: Column(
                      children: [
                        const Text('Scope A'),
                        RiverpodTextFormField(fieldId: fieldA),
                      ],
                    ),
                  ),
                  const Divider(),
                  Formix(
                    key: const Key('form_b'),
                    initialValue: {'field': 'Form B'},
                    child: Column(
                      children: [
                        const Text('Scope B'),
                        RiverpodTextFormField(fieldId: fieldB),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Form A'), findsOneWidget);
      expect(find.text('Form B'), findsOneWidget);

      // Modify first form
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('form_a')),
          matching: find.byType(TextField),
        ),
        'Changed A',
      );
      await tester.pump();

      expect(find.text('Changed A'), findsOneWidget);
      expect(find.text('Form B'), findsOneWidget);
    });
  });
}
