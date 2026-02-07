import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  testWidgets('FormixField used WITHOUT ProviderScope should show friendly error', (tester) async {
    // 1. Missing ProviderScope should be detected first
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FormixTextFormField(
            fieldId: FormixFieldID('name'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
  });

  testWidgets('FormixField used with ProviderScope but WITHOUT Formix should show friendly error', (tester) async {
    // 2. With ProviderScope but without Formix, it should show Missing Formix Ancestor
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FormixTextFormField(
              fieldId: FormixFieldID('name'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    expect(find.textContaining('Missing Formix Ancestor'), findsOneWidget);
  });

  testWidgets('Formix used WITHOUT ProviderScope should show friendly error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Formix(
            child: FormixTextFormField(
              fieldId: FormixFieldID('name'),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
  });
}
