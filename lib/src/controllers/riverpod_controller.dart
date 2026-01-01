import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'field.dart';
import 'field_id.dart';
import 'validation.dart';

/// Form state managed by Riverpod
class FormState {
  final Map<String, dynamic> values;
  final Map<String, ValidationResult> validations;
  final Map<String, bool> dirtyStates;
  final bool isSubmitting;

  const FormState({
    this.values = const {},
    this.validations = const {},
    this.dirtyStates = const {},
    this.isSubmitting = false,
  });

  FormState copyWith({
    Map<String, dynamic>? values,
    Map<String, ValidationResult>? validations,
    Map<String, bool>? dirtyStates,
    bool? isSubmitting,
  }) {
    return FormState(
      values: values ?? this.values,
      validations: validations ?? this.validations,
      dirtyStates: dirtyStates ?? this.dirtyStates,
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
}

/// Riverpod-based form controller
class RiverpodFormController extends StateNotifier<FormState> {
  RiverpodFormController({
    Map<String, dynamic> initialValue = const {},
  }) : super(FormState(values: Map.from(initialValue))) {
    _initialValue.addAll(initialValue);
  }

  final Map<String, dynamic> _initialValue = {};
  final Map<String, BetterFormField<dynamic>> _fieldDefinitions = {};

  /// Get the initial form value
  Map<String, dynamic> get initialValue => Map.unmodifiable(_initialValue);

  /// Check if a field is registered
  bool isFieldRegistered<T>(BetterFormFieldID<T> fieldId) {
    return _fieldDefinitions.containsKey(fieldId.key);
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
    final fieldDef = _fieldDefinitions[fieldId.key];
    final newValidations = Map<String, ValidationResult>.from(state.validations);
    if (fieldDef?.validator != null) {
      try {
        final String? validationResult = fieldDef!.validator!(value);
        newValidations[fieldId.key] = validationResult != null
            ? ValidationResult(
                isValid: false,
                errorMessage: validationResult,
              )
            : ValidationResult.valid;
      } catch (e) {
        newValidations[fieldId.key] = ValidationResult(
          isValid: false,
          errorMessage: 'Validation error: ${e.toString()}',
        );
      }
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
    );
  }

  /// Register a field
  void registerField<T>(BetterFormField<T> field) {
    final key = field.id.key;

    _fieldDefinitions[key] = BetterFormField<dynamic>(
      id: BetterFormFieldID<dynamic>(field.id.key),
      initialValue: field.initialValue,
      validator: field.validator != null
          ? (dynamic value) {
              if (value is T) {
                return field.validator!(value);
              }
              return null;
            }
          : null,
      label: field.label,
      hint: field.hint,
      transformer: field.transformer,
    );

    // Persist initial value
    if (!_initialValue.containsKey(key)) {
      if (field.initialValue != null) {
        _initialValue[key] = field.initialValue;
      } else {
        throw StateError('Field ${field.id.key} must have an initial value.');
      }
    }

    // Initialize state for this field
    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(state.validations);
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);

    if (!newValues.containsKey(key)) {
      newValues[key] = field.initialValue;
    }
    if (!newDirtyStates.containsKey(key)) {
      newDirtyStates[key] = false;
    }

    // Validate initial value if validator is provided
    if (field.validator != null && field.initialValue != null) {
      try {
        final String? validationResult = field.validator!(field.initialValue);
        newValidations[key] = validationResult != null
            ? ValidationResult(
                isValid: false,
                errorMessage: validationResult,
              )
            : ValidationResult.valid;
      } catch (e) {
        newValidations[key] = ValidationResult(
          isValid: false,
          errorMessage: 'Validation error: ${e.toString()}',
        );
      }
    } else if (!newValidations.containsKey(key)) {
      newValidations[key] = ValidationResult.valid;
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
    );
  }

  /// Unregister a field
  void unregisterField<T>(BetterFormFieldID<T> fieldId) {
    final key = fieldId.key;
    _fieldDefinitions.remove(key);

    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(state.validations);
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);

    newValues.remove(key);
    newValidations.remove(key);
    newDirtyStates.remove(key);

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
    );
  }

  /// Reset form to initial state
  void reset() {
    final newValues = Map<String, dynamic>.from(_initialValue);
    final newValidations = <String, ValidationResult>{};
    final newDirtyStates = <String, bool>{};

    for (final key in _fieldDefinitions.keys) {
      newValidations[key] = ValidationResult.valid;
      newDirtyStates[key] = false;
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      isSubmitting: false,
    );
  }

  /// Validate entire form
  bool validate() {
    var isFormValid = true;
    final newValidations = Map<String, ValidationResult>.from(state.validations);

    for (final field in _fieldDefinitions.values) {
      final key = field.id.key;
      final currentValue = state.values[key];

      if (currentValue != null && field.validator != null) {
        try {
          final String? validationResult = field.validator!(currentValue);
          newValidations[key] = validationResult != null
              ? ValidationResult(
                  isValid: false,
                  errorMessage: validationResult,
                )
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
      } else if (field.validator != null) {
        // Field has validator but no value - mark as invalid
        newValidations[key] = ValidationResult(
          isValid: false,
          errorMessage: 'This field is required',
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

  /// Set submitting state
  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }
}

/// Provider for form controller with auto-disposal
final formControllerProvider = StateNotifierProvider.autoDispose.family<
    RiverpodFormController,
    FormState,
    Map<String, dynamic>>((ref, initialValue) {
  return RiverpodFormController(initialValue: initialValue);
});

/// Provider for the current controller provider (can be overridden)
final currentControllerProvider = Provider<AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>>((ref) {
  return formControllerProvider(const {});
});

/// Provider for field value with selector for performance
final fieldValueProvider = Provider.family<dynamic, BetterFormFieldID<dynamic>>((ref, fieldId) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(controllerProvider.select((formState) => formState.getValue(fieldId)));
}, dependencies: [currentControllerProvider]);

/// Provider for field validation with selector for performance
final fieldValidationProvider = Provider.family<ValidationResult, BetterFormFieldID<dynamic>>((ref, fieldId) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(controllerProvider.select((formState) => formState.getValidation(fieldId)));
}, dependencies: [currentControllerProvider]);

/// Provider for field dirty state with selector for performance
final fieldDirtyProvider = Provider.family<bool, BetterFormFieldID<dynamic>>((ref, fieldId) {
  final controllerProvider = ref.watch(currentControllerProvider);
  return ref.watch(controllerProvider.select((formState) => formState.isFieldDirty(fieldId)));
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
  return ref.watch(controllerProvider.select((formState) => formState.isSubmitting));
}, dependencies: [currentControllerProvider]);
