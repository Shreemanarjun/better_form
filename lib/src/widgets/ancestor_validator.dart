import 'package:flutter/widgets.dart';
import '../../formix.dart';

/// Type alias for the Formix controller provider.
typedef FormixProvider = AutoDisposeStateNotifierProvider<FormixController, FormixData>;

/// A utility class to validate the presence of required ancestors for Formix widgets.
class FormixAncestorValidator {
  /// Validates both [ProviderScope] and [Formix] ancestors.
  ///
  /// Returns a [FormixConfigurationErrorWidget] if a required ancestor is missing,
  /// otherwise returns null.
  static Widget? validate(
    BuildContext context, {
    required String widgetName,
    FormixProvider? explicitProvider,
    bool hasExplicitController = false,
    bool requireFormix = true,
  }) {
    // 1. Check for ProviderScope first
    if (context.getElementForInheritedWidgetOfExactType<UncontrolledProviderScope>() == null) {
      return const FormixConfigurationErrorWidget(
        message: 'Missing ProviderScope',
        details:
            'Formix requires a ProviderScope at the root of your application to manage form state using Riverpod.\n\nExample:\nvoid main() {\n  runApp(ProviderScope(child: MyApp()));\n}',
      );
    }

    // 2. Check for Formix ancestor or explicit provider/controller
    if (!requireFormix || hasExplicitController) return null;

    final provider = explicitProvider ?? Formix.of(context);

    if (provider == null) {
      return FormixConfigurationErrorWidget(
        message: 'Missing Formix Ancestor',
        details: '$widgetName must be used inside a Formix widget.\n\nExample:\nFormix(\n  child: $widgetName(...),\n)',
      );
    }

    return null;
  }
}
