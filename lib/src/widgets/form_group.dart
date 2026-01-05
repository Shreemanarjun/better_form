import 'package:flutter/widgets.dart';
import '../controllers/field_id.dart';

/// A widget that provides a namespace for form fields.
///
/// Any [BetterFormFieldID] used within a [BetterFormGroup] can have the group's
/// prefix automatically prepended if they are resolved via the context.
/// This allows for easy nesting of form sections.
///
/// Example:
/// ```dart
/// BetterFormGroup(
///   prefix: 'user',
///   child: Column(
///     children: [
///       RiverpodTextFormField(fieldId: BetterFormFieldID('name')), // Resolves to 'user.name'
///       BetterFormGroup(
///         prefix: 'address',
///         child: RiverpodTextFormField(fieldId: BetterFormFieldID('city')), // Resolves to 'user.address.city'
///       ),
///     ],
///   ),
/// )
/// ```
class BetterFormGroup extends StatelessWidget {
  /// Creates a form group.
  const BetterFormGroup({super.key, required this.prefix, required this.child});

  /// The prefix for this group.
  final String prefix;

  /// The widget subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = context
        .dependOnInheritedWidgetOfExactType<_BetterFormGroupScope>();
    final fullPrefix = parent == null ? prefix : '${parent.fullPrefix}.$prefix';

    return _BetterFormGroupScope(
      prefix: prefix,
      fullPrefix: fullPrefix,
      child: child,
    );
  }

  /// Get the current combined prefix for the given [context].
  static String? prefixOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormGroupScope>();
    return scope?.fullPrefix;
  }

  /// Resolves a [BetterFormFieldID] by applying any active prefixes.
  static BetterFormFieldID<T> resolve<T>(
    BuildContext context,
    BetterFormFieldID<T> id,
  ) {
    final prefix = prefixOf(context);
    if (prefix == null) return id;
    return id.withPrefix(prefix);
  }
}

class _BetterFormGroupScope extends InheritedWidget {
  const _BetterFormGroupScope({
    required this.prefix,
    required this.fullPrefix,
    required super.child,
  });

  final String prefix;
  final String fullPrefix;

  @override
  bool updateShouldNotify(_BetterFormGroupScope oldWidget) =>
      prefix != oldWidget.prefix || fullPrefix != oldWidget.fullPrefix;
}
