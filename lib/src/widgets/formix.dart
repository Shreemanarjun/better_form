import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/form_analytics.dart';
import '../controllers/riverpod_controller.dart';
import '../persistence/form_persistence.dart';

/// A form widget that automatically manages a Riverpod controller provider
/// and makes it available to all child Riverpod form fields.
///
/// It provides a [FormixController] through an [InheritedWidget] and
/// overrides the [currentControllerProvider] for its descendants.
///
/// You can use a [GlobalKey<FormixState>] to interact with the form from
/// outside its widget tree.
class Formix extends ConsumerStatefulWidget {
  /// Creates a [Formix].
  const Formix({
    super.key,
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
    this.onChanged,
    this.analytics,
    this.keepAlive = false,
    required this.child,
  });

  /// Optional analytics hook
  final FormixAnalytics? analytics;

  /// initial values for the form fields.
  final Map<String, dynamic> initialValue;

  /// Configuration for the fields in this form.
  final List<FormixFieldConfig<dynamic>> fields;

  /// Optional persistence handler.
  final FormixPersistence? persistence;

  /// Unique identifier for this form (required for persistence).
  final String? formId;

  /// Callback triggered whenever any value in the form changes.
  final void Function(Map<String, dynamic> values)? onChanged;

  /// If true, prevents the form provider from being auto-disposed when the
  /// widget is unmounted. Useful for multi-step forms where you want to
  /// preserve data across navigation.
  final bool keepAlive;

  /// The widget subtree.
  final Widget child;

  @override
  ConsumerState<Formix> createState() => FormixState();

  /// Get the controller provider from the nearest [Formix] ancestor.
  static AutoDisposeStateNotifierProvider<FormixController, FormixData>? of(
    BuildContext context,
  ) {
    final _FormixScope? scope = context
        .dependOnInheritedWidgetOfExactType<_FormixScope>();
    return scope?.controllerProvider;
  }

  /// Get the [FormixController] instance from the nearest [Formix] ancestor.
  static FormixController? controllerOf(BuildContext context) {
    final _FormixScope? scope = context
        .dependOnInheritedWidgetOfExactType<_FormixScope>();
    return scope?.controller;
  }
}

/// State for [Formix], allowing external control via [GlobalKey].
class FormixState extends ConsumerState<Formix> {
  late final String _internalFormId;

  @override
  void initState() {
    super.initState();
    final typeName = widget.runtimeType.toString();
    _internalFormId = widget.formId ?? '${typeName}_${identityHashCode(this)}';
  }

  AutoDisposeStateNotifierProvider<FormixController, FormixData> get _provider {
    return formControllerProvider(
      FormixParameter(
        initialValue: widget.initialValue,
        fields: widget.fields,
        persistence: widget.persistence,
        formId: _internalFormId,
        analytics: widget.analytics,
      ),
    );
  }

  /// Access the controller to perform actions like [submit] or [reset].
  FormixController get controller => ref.read(_provider.notifier);

  /// Access the current immutable state of the form.
  ///
  /// Note: This is a snapshot. To watch state reactively, use [FormixBuilder].
  FormixData get data => ref.read(_provider);

  /// Access the provider for Riverpod-specific utilities.
  ///
  /// This allows you to use Riverpod's `ref.watch`, `ref.listen`, etc.
  /// outside of the widget tree.
  ///
  /// Example:
  /// ```dart
  /// final formKey = GlobalKey<FormixState>();
  ///
  /// // In a Consumer or ConsumerWidget:
  /// final provider = formKey.currentState?.provider;
  /// if (provider != null) {
  ///   // Watch the form state
  ///   final state = ref.watch(provider);
  ///
  ///   // Listen to specific changes
  ///   ref.listen(provider.select((s) => s.isValid), (prev, next) {
  ///     print('Validation changed: $next');
  ///   });
  /// }
  /// ```
  AutoDisposeStateNotifierProvider<FormixController, FormixData> get provider =>
      _provider;

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    // Keep provider alive if requested - by watching it, it won't be disposed
    if (widget.keepAlive) {
      ref.watch(provider);
    }

    final controllerInstance = ref.watch(provider.notifier);

    if (widget.onChanged != null) {
      ref.listen(provider.select((s) => s.values), (previous, next) {
        if (previous != next) {
          widget.onChanged!(next);
        }
      });
    }

    return ProviderScope(
      overrides: [currentControllerProvider.overrideWithValue(provider)],
      child: _FieldRegistrar(
        controllerProvider: provider,
        fields: widget.fields,
        child: _FormixScope(
          controller: controllerInstance,
          controllerProvider: provider,
          fields: widget.fields,
          child: widget.child,
        ),
      ),
    );
  }
}

class _FormixScope extends InheritedWidget {
  const _FormixScope({
    required super.child,
    required this.controller,
    required this.controllerProvider,
    required this.fields,
  });

  final FormixController controller;
  final AutoDisposeStateNotifierProvider<FormixController, FormixData>
  controllerProvider;
  final List<FormixFieldConfig<dynamic>> fields;

  @override
  bool updateShouldNotify(_FormixScope oldWidget) {
    return controller != oldWidget.controller ||
        controllerProvider != oldWidget.controllerProvider ||
        !const ListEquality().equals(fields, oldWidget.fields);
  }
}

class _FieldRegistrar extends ConsumerWidget {
  const _FieldRegistrar({
    required this.controllerProvider,
    required this.fields,
    required this.child,
  });

  final AutoDisposeStateNotifierProvider<FormixController, FormixData>
  controllerProvider;
  final List<FormixFieldConfig<dynamic>> fields;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(controllerProvider.notifier);

    final fieldsToRegister = fields
        .where((f) => !controller.isFieldRegistered(f.id))
        .map((f) => f.toField())
        .toList();

    if (fieldsToRegister.isNotEmpty) {
      controller.registerFields(fieldsToRegister);
    }

    return child;
  }
}
