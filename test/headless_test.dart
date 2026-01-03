import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('BetterFieldStateSnapshot', () {
    test('shouldShowError returns true when touched and invalid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult(isValid: false, errorMessage: 'Error'),
        isDirty: true,
        isTouched: true,
        isSubmitting: false,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.shouldShowError, true);
      focusNode.dispose();
    });

    test('shouldShowError returns true when submitting and invalid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult(isValid: false, errorMessage: 'Error'),
        isDirty: true,
        isTouched: false,
        isSubmitting: true,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.shouldShowError, true);
      focusNode.dispose();
    });

    test('shouldShowError returns false when valid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult.valid,
        isDirty: true,
        isTouched: true,
        isSubmitting: true,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.shouldShowError, false);
      focusNode.dispose();
    });

    test('shouldShowError returns true when valid but touched/submitting and invalid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult(isValid: false, errorMessage: 'Error'),
        isDirty: true,
        isTouched: true,
        isSubmitting: false,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.shouldShowError, true);
      focusNode.dispose();
    });

    test('shouldShowError returns false when validating', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult.validating,
        isDirty: true,
        isTouched: true,
        isSubmitting: true,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.shouldShowError, false);
      focusNode.dispose();
    });

    test('hasError returns true when validation is invalid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult(isValid: false, errorMessage: 'Error'),
        isDirty: true,
        isTouched: true,
        isSubmitting: false,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.hasError, true);
      focusNode.dispose();
    });

    test('hasError returns false when validation is valid', () {
      final focusNode = FocusNode();
      final snapshot = BetterFieldStateSnapshot<String>(
        value: 'test',
        validation: ValidationResult.valid,
        isDirty: true,
        isTouched: true,
        isSubmitting: false,
        focusNode: focusNode,
        didChange: (_) {},
        markAsTouched: () {},
      );

      expect(snapshot.hasError, false);
      focusNode.dispose();
    });
  });

  group('BetterRawFormField', () {
    testWidgets('provides snapshot with correct initial state', (tester) async {
      final id = BetterFormFieldID<String>('test_field');
      BetterFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'test_field': 'initial'},
                fields: [BetterFormFieldConfig(id: id, initialValue: 'initial')],
                child: BetterRawFormField<String>(
                  fieldId: id,
                  initialValue: 'initial',
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot, isNotNull);
      expect(capturedSnapshot!.value, 'initial');
      expect(capturedSnapshot!.isDirty, false);
      expect(capturedSnapshot!.isTouched, false);
      expect(capturedSnapshot!.isSubmitting, false);
      expect(capturedSnapshot!.validation.isValid, true);
      expect(capturedSnapshot!.focusNode, isNotNull);
    });

    testWidgets('snapshot updates when value changes', (tester) async {
      final id = BetterFormFieldID<String>('test_field');
      BetterFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'test_field': 'initial'},
                fields: [BetterFormFieldConfig(id: id, initialValue: 'initial')],
                child: BetterRawFormField<String>(
                  fieldId: id,
                  initialValue: 'initial',
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Change value
      capturedSnapshot!.didChange('updated');
      await tester.pump();

      expect(capturedSnapshot!.value, 'updated');
      expect(capturedSnapshot!.isDirty, true);
    });

    testWidgets('snapshot updates when validation changes', (tester) async {
      final id = BetterFormFieldID<String>('test_field');
      BetterFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'test_field': ''}, // Start with empty string
                fields: [
                  BetterFormFieldConfig(
                    id: id,
                    initialValue: '',
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                  )
                ],
                child: BetterRawFormField<String>(
                  fieldId: id,
                  initialValue: '',
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Valid: ${snapshot.validation.isValid}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Initially invalid (empty string fails validation)
      expect(capturedSnapshot!.validation.isValid, false);

      // Set valid value
      capturedSnapshot!.didChange('valid');
      await tester.pump();

      expect(capturedSnapshot!.validation.isValid, true);
    });

    testWidgets('snapshot updates when touched state changes', (tester) async {
      final id = BetterFormFieldID<String>('test_field');
      BetterFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                fields: [BetterFormFieldConfig(id: id)],
                child: BetterRawFormField<String>(
                  fieldId: id,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Touched: ${snapshot.isTouched}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.isTouched, false);

      // Mark as touched
      capturedSnapshot!.markAsTouched();
      await tester.pump();

      expect(capturedSnapshot!.isTouched, true);
    });

    testWidgets('snapshot updates when submitting state changes', (tester) async {
      final id = BetterFormFieldID<String>('test_field');
      BetterFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                fields: [BetterFormFieldConfig(id: id)],
                child: BetterRawFormField<String>(
                  fieldId: id,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Submitting: ${snapshot.isSubmitting}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.isSubmitting, false);

      // Set submitting
      final provider = BetterForm.of(tester.element(find.text('Submitting: false')))!;
      final container = ProviderScope.containerOf(tester.element(find.text('Submitting: false')));
      (container.read(provider.notifier) as BetterFormController).setSubmitting(true);
      await tester.pump();

      expect(capturedSnapshot!.isSubmitting, true);
    });
  });

  group('BetterRawTextField', () {
    testWidgets('provides text snapshot with correct initial state', (tester) async {
      final id = BetterFormFieldID<String>('text_field');
      BetterTextFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'text_field': 'initial'},
                fields: [BetterFormFieldConfig(id: id, initialValue: 'initial')],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  initialValue: 'initial',
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot, isNotNull);
      expect(capturedSnapshot!.value, 'initial');
      expect(capturedSnapshot!.textController, isNotNull);
      expect(capturedSnapshot!.textController.text, 'initial');
    });

    testWidgets('text controller updates when value changes externally', (tester) async {
      final id = BetterFormFieldID<String>('text_field');
      BetterTextFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'text_field': 'initial'},
                fields: [BetterFormFieldConfig(id: id, initialValue: 'initial')],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  initialValue: 'initial',
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Controller: ${snapshot.textController.text}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.textController.text, 'initial');

      // Change value externally
      final provider = BetterForm.of(tester.element(find.text('Controller: initial')))!;
      final container = ProviderScope.containerOf(tester.element(find.text('Controller: initial')));
      container.read(provider.notifier).setValue(id, 'external');
      await tester.pump();

      expect(capturedSnapshot!.textController.text, 'external');
    });

    testWidgets('value updates when text controller changes', (tester) async {
      final id = BetterFormFieldID<String>('text_field');
      BetterTextFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'text_field': 'initial'},
                fields: [BetterFormFieldConfig(id: id, initialValue: 'initial')],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  initialValue: 'initial',
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.value, 'initial');

      // Change text controller
      capturedSnapshot!.textController.text = 'typed';
      await tester.pump();

      expect(capturedSnapshot!.value, 'typed');
    });

    testWidgets('custom valueToString and stringToValue work correctly', (tester) async {
      final id = BetterFormFieldID<int>('number_field');
      BetterTextFieldStateSnapshot<int>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'number_field': 42},
                fields: [BetterFormFieldConfig(id: id, initialValue: 42)],
                child: BetterRawTextField<int>(
                  fieldId: id,
                  initialValue: 42,
                  valueToString: (v) => v?.toString() ?? '',
                  stringToValue: (s) => int.tryParse(s),
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.value, 42);
      expect(capturedSnapshot!.textController.text, '42');

      // Change text controller
      capturedSnapshot!.textController.text = '123';
      await tester.pump();

      expect(capturedSnapshot!.value, 123);
    });

    testWidgets('handles null values correctly', (tester) async {
      final id = BetterFormFieldID<String>('nullable_field');
      BetterTextFieldStateSnapshot<String>? capturedSnapshot;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                fields: [BetterFormFieldConfig(id: id)],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, snapshot) {
                    capturedSnapshot = snapshot;
                    return Text('Value: ${snapshot.value ?? "null"}');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(capturedSnapshot!.value, isNull);
      expect(capturedSnapshot!.textController.text, '');

      // Change to non-null value using didChange (more reliable)
      capturedSnapshot!.didChange('not null');
      await tester.pump();

      expect(capturedSnapshot!.value, 'not null');
      expect(capturedSnapshot!.textController.text, 'not null');

      // Change back to null
      capturedSnapshot!.didChange(null);
      await tester.pump();

      expect(capturedSnapshot!.value, isNull);
      expect(capturedSnapshot!.textController.text, '');
    });
  });

  group('Headless Widgets (Standalone)', () {
    testWidgets('BetterRawTextField finds child after registration', (
      tester,
    ) async {
      final id = BetterFormFieldID<String>('standalone');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BetterForm(
                initialValue: const {'standalone': 'Initial'},
                fields: <BetterFormFieldConfig<dynamic>>[
                  BetterFormFieldConfig<String>(
                    id: id,
                    initialValue: 'Initial',
                  ),
                ],
                child: BetterRawTextField<String>(
                  fieldId: id,
                  initialValue: 'Initial',
                  valueToString: (v) => v ?? '',
                  stringToValue: (s) => s.isEmpty ? null : s,
                  builder: (context, state) {
                    return Container(
                      key: const Key('my_headless_container'),
                      child: Text('Value: ${state.value}'),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Pump to process the widget tree
      await tester.pump();
      // Pump again to process the microtask for field registration
      await tester.pump();

      // Now the widget should be rendered
      expect(find.byKey(const Key('my_headless_container')), findsOneWidget);
      expect(find.text('Value: Initial'), findsOneWidget);

      // Verify value update
      final element = tester.element(
        find.byKey(const Key('my_headless_container')),
      );
      final controller = BetterForm.controllerOf(element)!;

      controller.setValue(id, 'Alex');
      await tester.pump();

      expect(find.text('Value: Alex'), findsOneWidget);
    });
  });
}
