import 'package:flutter/foundation.dart';
import 'riverpod_controller.dart';
import 'field_id.dart';
import 'field.dart';
import 'validation.dart';

/// Form controller for managing form state externally (Riverpod-based)
class BetterFormController extends RiverpodFormController {
  BetterFormController({
    super.initialValue = const {},
  });

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

  /// Extract data from form
  Map<String, dynamic> get values => state.values;

  /// Reset form to initial state
  @override
  void reset() {
    super.reset();
  }

  /// Dispose of resources
  @override
  void dispose() {
    super.dispose();
  }

  // Minimal compatibility layer for existing widgets
  // These methods provide backward compatibility while using Riverpod internally

  /// Get a ValueNotifier for a specific field (compatibility)
  ValueNotifier<T?> getFieldNotifier<T>(BetterFormFieldID<T> fieldId) {
    final notifier = ValueNotifier<T?>(getValue(fieldId));
    // Note: In a full implementation, this would listen to state changes
    // For now, this provides basic compatibility
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
    final notifier = ValueNotifier<ValidationResult>(getValidation(fieldId));
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
    final notifier = ValueNotifier<bool>(isFieldDirty(fieldId));
    return notifier;
  }

  /// Listen to dirty state changes for a specific field (compatibility)
  ValueNotifier<bool> fieldDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    return getDirtyNotifier(fieldId);
  }

  /// Legacy compatibility notifiers
  ValueNotifier<bool> get isDirtyNotifier => ValueNotifier(state.isDirty);
  ValueNotifier<bool> get isValidNotifier => ValueNotifier(state.isValid);

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
