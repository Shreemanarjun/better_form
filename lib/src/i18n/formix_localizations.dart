import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../i18n.dart';

/// Provides locale-aware validation messages for Formix.
///
/// This class integrates with Flutter's localization system through
/// [FormixLocalizationsDelegate] to automatically provide the appropriate
/// [FormixMessages] implementation based on the current locale.
///
/// ## Supported Locales
///
/// Out of the box, Formix supports the following locales:
/// - English (en) - Default
/// - Spanish (es)
/// - French (fr)
/// - German (de)
/// - Hindi (hi)
/// - Simplified Chinese (zh)
///
/// ## Setup
///
/// Add [FormixLocalizations.delegate] to your app's localization delegates:
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: const [
///     FormixLocalizations.delegate,
///     GlobalMaterialLocalizations.delegate,
///     GlobalCupertinoLocalizations.delegate,
///     GlobalWidgetsLocalizations.delegate,
///   ],
///   supportedLocales: const [
///     Locale('en'),
///     Locale('es'),
///     Locale('fr'),
///     // ... other locales
///   ],
///   // ...
/// )
/// ```
///
/// ## Usage
///
/// ### Basic Usage
///
/// ```dart
/// // In your validator
/// validator: (value, context) {
///   final messages = FormixLocalizations.of(context);
///   if (value == null || value.isEmpty) {
///     return messages.required('Email');
///   }
///   return null;
/// }
/// ```
///
/// ### Adding Custom Locales
///
/// To add support for additional locales, create a custom messages class:
///
/// ```dart
/// class PortugueseFormixMessages extends FormixMessages {
///   const PortugueseFormixMessages();
///
///   @override
///   String required(String label) => '$label é obrigatório';
///
///   // ... implement other methods
/// }
///
/// // Register it before runApp
/// void main() {
///   FormixLocalizations.registerLocale('pt', () => const PortugueseFormixMessages());
///   runApp(MyApp());
/// }
/// ```
///
/// ### Overriding Default Messages
///
/// You can override messages for any locale:
///
/// ```dart
/// FormixLocalizations.registerLocale('en', () => const MyCustomEnglishMessages());
/// ```
class FormixLocalizations extends InheritedWidget {
  /// Creates a [FormixLocalizations] widget.
  const FormixLocalizations({
    required this.messages,
    required super.child,
    super.key,
  });

  /// The messages for the current locale.
  final FormixMessages messages;

  /// Registry of locale-specific message providers
  static final Map<String, FormixMessages Function()> _localeRegistry = {
    'en': () => const DefaultFormixMessages(),
    'es': () => const SpanishFormixMessages(),
    'fr': () => const FrenchFormixMessages(),
    'de': () => const GermanFormixMessages(),
    'hi': () => const HindiFormixMessages(),
    'zh': () => const ChineseFormixMessages(),
  };

  /// The delegate for [FormixLocalizations].
  ///
  /// Add this to your app's [MaterialApp.localizationsDelegates]:
  ///
  /// ```dart
  /// MaterialApp(
  ///   localizationsDelegates: const [
  ///     FormixLocalizations.delegate,
  ///     // ... other delegates
  ///   ],
  /// )
  /// ```
  static const LocalizationsDelegate<FormixLocalizations> delegate =
      _FormixLocalizationsDelegate();

  /// Get the [FormixMessages] for the current locale from the widget tree.
  ///
  /// This method looks up the [FormixLocalizations] widget in the widget tree
  /// and returns its messages. If no [FormixLocalizations] widget is found,
  /// it falls back to using [forLocale] with the current locale.
  ///
  /// Example:
  /// ```dart
  /// final messages = FormixLocalizations.of(context);
  /// return messages.required('Email');
  /// ```
  static FormixMessages of(BuildContext context) {
    final localizations = context
        .dependOnInheritedWidgetOfExactType<FormixLocalizations>();

    if (localizations != null) {
      return localizations.messages;
    }

    // Fallback if delegate is not registered
    final locale = Localizations.localeOf(context);
    return forLocale(locale);
  }

  /// Get [FormixMessages] for a specific [Locale].
  ///
  /// This is useful when you need to get messages for a locale
  /// without a BuildContext.
  ///
  /// Example:
  /// ```dart
  /// final messages = FormixLocalizations.forLocale(const Locale('es'));
  /// ```
  static FormixMessages forLocale(Locale locale) {
    // Try exact match first (e.g., 'en_US')
    final exactKey = '${locale.languageCode}_${locale.countryCode}';
    if (_localeRegistry.containsKey(exactKey)) {
      return _localeRegistry[exactKey]!();
    }

    // Fall back to language code only (e.g., 'en')
    if (_localeRegistry.containsKey(locale.languageCode)) {
      return _localeRegistry[locale.languageCode]!();
    }

    // Default to English
    return const DefaultFormixMessages();
  }

  /// Register a custom locale or override an existing one.
  ///
  /// This should be called before [runApp] to ensure the locale is available
  /// when the app starts.
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   FormixLocalizations.registerLocale(
  ///     'pt',
  ///     () => const PortugueseFormixMessages(),
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// To override an existing locale:
  /// ```dart
  /// FormixLocalizations.registerLocale(
  ///   'en',
  ///   () => const MyCustomEnglishMessages(),
  /// );
  /// ```
  static void registerLocale(
    String localeCode,
    FormixMessages Function() messagesProvider,
  ) {
    _localeRegistry[localeCode] = messagesProvider;
  }

  /// Unregister a locale.
  ///
  /// After unregistering, the locale will fall back to English.
  static void unregisterLocale(String localeCode) {
    _localeRegistry.remove(localeCode);
  }

  /// Get all registered locale codes.
  static List<String> get supportedLocales =>
      _localeRegistry.keys.toList(growable: false);

  /// Check if a locale is supported.
  static bool isSupported(String localeCode) =>
      _localeRegistry.containsKey(localeCode);

  @override
  bool updateShouldNotify(FormixLocalizations oldWidget) {
    return messages != oldWidget.messages;
  }
}

/// The delegate for [FormixLocalizations].
///
/// This delegate is responsible for loading the appropriate [FormixMessages]
/// implementation based on the current locale.
class _FormixLocalizationsDelegate
    extends LocalizationsDelegate<FormixLocalizations> {
  const _FormixLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Support all locales, falling back to English for unsupported ones
    return true;
  }

  @override
  Future<FormixLocalizations> load(Locale locale) {
    final messages = FormixLocalizations.forLocale(locale);
    return SynchronousFuture(
      FormixLocalizations(messages: messages, child: const SizedBox.shrink()),
    );
  }

  @override
  bool shouldReload(_FormixLocalizationsDelegate old) => false;
}
