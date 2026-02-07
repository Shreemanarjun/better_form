import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../formix.dart';

/// A widget that automatically derives field values based on other field changes.
///
/// This widget allows you to declaratively define field dependencies and
/// transformation logic, making it easy to create computed or derived fields.
///
/// Example usage:
/// ```dart
/// FormixFieldDerivation(
///   dependencies: [dobField],
///   derive: (values) {
///     final dob = values[dobField] as DateTime?;
///     if (dob == null) return null;
///
///     final now = DateTime.now();
///     int age = now.year - dob.year;
///     if (now.month < dob.month ||
///         (now.month == dob.month && now.day < dob.day)) {
///       age--;
///     }
///     return age;
///   },
///   targetField: ageField,
/// )
/// ```
class FormixFieldDerivation extends ConsumerStatefulWidget {
  /// Creates a field derivation widget.
  ///
  /// [dependencies] - List of fields this derivation depends on
  /// [derive] - Function that computes the derived value from dependency values
  /// [targetField] - The field to update with the derived value
  /// [key] - Optional widget key
  const FormixFieldDerivation({
    super.key,
    required this.dependencies,
    required this.derive,
    required this.targetField,
  });

  /// The fields that this derivation depends on.
  /// When any of these fields change, the derivation will be recalculated.
  final List<FormixFieldID<dynamic>> dependencies;

  /// Function that computes the derived value.
  /// Receives a map of current field values and returns the computed value.
  final dynamic Function(Map<FormixFieldID<dynamic>, dynamic>) derive;

  /// The field to update with the derived value.
  final FormixFieldID<dynamic> targetField;

  @override
  ConsumerState<FormixFieldDerivation> createState() => _FormixFieldDerivationState();
}

class _FormixFieldDerivationState extends ConsumerState<FormixFieldDerivation> {
  FormixController? _controller;
  Object? _initializationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var provider = Formix.of(context);
    if (provider == null) {
      try {
        provider = ref.watch(currentControllerProvider);
      } catch (_) {
        // ProviderScope missing
      }
    }

    if (provider == null) {
      if (mounted) {
        setState(() {
          _initializationError = 'FormixFieldDerivation used outside of Formix';
        });
      }
      return;
    }

    // Keep provider alive
    ref.watch(provider);
    try {
      final newController = ref.read(provider.notifier);
      if (newController != _controller) {
        _controller = newController;
        // Initial calculation - defer to avoid calling setState during build
        scheduleMicrotask(_recalculate);
      }
      _initializationError = null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = e;
        });
      }
    }
  }

  void _recalculate() {
    if (_controller == null || !mounted) return;

    try {
      // Get current values of all dependencies
      final values = <FormixFieldID<dynamic>, dynamic>{};
      for (final fieldId in widget.dependencies) {
        values[fieldId] = _controller!.getValue(fieldId);
      }

      // Compute the derived value
      final derivedValue = widget.derive(values);

      // Only update if the value has actually changed to avoid infinite loops
      final currentValue = _controller!.getValue(widget.targetField);
      if (currentValue != derivedValue) {
        // Defer the update to avoid modifying provider during widget building
        scheduleMicrotask(() {
          if (_controller != null && mounted) {
            _controller!.setValue(widget.targetField, derivedValue);
          }
        });
      }
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode) {
        debugPrint('Error in field derivation for ${widget.targetField}: $e');
      }
      // In production, we silently ignore errors to prevent crashes
    }
  }

  @override
  void didUpdateWidget(FormixFieldDerivation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if dependencies or target field changed
    if (!listEquals(oldWidget.dependencies, widget.dependencies) || oldWidget.targetField != widget.targetField) {
      // Recalculate with new dependencies
      scheduleMicrotask(_recalculate);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return FormixConfigurationErrorWidget(
        message: _initializationError is String ? _initializationError as String : 'Failed to initialize FormixFieldDerivation',
        details: _initializationError.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.'
            : 'Error: $_initializationError',
      );
    }

    // Listen to each dependency reactively using granular selectors
    for (final fieldId in widget.dependencies) {
      ref.listen(fieldValueProvider(fieldId), (_, __) => _recalculate());
    }

    // This widget doesn't render anything visible
    return const SizedBox.shrink();
  }
}

