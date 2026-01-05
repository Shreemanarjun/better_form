import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

void main() {
  group('Golden Tests', () {
    testWidgets('TextFormField Appearance', (tester) async {
      final field = BetterFormFieldID<String>('text');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: BetterForm(
                    initialValue: const {'text': 'Initial Value'},
                    child: RiverpodTextFormField(
                      fieldId: field,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        hintText: 'Hint',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RiverpodTextFormField),
        matchesGoldenFile('goldens/text_field.png'),
      );
    });

    testWidgets('FormStatus Appearance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: BetterForm(
                    initialValue: const {'text': 'Something'},
                    child: const RiverpodFormStatus(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(RiverpodFormStatus),
        matchesGoldenFile('goldens/form_status.png'),
      );
    });
  });
}
