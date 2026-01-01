import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../controllers/riverpod_controller.dart';
import '../controllers/field_id.dart';
import 'riverpod_form_fields.dart';

/// A widget that automatically derives field values based on other field changes.
///
/// This widget allows you to declaratively define field dependencies and
/// transformation logic, making it easy to create computed or derived fields.
///
/// Example usage:
/// ```dart
/// BetterFormFieldDerivation(
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
class BetterFormFieldDerivation extends StatefulWidget {
  /// Creates a field derivation widget.
  ///
  /// [dependencies] - List of fields this derivation depends on
  /// [derive] - Function that computes the derived value from dependency values
  /// [targetField] - The field to update with the derived value
  /// [key] - Optional widget key
  const BetterFormFieldDerivation({
    super.key,
    required this.dependencies,
    required this.derive,
    required this.targetField,
  });

  /// The fields that this derivation depends on.
  /// When any of these fields change, the derivation will be recalculated.
  final List<BetterFormFieldID<dynamic>> dependencies;

  /// Function that computes the derived value.
  /// Receives a map of current field values and returns the computed value.
  final dynamic Function(Map<BetterFormFieldID<dynamic>, dynamic>) derive;

  /// The field to update with the derived value.
  final BetterFormFieldID<dynamic> targetField;

  @override
  State<BetterFormFieldDerivation> createState() =>
      _BetterFormFieldDerivationState();
}

class _BetterFormFieldDerivationState extends State<BetterFormFieldDerivation> {
  BetterFormController? _controller;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = _onDependenciesChanged;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = BetterForm.controllerOf(context);
    if (newController != _controller) {
      // Remove listeners from old controller
      if (_controller != null) {
        for (final fieldId in widget.dependencies) {
          _controller!.removeFieldListener(fieldId, _listener);
        }
      }

      // Add listeners to new controller
      _controller = newController;
      if (_controller != null) {
        // Ensure all dependency fields are registered
        for (final fieldId in widget.dependencies) {
          _ensureFieldRegistered(fieldId);
        }
        // Ensure target field is registered
        _ensureFieldRegistered(widget.targetField);

        for (final fieldId in widget.dependencies) {
          _controller!.addFieldListener(fieldId, _listener);
        }

        // Initial calculation - defer to avoid calling setState during build
        scheduleMicrotask(_recalculate);
      }
    }
  }

  @override
  void didUpdateWidget(BetterFormFieldDerivation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If dependencies changed, update listeners
    if (!listEquals(oldWidget.dependencies, widget.dependencies)) {
      if (_controller != null) {
        // Remove old listeners
        for (final fieldId in oldWidget.dependencies) {
          if (!widget.dependencies.contains(fieldId)) {
            _controller!.removeFieldListener(fieldId, _listener);
          }
        }

        // Add new listeners
        for (final fieldId in widget.dependencies) {
          if (!oldWidget.dependencies.contains(fieldId)) {
            _controller!.addFieldListener(fieldId, _listener);
          }
        }
      }

      // Recalculate with new dependencies
      _recalculate();
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      for (final fieldId in widget.dependencies) {
        _controller!.removeFieldListener(fieldId, _listener);
      }
    }
    super.dispose();
  }

  void _ensureFieldRegistered(BetterFormFieldID<dynamic> fieldId) {
    // For derivations, we don't require pre-registration since fields may be
    // registered later in the widget tree. The derivation will work as long
    // as the field exists when the derivation runs.
  }

  void _onDependenciesChanged() {
    _recalculate();
  }

  void _recalculate() {
    if (_controller == null) return;

    try {
      // Get current values of all dependencies
      final values = <BetterFormFieldID<dynamic>, dynamic>{};
      for (final fieldId in widget.dependencies) {
        values[fieldId] = _controller!.getValue(fieldId);
      }

      // Compute the derived value
      final derivedValue = widget.derive(values);

      // Update the target field
      _controller!.setValue(widget.targetField, derivedValue);
    } catch (e) {
      // Log error in debug mode
      if (kDebugMode) {
        debugPrint('Error in field derivation for ${widget.targetField}: $e');
      }
      // In production, we silently ignore errors to prevent crashes
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    return const SizedBox.shrink();
  }
}

/// A more advanced version that supports multiple derivations and more complex logic.
class BetterFormFieldDerivations extends StatefulWidget {
  /// Creates multiple field derivations.
  ///
  /// [derivations] - List of derivation configurations
  /// [key] - Optional widget key
  const BetterFormFieldDerivations({super.key, required this.derivations});

  /// List of derivation configurations.
  final List<FieldDerivationConfig> derivations;

  @override
  State<BetterFormFieldDerivations> createState() =>
      _BetterFormFieldDerivationsState();
}

class _BetterFormFieldDerivationsState
    extends State<BetterFormFieldDerivations> {
  BetterFormController? _controller;
  final Map<String, VoidCallback> _listeners = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = BetterForm.controllerOf(context);
    if (newController != _controller) {
      // Clean up old listeners
      _removeAllListeners();

      // Set up new controller
      _controller = newController;
      if (_controller != null) {
        _setupListeners();
        // Initial calculations - defer to avoid calling setState during build
        scheduleMicrotask(_recalculateAll);
      }
    }
  }

  @override
  void didUpdateWidget(BetterFormFieldDerivations oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.derivations, widget.derivations)) {
      _removeAllListeners();
      _setupListeners();
      _recalculateAll();
    }
  }

  @override
  void dispose() {
    _removeAllListeners();
    super.dispose();
  }

  void _setupListeners() {
    if (_controller == null) return;

    void listener(FieldDerivationConfig config) => _onDerivationChanged(config);

    for (final config in widget.derivations) {
      final listenerKey = config.targetField.key;
      _listeners[listenerKey] = () => listener(config);

      for (final fieldId in config.dependencies) {
        _controller!.addFieldListener(fieldId, _listeners[listenerKey]!);
      }
    }
  }

  void _removeAllListeners() {
    if (_controller == null) return;

    for (final config in widget.derivations) {
      final listener = _listeners[config.targetField.key];
      if (listener != null) {
        for (final fieldId in config.dependencies) {
          _controller!.removeFieldListener(fieldId, listener);
        }
      }
    }
    _listeners.clear();
  }

  void _onDerivationChanged(FieldDerivationConfig config) {
    _recalculate(config);
  }

  void _recalculate(FieldDerivationConfig config) {
    if (_controller == null) return;

    try {
      // Get current values of all dependencies
      final values = <BetterFormFieldID<dynamic>, dynamic>{};
      for (final fieldId in config.dependencies) {
        values[fieldId] = _controller!.getValue(fieldId);
      }

      // Compute the derived value
      final derivedValue = config.derive(values);

      // Update the target field
      _controller!.setValue(config.targetField, derivedValue);
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
  Widget build(BuildContext context) {
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
  final List<BetterFormFieldID<dynamic>> dependencies;

  /// Function that computes the derived value from dependency values.
  final dynamic Function(Map<BetterFormFieldID<dynamic>, dynamic>) derive;

  /// The field to update with the derived value.
  final BetterFormFieldID<dynamic> targetField;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldDerivationConfig &&
        listEquals(dependencies, other.dependencies) &&
        targetField == other.targetField;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(dependencies), targetField);
}