/// A more advanced version that supports multiple derivations and more complex logic.
class FormixFieldDerivations extends ConsumerStatefulWidget {
  /// Creates multiple field derivations.
  ///
  /// [derivations] - List of derivation configurations
  /// [key] - Optional widget key
  const FormixFieldDerivations({super.key, required this.derivations});

  /// List of derivation configurations.
  final List<FieldDerivationConfig> derivations;

  @override
  ConsumerState<FormixFieldDerivations> createState() => _FormixFieldDerivationsState();
}

class _FormixFieldDerivationsState extends ConsumerState<FormixFieldDerivations> {
  FormixController? _controller;
  Object? _initializationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var provider = Formix.of(context);
    if (provider == null) {
      try {
        provider = ref.watch(currentControllerProvider);
      } catch (_) {
        // ProviderScope missing
      }
    }

    if (provider == null) {
      if (mounted) {
        setState(() {
          _initializationError = 'FormixFieldDerivations used outside of Formix';
        });
      }
      return;
    }

    // Keep provider alive
    ref.watch(provider);
    try {
      final newController = ref.read(provider.notifier);
      if (newController != _controller) {
        _controller = newController;
        // Initial calculations - defer to avoid calling setState during build
        scheduleMicrotask(_recalculateAll);
      }
      _initializationError = null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = e;
        });
      }
    }
  }

  void _recalculate(FieldDerivationConfig config) {
    if (_controller == null || !mounted) return;

    try {
      // Get current values of all dependencies
      final values = <FormixFieldID<dynamic>, dynamic>{};
      for (final fieldId in config.dependencies) {
        values[fieldId] = _controller!.getValue(fieldId);
      }

      // Compute the derived value
      final derivedValue = config.derive(values);

      // Only update if the value has actually changed to avoid infinite loops
      final currentValue = _controller!.getValue(config.targetField);
      if (currentValue != derivedValue) {
        // Defer the update to avoid modifying provider during widget building
        scheduleMicrotask(() {
          if (_controller != null && mounted) {
            _controller!.setValue(config.targetField, derivedValue);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in field derivation for ${config.targetField}: $e');
      }
    }
  }

  void _recalculateAll() {
    for (final config in widget.derivations) {
      _recalculate(config);
    }
  }

  @override
  void didUpdateWidget(FormixFieldDerivations oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if derivations changed
    if (!listEquals(oldWidget.derivations, widget.derivations)) {
      // Recalculate with new derivations
      scheduleMicrotask(_recalculateAll);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return FormixConfigurationErrorWidget(
        message: _initializationError is String ? _initializationError as String : 'Failed to initialize FormixFieldDerivations',
        details: _initializationError.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.'
            : 'Error: $_initializationError',
      );
    }

    // Set up granular listeners for all derivations
    final uniqueDependencies = widget.derivations.expand((d) => d.dependencies).toSet();
    for (final dep in uniqueDependencies) {
      ref.listen(fieldValueProvider(dep), (prev, next) {
        // Find which derivations need to be recalculated
        for (final config in widget.derivations) {
          if (config.dependencies.contains(dep)) {
            _recalculate(config);
          }
        }
      });
    }

    return const SizedBox.shrink();
  }
}

/// Configuration for a single field derivation.
class FieldDerivationConfig {
  /// Creates a field derivation configuration.
  ///
  /// [dependencies] - Fields this derivation depends on
  /// [derive] - Function to compute the derived value
  /// [targetField] - Field to update with the result
  const FieldDerivationConfig({
    required this.dependencies,
    required this.derive,
    required this.targetField,
  });

  /// The fields that this derivation depends on.
  final List<FormixFieldID<dynamic>> dependencies;

  /// Function that computes the derived value from dependency values.
  final dynamic Function(Map<FormixFieldID<dynamic>, dynamic>) derive;

  /// The field to update with the derived value.
  final FormixFieldID<dynamic> targetField;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDerivationConfig && listEquals(dependencies, other.dependencies) && targetField == other.targetField;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(dependencies), targetField);
}
