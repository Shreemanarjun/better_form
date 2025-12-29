import 'dart:async';

import 'package:flutter/material.dart';

import 'controller.dart';
import 'field_id.dart';
import 'field.dart';
import 'validation.dart';

/// Base class for form field schemas with type safety
abstract class FormFieldSchema<T> {
  const FormFieldSchema({
    required this.id,
    required this.initialValue,
    this.validator,
    this.asyncValidator,
    this.label,
    this.hint,
    this.isRequired = false,
    this.isVisible = true,
    this.dependencies = const [],
  });

  /// Unique identifier for the field
  final BetterFormFieldID<T> id;

  /// Initial value for the field
  final T initialValue;

  /// Synchronous validator
  final String? Function(T value)? validator;

  /// Asynchronous validator
  final Future<String?> Function(T value)? asyncValidator;

  /// Display label
  final String? label;

  /// Display hint
  final String? hint;

  /// Whether the field is required
  final bool isRequired;

  /// Whether the field is currently visible
  final bool isVisible;

  /// Fields that this field depends on for visibility/validation
  final List<BetterFormFieldID<dynamic>> dependencies;

  /// Create the actual field definition
  BetterFormField<T> toFieldDefinition() {
    return BetterFormField<T>(
      id: id,
      initialValue: initialValue,
      validator: validator,
      label: label,
      hint: hint,
    );
  }

  /// Check if this field should be visible based on form state
  bool shouldBeVisible(Map<String, dynamic> formState) {
    return isVisible;
  }

  /// Get validation errors for this field
  Future<List<String>> validate(T value, Map<String, dynamic> formState) async {
    final errors = <String>[];

    // Synchronous validation
    if (validator != null) {
      final syncError = validator!(value);
      if (syncError != null) {
        errors.add(syncError);
      }
    }

    // Asynchronous validation
    if (asyncValidator != null) {
      try {
        final asyncError = await asyncValidator!(value);
        if (asyncError != null) {
          errors.add(asyncError);
        }
      } catch (e) {
        errors.add('Validation failed: ${e.toString()}');
      }
    }

    // Required field validation
    if (isRequired && _isEmptyValue(value)) {
      errors.add('${label ?? id.key} is required');
    }

    return errors;
  }

  bool _isEmptyValue(T value) {
    if (value == null) {
      return true;
    }
    if (value is String) {
      return value.trim().isEmpty;
    }
    if (value is Iterable) {
      return value.isEmpty;
    }
    return false;
  }
}

/// Schema for text fields
class TextFieldSchema extends FormFieldSchema<String> {
  const TextFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.keyboardType,
  });

  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final TextInputType? keyboardType;

  @override
  Future<List<String>> validate(
    String value,
    Map<String, dynamic> formState,
  ) async {
    final errors = await super.validate(value, formState);

    if (minLength != null && value.length < minLength!) {
      errors.add('Minimum length is $minLength characters');
    }

    if (maxLength != null && value.length > maxLength!) {
      errors.add('Maximum length is $maxLength characters');
    }

    if (pattern != null && !RegExp(pattern!).hasMatch(value)) {
      errors.add('Invalid format');
    }

    return errors;
  }
}

/// Schema for number fields
class NumberFieldSchema extends FormFieldSchema<num> {
  const NumberFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
    this.min,
    this.max,
    this.decimalPlaces = 0,
  });

  final num? min;
  final num? max;
  final int decimalPlaces;

  @override
  Future<List<String>> validate(
    num value,
    Map<String, dynamic> formState,
  ) async {
    final errors = await super.validate(value, formState);

    if (min != null && value < min!) {
      errors.add('Minimum value is $min');
    }

    if (max != null && value > max!) {
      errors.add('Maximum value is $max');
    }

    return errors;
  }
}

/// Schema for boolean fields
class BooleanFieldSchema extends FormFieldSchema<bool> {
  const BooleanFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
  });
}

/// Schema for date fields
class DateFieldSchema extends FormFieldSchema<DateTime> {
  const DateFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
    this.minDate,
    this.maxDate,
  });

  final DateTime? minDate;
  final DateTime? maxDate;

  @override
  Future<List<String>> validate(
    DateTime value,
    Map<String, dynamic> formState,
  ) async {
    final errors = await super.validate(value, formState);

    if (minDate != null && value.isBefore(minDate!)) {
      errors.add('Date must be after ${minDate!.toString().split(' ')[0]}');
    }

    if (maxDate != null && value.isAfter(maxDate!)) {
      errors.add('Date must be before ${maxDate!.toString().split(' ')[0]}');
    }

    return errors;
  }
}

/// Schema for selection fields (dropdown, radio, etc.)
class SelectionFieldSchema<T> extends FormFieldSchema<T> {
  const SelectionFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
    required this.options,
  });

  final List<T> options;

  @override
  Future<List<String>> validate(T value, Map<String, dynamic> formState) async {
    final errors = await super.validate(value, formState);

    if (!options.contains(value)) {
      errors.add('Invalid selection');
    }

    return errors;
  }
}

/// Conditional field schema that shows/hides based on other field values
class ConditionalFieldSchema<T> extends FormFieldSchema<T> {
  const ConditionalFieldSchema({
    required super.id,
    required super.initialValue,
    super.validator,
    super.asyncValidator,
    super.label,
    super.hint,
    super.isRequired,
    super.isVisible,
    super.dependencies,
    required this.visibilityCondition,
  });

  final bool Function(Map<String, dynamic> formState) visibilityCondition;

  @override
  bool shouldBeVisible(Map<String, dynamic> formState) {
    return visibilityCondition(formState);
  }
}

/// Form schema that defines the structure of an entire form
class FormSchema {
  const FormSchema({
    required this.fields,
    this.name,
    this.description,
    this.submitButtonText = 'Submit',
    this.resetButtonText = 'Reset',
    this.onSubmit,
    this.onValidate,
  });

