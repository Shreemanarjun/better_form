import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide FormState;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'field.dart';
import 'field_id.dart';
import 'validation.dart';
import '../i18n.dart';
import '../enums.dart';
import '../persistence/form_persistence.dart';

/// Form state managed by Riverpod
class FormState {
  final Map<String, dynamic> values;
  final Map<String, ValidationResult> validations;
  final Map<String, bool> dirtyStates;
  final Map<String, bool> touchedStates;
  final bool isSubmitting;

  const FormState({
    this.values = const {},
    this.validations = const {},
    this.dirtyStates = const {},
    this.touchedStates = const {},
    this.isSubmitting = false,
  });

  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, ValidationResult>? validations,
    Map<String, bool>? dirtyStates,
    Map<String, bool>? touchedStates,
    bool? isSubmitting,
  }) {
    return FormState(
      values: values ?? this.values,
      validations: validations ?? this.validations,
      dirtyStates: dirtyStates ?? this.dirtyStates,
      touchedStates: touchedStates ?? this.touchedStates,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  /// Check if form is valid
  bool get isValid => validations.values.every((v) => v.isValid);

  /// Check if form is dirty
  bool get isDirty => dirtyStates.values.any((d) => d);

  /// Get field value with type safety
  T? getValue<T>(BetterFormFieldID<T> fieldId) {
    final value = values[fieldId.key];
    return value is T ? value : null;
  }

  /// Get field validation
  ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId) {
    return validations[fieldId.key] ?? ValidationResult.valid;
  }

  /// Check if field is dirty
  bool isFieldDirty<T>(BetterFormFieldID<T> fieldId) {
    return dirtyStates[fieldId.key] ?? false;
  }

  /// Check if field is touched
  bool isFieldTouched<T>(BetterFormFieldID<T> fieldId) {
    return touchedStates[fieldId.key] ?? false;
  }
}

/// Configuration for a form field
class BetterFormFieldConfig<T> {
  const BetterFormFieldConfig({
    required this.id,
    this.initialValue,
    this.validator,
    this.label,
    this.hint,
    this.asyncValidator,
    this.debounceDuration,
  });

  final BetterFormFieldID<T> id;
  final T? initialValue;
  final String? Function(T value)? validator;
  final String? label;
  final String? hint;
  final Future<String?> Function(T value)? asyncValidator;
  final Duration? debounceDuration;

