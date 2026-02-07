import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  testWidgets('FormixField used without ProviderScope or Formix should show helpful error', (tester) async {
    // This is expected to throw "No ProviderScope found" from Riverpod.
    // We want to avoid the "too much render error" and show something better if possible,
    // or at least ensure we don't have infinite loops.

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

    // We expect the widget to catch the error and display FormixConfigurationErrorWidget
    await tester.pump();
    final errorWidget = find.byType(FormixConfigurationErrorWidget);

    expect(errorWidget, findsOneWidget);
    expect(find.textContaining('Missing ProviderScope'), findsOneWidget);
  });
}
