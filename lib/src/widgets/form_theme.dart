import 'package:flutter/material.dart';

/// Defines the visual theme for Formix fields.
class FormixThemeData {
  /// The default decoration theme to apply to [Formix] fields.
  final InputDecorationTheme? decorationTheme;

  /// Whether this theme is enabled and should be applied to fields.
  final bool enabled;

  /// Global loading icon to show during async validation.
  final Widget? loadingIcon;

  /// Global icon to show when a field is dirty.
  final Widget? editIcon;

  /// Creates a [FormixThemeData] with the given parameters.
  const FormixThemeData({
    this.decorationTheme,
    this.enabled = true,
    this.loadingIcon,
    this.editIcon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormixThemeData &&
          runtimeType == other.runtimeType &&
          decorationTheme == other.decorationTheme &&
          enabled == other.enabled &&
          loadingIcon == other.loadingIcon &&
          editIcon == other.editIcon;

  @override
  int get hashCode => Object.hash(decorationTheme, enabled, loadingIcon, editIcon);
}

/// An InheritedWidget that provides [FormixThemeData] to its descendants.
class FormixTheme extends InheritedWidget {
  /// The [FormixThemeData] provided by this widget.
  final FormixThemeData data;

  /// Creates a [FormixTheme] widget.
  const FormixTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Retrieves the [FormixThemeData] from the closest [FormixTheme] ancestor.
  ///
  /// If no [FormixTheme] is found, returns a default [FormixThemeData].
  static FormixThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<FormixTheme>();
    return theme?.data ?? const FormixThemeData();
  }

  @override
  bool updateShouldNotify(FormixTheme oldWidget) => data != oldWidget.data;
}