  BetterFormField<T> toField() {
    T? finalInitialValue = initialValue;
    // Capture validator in local variable to avoid type inference issues
    final originalValidator = validator;
    String? Function(T)? wrappedValidator;
    if (originalValidator != null) {
      wrappedValidator = (T value) => originalValidator(value);
    }

    final originalAsyncValidator = asyncValidator;
    Future<String?> Function(T)? wrappedAsyncValidator;
    if (originalAsyncValidator != null) {
      wrappedAsyncValidator = (T value) => originalAsyncValidator(value);
    }

    return BetterFormField<T>(
      id: id,
      initialValue: finalInitialValue,
      validator: wrappedValidator,
      label: label,
      hint: hint,
      asyncValidator: wrappedAsyncValidator,
      debounceDuration: debounceDuration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BetterFormFieldConfig<T> &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          initialValue == other.initialValue &&
          validator == other.validator &&
          label == other.label &&
          hint == other.hint &&
          asyncValidator == other.asyncValidator &&
          debounceDuration == other.debounceDuration;

  @override
  int get hashCode =>
      id.hashCode ^
      initialValue.hashCode ^
      validator.hashCode ^
      label.hashCode ^
      hint.hashCode ^
      asyncValidator.hashCode ^
      debounceDuration.hashCode;
}

/// Riverpod-based form controller
class RiverpodFormController extends StateNotifier<FormState> {
  final BetterFormMessages messages;
  final Map<String, dynamic> _initialValue = {};
  final Map<String, Timer> _debouncers = {};
  final Map<String, BetterFormField<dynamic>> _fieldDefinitions = {};

  static FormState _createInitialState(
    Map<String, dynamic> initialValues,
    List<BetterFormField> fields,
  ) {
    final values = Map<String, dynamic>.from(initialValues);
    final validations = <String, ValidationResult>{};
    final dirtyStates = <String, bool>{};
    final touchedStates = <String, bool>{};

    for (final field in fields) {
      final key = field.id.key;
      if (!values.containsKey(key)) {
        values[key] = field.initialValue;
      }
      dirtyStates[key] = false;
      touchedStates[key] = false;

      // Initial validation
      final dynamic validator = (field as dynamic).validator;
      final val = values[key];
      if (validator != null && val != null) {
        try {
          final result = (validator as dynamic)(val);
          validations[key] = result != null
              ? ValidationResult(isValid: false, errorMessage: result)
              : ValidationResult.valid;
        } catch (e) {
          validations[key] = ValidationResult(
            isValid: false,
            errorMessage: 'Validation error: $e',
          );
        }
      } else {
        validations[key] = ValidationResult.valid;
      }
    }

    return FormState(
      values: values,
      validations: validations,
      dirtyStates: dirtyStates,
      touchedStates: touchedStates,
    );
  }

  final BetterFormPersistence? persistence;
  final String? formId;

  RiverpodFormController({
    Map<String, dynamic> initialValue = const {},
    List<BetterFormField> fields = const [],
    this.messages = const DefaultBetterFormMessages(),
    this.persistence,
    this.formId,
  }) : super(_createInitialState(initialValue, fields)) {
    _initialValue.addAll(initialValue);
    for (final field in fields) {
      final key = field.id.key;
      // We need to wrap these as well for consistency with registerField
      _fieldDefinitions[key] = BetterFormField<dynamic>(
        id: BetterFormFieldID<dynamic>(key),
        initialValue: (field as dynamic).initialValue,
        validator: (field as dynamic).validator != null
            ? _wrapValidator(field as dynamic)
            : null,
        label: (field as dynamic).label,
        hint: (field as dynamic).hint,
        transformer: (field as dynamic).transformer != null
            ? _wrapTransformer(field as dynamic)
            : null,
        asyncValidator: (field as dynamic).asyncValidator != null
            ? _wrapAsyncValidator(field as dynamic)
            : null,
        debounceDuration: (field as dynamic).debounceDuration,
      );
    }
    _loadPersistedState();
  }

  /// Get the current state of the form.
  FormState get currentState => state;

  Future<void> _loadPersistedState() async {
    if (persistence != null && formId != null) {
      final savedValues = await persistence!.getSavedState(formId!);
      if (savedValues != null && mounted) {
        final newValues = Map<String, dynamic>.from(state.values);
        newValues.addAll(savedValues);

        // We need to re-validate everything with the loaded values
        final newValidations = Map<String, ValidationResult>.from(
          state.validations,
        );
        final newDirtyStates = Map<String, bool>.from(state.dirtyStates);

        for (final key in savedValues.keys) {
          // check if field exists, validation etc.
          if (_fieldDefinitions.containsKey(key)) {
            final field = _fieldDefinitions[key]!;
            final value = savedValues[key];

            // Mark as dirty if different from initial
            final initial = _initialValue[key];
            final isDirty = initial == null ? value != null : value != initial;
            newDirtyStates[key] = isDirty;

            // Validate
            if (field.validator != null) {
              try {
                final res = (field.validator as dynamic)(value);
                newValidations[key] = res != null
                    ? ValidationResult(isValid: false, errorMessage: res)
                    : ValidationResult.valid;
              } catch (_) {}
            }
          } else {
            // If field not registered yet, just set value, it will be validated on registration
            newDirtyStates[key] = true;
          }
        }

        state = state.copyWith(
          values: newValues,
          validations: newValidations,
          dirtyStates: newDirtyStates,
        );
      }
    }
  }

  static String? Function(dynamic)? _wrapValidator(dynamic field) {
    final dynamic validator = field.validator;
    if (validator == null) return null;
    return (dynamic value) {
      try {
        return (validator as dynamic)(value);
      } catch (e) {
        return 'Type conversion error: ${e.toString()}';
      }
    };
  }

  static dynamic Function(dynamic)? _wrapTransformer(dynamic field) {
    final dynamic transformer = field.transformer;
    if (transformer == null) return null;
    return (dynamic value) {
      try {
        return (transformer as dynamic)(value);
      } catch (e) {
        return value;
      }
    };
  }

  static Future<String?> Function(dynamic)? _wrapAsyncValidator(dynamic field) {
    final dynamic asyncValidator = field.asyncValidator;
    if (asyncValidator == null) return null;
    return (dynamic value) async {
      try {
        return await (asyncValidator as dynamic)(value);
      } catch (e) {
        return 'Async validation error: ${e.toString()}';
      }
    };
  }

  /// Get the initial form value
  Map<String, dynamic> get initialValue => Map.unmodifiable(_initialValue);

  /// Check if form is submitting
  bool get isSubmitting => state.isSubmitting;

  /// Check if a field is registered
  bool isFieldRegistered<T>(BetterFormFieldID<T> fieldId) {
    return _fieldDefinitions.containsKey(fieldId.key);
  }

  @override
  void dispose() {
    for (var timer in _debouncers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  /// Get field value with type safety
  T? getValue<T>(BetterFormFieldID<T> fieldId) {
    return state.getValue(fieldId);
  }

  /// Set field value with type safety and validation
  void setValue<T>(BetterFormFieldID<T> fieldId, T value) {
    // Type check
    final expectedInitialValue = _initialValue[fieldId.key];
    if (expectedInitialValue != null &&
        value.runtimeType != expectedInitialValue.runtimeType) {
      throw ArgumentError(
        'Type mismatch: expected ${expectedInitialValue.runtimeType}, got ${value.runtimeType}',
      );
    }

    final fieldDef = _fieldDefinitions[fieldId.key];

    // Apply transformer if available
    final transformer = fieldDef?.transformer;
    if (transformer != null) {
      // safe cast assuming transformer returns T (or dynamic that fits)
      value = transformer(value) as T;
    }

    // Update value
    final newValues = Map<String, dynamic>.from(state.values);
    newValues[fieldId.key] = value;

    // Update dirty state
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final initialValue = _initialValue[fieldId.key];
    final isDirty = initialValue == null
        ? value != null
        : value != initialValue;
    newDirtyStates[fieldId.key] = isDirty;

    // Validate field if it has a validator
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    ValidationResult syncResult = ValidationResult.valid;

    // Sync Validation
    final validator = fieldDef?.validator;
    if (validator != null) {
      try {
        final String? validationResult = validator(value);
        syncResult = validationResult != null
            ? ValidationResult(isValid: false, errorMessage: validationResult)
            : ValidationResult.valid;
      } catch (e) {
        syncResult = ValidationResult(
          isValid: false,
          errorMessage: 'Validation error: ${e.toString()}',
        );
      }
    }

    newValidations[fieldId.key] = syncResult;

    // Handle Async Validation with Debounce
    final asyncValidator = fieldDef?.asyncValidator;
    if (syncResult.isValid && asyncValidator != null) {
      // Cancel previous timer
      _debouncers[fieldId.key]?.cancel();

      // Set to validating
      newValidations[fieldId.key] = ValidationResult.validating;

      // Start timer
      _debouncers[fieldId.key] = Timer(
        fieldDef?.debounceDuration ?? const Duration(milliseconds: 300),
        () async {
          if (!mounted) return;
          try {
            final error = await asyncValidator(value);
            if (!mounted) return;

            // Get fresh state validations
            final currentValidations = Map<String, ValidationResult>.from(
              state.validations,
            );
            currentValidations[fieldId.key] = error != null
                ? ValidationResult(isValid: false, errorMessage: error)
                : ValidationResult.valid;

            state = state.copyWith(validations: currentValidations);
          } catch (e) {
            if (!mounted) return;
            final currentValidations = Map<String, ValidationResult>.from(
              state.validations,
            );
            currentValidations[fieldId.key] = ValidationResult(
              isValid: false,
              errorMessage: 'Async validation failed',
            );
            state = state.copyWith(validations: currentValidations);
          }
        },
      );
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
    );

    // Persist change
    if (persistence != null && formId != null) {
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Register a field
  void registerField<T>(BetterFormField<T> field) {
    final key = field.id.key;

    final validator = field.validator;
    final transformer = field.transformer;
    final asyncValidator = field.asyncValidator;

    _fieldDefinitions[key] = BetterFormField<dynamic>(
      id: BetterFormFieldID<dynamic>(field.id.key),
      initialValue: field.initialValue,
      validator: validator != null ? _wrapValidator(field) : null,
      label: field.label,
      hint: field.hint,
      transformer: transformer != null ? _wrapTransformer(field) : null,
      asyncValidator: asyncValidator != null
          ? _wrapAsyncValidator(field)
          : null,
      debounceDuration: field.debounceDuration,
    );

    // Persist initial value (can be null for nullable fields)
    if (!_initialValue.containsKey(key)) {
      _initialValue[key] = field.initialValue;
    }

    // Initialize initialValue and state for this field if not present
    if (!_initialValue.containsKey(key)) {
      _initialValue[key] = field.initialValue;
    }
    void updateState() {
      if (!mounted) return;

      // Merge with latest state to avoid overwriting other registrations
      final currentValues = Map<String, dynamic>.from(state.values);
      final currentValidations = Map<String, ValidationResult>.from(
        state.validations,
      );
      final currentDirtyStates = Map<String, bool>.from(state.dirtyStates);
      final currentTouchedStates = Map<String, bool>.from(state.touchedStates);

      if (!currentValues.containsKey(key)) {
        currentValues[key] = field.initialValue;
      }
      if (!currentDirtyStates.containsKey(key)) {
        currentDirtyStates[key] = false;
      }
      if (!currentTouchedStates.containsKey(key)) {
        currentTouchedStates[key] = false;
      }

      // Re-validate if not already present or if we need to force it
      if (!currentValidations.containsKey(key)) {
        final validatorFunc = field.validator;
        final initialValue = field.initialValue;
        if (validatorFunc != null && initialValue != null) {
          try {
            final String? validationResult = validatorFunc(initialValue);
            currentValidations[key] = validationResult != null
                ? ValidationResult(
                    isValid: false,
                    errorMessage: validationResult,
                  )
                : ValidationResult.valid;
          } catch (e) {
            currentValidations[key] = ValidationResult(
              isValid: false,
              errorMessage: 'Validation error: ${e.toString()}',
            );
          }
        } else {
          currentValidations[key] = ValidationResult.valid;
        }
      }

      state = state.copyWith(
        values: currentValues,
        validations: currentValidations,
        dirtyStates: currentDirtyStates,
        touchedStates: currentTouchedStates,
      );
    }

    // Only defer if we're currently in a build/layout/paint phase
    bool isPersistent = false;
    try {
      final scheduler = WidgetsBinding.instance;
      isPersistent =
          scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks;
    } catch (_) {
      // Binding not initialized or other error, assume not persistent
    }

    if (isPersistent) {
      Future.microtask(updateState);
    } else {
      updateState();
    }
  }

  /// Unregister a field
  void unregisterField<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    _fieldDefinitions.remove(key);

    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);

    newValues.remove(key);
    newValidations.remove(key);
    newDirtyStates.remove(key);
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);
    newTouchedStates.remove(key);

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
    );
    // Should we persist removal? Maybe.
    if (persistence != null && formId != null) {
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Reset form to initial state or clear it
  void reset({ResetStrategy strategy = ResetStrategy.initialValues}) {
    final Map<String, dynamic> newValues;
    if (strategy == ResetStrategy.initialValues) {
      newValues = Map<String, dynamic>.from(_initialValue);
    } else {
      newValues = {};
      for (final entry in _fieldDefinitions.entries) {
        newValues[entry.key] =
            entry.value.emptyValue ?? _getDefaultEmptyValue(entry.value);
      }
    }

    final newValidations = <String, ValidationResult>{};
    final newDirtyStates = <String, bool>{};

    for (final key in _fieldDefinitions.keys) {
      newDirtyStates[key] = false;

      // Re-validate the field with its new value
      final fieldDef = _fieldDefinitions[key]!;
      final newValue = newValues[key];
      final validator = fieldDef.validator;

      if (validator != null && newValue != null) {
        try {
          final String? validationResult = validator(newValue);
          newValidations[key] = validationResult != null
              ? ValidationResult(isValid: false, errorMessage: validationResult)
              : ValidationResult.valid;
        } catch (e) {
          newValidations[key] = ValidationResult(
            isValid: false,
            errorMessage: 'Validation error: ${e.toString()}',
          );
        }
      } else {
        newValidations[key] = ValidationResult.valid;
      }
    }

    final newTouchedStates = <String, bool>{};
    for (final key in _fieldDefinitions.keys) {
      newTouchedStates[key] = false;
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
      isSubmitting: false,
    );

    if (persistence != null && formId != null) {
      // If resetting to initial values, we effectively "clear" the modifications.
      // We can either clear storage or save the new (initial) values.
      // Saving the current values is safer.
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Reset specific fields
  void resetFields(
    List<BetterFormFieldID> fieldIds, {
    ResetStrategy strategy = ResetStrategy.initialValues,
  }) {
    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);

    for (final fieldId in fieldIds) {
      final key = fieldId.key;
      final fieldDef = _fieldDefinitions[key];
      if (fieldDef == null) continue;

      final dynamic newValue;
      if (strategy == ResetStrategy.initialValues) {
        newValue = _initialValue[key];
      } else {
        newValue = fieldDef.emptyValue ?? _getDefaultEmptyValue(fieldDef);
      }

      newValues[key] = newValue;
      newDirtyStates[key] = false;
      newTouchedStates[key] = false;

      // Re-validate
      final validator = fieldDef.validator;
      if (validator != null && newValue != null) {
        try {
          final String? validationResult = validator(newValue);
          newValidations[key] = validationResult != null
              ? ValidationResult(isValid: false, errorMessage: validationResult)
              : ValidationResult.valid;
        } catch (e) {
          newValidations[key] = ValidationResult(
            isValid: false,
            errorMessage: 'Validation error',
          );
        }
      } else {
        newValidations[key] = ValidationResult.valid;
      }
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
    );
  }

  /// Validate entire form
  bool validate() {
    var isFormValid = true;
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );

    for (final field in _fieldDefinitions.values) {
      final key = field.id.key;
      final currentValue = state.values[key];
      final validator = field.validator;

      if (currentValue != null && validator != null) {
        try {
          final String? validationResult = validator(currentValue);
          newValidations[key] = validationResult != null
              ? ValidationResult(isValid: false, errorMessage: validationResult)
              : ValidationResult.valid;

          if (validationResult != null) {
            isFormValid = false;
          }
        } catch (e) {
          newValidations[key] = ValidationResult(
            isValid: false,
            errorMessage: 'Validation error: ${e.toString()}',
          );
          isFormValid = false;
        }
      } else if (validator != null) {
        // Field has validator but no value - mark as invalid
        newValidations[key] = ValidationResult(
          isValid: false,
          errorMessage: messages.required(field.label ?? key),
        );
        isFormValid = false;
      }
    }

    state = state.copyWith(validations: newValidations);
    return isFormValid;
  }

  /// Get validation result for field
  ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId) {
    return state.getValidation(fieldId);
  }

  /// Check if field is dirty
  bool isFieldDirty<T>(BetterFormFieldID<T> fieldId) {
    return state.isFieldDirty(fieldId);
  }

  /// Check if field is touched
  bool isFieldTouched<T>(BetterFormFieldID<T> fieldId) {
    return state.isFieldTouched(fieldId);
  }

  /// Mark field as touched
  void markAsTouched<T>(BetterFormFieldID<T> fieldId) {
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);
    newTouchedStates[fieldId.key] = true;
    state = state.copyWith(touchedStates: newTouchedStates);
  }

  /// Set submitting state
  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  /// Get default empty value for a field type
  dynamic _getDefaultEmptyValue(BetterFormField<dynamic> field) {
    // Try to infer from initial value type
    final initialValue = field.initialValue;
    if (initialValue is String) return '';
    if (initialValue is num) return 0;
    if (initialValue is bool) return false;
    if (initialValue is List) return [];
    if (initialValue is Map) return {};
    // For other types, return null
    return null;
  }
}

/// Form controller for managing form state externally (Riverpod-based)
/// This version adds ValueNotifier compatibility layer for non-Riverpod widgets.
class BetterFormController extends RiverpodFormController {
  BetterFormController({
    super.initialValue,
    super.fields,
    super.messages = const DefaultBetterFormMessages(),
    super.persistence,
    super.formId,
  }) {
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
    //  debugPrint('STATE CHANGED: values=${state.values.keys.toList()}');
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

  /// Get boolean for submitting state
  @override
  bool get isSubmitting => state.isSubmitting;

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

  /// Get a ValueNotifier for a specific field
  ValueNotifier<T?> getFieldNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_valueNotifiers.containsKey(fieldId.key)) {
      return _valueNotifiers[fieldId.key] as ValueNotifier<T?>;
    }
    final notifier = ValueNotifier<T?>(getValue(fieldId));
    _valueNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Listen to a specific field's value changes
  ValueListenable<T?> fieldValueListenable<T>(BetterFormFieldID<T> fieldId) {
    return getFieldNotifier(fieldId);
  }

  /// Get validation notifier for a field
  ValueNotifier<ValidationResult> fieldValidationNotifier<T>(
    BetterFormFieldID<T> fieldId,
  ) {
    if (_validationNotifiers.containsKey(fieldId.key)) {
      return _validationNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<ValidationResult>(getValidation(fieldId));
    _validationNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Get dirty notifier for a field
  ValueNotifier<bool> fieldDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_dirtyNotifiers.containsKey(fieldId.key)) {
      return _dirtyNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldDirty(fieldId));
    _dirtyNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Get touched notifier for a field
  ValueNotifier<bool> fieldTouchedNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_touchedNotifiers.containsKey(fieldId.key)) {
      return _touchedNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldTouched(fieldId));
    _touchedNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Global notifiers
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
  void focusFirstError() {
    for (final entry in state.validations.entries) {
      if (!entry.value.isValid) {
        _focusNodes[entry.key]?.requestFocus();
        return;
      }
    }
  }

  /// Get all current form values as a map
  Map<String, dynamic> toMap() => Map.unmodifiable(state.values);

  /// Helper to get only modified values
  Map<String, dynamic> getChangedValues() {
    final result = <String, dynamic>{};
    for (final entry in state.dirtyStates.entries) {
      if (entry.value) {
        result[entry.key] = state.values[entry.key];
      }
    }
    return result;
  }

  /// Bulk update form values without changing initial values or resetting dirty state
  /// This will trigger validation for updated fields.
  void updateFromMap(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final fieldId = BetterFormFieldID<dynamic>(entry.key);
      if (isFieldRegistered(fieldId)) {
        setValue(fieldId, entry.value);
      }
    }
  }

  /// Reset the form to a new set of initial values.
  /// This will update the underlying initial values, set current values to them,
  /// and clear all dirty states.
  void resetToValues(Map<String, dynamic> data) {
    // We need to update _initialValue and then call reset
    for (final entry in data.entries) {
      _initialValue[entry.key] = entry.value;
    }
    reset(strategy: ResetStrategy.initialValues);
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
}

/// Provider for form messages
final betterFormMessagesProvider = Provider<BetterFormMessages>((ref) {
  return const DefaultBetterFormMessages();
});

/// Parameter for form controller provider family
@immutable
class BetterFormParameter {
  const BetterFormParameter({
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
  });

  final Map<String, dynamic> initialValue;
  final List<BetterFormFieldConfig> fields;
  final BetterFormPersistence? persistence;
  final String? formId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BetterFormParameter &&
          const MapEquality().equals(initialValue, other.initialValue) &&
          const ListEquality().equals(fields, other.fields) &&
          persistence == other.persistence &&
          formId == other.formId;

  @override
  int get hashCode =>
      const MapEquality().hash(initialValue) ^
      const ListEquality().hash(fields) ^
      persistence.hashCode ^
      formId.hashCode;
}

/// Provider for form controller with auto-disposal
final formControllerProvider = StateNotifierProvider.autoDispose
    .family<RiverpodFormController, FormState, BetterFormParameter>((
      ref,
      param,
    ) {
      final messages = ref.watch(betterFormMessagesProvider);
      return BetterFormController(
        initialValue: param.initialValue,
        fields: param.fields.map((f) => f.toField()).toList(),
        messages: messages,
        persistence: param.persistence,
        formId: param.formId,
      );
    });

/// Provider for the current controller provider (can be overridden)
final currentControllerProvider =
    Provider<
      AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>
    >((ref) {
      return formControllerProvider(
        const BetterFormParameter(initialValue: {}),
      );
    });

/// Provider for field value with selector for performance
final fieldValueProvider = Provider.family<dynamic, BetterFormFieldID<dynamic>>(
  (ref, fieldId) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(
      controllerProvider.select((formState) => formState.getValue(fieldId)),
    );
  },
  dependencies: [currentControllerProvider],
);

/// Provider for field validation with selector for performance
final fieldValidationProvider =
    Provider.family<ValidationResult, BetterFormFieldID<dynamic>>((
      ref,
      fieldId,
    ) {
      final controllerProvider = ref.watch(currentControllerProvider);
      return ref.watch(
        controllerProvider.select(
          (formState) => formState.getValidation(fieldId),
        ),
      );
    }, dependencies: [currentControllerProvider]);

/// Provider for field dirty state with selector for performance
final fieldDirtyProvider = Provider.family<bool, BetterFormFieldID<dynamic>>((
  ref,
  fieldId,
) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(
    controllerProvider.select((formState) => formState.isFieldDirty(fieldId)),
  );
}, dependencies: [currentControllerProvider]);

/// Provider for field touched state with selector for performance
final fieldTouchedProvider = Provider.family<bool, BetterFormFieldID<dynamic>>((
  ref,
  fieldId,
) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(
    controllerProvider.select((formState) => formState.isFieldTouched(fieldId)),
  );
}, dependencies: [currentControllerProvider]);

/// Provider for form validity with selector for performance
final formValidProvider = Provider<bool>((ref) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(controllerProvider.select((formState) => formState.isValid));
}, dependencies: [currentControllerProvider]);

/// Provider for form dirty state with selector for performance
final formDirtyProvider = Provider<bool>((ref) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(controllerProvider.select((formState) => formState.isDirty));
}, dependencies: [currentControllerProvider]);

/// Provider for form submitting state with selector for performance
final formSubmittingProvider = Provider<bool>((ref) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(
    controllerProvider.select((formState) => formState.isSubmitting),
  );
}, dependencies: [currentControllerProvider]);
