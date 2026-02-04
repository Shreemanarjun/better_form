import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixFieldAsyncTransformer', () {
    late FormixFieldID<String> sourceField;
    late FormixFieldID<String> targetField;

    setUp(() {
      sourceField = const FormixFieldID<String>('source');
      targetField = const FormixFieldID<String>('target');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      await tester.runAsync(() async {
        final widget = FormixFieldAsyncTransformer<String, String>(
          sourceField: sourceField,
          targetField: targetField,
          transform: (value) async => (value ?? '').toUpperCase(),
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Formix(
                initialValue: const {'source': 'initial', 'target': 'target'},
                fields: [
                  FormixFieldConfig(id: sourceField),
                  FormixFieldConfig(id: targetField),
                ],
                child: widget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byWidget(widget), findsOneWidget);
        expect(find.byType(SizedBox), findsOneWidget);
      });
    });

    testWidgets('transforms value asynchronously on source change', (
      tester,
    ) async {
      final widget = FormixFieldAsyncTransformer<String, String>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return (value ?? '').toUpperCase();
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'Hi', 'target': 'HI'},
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      );
      final controller = container.read(provider.notifier);

      // Wait for initial transform if any (none expected if values match)
      await tester.pumpAndSettle();

      // Change source value
      controller.setValue(sourceField, 'Hello');
      await tester.pump();

      // Should not be updated yet
      expect(controller.getValue(targetField), 'HI');

      // Wait for async transform
      await tester.pumpAndSettle();

      expect(controller.getValue(targetField), 'HELLO');
    });

    testWidgets('supports debounce', (tester) async {
      int transformCallCount = 0;

      final widget = FormixFieldAsyncTransformer<String, String>(
        sourceField: sourceField,
        targetField: targetField,
        debounce: const Duration(milliseconds: 200),
        transform: (value) async {
          transformCallCount++;
          return (value ?? '').toUpperCase();
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'start', 'target': 'START'},
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      );
      final controller = container.read(provider.notifier);

      // Wait for initial value debounce to settle completely
      await tester.pump(const Duration(seconds: 1));

      // Reset count after any initial calls
      transformCallCount = 0;

      // Rapidly change source value
      controller.setValue(sourceField, 'a');
      await tester.pump(const Duration(milliseconds: 50));

      controller.setValue(sourceField, 'ab');
      await tester.pump(const Duration(milliseconds: 50));

      controller.setValue(sourceField, 'abc');

      // Wait for debounce and processing
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(transformCallCount, greaterThan(0));
      expect(transformCallCount, lessThan(3));
      expect(controller.getValue(targetField), 'ABC');
    });

    testWidgets('handles errors gracefully in debug mode', (tester) async {
      final widget = FormixFieldAsyncTransformer<String, String>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) async {
          throw Exception('Async error');
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'initial', 'target': 'target'},
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(
          find.byType(FormixFieldAsyncTransformer<String, String>),
        ),
      );
      final controller = container.read(provider.notifier);

      // Trigger error
      controller.setValue(sourceField, 'new');
      await tester.pumpAndSettle();

      // Should not crash, target field should keep its initial value
      expect(controller.getValue(targetField), 'target');
    });

    testWidgets('handles widget disposal gracefully', (tester) async {
      await tester.runAsync(() async {
        final widget = FormixFieldAsyncTransformer<String, String>(
          sourceField: sourceField,
          targetField: targetField,
          transform: (value) async {
            await Future.delayed(const Duration(milliseconds: 200));
            return 'Disposed result';
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Formix(
                initialValue: const {'source': 'start', 'target': 'start'},
                fields: [
                  FormixFieldConfig(id: sourceField),
                  FormixFieldConfig(id: targetField),
                ],
                child: widget,
              ),
            ),
          ),
        );

        final provider = Formix.of(
          tester.element(
            find.byType(FormixFieldAsyncTransformer<String, String>),
          ),
        )!;
        final container = ProviderScope.containerOf(
          tester.element(
            find.byType(FormixFieldAsyncTransformer<String, String>),
          ),
        );
        final controller = container.read(provider.notifier);

        // Trigger async operation
        controller.setValue(sourceField, 'new');

        // Dispose widget immediately
        await tester.pumpWidget(Container());

        // Wait for async operation to theoretically complete
        await Future.delayed(const Duration(milliseconds: 300));
      });
    });
  });
}