  /// Name of the form
  final String? name;

  /// Description of the form
  final String? description;

  /// All field schemas in the form
  final List<FormFieldSchema<dynamic>> fields;

  /// Text for submit button
  final String submitButtonText;

  /// Text for reset button
  final String resetButtonText;

  /// Submit handler
  final Future<void> Function(Map<String, dynamic> values)? onSubmit;

  /// Custom validation handler
  final Future<List<String>> Function(Map<String, dynamic> values)? onValidate;

  /// Get a field schema by ID
  FormFieldSchema<T>? getField<T>(BetterFormFieldID<T> fieldId) {
    try {
      return fields.firstWhere((field) => field.id == fieldId)
          as FormFieldSchema<T>;
    } catch (_) {
      return null;
    }
  }

  /// Get all visible fields based on current form state
  List<FormFieldSchema<dynamic>> getVisibleFields(
    Map<String, dynamic> formState,
  ) {
    return fields.where((field) => field.shouldBeVisible(formState)).toList();
  }

  /// Validate the entire form
  Future<FormValidationResult> validate(Map<String, dynamic> formState) async {
    final fieldErrors = <BetterFormFieldID<dynamic>, List<String>>{};
    var hasErrors = false;

    // Validate each field
    for (final field in fields) {
      if (field.shouldBeVisible(formState)) {
        final value = formState[field.id.key];
        if (value != null) {
          final errors = await field.validate(value, formState);
          if (errors.isNotEmpty) {
            fieldErrors[field.id] = errors;
            hasErrors = true;
          }
        }
      }
    }

    // Run custom validation if provided
    List<String> customErrors = [];
    if (onValidate != null) {
      customErrors = await onValidate!(formState);
      if (customErrors.isNotEmpty) {
        hasErrors = true;
      }
    }

    return FormValidationResult(
      isValid: !hasErrors,
      fieldErrors: fieldErrors,
      customErrors: customErrors,
    );
  }

  /// Submit the form
  Future<FormSubmissionResult> submit(Map<String, dynamic> formState) async {
    try {
      // Validate first
      final validationResult = await validate(formState);
      if (!validationResult.isValid) {
        return FormSubmissionResult.failure(
          error: 'Validation failed',
          validationResult: validationResult,
        );
      }

      // Submit if handler provided
      if (onSubmit != null) {
        await onSubmit!(formState);
        return FormSubmissionResult.success();
      } else {
        return FormSubmissionResult.success(data: formState);
      }
    } catch (e) {
      return FormSubmissionResult.failure(error: e.toString());
    }
  }
}

/// Result of form validation
class FormValidationResult {
  const FormValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
    this.customErrors = const [],
  });

  final bool isValid;
  final Map<BetterFormFieldID<dynamic>, List<String>> fieldErrors;
  final List<String> customErrors;

  /// Get all error messages
  List<String> get allErrors {
    final errors = <String>[];
    errors.addAll(customErrors);
    for (final fieldErrors in fieldErrors.values) {
      errors.addAll(fieldErrors);
    }
    return errors;
  }

  /// Get errors for a specific field
  List<String> getFieldErrors(BetterFormFieldID<dynamic> fieldId) {
    return fieldErrors[fieldId] ?? [];
  }
}

/// Result of form submission
class FormSubmissionResult {
  const FormSubmissionResult._({
    required this.success,
    this.data,
    this.error,
    this.validationResult,
  });

  factory FormSubmissionResult.success({dynamic data}) {
    return FormSubmissionResult._(success: true, data: data);
  }

  factory FormSubmissionResult.failure({
    required String error,
    FormValidationResult? validationResult,
  }) {
    return FormSubmissionResult._(
      success: false,
      error: error,
      validationResult: validationResult,
    );
  }

  final bool success;
  final dynamic data;
  final String? error;
  final FormValidationResult? validationResult;
}

/// Enhanced controller that works with form schemas
class SchemaBasedFormController extends BetterFormController {
  SchemaBasedFormController({
    required this.schema,
    Map<String, dynamic> initialValue = const {},
  }) : super(initialValue: _buildInitialValue(schema, initialValue)) {
    // Register fields
    for (final field in schema.fields) {
      registerField(field.toFieldDefinition());
    }
  }

  final FormSchema schema;

  /// Get visible fields based on current form state
  List<FormFieldSchema<dynamic>> get visibleFields {
    return schema.getVisibleFields(values);
  }

  /// Validate the entire form using the schema
  Future<FormValidationResult> validateForm() async {
    final result = await schema.validate(values);

    // Update field validation notifiers manually
    for (final field in schema.fields) {
      final fieldErrors = result.getFieldErrors(field.id);
      final validationResult = fieldErrors.isEmpty
          ? ValidationResult.valid
          : ValidationResult(
              isValid: false,
              errorMessage: fieldErrors.join(', '),
            );

      // Update the field validation notifier
      final validationNotifier = fieldValidationNotifier<dynamic>(field.id);
      validationNotifier.value = validationResult;
    }

    return result;
  }

  /// Submit the form using the schema
  Future<FormSubmissionResult> submitForm() async {
    // For now, just submit without checking submitting state
    try {
      final result = await schema.submit(values);
      return result;
    } catch (e) {
      return FormSubmissionResult.failure(error: e.toString());
    }
  }

  static Map<String, dynamic> _buildInitialValue(
    FormSchema schema,
    Map<String, dynamic> initialValue,
  ) {
    final result = <String, dynamic>{};

    // Set schema defaults
    for (final field in schema.fields) {
      result[field.id.key] = field.initialValue;
    }

    // Override with provided values
    result.addAll(initialValue);

    return result;
  }

}
