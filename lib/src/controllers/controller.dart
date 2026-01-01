import 'package:flutter/widgets.dart' hide FormState;
import 'package:flutter/foundation.dart';
import 'riverpod_controller.dart';
import 'field_id.dart';
import 'field.dart';
import 'validation.dart';
import '../enums.dart';

/// Form controller for managing form state externally (Riverpod-based)
/// Form controller for managing form state externally (Riverpod-based)
class BetterFormController extends RiverpodFormController {
  BetterFormController({super.initialValue = const {}}) {
    addListener(_onStateChanged);
  }

  // Cache notifiers to ensure consistency
  final Map<String, ValueNotifier<dynamic>> _valueNotifiers = {};
  final Map<String, ValueNotifier<ValidationResult>> _validationNotifiers = {};
  final Map<String, ValueNotifier<bool>> _dirtyNotifiers = {};
  final Map<String, ValueNotifier<bool>> _touchedNotifiers = {};

  ValueNotifier<bool>? _isDirtyNotifier;
  ValueNotifier<bool>? _isValidNotifier;
  ValueNotifier<bool>? _isSubmittingNotifier;

  void _onStateChanged(FormState state) {
    // Update value notifiers
    for (final key in _valueNotifiers.keys) {
      final notifier = _valueNotifiers[key];
      final newValue = state.values[key];
      if (notifier != null && notifier.value != newValue) {
        notifier.value = newValue;
      }
    }

    // Update validation notifiers
    for (final key in _validationNotifiers.keys) {
      final notifier = _validationNotifiers[key];
      final newResult = state.validations[key] ?? ValidationResult.valid;
      if (notifier != null && notifier.value != newResult) {
        notifier.value = newResult;
      }
    }

    // Update dirty notifiers
    for (final key in _dirtyNotifiers.keys) {
      final notifier = _dirtyNotifiers[key];
      final isDirty = state.dirtyStates[key] ?? false;
      if (notifier != null && notifier.value != isDirty) {
        notifier.value = isDirty;
      }
    }

    // Update touched notifiers
    for (final key in _touchedNotifiers.keys) {
      final notifier = _touchedNotifiers[key];
      final isTouched = state.touchedStates[key] ?? false;
      if (notifier != null && notifier.value != isTouched) {
        notifier.value = isTouched;
      }
    }

    // Update global notifiers
    if (_isDirtyNotifier != null && _isDirtyNotifier!.value != state.isDirty) {
      _isDirtyNotifier!.value = state.isDirty;
    }
    if (_isValidNotifier != null && _isValidNotifier!.value != state.isValid) {
      _isValidNotifier!.value = state.isValid;
    }
    if (_isSubmittingNotifier != null &&
        _isSubmittingNotifier!.value != state.isSubmitting) {
      _isSubmittingNotifier!.value = state.isSubmitting;
    }

    // Call legacy listeners
    for (final listener in _fieldListeners) {
      listener();
    }
    for (final listener in _dirtyListeners) {
      listener(state.isDirty);
    }
  }

  /// Check if a field is registered
  @override
  bool isFieldRegistered<T>(BetterFormFieldID<T> fieldId) {
    return super.isFieldRegistered(fieldId);
  }

  /// Get value with type safety
  /// Returns null if the field is not registered or has no value
  @override
  T? getValue<T>(BetterFormFieldID<T> fieldId) {
    return super.getValue(fieldId);
  }

  /// Set value with type safety and validation
  @override
  void setValue<T>(BetterFormFieldID<T> fieldId, T value) {
    super.setValue(fieldId, value);
  }

  /// Register a field with the controller
  @override
  void registerField<T>(BetterFormField<T> field) {
    super.registerField(field);
  }

  /// Unregister a field from the controller
  @override
  void unregisterField<T>(BetterFormFieldID<T> fieldId) {
    super.unregisterField(fieldId);
    // Remove notifiers? No, they might be listening.
    // They will just stop receiving updates or receive nulls/defaults.
  }

  /// Check if field is dirty
  @override
  bool isFieldDirty<T>(BetterFormFieldID<T> fieldId) {
    return super.isFieldDirty(fieldId);
  }

