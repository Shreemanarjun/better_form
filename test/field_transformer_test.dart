import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixFieldTransformer', () {
    late FormixFieldID<String> sourceField;
    late FormixFieldID<int> targetField;

    setUp(() {
      sourceField = FormixFieldID<String>('source');
      targetField = FormixFieldID<int>('target');
    });

    testWidgets('build returns SizedBox.shrink', (tester) async {
      final widget = FormixFieldTransformer<String, int>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) => value?.length ?? 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'initial', 'target': 0},
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      expect(find.byWidget(widget), findsOneWidget);
      // The widget should render as a SizedBox.shrink
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('transforms value on source change', (tester) async {
      final widget = FormixFieldTransformer<String, int>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) => value?.length ?? 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'Hi', 'target': 0},
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: widget,
            ),
          ),
        ),
      );

      // Get controller to check values
      final provider = Formix.of(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      );
      final controller = container.read(provider.notifier);

      // Initial value should be transformed
      expect(controller.getValue(targetField), 2);

      // Change source value
      controller.setValue(sourceField, 'Hello');
      await tester.pump();

      expect(controller.getValue(targetField), 5);
    });

    testWidgets('handles null source value', (tester) async {
      final widget = FormixFieldTransformer<String, int>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) => value?.length ?? 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': null, 'target': 0},
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
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      );
      final controller = container.read(provider.notifier);

      expect(controller.getValue(targetField), 0);

      // Change source to non-null
      controller.setValue(sourceField, 'Test');
      await tester.pump();

      expect(controller.getValue(targetField), 4);
    });

    testWidgets('handles errors gracefully in debug mode', (tester) async {
      final widget = FormixFieldTransformer<String, int>(
        sourceField: sourceField,
        targetField: targetField,
        transform: (value) {
          throw Exception('Test error');
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {'source': 'initial', 'target': 100},
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
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      );
      final controller = container.read(provider.notifier);

      // Should not crash, target field should keep its initial value
      expect(controller.getValue(targetField), 100);
    });

    testWidgets('updates listeners when properties change', (tester) async {
      final newSourceField = FormixFieldID<String>('newSource');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'old',
                'newSource': 'new',
                'target': 0,
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: newSourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: FormixFieldTransformer<String, int>(
                sourceField: sourceField,
                targetField: targetField,
                transform: (value) => value?.length ?? 0,
              ),
            ),
          ),
        ),
      );

      final provider = Formix.of(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      )!;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormixFieldTransformer<String, int>)),
      );
      final controller = container.read(provider.notifier);

      expect(controller.getValue(targetField), 3); // "old".length

      // Update widget to listen to newSourceField
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Formix(
              initialValue: const {
                'source': 'old',
                'newSource': 'new',
                'target': 0,
              },
              fields: [
                FormixFieldConfig(id: sourceField),
                FormixFieldConfig(id: newSourceField),
                FormixFieldConfig(id: targetField),
              ],
              child: FormixFieldTransformer<String, int>(
                sourceField: newSourceField,
                targetField: targetField,
                transform: (value) => value?.length ?? 0,
              ),
            ),
          ),
        ),
      );

      // Should update immediately with new source's value
      // "new".length is also 3, so let's check listeners update implicitly
      // by changing value of newSource
      controller.setValue(newSourceField, 'newer');
      await tester.pump();
      expect(controller.getValue(targetField), 5);

      // Changing old source should no longer affect target
      controller.setValue(sourceField, 'very long string');
      await tester.pump();
      expect(controller.getValue(targetField), 5);
    });
  });
}
