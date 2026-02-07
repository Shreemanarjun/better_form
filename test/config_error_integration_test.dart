import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  const fieldId = FormixFieldID<String>('test');

  group('Configuration Error Visibility Tests', () {
    testWidgets('Missing ProviderScope shows initialization error for FormixTextFormField', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Formix(
            child: Scaffold(
              body: FormixTextFormField(fieldId: fieldId),
            ),
          ),
        ),
      );

      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
    });

    testWidgets('Missing ProviderScope shows initialization error for FormixFieldSelector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Formix(
            child: Scaffold(
              body: FormixFieldSelector<String>(
                fieldId: fieldId,
                builder: _dummyBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
      expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
    });
  });
}

Widget _dummyBuilder(BuildContext context, FieldChangeInfo<String> info, Widget? child) {
  return const SizedBox();
}
