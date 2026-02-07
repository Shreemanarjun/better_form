import 'dart:async';

import 'package:flutter/material.dart';

import '../../formix.dart';
import 'ancestor_validator.dart';

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
class FormixDependentAsyncField<T, D> extends ConsumerStatefulWidget {
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
    this.onData,
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

  /// Optional callback executed when data is successfully loaded.
  final void Function(BuildContext context, FormixController controller, T data)? onData;

  @override
  ConsumerState<FormixDependentAsyncField<T, D>> createState() => _FormixDependentAsyncFieldState<T, D>();
}

class _FormixDependentAsyncFieldState<T, D> extends ConsumerState<FormixDependentAsyncField<T, D>> {
  D? _lastDependencyValue;
  Future<T>? _currentFuture;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final errorWidget = FormixAncestorValidator.validate(
      context,
      widgetName: 'FormixDependentAsyncField',
      requireFormix: false,
    );

    if (errorWidget != null) return errorWidget;

    final activeProvider = (Formix.of(context) ?? ref.watch(currentControllerProvider))!;

    try {
      // Watch the dependency value with type safety
      final dependencyValue = ref.watch(
        activeProvider.select((s) => s.getValue(widget.dependency)),
      );

      // Only recreate the future if the dependency value has changed or it's the first build
      if (!_initialized || dependencyValue != _lastDependencyValue) {
        _lastDependencyValue = dependencyValue;
        _currentFuture = widget.future(dependencyValue);
        _initialized = true;
      }

      // Listen for dependency changes to reset the related field
      if (widget.resetField != null) {
        ref.listen(activeProvider.select((s) => s.getValue(widget.dependency)), (
          previous,
          next,
        ) {
          if (previous != next) {
            ref.read(activeProvider.notifier).setValue(widget.resetField!, null);
          }
        });
      }

      return FormixAsyncField<T>(
        fieldId: widget.fieldId,
        // Pass the cached future
        future: _currentFuture,
        // Use the dependency value as the 'dependencies' list for FormixAsyncField
        // This tells FormixAsyncField to re-execute the future when this value changes
        dependencies: [dependencyValue],
        // Define retry logic (same as initial fetch)
        onRetry: () {
          // Force update the current future on retry
          final future = widget.future(dependencyValue);
          setState(() {
            _currentFuture = future;
          });
          return future;
        },
        builder: widget.builder,
        loadingBuilder: widget.loadingBuilder,
        asyncErrorBuilder: widget.asyncErrorBuilder,
        keepPreviousData: widget.keepPreviousData,
        debounce: widget.debounce,
        initialValue: widget.initialValue,
        initialValueStrategy: widget.initialValueStrategy,
        manual: widget.manual,
        onData: widget.onData,
      );
    } catch (e) {
      return FormixConfigurationErrorWidget(
        message: 'Failed to initialize FormixDependentAsyncField',
        details: e.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.\n\nExample:\nvoid main() {\n  runApp(ProviderScope(child: MyApp()));\n}'
            : 'Error: $e',
      );
    }
  }
}
