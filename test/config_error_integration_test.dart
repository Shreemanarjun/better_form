import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  const fieldId = FormixFieldID<String>('test');
  const boolFieldId = FormixFieldID<bool>('bool');

  group('Configuration Error Visibility Tests', () {
    // Helper to wrap with ProviderScope and MaterialApp
    Future<void> pumpWithErrorCheck(WidgetTester tester, Widget widget) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        ),
      );
    }

    testWidgets('FormixTextFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(tester, const FormixTextFormField(fieldId: fieldId));
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      expect(find.textContaining('FormixTextFormField used outside of Formix'), findsOneWidget);
      expect(find.textContaining('This widget requires a Formix ancestor'), findsOneWidget);
    });

    testWidgets('FormixCupertinoTextFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(tester, const FormixCupertinoTextFormField(fieldId: fieldId));
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      expect(find.textContaining('FormixCupertinoTextFormField used outside of Formix'), findsOneWidget);
    });

    testWidgets('FormixAdaptiveTextFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(tester, const FormixAdaptiveTextFormField(fieldId: fieldId));
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixCheckboxFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(tester, const FormixCheckboxFormField(fieldId: boolFieldId));
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixDropdownFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        const FormixDropdownFormField<String>(
          fieldId: fieldId,
          items: [DropdownMenuItem(value: 'a', child: Text('A'))],
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixNumberFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(tester, const FormixNumberFormField(fieldId: FormixFieldID<num>('num')));
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixAsyncField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixAsyncField<String>(
          fieldId: fieldId,
          manual: true,
          builder: (context, state) => const Text('Data'),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixArray shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixArray(
          id: const FormixArrayID<List<dynamic>>('array'),
          itemBuilder: (context, index, id, scope) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('SliverFormixArray shows error outside Formix', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverFormixArray(
                    id: FormixArrayID<List<dynamic>>('array'),
                    itemBuilder: _dummyArrayBuilder,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixSection shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        const FormixSection(
          fields: [],
          child: SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixNavigationGuard shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        const FormixNavigationGuard(
          child: SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldDerivation shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldDerivation(
          dependencies: const [],
          derive: (data) => 'derived',
          targetField: fieldId,
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldTransformer shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldTransformer<String, String>(
          sourceField: const FormixFieldID('source'),
          targetField: fieldId,
          transform: (v) => v ?? '',
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldAsyncTransformer shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldAsyncTransformer<String, String>(
          sourceField: const FormixFieldID('source'),
          targetField: fieldId,
          transform: (v) async => v ?? '',
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldDerivations shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        const FormixFieldDerivations(
          derivations: [],
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixBuilder shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixBuilder(
          builder: (context, scope) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldSelector shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldSelector<String>(
          fieldId: fieldId,
          builder: (context, info, child) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldValueSelector shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldValueSelector<String>(
          fieldId: fieldId,
          builder: (context, value, child) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldConditionalSelector shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldConditionalSelector<String>(
          fieldId: fieldId,
          shouldRebuild: (info) => true,
          builder: (context, info, child) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldPerformanceMonitor shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixFieldPerformanceMonitor<String>(
          fieldId: fieldId,
          builder: (context, info, count) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixDependentField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixDependentField<String>(
          fieldId: fieldId,
          builder: (context, value) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixDependentAsyncField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixDependentAsyncField<String, String>(
          fieldId: fieldId,
          dependency: const FormixFieldID('dep'),
          future: (v) => Future.value('res'),
          builder: (context, state) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixFieldRegistry shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        const FormixFieldRegistry(
          fields: [],
          child: SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixRawFormField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixRawFormField<String>(
          fieldId: fieldId,
          builder: (context, state) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixRawTextField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixRawTextField<String>(
          fieldId: fieldId,
          valueToString: (v) => v ?? '',
          stringToValue: (s) => s,
          builder: (context, state) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixRawStringField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixRawStringField(
          fieldId: fieldId,
          builder: (context, state) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('FormixRawNotifierField shows error outside Formix', (tester) async {
      await pumpWithErrorCheck(
        tester,
        FormixRawNotifierField<String>(
          fieldId: fieldId,
          builder: (context, state) => const SizedBox(),
        ),
      );
      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    });

    testWidgets('Missing ProviderScope shows initialization error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FormixTextFormField(fieldId: fieldId),
          ),
        ),
      );

      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
      expect(find.textContaining('runApp(ProviderScope(child: MyApp()));'), findsOneWidget);
    });
    group('Sliver Widget Edge Cases', () {
      testWidgets('SliverFormixArray in viewport shows error outside Formix', (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    SliverFormixArray(
                      id: FormixArrayID<List<dynamic>>('array'),
                      itemBuilder: _dummyArrayBuilder,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      });
    });
  });
}

Widget _dummyArrayBuilder(BuildContext context, int index, FormixFieldID<List<dynamic>> id, FormixScope scope) => const SizedBox();
