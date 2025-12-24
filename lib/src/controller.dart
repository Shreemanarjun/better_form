import 'package:flutter/foundation.dart';

import 'field_id.dart';
import 'field.dart';
import 'validation.dart';

/// Callback for field value changes
typedef FieldChangeCallback<T> =
    void Function(BetterFormFieldID<T> fieldId, T value);

/// Callback for form dirty state changes
typedef DirtyStateCallback = void Function(bool isDirty);

/// Type-safe initial value builder for BetterFormController
class BetterFormInitialValue {
  final Map<String, dynamic> _values = {};

  /// Set initial value for a field
  void set<T>(BetterFormFieldID<T> fieldId, T value) {
    _values[fieldId.key] = value;
  }

  /// Get initial value for a field
  T? get<T>(BetterFormFieldID<T> fieldId) {
    final value = _values[fieldId.key];
    return value is T ? value : null;
  }

  /// Build the initial value map
  Map<String, dynamic> build() => Map.unmodifiable(_values);
}

/// Form controller for managing form state externally
class BetterFormController extends ChangeNotifier {
  BetterFormController({
    Map<String, dynamic> initialValue = const {},
    BetterFormInitialValue? initialValueBuilder,
  }) : _initialValue = Map.from(initialValueBuilder?.build() ?? initialValue);

  final Map<String, dynamic> _initialValue;
  final Map<String, dynamic> _value = {};
  final Map<String, ValidationResult> _validationResults = {};
  final Map<String, bool> _dirtyStates = {};
  final Map<String, List<VoidCallback>> _listeners = {};
  final Map<String, ValueNotifier<dynamic>> _fieldNotifiers = {};
  final Map<String, BetterFormField<dynamic>> _fieldDefinitions = {};
  final Map<String, Function> _validators = {};

  bool _isDirty = false;
  final List<DirtyStateCallback> _dirtyListeners = [];
  final ValueNotifier<bool> _isDirtyNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isValidNotifier = ValueNotifier(true);

  Map<String, dynamic> get initialValue => Map.unmodifiable(_initialValue);
  Map<String, dynamic> get value => Map.unmodifiable(_value);
  bool get isDirty => _isDirty;
  ValueNotifier<bool> get isDirtyNotifier => _isDirtyNotifier;
  ValueNotifier<bool> get isValidNotifier => _isValidNotifier;
  bool get isValid => _isValidNotifier.value;

  /// Check if a field is registered
  bool isFieldRegistered<T>(BetterFormFieldID<T> fieldId) {
    return _fieldDefinitions.containsKey(fieldId.key);
  }

  /// Get value with type safety
  T getValue<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    final value = _value[key];

    // Check if value is of the correct type (including null for nullable types)
    if (value is T) {
      return value;
    }

    // If value is null, try to provide a default or handle registration
    if (value == null) {
      // If the field is registered, we might be able to provide the initial value
      final fieldDef = _fieldDefinitions[key];
      if (fieldDef != null) {
        final initialValue = fieldDef.initialValue;
        if (initialValue is T) return initialValue;
      }

      // Try to provide a default value for the type T
      final defaultValue = getDefaultValueForType<T>();
      if (defaultValue is T) {
        return defaultValue;
      }

      // If null is valid for T, return null
      try {
        return null as T;
      } catch (_) {
        // T is not nullable and we couldn't find a default
      }
    }

