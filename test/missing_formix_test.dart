import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  testWidgets('FormixField used with ProviderScope but WITHOUT Formix should detect it', (tester) async {
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

    await tester.pump();

    expect(find.byType(FormixConfigurationErrorWidget), findsOneWidget);
    expect(find.textContaining('used outside of Formix'), findsOneWidget);
  });
}
