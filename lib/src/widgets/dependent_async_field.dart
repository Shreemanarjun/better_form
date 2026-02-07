import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'async_form_field.dart';
import '../controllers/field_id.dart';
import '../enums.dart';
import 'formix.dart';

/// A simplified version of [FormixAsyncField] that automatically manages dependencies.
///
/// It watches the [dependency] field and:
/// 1. Re-executes [future] when the dependency changes.
/// 2. Clears the [resetField] value when the dependency changes (optional).
/// 3. Passes the dependency value to the [future] builder.
///
/// This reduces boilerplate for common parent-child field relationships (e.g. Country -> City).
///
/// Example:
/// ```dart
/// FormixDependentAsyncField<List<String>, String>(
///   fieldId: cityOptionsField,
///   dependency: countryField,
///   resetField: cityField, // Clear selected city when country changes
///   future: (country) => fetchCities(country),
///   builder: (context, state) {
///     // ... build dropdown
///   },
/// )
/// ```
class FormixDependentAsyncField<T, D> extends ConsumerWidget {
  /// Creates a [FormixDependentAsyncField].
  const FormixDependentAsyncField({
    super.key,
    required this.fieldId,
    required this.dependency,
    required this.future,
    required this.builder,
    this.resetField,
    this.keepPreviousData = false,
    this.loadingBuilder,
    this.asyncErrorBuilder,
    this.debounce,
    this.initialValue,
    this.initialValueStrategy,
    this.manual = false,
  });

  /// The ID of this field (used to store the async state/result).
  final FormixFieldID<T> fieldId;

  /// The ID of the dependency field to watch.
  final FormixFieldID<D> dependency;

  /// Optional field to reset (set to null) when the dependency changes.
  /// Typically this is the field that consumes the options produced by this widget.
  final FormixFieldID<dynamic>? resetField;

  /// Function to create the future based on the dependency value.
  final Future<T> Function(D? dependencyValue) future;

  /// A builder function that is called when data is available.
  final Widget Function(BuildContext context, FormixAsyncFieldState<T> state) builder;

  /// Whether to keep the previous data while loading the new data.
  final bool keepPreviousData;

  /// Optional builder for the loading state.
  final WidgetBuilder? loadingBuilder;

  /// Optional builder for the error state.
  final Widget Function(BuildContext context, Object error)? asyncErrorBuilder;

  /// Debounce duration for the future.
  final Duration? debounce;

  /// Initial value for the field.
  final T? initialValue;

  /// If true, the field must be manually refreshed.
  final bool manual;

  /// Strategy for handling initial values.
  final FormixInitialValueStrategy? initialValueStrategy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formProvider = Formix.of(context);
    if (formProvider == null) {
      throw FlutterError(
        'FormixDependentAsyncField must be used inside a Formix widget',
      );
    }

    // Watch the dependency value with type safety
    final dependencyValue = ref.watch(
      formProvider.select((s) => s.getValue(dependency)),
    );

    // Listen for dependency changes to reset the related field
    if (resetField != null) {
      ref.listen(formProvider.select((s) => s.getValue(dependency)), (
        previous,
        next,
      ) {
        if (previous != next) {
          ref.read(formProvider.notifier).setValue(resetField!, null);
        }
      });
    }

    return FormixAsyncField<T>(
      fieldId: fieldId,
      // Pass the current dependency value to the future creator
      future: future(dependencyValue),
      // Use the dependency value as the 'dependencies' list for FormixAsyncField
      // This tells FormixAsyncField to re-execute the future when this value changes
      dependencies: [dependencyValue],
      // Define retry logic (same as initial fetch)
      onRetry: () => future(dependencyValue),
      builder: builder,
      loadingBuilder: loadingBuilder,
      asyncErrorBuilder: asyncErrorBuilder,
      keepPreviousData: keepPreviousData,
      debounce: debounce,
      initialValue: initialValue,
      initialValueStrategy: initialValueStrategy,
      manual: manual,
    );
  }
}
