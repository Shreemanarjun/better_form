import 'package:flutter/material.dart';

import '../controller.dart';
import '../field_id.dart';
import '../form.dart';
import '../validation.dart';

/// A widget that listens to a specific field's value changes using ValueListenableBuilder
class BetterFormFieldValueListenableBuilder<T> extends StatelessWidget {
  const BetterFormFieldValueListenableBuilder({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? BetterForm.of(context)!;

    return ValueListenableBuilder<T>(
      valueListenable: ctrl.fieldValueListenable<T>(fieldId),
      builder: builder,
      child: child,
    );
  }
}

/// A widget that listens to a specific field's validation changes
class BetterFormFieldValidationListenableBuilder<T> extends StatelessWidget {
  const BetterFormFieldValidationListenableBuilder({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, ValidationResult validation, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? BetterForm.of(context)!;

    return ValueListenableBuilder<ValidationResult>(
      valueListenable: ctrl.fieldValidationNotifier<T>(fieldId),
      builder: builder,
      child: child,
    );
  }
}

/// A widget that listens to a specific field's dirty state changes
class BetterFormFieldDirtyListenableBuilder<T> extends StatelessWidget {
  const BetterFormFieldDirtyListenableBuilder({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, bool isDirty, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? BetterForm.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: ctrl.fieldDirtyNotifier<T>(fieldId),
      builder: builder,
      child: child,
    );
  }
}

/// A widget that combines value, validation, and dirty state listening for a field
class BetterFormFieldListenableBuilder<T> extends StatelessWidget {
  const BetterFormFieldListenableBuilder({
    super.key,
    required this.fieldId,
    required this.builder,
    this.controller,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(
    BuildContext context,
    T value,
    ValidationResult validation,
    bool isDirty,
  ) builder;
  final BetterFormController? controller;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? BetterForm.of(context)!;

    return ValueListenableBuilder<T>(
      valueListenable: ctrl.fieldValueListenable<T>(fieldId),
      builder: (context, value, _) {
        return ValueListenableBuilder<ValidationResult>(
          valueListenable: ctrl.fieldValidationNotifier<T>(fieldId),
          builder: (context, validation, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: ctrl.fieldDirtyNotifier<T>(fieldId),
              builder: (context, isDirty, _) {
                return builder(context, value, validation, isDirty);
              },
            );
          },
        );
      },
    );
  }
}

/// A widget that listens to the entire form's dirty state
class BetterFormDirtyListenableBuilder extends StatelessWidget {
  const BetterFormDirtyListenableBuilder({
    super.key,
    required this.builder,
    this.controller,
    this.child,
  });

  final Widget Function(BuildContext context, bool isDirty, Widget? child) builder;
  final BetterFormController? controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? BetterForm.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: ctrl.isDirtyNotifier,
      builder: builder,
      child: child,
    );
  }
}
