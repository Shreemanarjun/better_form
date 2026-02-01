import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formix/formix.dart';

void main() {
  group('FormixLocalizations', () {
    test('supports all declared locales', () {
      final supportedLocales = FormixLocalizations.supportedLocales;

      expect(supportedLocales, contains('en'));
      expect(supportedLocales, contains('es'));
      expect(supportedLocales, contains('fr'));
      expect(supportedLocales, contains('de'));
      expect(supportedLocales, contains('hi'));
      expect(supportedLocales, contains('zh'));
    });

    test('isSupported returns correct values', () {
      expect(FormixLocalizations.isSupported('en'), isTrue);
      expect(FormixLocalizations.isSupported('es'), isTrue);
      expect(FormixLocalizations.isSupported('fr'), isTrue);
      expect(FormixLocalizations.isSupported('de'), isTrue);
      expect(FormixLocalizations.isSupported('hi'), isTrue);
      expect(FormixLocalizations.isSupported('zh'), isTrue);
      expect(FormixLocalizations.isSupported('xx'), isFalse);
    });

    test('forLocale returns correct messages for supported locales', () {
      final enMessages = FormixLocalizations.forLocale(const Locale('en'));
      expect(enMessages, isA<DefaultFormixMessages>());

      final esMessages = FormixLocalizations.forLocale(const Locale('es'));
      expect(esMessages, isA<SpanishFormixMessages>());

      final frMessages = FormixLocalizations.forLocale(const Locale('fr'));
      expect(frMessages, isA<FrenchFormixMessages>());

      final deMessages = FormixLocalizations.forLocale(const Locale('de'));
      expect(deMessages, isA<GermanFormixMessages>());

      final hiMessages = FormixLocalizations.forLocale(const Locale('hi'));
      expect(hiMessages, isA<HindiFormixMessages>());

      final zhMessages = FormixLocalizations.forLocale(const Locale('zh'));
      expect(zhMessages, isA<ChineseFormixMessages>());
    });

    test(
      'forLocale falls back to language code for country-specific locales',
      () {
        final enUSMessages = FormixLocalizations.forLocale(
          const Locale('en', 'US'),
        );
        expect(enUSMessages, isA<DefaultFormixMessages>());

        final esESMessages = FormixLocalizations.forLocale(
          const Locale('es', 'ES'),
        );
        expect(esESMessages, isA<SpanishFormixMessages>());

        final esMXMessages = FormixLocalizations.forLocale(
          const Locale('es', 'MX'),
        );
        expect(esMXMessages, isA<SpanishFormixMessages>());
      },
    );

    test('forLocale falls back to English for unsupported locales', () {
      final unsupportedMessages = FormixLocalizations.forLocale(
        const Locale('xx'),
      );
      expect(unsupportedMessages, isA<DefaultFormixMessages>());
    });

    test('registerLocale adds new locale', () {
      final customMessages = _CustomTestMessages();
      FormixLocalizations.registerLocale('test', () => customMessages);

      expect(FormixLocalizations.isSupported('test'), isTrue);
      final messages = FormixLocalizations.forLocale(const Locale('test'));
      expect(messages, isA<_CustomTestMessages>());

      // Cleanup
      FormixLocalizations.unregisterLocale('test');
    });

    test('registerLocale overrides existing locale', () {
      final customEnglish = _CustomTestMessages();
      FormixLocalizations.registerLocale('en', () => customEnglish);

      final messages = FormixLocalizations.forLocale(const Locale('en'));
      expect(messages, isA<_CustomTestMessages>());

      // Restore original
      FormixLocalizations.registerLocale(
        'en',
        () => const DefaultFormixMessages(),
      );
    });

    test('unregisterLocale removes locale', () {
      FormixLocalizations.registerLocale('test', () => _CustomTestMessages());
      expect(FormixLocalizations.isSupported('test'), isTrue);

      FormixLocalizations.unregisterLocale('test');
      expect(FormixLocalizations.isSupported('test'), isFalse);
    });

    testWidgets('of() returns correct messages based on context locale', (
      tester,
    ) async {
      FormixMessages? capturedMessages;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              capturedMessages = FormixLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );

      expect(capturedMessages, isA<SpanishFormixMessages>());
    });

    testWidgets('messages update when locale changes', (tester) async {
      FormixMessages? capturedMessages;
      Locale currentLocale = const Locale('en');

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              locale: currentLocale,
              supportedLocales: const [Locale('en'), Locale('es')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: Builder(
                builder: (context) {
                  capturedMessages = FormixLocalizations.of(context);
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentLocale = const Locale('es');
                      });
                    },
                    child: const Text('Change Locale'),
                  );
                },
              ),
            );
          },
        ),
      );

      expect(capturedMessages, isA<DefaultFormixMessages>());

      await tester.tap(find.text('Change Locale'));
      await tester.pumpAndSettle();

      expect(capturedMessages, isA<SpanishFormixMessages>());
    });
  });

  group('English Messages (DefaultFormixMessages)', () {
    const messages = DefaultFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email is required'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('Invalid format'));
    });

    test('minLength message', () {
      expect(messages.minLength(8), equals('Minimum length is 8 characters'));
    });

    test('maxLength message', () {
      expect(
        messages.maxLength(100),
        equals('Maximum length is 100 characters'),
      );
    });

    test('minValue message', () {
      expect(messages.minValue(18), equals('Minimum value is 18'));
    });

    test('maxValue message', () {
      expect(messages.maxValue(120), equals('Maximum value is 120'));
    });

    test('invalidSelection message', () {
      expect(messages.invalidSelection(), equals('Invalid selection'));
    });

    test('validationFailed message', () {
      expect(
        messages.validationFailed('Network error'),
        equals('Validation failed: Network error'),
      );
    });

    test('validating message', () {
      expect(messages.validating(), equals('Validating...'));
    });

    test('format helper works correctly', () {
      final result = messages.format(
        '{label} must be at least {min} characters',
        {'label': 'Password', 'min': 8},
      );
      expect(result, equals('Password must be at least 8 characters'));
    });
  });

  group('Spanish Messages (SpanishFormixMessages)', () {
    const messages = SpanishFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email es requerido'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('Formato inválido'));
    });

    test('minLength message', () {
      expect(
        messages.minLength(8),
        equals('La longitud mínima es 8 caracteres'),
      );
    });

    test('maxLength message', () {
      expect(
        messages.maxLength(100),
        equals('La longitud máxima es 100 caracteres'),
      );
    });

    test('minValue message', () {
      expect(messages.minValue(18), equals('El valor mínimo es 18'));
    });

    test('maxValue message', () {
      expect(messages.maxValue(120), equals('El valor máximo es 120'));
    });

    test('invalidSelection message', () {
      expect(messages.invalidSelection(), equals('Selección inválida'));
    });

    test('validationFailed message', () {
      expect(
        messages.validationFailed('Error de red'),
        equals('Validación falló: Error de red'),
      );
    });

    test('validating message', () {
      expect(messages.validating(), equals('Validando...'));
    });
  });

  group('French Messages (FrenchFormixMessages)', () {
    const messages = FrenchFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email est requis'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('Format invalide'));
    });

    test('minLength message', () {
      expect(
        messages.minLength(8),
        equals('La longueur minimale est de 8 caractères'),
      );
    });

    test('validating message', () {
      expect(messages.validating(), equals('Validation en cours...'));
    });
  });

  group('German Messages (GermanFormixMessages)', () {
    const messages = GermanFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email ist erforderlich'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('Ungültiges Format'));
    });

    test('minLength message', () {
      expect(messages.minLength(8), equals('Mindestlänge ist 8 Zeichen'));
    });

    test('validating message', () {
      expect(messages.validating(), equals('Validierung läuft...'));
    });
  });

  group('Hindi Messages (HindiFormixMessages)', () {
    const messages = HindiFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email आवश्यक है'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('अमान्य प्रारूप'));
    });

    test('minLength message', () {
      expect(messages.minLength(8), equals('न्यूनतम लंबाई 8 अक्षर है'));
    });

    test('validating message', () {
      expect(messages.validating(), equals('सत्यापित हो रहा है...'));
    });
  });

  group('Chinese Messages (ChineseFormixMessages)', () {
    const messages = ChineseFormixMessages();

    test('required message', () {
      expect(messages.required('Email'), equals('Email是必填项'));
    });

    test('invalidFormat message', () {
      expect(messages.invalidFormat(), equals('格式无效'));
    });

    test('minLength message', () {
      expect(messages.minLength(8), equals('最小长度为8个字符'));
    });

    test('validating message', () {
      expect(messages.validating(), equals('正在验证...'));
    });
  });

  group('Date Formatting', () {
    final testDate = DateTime(2024, 3, 15);

    test('English date format', () {
      const messages = DefaultFormixMessages();
      expect(messages.minDate(testDate), contains('2024-03-15'));
    });

    test('Spanish date format', () {
      const messages = SpanishFormixMessages();
      expect(messages.minDate(testDate), contains('15/03/2024'));
    });

    test('French date format', () {
      const messages = FrenchFormixMessages();
      expect(messages.minDate(testDate), contains('15/03/2024'));
    });

    test('German date format', () {
      const messages = GermanFormixMessages();
      expect(messages.minDate(testDate), contains('15.03.2024'));
    });

    test('Chinese date format', () {
      const messages = ChineseFormixMessages();
      expect(messages.minDate(testDate), contains('2024年03月15日'));
    });
  });

  group('Integration with Validators', () {
    testWidgets('validator uses locale-aware messages', (tester) async {
      String? capturedError;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextFormField(
                  validator: (value) {
                    final messages = FormixLocalizations.of(context);
                    if (value == null || value.isEmpty) {
                      capturedError = messages.required('Email');
                      return capturedError;
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.always,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(capturedError, equals('Email es requerido'));
    });

    testWidgets('validation messages update when locale changes', (
      tester,
    ) async {
      String? capturedError;
      Locale currentLocale = const Locale('en');

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              locale: currentLocale,
              supportedLocales: const [Locale('en'), Locale('fr')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) {
                          return TextFormField(
                            validator: (value) {
                              final messages = FormixLocalizations.of(context);
                              if (value == null || value.isEmpty) {
                                capturedError = messages.required('Email');
                                return capturedError;
                              }
                              return null;
                            },
                            autovalidateMode: AutovalidateMode.always,
                          );
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentLocale = const Locale('fr');
                          });
                        },
                        child: const Text('Change to French'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(capturedError, equals('Email is required'));

      await tester.tap(find.text('Change to French'));
      await tester.pumpAndSettle();

      expect(capturedError, equals('Email est requis'));
    });
  });

  group('Thread Safety and Immutability', () {
    test('messages instances are const and immutable', () {
      const msg1 = DefaultFormixMessages();
      const msg2 = DefaultFormixMessages();
      expect(identical(msg1, msg2), isTrue);
    });

    test('multiple concurrent locale lookups work correctly', () {
      final futures = List.generate(100, (i) {
        return Future(() {
          final locale = Locale(['en', 'es', 'fr', 'de'][i % 4]);
          return FormixLocalizations.forLocale(locale);
        });
      });

      expect(Future.wait(futures), completes);
    });
  });

  group('Edge Cases', () {
    test('handles null country code gracefully', () {
      final messages = FormixLocalizations.forLocale(const Locale('es'));
      expect(messages, isA<SpanishFormixMessages>());
    });

    test('handles unknown locale code', () {
      final messages = FormixLocalizations.forLocale(const Locale('xyz'));
      expect(messages, isA<DefaultFormixMessages>());
    });

    test('handles very long field labels', () {
      const messages = DefaultFormixMessages();
      final longLabel = 'A' * 1000;
      final result = messages.required(longLabel);
      expect(result, contains(longLabel));
    });

    test('handles special characters in labels', () {
      const messages = DefaultFormixMessages();
      expect(messages.required('Email@#\$%'), equals('Email@#\$% is required'));
    });

    test('handles numeric values correctly', () {
      const messages = DefaultFormixMessages();
      expect(messages.minValue(0), equals('Minimum value is 0'));
      expect(messages.minValue(-100), equals('Minimum value is -100'));
      expect(messages.minValue(1.5), equals('Minimum value is 1.5'));
    });
  });

  group('LocalizationsDelegate', () {
    test('delegate is available', () {
      expect(FormixLocalizations.delegate, isNotNull);
      expect(
        FormixLocalizations.delegate,
        isA<LocalizationsDelegate<FormixLocalizations>>(),
      );
    });

    test('delegate supports all locales', () {
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('en')),
        isTrue,
      );
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('es')),
        isTrue,
      );
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('fr')),
        isTrue,
      );
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('de')),
        isTrue,
      );
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('hi')),
        isTrue,
      );
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('zh')),
        isTrue,
      );
      // Should support any locale (falls back to English)
      expect(
        FormixLocalizations.delegate.isSupported(const Locale('xyz')),
        isTrue,
      );
    });

    test('delegate loads correct messages for locale', () async {
      final enLocalizations = await FormixLocalizations.delegate.load(
        const Locale('en'),
      );
      expect(enLocalizations.messages, isA<DefaultFormixMessages>());

      final esLocalizations = await FormixLocalizations.delegate.load(
        const Locale('es'),
      );
      expect(esLocalizations.messages, isA<SpanishFormixMessages>());
    });

    test('delegate shouldReload returns false', () {
      const delegate1 = FormixLocalizations.delegate;
      const delegate2 = FormixLocalizations.delegate;
      expect(delegate1.shouldReload(delegate2), isFalse);
    });

    testWidgets('delegate integrates with MaterialApp', (tester) async {
      FormixMessages? capturedMessages;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            FormixLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              capturedMessages = FormixLocalizations.of(context);
              return Container();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(capturedMessages, isA<SpanishFormixMessages>());
    });

    testWidgets('of() works with delegate registered', (tester) async {
      String? errorMessage;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            FormixLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final messages = FormixLocalizations.of(context);
                errorMessage = messages.required('Email');
                return Text(errorMessage!);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(errorMessage, equals('Email est requis'));
      expect(find.text('Email est requis'), findsOneWidget);
    });

    testWidgets('of() falls back when delegate not registered', (tester) async {
      String? errorMessage;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: const [
            // Note: FormixLocalizations.delegate NOT included
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final messages = FormixLocalizations.of(context);
                errorMessage = messages.required('Email');
                return Text(errorMessage!);
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Should still work, falling back to forLocale
      expect(errorMessage, equals('Email es requerido'));
    });
  });
}

class _CustomTestMessages extends FormixMessages {
  @override
  String required(String label) => 'TEST: $label required';

  @override
  String invalidFormat() => 'TEST: Invalid';

  @override
  String minLength(int minLength) => 'TEST: Min $minLength';

  @override
  String maxLength(int maxLength) => 'TEST: Max $maxLength';

  @override
  String minValue(num min) => 'TEST: Min value $min';

  @override
  String maxValue(num max) => 'TEST: Max value $max';

  @override
  String minDate(DateTime minDate) => 'TEST: Min date';

  @override
  String maxDate(DateTime maxDate) => 'TEST: Max date';

  @override
  String invalidSelection() => 'TEST: Invalid selection';

  @override
  String validationFailed(String error) => 'TEST: Failed $error';

  @override
  String validating() => 'TEST: Validating';
}
