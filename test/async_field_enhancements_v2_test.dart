import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixAsyncField Enhancements V2', () {
    testWidgets('isPending shortcut reflects field pending states', (
      tester,
    ) async {
      final completer = Completer<String>();
      final fieldId = const FormixFieldID<String>('async_field');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: FormixAsyncField<String>(
                  fieldId: fieldId,
                  future: completer.future,
                  builder: (context, state) =>
                      Text('Resolved: ${state.asyncState.value}'),
                  loadingBuilder: (context) => const Text('Loading...'),
                ),
              ),
            ),
          ),
        ),
      );

      final formixState = tester.state<FormixState>(find.byType(Formix));
      final controller = formixState.controller;

      // Initially loading, so should be pending
      expect(controller.state.isPending, isTrue);
      expect(controller.isPendingNotifier.value, isTrue);

      completer.complete('done');
      await tester.pumpAndSettle();

      // Resolved, should not be pending
      expect(controller.state.isPending, isFalse);
      expect(controller.isPendingNotifier.value, isFalse);
    });

    testWidgets('submit waits for pending field by default', (tester) async {
      final completer = Completer<String>();
      final fieldId = const FormixFieldID<String>('async_field');
      Map<String, dynamic>? submittedValues;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: Builder(
                  builder: (context) {
                    return Column(
                      children: [
                        FormixAsyncField<String>(
                          fieldId: fieldId,
                          future: completer.future,
                          builder: (context, state) =>
                              Text('Value: ${state.asyncState.value}'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Formix.controllerOf(context)!.submit(
                              onValid: (values) async {
                                submittedValues = values;
                              },
                            );
                          },
                          child: const Text('Submit'),
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

      // Start submission while field is pending
      await tester.tap(find.text('Submit'));
      await tester.pump(const Duration(milliseconds: 100));

      // Submission should be waiting for the field
      expect(submittedValues, isNull);

      final formixState = tester.state<FormixState>(find.byType(Formix));
      expect(formixState.controller.state.isSubmitting, isTrue);

      // Resolve the field
      completer.complete('async_value');

      // We need to pump enough times for the 'while' loop in _performSubmit to proceed
      // It waits for stream.first and then a zero delay.
      await tester.pump(); // Handle stream notification
      await tester.pump(); // Handle zero delay
      await tester.pumpAndSettle();

      expect(submittedValues, isNotNull);
      expect(submittedValues![fieldId.key], equals('async_value'));
    });

    testWidgets('reset clears pending states and re-triggers async field', (
      tester,
    ) async {
      int fetchCount = 0;
      final fieldId = const FormixFieldID<String>('async_field');

      Future<String> fetchData() async {
        fetchCount++;
        return 'data_$fetchCount';
      }

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Formix(
                child: FormixAsyncField<String>(
                  fieldId: fieldId,
                  future: fetchData(),
                  builder: (context, state) =>
                      Text('Value: ${state.asyncState.value}'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Value: data_1'), findsOneWidget);
      expect(fetchCount, equals(1));

      final formixState = tester.state<FormixState>(find.byType(Formix));
      final controller = formixState.controller;

      // Manually set a pending state to test clearing
      controller.setPending(const FormixFieldID<String>('other'), true);
      expect(controller.state.isPending, isTrue);

      // Reset the form
      controller.reset();
      await tester.pump(); // Trigger reset and refresh

      // Pending states should be cleared
      expect(controller.state.pendingStates, isEmpty);
      expect(
        controller.state.isPending,
        isTrue,
      ); // True because async_field is fetching again

      await tester.pumpAndSettle();
      expect(find.text('Value: data_2'), findsOneWidget);
      expect(fetchCount, equals(2));
      expect(controller.state.isPending, isFalse);
    });
  });
}