  /// Get validation result for field
  @override
  ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId) {
    return super.getValidation(fieldId);
  }

  /// Validate entire form
  @override
  bool validate() {
    return super.validate();
  }

  /// Check if field is touched
  @override
  bool isFieldTouched<T>(BetterFormFieldID<T> fieldId) {
    return super.isFieldTouched(fieldId);
  }

  /// Mark field as touched
  @override
  void markAsTouched<T>(BetterFormFieldID<T> fieldId) {
    super.markAsTouched(fieldId);
  }

  /// Check if submittting
  @override
  bool get isSubmitting => super.isSubmitting;

  /// Check if form is dirty
  bool get isDirty => state.isDirty;

  /// Extract data from form
  Map<String, dynamic> get values => state.values;

  /// Reset form to initial state
  @override
  void reset({ResetStrategy strategy = ResetStrategy.initialValues}) {
    super.reset(strategy: strategy);
  }

  /// Dispose of resources
  @override
  void dispose() {
    for (final notifier in _valueNotifiers.values) {
      notifier.dispose();
    }
    for (final notifier in _validationNotifiers.values) {
      notifier.dispose();
    }
    for (final notifier in _dirtyNotifiers.values) {
      notifier.dispose();
    }
    for (final notifier in _touchedNotifiers.values) {
      notifier.dispose();
    }
    _isDirtyNotifier?.dispose();
    _isValidNotifier?.dispose();
    _isSubmittingNotifier?.dispose();

    super.dispose();
  }

  // Minimal compatibility layer for existing widgets
  // These methods provide backward compatibility while using Riverpod internally

  /// Get a ValueNotifier for a specific field (compatibility)
  ValueNotifier<T?> getFieldNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_valueNotifiers.containsKey(fieldId.key)) {
      return _valueNotifiers[fieldId.key] as ValueNotifier<T?>;
    }
    final notifier = ValueNotifier<T?>(getValue(fieldId));
    _valueNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Listen to a specific field's value changes (compatibility)
  ValueListenable<T?> fieldValueListenable<T>(BetterFormFieldID<T> fieldId) {
    return getFieldNotifier(fieldId);
  }

  /// Get validation notifier for a field (compatibility)
  ValueNotifier<ValidationResult> getValidationNotifier<T>(
    BetterFormFieldID<T> fieldId,
  ) {
    if (_validationNotifiers.containsKey(fieldId.key)) {
      return _validationNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<ValidationResult>(getValidation(fieldId));
    _validationNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Listen to validation changes for a specific field (compatibility)
  ValueNotifier<ValidationResult> fieldValidationNotifier<T>(
    BetterFormFieldID<T> fieldId,
  ) {
    return getValidationNotifier(fieldId);
  }

  /// Get dirty notifier for a field (compatibility)
  ValueNotifier<bool> getDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_dirtyNotifiers.containsKey(fieldId.key)) {
      return _dirtyNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldDirty(fieldId));
    _dirtyNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Listen to dirty state changes for a specific field (compatibility)
  ValueNotifier<bool> fieldDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    return getDirtyNotifier(fieldId);
  }

  /// Get touched notifier for a field (compatibility)
  ValueNotifier<bool> getTouchedNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_touchedNotifiers.containsKey(fieldId.key)) {
      return _touchedNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldTouched(fieldId));
    _touchedNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Listen to touched state changes for a specific field (compatibility)
  ValueNotifier<bool> fieldTouchedNotifier<T>(BetterFormFieldID<T> fieldId) {
    return getTouchedNotifier(fieldId);
  }

  /// Legacy compatibility notifiers
  ValueNotifier<bool> get isDirtyNotifier {
    _isDirtyNotifier ??= ValueNotifier(state.isDirty);
    return _isDirtyNotifier!;
  }

  ValueNotifier<bool> get isValidNotifier {
    _isValidNotifier ??= ValueNotifier(state.isValid);
    return _isValidNotifier!;
  }

  ValueNotifier<bool> get isSubmittingNotifier {
    _isSubmittingNotifier ??= ValueNotifier(state.isSubmitting);
    return _isSubmittingNotifier!;
  }

  // Listener management for compatibility
  final _fieldListeners = <VoidCallback>[];
  final _dirtyListeners = <void Function(bool)>[];

  /// Add a listener for field changes (compatibility)
  void addFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _fieldListeners.add(listener);
  }

  /// Remove a listener (compatibility)
  void removeFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _fieldListeners.remove(listener);
  }

  /// Add a dirty state listener (compatibility)
  void addDirtyListener(void Function(bool) listener) {
    _dirtyListeners.add(listener);
  }

  /// Remove a dirty state listener (compatibility)
  void removeDirtyListener(void Function(bool) listener) {
    _dirtyListeners.remove(listener);
  }

  // Focus Management
  final Map<String, FocusNode> _focusNodes = {};

  /// Register a focus node for a field
  void registerFocusNode<T>(BetterFormFieldID<T> fieldId, FocusNode node) {
    _focusNodes[fieldId.key] = node;
  }

  /// Request focus for a specific field
  void focusField<T>(BetterFormFieldID<T> fieldId) {
    _focusNodes[fieldId.key]?.requestFocus();
  }

  /// Focus the first field with an error
  /// Note: Logic depends on iterator order of keys, which might not match visual order
  /// unless registered in order. SchemaBasedFormController provides better ordering.
  void focusFirstError() {
    for (final entry in state.validations.entries) {
      if (!entry.value.isValid) {
        _focusNodes[entry.key]?.requestFocus();
        return;
      }
    }
  }
}
