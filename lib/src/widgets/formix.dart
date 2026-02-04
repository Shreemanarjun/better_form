import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/form_analytics.dart';
import '../controllers/field.dart';
import '../controllers/riverpod_controller.dart';
import '../persistence/form_persistence.dart';
import '../enums.dart';

/// A form container widget that manages a [FormixController] and provides it
/// to descendant widgets via the widget tree and Riverpod.
///
/// Features:
/// *   **State Management**: Uses Riverpod to efficiently manage form data.
/// *   **Auto-Registration**: Fields register themselves with the controller on mount.
/// *   **Persistence**: Can automatically save and restore form state.
/// *   **Validation**: Supports global and per-field validation configurations.
/// *   **Analytics**: Integrated hooks for tracking form interactions.
///
/// Example:
/// ```dart
/// Formix(
///   initialValue: {'email': 'test@example.com'},
///   onChanged: (values) => print('Form changed: $values'),
///   child: Column(
///     children: [
///       FormixTextFormField(fieldId: FormixFieldID('email')),
///       ElevatedButton(
///         onPressed: () => Formix.controllerOf(context)?.submit(
///           onValid: (data) => print('Success: $data'),
///         ),
///         child: Text('Submit'),
///       ),
///     ],
///   ),
/// )
/// ```
class Formix extends ConsumerStatefulWidget {
  /// Creates a [Formix].
  const Formix({
    super.key,
    this.controller,
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
    this.onChanged,
    this.analytics,
    this.keepAlive = false,
    this.autovalidateMode = FormixAutovalidateMode.always,
    required this.child,
  });

  /// Optional explicit controller.
  final FormixController? controller;

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

  /// The autovalidate mode for the form.
  final FormixAutovalidateMode autovalidateMode;

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
    final provider = formControllerProvider(
      FormixParameter(
        initialValue: widget.initialValue,
        fields: widget.fields,
        persistence: widget.persistence,
        formId: widget.formId,
        namespace: _internalFormId,
        analytics: widget.analytics,
        keepAlive: widget.keepAlive,
        autovalidateMode: widget.autovalidateMode,
      ),
    );

    return provider;
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
      overrides: [
        if (widget.controller != null)
          provider.overrideWith((ref) => widget.controller!),
        currentControllerProvider.overrideWithValue(provider),
      ],
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

class _FieldRegistrar extends ConsumerStatefulWidget {
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
  ConsumerState<_FieldRegistrar> createState() => _FieldRegistrarState();
}

class _FieldRegistrarState extends ConsumerState<_FieldRegistrar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerFields();
  }

  void _registerFields() {
    final controller = ref.read(widget.controllerProvider.notifier);

    final fieldsToRegister = <FormixField<dynamic>>[];

    for (final config in widget.fields) {
      final field = config.toField();
      if (!controller.isFieldRegistered(config.id)) {
        fieldsToRegister.add(field);
      } else {
        // Check if we need to update the definition
        // Note: We use the existing field definition comparison if possible,
        // but FormixField doesn't implement ==.
        // So we assume if widget.fields changed (triggering didUpdateWidget),
        // we should re-register.
      }
    }

    if (fieldsToRegister.isNotEmpty) {
      controller.registerFields(fieldsToRegister);
    }
  }

  @override
  void didUpdateWidget(_FieldRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fields != oldWidget.fields) {
      // Configuration changed (e.g. hot reload or dynamic fields).
      // Re-register ALL fields to ensure definitions are updated.
      // registerFields handles standardizing updates without data loss.
      final controller = ref.read(widget.controllerProvider.notifier);
      controller.registerFields(widget.fields.map((f) => f.toField()).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
