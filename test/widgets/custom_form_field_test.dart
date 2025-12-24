import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

// Define test field IDs
const nameField = BetterFormFieldID<String>('name');
const priorityField = BetterFormFieldID<String>('priority');
const tagsField = BetterFormFieldID<List<String>>('tags');

// Custom form field examples for testing

class TestTextField extends BetterFormFieldWidget<String> {
  const TestTextField({super.key, required super.fieldId, super.controller});

  @override
  BetterFormFieldWidgetState<String> createState() => _TestTextFieldState();
}

class _TestTextFieldState extends BetterFormFieldWidgetState<String> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: didChange,
      decoration: InputDecoration(
        errorText: validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit) : null,
      ),
    );
  }
}

class TestDropdownField extends BetterFormFieldWidget<String> {
  const TestDropdownField({
    super.key,
    required super.fieldId,
    super.controller,
  });

  @override
  BetterFormFieldWidgetState<String> createState() => _TestDropdownFieldState();
}

class _TestDropdownFieldState extends BetterFormFieldWidgetState<String> {
  final options = ['Low', 'Medium', 'High'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: (newValue) => didChange(newValue!),
      decoration: InputDecoration(
        errorText: validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit) : null,
      ),
    );
  }
}

class TestTagsField extends BetterFormFieldWidget<List<String>> {
  const TestTagsField({super.key, required super.fieldId, super.controller});

  @override
  BetterFormFieldWidgetState<List<String>> createState() =>
      _TestTagsFieldState();
}

class _TestTagsFieldState extends BetterFormFieldWidgetState<List<String>> {

  void addTag(String tag) {
    if (!value.contains(tag)) {
      didChange([...value, tag]);
    }
  }

  void removeTag(String tag) {
    didChange(value.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Tags: ${value.join(", ")}'),
        if (validation.errorMessage != null)
          Text(
            validation.errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        if (isDirty)
          const Text('Modified', style: TextStyle(color: Colors.blue)),
      ],
    );
  }
}

