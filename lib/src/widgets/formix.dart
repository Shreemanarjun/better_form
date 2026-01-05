import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/riverpod_controller.dart';
import '../persistence/form_persistence.dart';

/// A form widget that automatically manages a Riverpod controller provider
/// and makes it available to all child Riverpod form fields.
///
/// It provides a [FormixController] through an [InheritedWidget] and
/// overrides the [currentControllerProvider] for its descendants.
class Formix extends ConsumerWidget {
  /// Creates a [Formix].
  const Formix({
    super.key,
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
    required this.child,
  });

  /// initial values for the form fields.
  final Map<String, dynamic> initialValue;

  /// Configuration for the fields in this form.
  final List<FormixFieldConfig<dynamic>> fields;

  /// Optional persistence handler.
  final FormixPersistence? persistence;

  /// Unique identifier for this form (required for persistence).
  final String? formId;

  /// The widget subtree.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a unique controller provider for this form instance
    final controllerProvider = formControllerProvider(
      FormixParameter(
        initialValue: initialValue,
        fields: fields,
        persistence: persistence,
        formId: formId,
      ),
    );

    // We watch the notifier once to get the instance
    final controller =
        ref.watch(controllerProvider.notifier) as FormixController;

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: _FieldRegistrar(
        controllerProvider: controllerProvider,
        fields: fields,
        child: _FormixScope(
          controller: controller,
          controllerProvider: controllerProvider,
          fields: fields,
          child: child,
        ),
      ),
    );
  }

  /// Get the controller provider from the nearest [Formix] ancestor.
  static AutoDisposeStateNotifierProvider<RiverpodFormController, FormixState>?
  of(BuildContext context) {
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

class _FormixScope extends InheritedWidget {
  const _FormixScope({
    required super.child,
    required this.controller,
    required this.controllerProvider,
    required this.fields,
  });

  final FormixController controller;
  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormixState>
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

  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormixState>
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
