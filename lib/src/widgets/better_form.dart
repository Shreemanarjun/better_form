import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/riverpod_controller.dart';
import '../persistence/form_persistence.dart';

/// A form widget that automatically manages a Riverpod controller provider
/// and makes it available to all child Riverpod form fields.
///
/// It provides a [BetterFormController] through an [InheritedWidget] and
/// overrides the [currentControllerProvider] for its descendants.
class BetterForm extends ConsumerWidget {
  /// Creates a [BetterForm].
  const BetterForm({
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
  final List<BetterFormFieldConfig<dynamic>> fields;

  /// Optional persistence handler.
  final BetterFormPersistence? persistence;

  /// Unique identifier for this form (required for persistence).
  final String? formId;

  /// The widget subtree.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a unique controller provider for this form instance
    final controllerProvider = formControllerProvider(
      BetterFormParameter(
        initialValue: initialValue,
        fields: fields,
        persistence: persistence,
        formId: formId,
      ),
    );

    // We watch the notifier once to get the instance
    final controller =
        ref.watch(controllerProvider.notifier) as BetterFormController;

    return ProviderScope(
      overrides: [
        currentControllerProvider.overrideWithValue(controllerProvider),
      ],
      child: _FieldRegistrar(
        controllerProvider: controllerProvider,
        fields: fields,
        child: _BetterFormScope(
          controller: controller,
          controllerProvider: controllerProvider,
          fields: fields,
          child: child,
        ),
      ),
    );
  }

  /// Get the controller provider from the nearest [BetterForm] ancestor.
  static AutoDisposeStateNotifierProvider<
    RiverpodFormController,
    BetterFormState
  >?
  of(BuildContext context) {
    final _BetterFormScope? scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controllerProvider;
  }

  /// Get the [BetterFormController] instance from the nearest [BetterForm] ancestor.
  static BetterFormController? controllerOf(BuildContext context) {
    final _BetterFormScope? scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controller;
  }
}

class _BetterFormScope extends InheritedWidget {
  const _BetterFormScope({
    required super.child,
    required this.controller,
    required this.controllerProvider,
    required this.fields,
  });

  final BetterFormController controller;
  final AutoDisposeStateNotifierProvider<
    RiverpodFormController,
    BetterFormState
  >
  controllerProvider;
  final List<BetterFormFieldConfig<dynamic>> fields;

  @override
  bool updateShouldNotify(_BetterFormScope oldWidget) {
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

  final AutoDisposeStateNotifierProvider<
    RiverpodFormController,
    BetterFormState
  >
  controllerProvider;
  final List<BetterFormFieldConfig<dynamic>> fields;
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
