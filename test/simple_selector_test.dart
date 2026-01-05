import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

void main() {
  testWidgets('BetterFormFieldConditionalSelector simple test', (tester) async {
    final fieldId = const BetterFormFieldID<String>('name');
    int buildCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BetterForm(
              initialValue: const {'name': 'A'},
              fields: [BetterFormFieldConfig(id: fieldId)],
              child: BetterFormFieldConditionalSelector<String>(
                fieldId: fieldId,
                shouldRebuild: (info) => true,
                builder: (context, info, child) {
                  buildCount++;
                  return Text('Value: ${info.value}');
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Value: A'), findsOneWidget);
    expect(buildCount, 1);
  });
}