    // Still no valid value, throw a descriptive error
    throw StateError(
      'Type mismatch for field ${fieldId.key}: expected $T, got ${value?.runtimeType ?? 'null'}. '
      'Ensure the field is properly registered with the correct type.',
    );
  }

  T? getDefaultValueForType<T>() {
    if (T == String) return '' as T;
    if (T == int) return 0 as T;
    if (T == double) return 0.0 as T;
    if (T == bool) return false as T;
    if (T == List) return <dynamic>[] as T;
    if (T == DateTime) return DateTime.now() as T;
    return null;
  }

  /// Set value with type safety and validation
  void setValue<T>(BetterFormFieldID<T> fieldId, T value) {
    final key = fieldId.key;

    // Type check at runtime using the initial value's type
    final expectedInitialValue = _initialValue[key];
    if (expectedInitialValue != null &&
        value.runtimeType != expectedInitialValue.runtimeType) {
      throw ArgumentError(
        'Type mismatch: expected ${expectedInitialValue.runtimeType}, got ${value.runtimeType}',
      );
    }

    // Check if value actually changed
    final currentValue = _value[key];
    if (currentValue == value) {
      // Even if the value didn't change, we might need to update dirty state
      // If the value equals the initial value, clear the dirty state
      final currentInitialValue = _initialValue[key];
      if (currentInitialValue != null && value == currentInitialValue) {
        _dirtyStates[key] = false;
        _checkAndNotifyDirtyState();
      }
      return;
    }

    _value[key] = value;
    // Check if the new value is different from the initial value
    final fieldInitialValue = _initialValue[key];
    _dirtyStates[key] = fieldInitialValue == null || value != fieldInitialValue;

    // Run validation if validator exists
    final validator = _validators[key];
    if (validator != null) {
      try {
        // Call validator with the correctly typed value
        final validationResult = validator(value);
        _validationResults[key] = validationResult != null
            ? ValidationResult(isValid: false, errorMessage: validationResult)
            : ValidationResult.valid;
      } catch (e) {
        // If there's a type mismatch, mark as invalid
        _validationResults[key] = ValidationResult(
          isValid: false,
          errorMessage: 'Validation error: ${e.toString()}',
        );
      }
    }

    // Notify listeners
    _notifyListeners(key);
    _checkAndNotifyDirtyState();
    notifyListeners();
  }

  /// Register a field with the controller
  void registerField<T>(BetterFormField<T> field) {
    final key = field.id.key;
    _fieldDefinitions[key] = field;
    if (field.validator != null) {
      _validators[key] = field.validator!;
    }

    // Ensure the initial value is never null
    final initialValue =
        _initialValue[key] ?? field.initialValue ?? getDefaultValueForType<T>();
    _value[key] = initialValue;
    _dirtyStates[key] = false;
    _listeners[key] = [];

    // Run initial validation if validator exists
    if (field.validator != null) {
      final validationResult = field.validator!(initialValue);
      _validationResults[key] = validationResult != null
          ? ValidationResult(isValid: false, errorMessage: validationResult)
          : ValidationResult.valid;
    } else {
      _validationResults[key] = ValidationResult.valid;
    }
  }

  /// Unregister a field from the controller
  void unregisterField<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    _fieldDefinitions.remove(key);
    _value.remove(key);
    _validationResults.remove(key);
    _dirtyStates.remove(key);
    _listeners.remove(key);
    _fieldNotifiers[key]?.dispose();
    _fieldNotifiers.remove(key);
  }

  /// Get a ValueNotifier for a specific field
  ValueNotifier<T> getFieldNotifier<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    if (!_fieldNotifiers.containsKey(key)) {
      T? initialValue = _value[key] as T?;
      if (initialValue == null) {
        // Try initial value from builder or default
        final registeredInitialValue = _initialValue[key];
        if (registeredInitialValue is T) {
          initialValue = registeredInitialValue;
        } else {
          initialValue = getDefaultValueForType<T>();
        }
      }

      _fieldNotifiers[key] = ValueNotifier<T>(initialValue as T);
    }
    return _fieldNotifiers[key] as ValueNotifier<T>;
  }

  /// Listen to a specific field's value changes
  /// Returns a ValueListenable that can be used with ValueListenableBuilder
  ValueListenable<T> fieldValueListenable<T>(BetterFormFieldID<T> fieldId) {
    return getFieldNotifier<T>(fieldId);
  }

  /// Listen to validation changes for a specific field
  ValueNotifier<ValidationResult> fieldValidationNotifier<T>(
    BetterFormFieldID<T> fieldId,
  ) {
    final key = fieldId.key;
    final notifierKey = '${key}_validation';
    if (!_fieldNotifiers.containsKey(notifierKey)) {
      _fieldNotifiers[notifierKey] = ValueNotifier<ValidationResult>(
        _validationResults[key] ?? ValidationResult.valid,
      );
    }
    return _fieldNotifiers[notifierKey] as ValueNotifier<ValidationResult>;
  }

  /// Listen to dirty state changes for a specific field
  ValueNotifier<bool> fieldDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    final notifierKey = '${key}_dirty';
    if (!_fieldNotifiers.containsKey(notifierKey)) {
      _fieldNotifiers[notifierKey] = ValueNotifier<bool>(
        _dirtyStates[key] ?? false,
      );
    }
    return _fieldNotifiers[notifierKey] as ValueNotifier<bool>;
  }

  /// Check if field is dirty
  bool isFieldDirty<T>(BetterFormFieldID<T> fieldId) {
    return _dirtyStates[fieldId.key] ?? false;
  }

  /// Get validation result for field
  ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId) {
    return _validationResults[fieldId.key] ?? ValidationResult.valid;
  }

  /// Add a listener for field changes
  void addFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _listeners[fieldId.key]?.add(listener);
  }

  /// Remove a listener
  void removeFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _listeners[fieldId.key]?.remove(listener);
  }

  /// Add a dirty state listener
  void addDirtyListener(DirtyStateCallback listener) {
    _dirtyListeners.add(listener);
  }

  /// Remove a dirty state listener
  void removeDirtyListener(DirtyStateCallback listener) {
    _dirtyListeners.remove(listener);
  }

  void _notifyListeners(String key) {
    final listeners = _listeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        listener();
      }
    }

    // Update field value notifier if it exists
    if (_fieldNotifiers.containsKey(key)) {
      _fieldNotifiers[key]!.value = _value[key];
    }

    // Update validation notifier if it exists
    final validationKey = '${key}_validation';
    if (_fieldNotifiers.containsKey(validationKey)) {
      (_fieldNotifiers[validationKey] as ValueNotifier<ValidationResult>)
              .value =
          _validationResults[key] ?? ValidationResult.valid;
    }

    // Update dirty notifier if it exists
    final dirtyKey = '${key}_dirty';
    if (_fieldNotifiers.containsKey(dirtyKey)) {
      (_fieldNotifiers[dirtyKey] as ValueNotifier<bool>).value =
          _dirtyStates[key] ?? false;
    }
  }

  void _checkAndNotifyDirtyState() {
    final wasDirty = _isDirty;
    _isDirty = _dirtyStates.values.any((dirty) => dirty);

    if (wasDirty != _isDirty) {
      _isDirtyNotifier.value = _isDirty;
      for (final listener in _dirtyListeners) {
        listener(_isDirty);
      }
    }

    // Also update isValid state here as validation might have changed
    _isValidNotifier.value = _validationResults.values.every(
      (result) => result.isValid,
    );
  }

  /// Reset form to initial state
  void reset() {
    for (final key in _initialValue.keys) {
      _value[key] = _initialValue[key];
      _dirtyStates[key] = false;
      _validationResults[key] = ValidationResult.valid;
      _notifyListeners(key);
    }
    _checkAndNotifyDirtyState();
    notifyListeners();
  }

  /// Reset initial values (useful after successful save)
  void resetInitialValues() {
    _initialValue.clear();
    _initialValue.addAll(_value);
    // Recalculate dirty states based on new initial values
    for (final key in _value.keys) {
      final currentValue = _value[key];
      final initialValue = _initialValue[key];
      _dirtyStates[key] = currentValue != initialValue;
    }
    _checkAndNotifyDirtyState();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final notifier in _fieldNotifiers.values) {
      notifier.dispose();
    }
    _fieldNotifiers.clear();
    _isDirtyNotifier.dispose();
    _isValidNotifier.dispose();
    _listeners.clear();
    _dirtyListeners.clear();
    super.dispose();
  }
}