void main() {
  group('Custom Form Field Widget Tests', () {
    late BetterFormController controller;

    setUp(() {
      controller = BetterFormController(
        initialValue: {
          'name': 'John',
          'priority': 'Medium',
          'tags': <String>[],
        },
      );

      // Pre-register fields with validators (auto-registration happens for others)
      controller.registerField(
        BetterFormField(
          id: nameField,
          initialValue: 'John',
          validator: (value) => value.isEmpty ? 'Name required' : null,
        ),
      );

      controller.registerField(
        BetterFormField(
          id: tagsField,
          initialValue: <String>[],
          validator: (value) =>
              value.isEmpty ? 'At least one tag required' : null,
        ),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('TestTextField should display initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTextField(fieldId: nameField),
            ),
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
    });

    testWidgets('TestTextField should update value on text change', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTextField(fieldId: nameField),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(controller.getValue(nameField), 'Jane');
      expect(controller.isFieldDirty(nameField), true);
    });

    testWidgets('TestTextField should show validation error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTextField(fieldId: nameField),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();

      expect(find.text('Name required'), findsOneWidget);
      expect(controller.getValidation(nameField).isValid, false);
    });

    testWidgets('TestTextField should show dirty indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTextField(fieldId: nameField),
            ),
          ),
        ),
      );

      // Initially not dirty
      expect(find.byIcon(Icons.edit), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      // Should show dirty indicator
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('TestDropdownField should display initial value', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestDropdownField(fieldId: priorityField),
            ),
          ),
        ),
      );

      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('TestDropdownField should update value on selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestDropdownField(fieldId: priorityField),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('High').last);
      await tester.pumpAndSettle();

      expect(controller.getValue(priorityField), 'High');
      expect(controller.isFieldDirty(priorityField), true);
    });

    testWidgets('TestTagsField should display initial empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTagsField(fieldId: tagsField),
            ),
          ),
        ),
      );

      expect(find.text('Tags: '), findsOneWidget);
    });

    testWidgets('TestTagsField should show validation error when empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTagsField(fieldId: tagsField),
            ),
          ),
        ),
      );

      // Trigger validation by checking controller
      expect(controller.getValidation(tagsField).isValid, false);
      expect(find.text('At least one tag required'), findsOneWidget);
    });

    testWidgets('TestTagsField should handle programmatic value changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: TestTagsField(fieldId: tagsField),
            ),
          ),
        ),
      );

      // Initially empty
      expect(find.text('Tags: '), findsOneWidget);

      // Programmatically add a tag
      controller.setValue(tagsField, ['flutter']);
      await tester.pump();

      expect(find.text('Tags: flutter'), findsOneWidget);
      expect(controller.isFieldDirty(tagsField), true);
    });

    testWidgets('Custom fields should work with BetterFormFieldListener', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormFieldListener<String>(
                    fieldId: nameField,
                    builder: (context, value, child) {
                      return Text('Current name: $value');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Current name: John'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(find.text('Current name: Jane'), findsOneWidget);
    });

    testWidgets('Custom fields should work with BetterFormDirtyListener', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormDirtyListener(
                    builder: (context, isDirty, child) {
                      return Text(isDirty ? 'Form modified' : 'Form clean');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Form clean'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(find.text('Form modified'), findsOneWidget);
    });

    testWidgets(
      'BetterForm.of(context) should provide controller access anywhere',
      (tester) async {
        late BetterFormController accessedController;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterForm(
                controller: controller,
                child: Builder(
                  builder: (context) {
                    // Access controller via context
                    accessedController = BetterForm.of(context)!;
                    return TestTextField(fieldId: nameField);
                  },
                ),
              ),
            ),
          ),
        );

        // Verify the accessed controller is the same as the original
        expect(accessedController, same(controller));
        expect(accessedController.getValue(nameField), 'John');
      },
    );

    testWidgets('Context access should work in deeply nested widgets', (
      tester,
    ) async {
      late BetterFormController accessedController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      // Access controller from deeply nested context
                      accessedController = BetterForm.of(context)!;
                      return TestTextField(fieldId: nameField);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify the accessed controller works correctly
      expect(accessedController, same(controller));
      expect(accessedController.getValue(nameField), 'John');

      // Test that changes through context access work
      accessedController.setValue(nameField, 'Jane');
      await tester.pump();

      // The field should update to show the new value
      expect(controller.getValue(nameField), 'Jane');
      expect(accessedController.getValue(nameField), 'Jane');
    });

    testWidgets('ValueListenableBuilder should listen to field value changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormFieldValueListenableBuilder<String>(
                    fieldId: nameField,
                    builder: (context, value, child) {
                      return Text('Listened value: $value');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Listened value: John'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(find.text('Listened value: Jane'), findsOneWidget);
    });

    testWidgets(
      'ValueListenableBuilder should listen to field validation changes',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterForm(
                controller: controller,
                child: Column(
                  children: [
                    TestTextField(fieldId: nameField),
                    BetterFormFieldValidationListenableBuilder<String>(
                      fieldId: nameField,
                      builder: (context, validation, child) {
                        return Text(
                          'Validation: ${validation.isValid ? "Valid" : "Invalid"}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Validation: Valid'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '');
        await tester.pump();

        expect(find.text('Validation: Invalid'), findsOneWidget);
      },
    );

    testWidgets(
      'ValueListenableBuilder should listen to field dirty state changes',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterForm(
                controller: controller,
                child: Column(
                  children: [
                    TestTextField(fieldId: nameField),
                    BetterFormFieldDirtyListenableBuilder<String>(
                      fieldId: nameField,
                      builder: (context, isDirty, child) {
                        return Text('Dirty: $isDirty');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(find.text('Dirty: false'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'Jane');
        await tester.pump();

        expect(find.text('Dirty: true'), findsOneWidget);
      },
    );

    testWidgets('Combined field listenable builder should work', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormFieldListenableBuilder<String>(
                    fieldId: nameField,
                    builder: (context, value, validation, isDirty) {
                      return Text(
                        'Combined: $value, ${validation.isValid}, $isDirty',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Combined: John, true, false'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(find.text('Combined: Jane, true, true'), findsOneWidget);
    });

    testWidgets('Form dirty listenable builder should work', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormDirtyListenableBuilder(
                    builder: (context, isDirty, child) {
                      return Text('Form dirty: $isDirty');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Form dirty: false'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(find.text('Form dirty: true'), findsOneWidget);
    });

    testWidgets(
      'BetterFormFieldSelector should provide granular change information',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterForm(
                controller: controller,
                child: Column(
                  children: [
                    TestTextField(fieldId: nameField),
                    BetterFormFieldSelector<String>(
                      fieldId: nameField,
                      builder: (context, info, child) {
                        return Text(
                          'Value: "${info.value}" | Valid: ${info.validation.isValid} | '
                          'Dirty: ${info.isDirty} | Changed: ${info.hasInitialValueChanged}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(
          find.text(
            'Value: "John" | Valid: true | Dirty: false | Changed: false',
          ),
          findsOneWidget,
        );

        await tester.enterText(find.byType(TextFormField), 'Jane');
        await tester.pump();

        expect(
          find.text(
            'Value: "Jane" | Valid: true | Dirty: true | Changed: true',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('BetterFormFieldSelector should respect listen flags', (
      tester,
    ) async {
      int rebuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormFieldSelector<String>(
                    fieldId: nameField,
                    listenToValue: true,
                    listenToValidation: false, // Don't listen to validation
                    listenToDirty: false, // Don't listen to dirty state
                    builder: (context, info, child) {
                      rebuildCount++;
                      return Text('Rebuild $rebuildCount: ${info.value}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(rebuildCount, 1); // Initial build
      expect(find.text('Rebuild 1: John'), findsOneWidget);

      // Change value - should rebuild
      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();
      expect(rebuildCount, 2);
      expect(find.text('Rebuild 2: Jane'), findsOneWidget);
    });

    testWidgets('BetterFormFieldPerformanceMonitor should track rebuilds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: Column(
                children: [
                  TestTextField(fieldId: nameField),
                  BetterFormFieldPerformanceMonitor<String>(
                    fieldId: nameField,
                    builder: (context, info, rebuildCount) {
                      return Text('${info.value} (rebuilds: $rebuildCount)');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('John (rebuilds: 1)'), findsOneWidget);

      // Change value programmatically to trigger rebuild
      controller.setValue(nameField, 'Jane');
      await tester.pump();

      expect(find.text('Jane (rebuilds: 2)'), findsOneWidget);
    });

    testWidgets(
      'BetterFormFieldConditionalSelector should rebuild based on condition',
      (tester) async {
        int rebuildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BetterForm(
                controller: controller,
                child: Column(
                  children: [
                    TestTextField(fieldId: nameField),
                    BetterFormFieldConditionalSelector<String>(
                      fieldId: nameField,
                      shouldRebuild: (info) =>
                          info.valueChanged, // Only rebuild on value changes
                      builder: (context, info, child) {
                        rebuildCount++;
                        return Text(
                          'Conditional rebuild $rebuildCount: ${info.value}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(
          rebuildCount,
          0,
        ); // Should not rebuild initially since no value change yet
        expect(find.text('Conditional rebuild'), findsNothing);

        // Change value - should rebuild
        await tester.enterText(find.byType(TextFormField), 'Jane');
        await tester.pump();

        expect(rebuildCount, 1);
        expect(find.text('Conditional rebuild 1: Jane'), findsOneWidget);
      },
    );
  });

  group('Ready-made Form Field Widget Tests', () {
    late BetterFormController controller;

    setUp(() {
      controller = BetterFormController(
        initialValue: {'name': 'John', 'age': 25, 'isStudent': false},
      );

      controller.registerField(
        BetterFormField(
          id: nameField,
          initialValue: 'John',
          validator: (value) => value.isEmpty ? 'Required' : null,
        ),
      );

      controller.registerField(
        BetterFormField(
          id: const BetterFormFieldID<int>('age'),
          initialValue: 25,
        ),
      );

      controller.registerField(
        BetterFormField(
          id: const BetterFormFieldID<bool>('isStudent'),
          initialValue: false,
        ),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('BetterTextFormField should work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: BetterTextFormField(
                fieldId: nameField,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Jane');
      await tester.pump();

      expect(controller.getValue(nameField), 'Jane');
    });

    testWidgets('BetterNumberFormField should work correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: BetterNumberFormField(
                fieldId: const BetterFormFieldID<int>('age'),
                decoration: const InputDecoration(labelText: 'Age'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('25'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '30');
      await tester.pump();

      expect(controller.getValue(const BetterFormFieldID<int>('age')), 30);
    });

    testWidgets('BetterCheckboxFormField should work correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterForm(
              controller: controller,
              child: BetterCheckboxFormField(
                fieldId: const BetterFormFieldID<bool>('isStudent'),
                title: const Text('Student?'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Student?'), findsOneWidget);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(
        controller.getValue(const BetterFormFieldID<bool>('isStudent')),
        true,
      );
    });
  });
}

// Helper widget for testing tags field interactions
class TestTagsWidget extends StatefulWidget {
  const TestTagsWidget({super.key, required this.controller});

  final BetterFormController controller;

  @override
  State<TestTagsWidget> createState() => _TestTagsWidgetState();
}

class _TestTagsWidgetState extends State<TestTagsWidget> {
  @override
  Widget build(BuildContext context) {
    return BetterForm(
      controller: widget.controller,
      child: Column(
        children: [
          TestTagsField(fieldId: tagsField),
          ElevatedButton(
            key: const Key('add-tag'),
            onPressed: () =>
                (context.findAncestorStateOfType<_TestTagsFieldState>()
                        as _TestTagsFieldState)
                    .addTag('flutter'),
            child: const Text('Add Flutter'),
          ),
          ElevatedButton(
            key: const Key('add-tag-2'),
            onPressed: () =>
                (context.findAncestorStateOfType<_TestTagsFieldState>()
                        as _TestTagsFieldState)
                    .addTag('dart'),
            child: const Text('Add Dart'),
          ),
          ElevatedButton(
            key: const Key('remove-tag-0'),
            onPressed: () =>
                (context.findAncestorStateOfType<_TestTagsFieldState>()
                        as _TestTagsFieldState)
                    .removeTag('flutter'),
            child: const Text('Remove Flutter'),
          ),
        ],
      ),
    );
  }
}
