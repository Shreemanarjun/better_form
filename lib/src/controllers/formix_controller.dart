import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'riverpod_controller.dart';
import 'field_id.dart';
import 'validation.dart';
import '../enums.dart';
import '../i18n.dart';
import 'batch.dart';

/// A controller for managing form state that is compatible with vanilla Flutter.
///
/// While [RiverpodFormController] is pure Riverpod, [FormixController] adds
/// a compatibility layer that exposes [ValueNotifier]s and [ValueListenable]s.
/// This allows non-Riverpod widgets within your app to react to form changes
/// without needing access to [WidgetRef].
class FormixController extends RiverpodFormController {
  /// Creates a [FormixController].
  FormixController({
    super.initialValue,
    super.fields,
    super.messages = const DefaultFormixMessages(),
    super.persistence,
    super.formId,
    super.analytics,
    super.namespace,
    super.autovalidateMode = FormixAutovalidateMode.always,
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
  ValueNotifier<bool>? _isPendingNotifier;

  void _onStateChanged(FormixData state) {
    // Optimization: If changedFields is present, only update notifiers for those keys.
    // If null, we fall back to checking all cached notifiers (e.g. initial load).
    final changedKeys = state.changedFields;

    // Helper to update a specific notifier map
    void updateNotifiers<T>(
      Map<String, ValueNotifier<T>> notifiers,
      T Function(String key) getValue,
    ) {
      if (notifiers.isEmpty) return;

      // If we have a delta, only check relevant keys that we are actually listening to
      final keysToCheck = changedKeys != null ? changedKeys.where((k) => notifiers.containsKey(k)) : notifiers.keys;

      for (final key in keysToCheck) {
        final notifier = notifiers[key];
        if (notifier == null) continue;

        final newValue = getValue(key);
        if (notifier.value != newValue) {
          notifier.value = newValue;
        }
      }
    }

    // Update value notifiers
    updateNotifiers(_valueNotifiers, (key) => state.values[key]);

    // Update validation notifiers
    updateNotifiers(
      _validationNotifiers,
      (key) => state.validations[key] ?? ValidationResult.valid,
    );

    // Update dirty notifiers
    updateNotifiers(_dirtyNotifiers, (key) => state.dirtyStates[key] ?? false);

    // Update touched notifiers
    updateNotifiers(
      _touchedNotifiers,
      (key) => state.touchedStates[key] ?? false,
    );

    // Update global notifiers
    if (_isDirtyNotifier != null && _isDirtyNotifier!.value != state.isDirty) {
      _isDirtyNotifier!.value = state.isDirty;
    }
    if (_isValidNotifier != null && _isValidNotifier!.value != state.isValid) {
      _isValidNotifier!.value = state.isValid;
    }
    if (_isSubmittingNotifier != null && _isSubmittingNotifier!.value != state.isSubmitting) {
      _isSubmittingNotifier!.value = state.isSubmitting;
    }
    if (_isPendingNotifier != null && _isPendingNotifier!.value != state.isPending) {
      _isPendingNotifier!.value = state.isPending;
    }

    // Call legacy listeners
    // Optimization: Only notify listeners for fields that actually changed
    // If changedKeys is null (e.g. initial), notify all.
    if (changedKeys != null) {
      for (final key in changedKeys) {
        final listeners = _fieldListeners[key];
        if (listeners != null) {
          for (final listener in listeners) {
            listener();
          }
        }
      }
    } else {
      // Notify all
      for (final listeners in _fieldListeners.values) {
        for (final listener in listeners) {
          listener();
        }
      }
    }
    for (final listener in _dirtyListeners) {
      listener(state.isDirty);
    }
  }

  /// Whether the form is currently being submitted.
  @override
  bool get isSubmitting => state.isSubmitting;

  /// Whether any field in the form has been modified.
  bool get isDirty => state.isDirty;

  /// Map of all current field keys to their values.
  Map<String, dynamic> get values => state.values;

  /// Resets the form to its initial state.
  @override
  void reset({ResetStrategy strategy = ResetStrategy.initialValues}) {
    super.reset(strategy: strategy);
  }

  /// Submits the form with automatic focus support on validation failure.
  @override
  Future<void> submit({
    required Future<void> Function(Map<String, dynamic> values) onValid,
    void Function(Map<String, ValidationResult> errors)? onError,
    Duration? debounce,
    Duration? throttle,
    bool optimistic = false,
    bool autoFocusOnInvalid = true,
    bool waitForPending = true,
  }) async {
    await super.submit(
      onValid: onValid,
      onError: (errors) {
        if (autoFocusOnInvalid) {
          focusFirstError();
        }
        announceErrors();
        onError?.call(errors);
      },
      debounce: debounce,
      throttle: throttle,
      optimistic: optimistic,
      waitForPending: waitForPending,
    );
  }

  /// Disposes all created notifiers and listeners.
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
    _isPendingNotifier?.dispose();

    _focusNodes.clear();
    _contexts.clear();

    super.dispose();
  }

  /// Returns a [ValueNotifier] for the value of the specified field.
  ValueNotifier<T?> getFieldNotifier<T>(FormixFieldID<T> fieldId) {
    if (_valueNotifiers.containsKey(fieldId.key)) {
      return _valueNotifiers[fieldId.key] as ValueNotifier<T?>;
    }
    final notifier = ValueNotifier<T?>(getValue(fieldId));
    _valueNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Returns a [ValueListenable] for the value of the specified field.
  ValueListenable<T?> fieldValueListenable<T>(FormixFieldID<T> fieldId) {
    return getFieldNotifier(fieldId);
  }

  /// Returns a [ValueNotifier] for the validation result of the specified field.
  ValueNotifier<ValidationResult> fieldValidationNotifier<T>(
    FormixFieldID<T> fieldId,
  ) {
    if (_validationNotifiers.containsKey(fieldId.key)) {
      return _validationNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<ValidationResult>(getValidation(fieldId));
    _validationNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Returns a [ValueNotifier] for the dirty status of the specified field.
  ValueNotifier<bool> fieldDirtyNotifier<T>(FormixFieldID<T> fieldId) {
    if (_dirtyNotifiers.containsKey(fieldId.key)) {
      return _dirtyNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldDirty(fieldId));
    _dirtyNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Returns a [ValueNotifier] for the touched status of the specified field.
  ValueNotifier<bool> fieldTouchedNotifier<T>(FormixFieldID<T> fieldId) {
    if (_touchedNotifiers.containsKey(fieldId.key)) {
      return _touchedNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldTouched(fieldId));
    _touchedNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// A [ValueNotifier] that tracks whether the form is dirty.
  ValueNotifier<bool> get isDirtyNotifier {
    _isDirtyNotifier ??= ValueNotifier(state.isDirty);
    return _isDirtyNotifier!;
  }

  /// A [ValueNotifier] that tracks whether the form is valid.
  ValueNotifier<bool> get isValidNotifier {
    _isValidNotifier ??= ValueNotifier(state.isValid);
    return _isValidNotifier!;
  }

  /// A [ValueNotifier] that tracks whether the form is submitting.
  ValueNotifier<bool> get isSubmittingNotifier {
    _isSubmittingNotifier ??= ValueNotifier(state.isSubmitting);
    return _isSubmittingNotifier!;
  }

  /// A [ValueNotifier] that tracks whether any field is in a pending state.
  ValueNotifier<bool> get isPendingNotifier {
    _isPendingNotifier ??= ValueNotifier(state.isPending);
    return _isPendingNotifier!;
  }

  // Focus Management
  final Map<String, FocusNode> _focusNodes = {};

  /// Registers a [FocusNode] to be associated with a specific field.
  /// Typically called by field widgets in their `initState`.
  void registerFocusNode<T>(FormixFieldID<T> fieldId, FocusNode node) {
    _focusNodes[fieldId.key] = node;
  }

  /// Requests focus for the specified field.
  void focusField<T>(FormixFieldID<T> id) {
    _focusNodes[id.key]?.requestFocus();
  }

  /// Focuses the next registered field relative to the current one.
  void focusNextField<T>(FormixFieldID<T> currentId) {
    final keys = _focusNodes.keys.toList();
    final currentIndex = keys.indexOf(currentId.key);
    if (currentIndex != -1 && currentIndex < keys.length - 1) {
      _focusNodes[keys[currentIndex + 1]]?.requestFocus();
    }
  }

  final Map<String, BuildContext> _contexts = {};

  /// Registers a [BuildContext] for a field, primarily for programmatic scrolling.
  void registerContext<T>(FormixFieldID<T> id, BuildContext context) {
    _contexts[id.key] = context;
  }

  /// Scrolls the UI to ensure the specified field is visible.
  void scrollToField<T>(
    FormixFieldID<T> id, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.5,
    ScrollPositionAlignmentPolicy alignmentPolicy = ScrollPositionAlignmentPolicy.explicit,
  }) {
    final context = _contexts[id.key];
    if (context != null && context.mounted) {
      Scrollable.ensureVisible(
        context,
        duration: duration,
        curve: curve,
        alignment: alignment,
        alignmentPolicy: alignmentPolicy,
      );
    }
  }

  /// Focuses the first field that currently has a validation error.
  /// Also scrolls to make the field visible if a context is registered.
  void focusFirstError({
    Duration scrollDuration = const Duration(milliseconds: 300),
    Curve scrollCurve = Curves.easeInOut,
  }) {
    for (final entry in state.validations.entries) {
      if (!entry.value.isValid) {
        // Scroll to the field first
        final context = _contexts[entry.key];
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: scrollDuration,
            curve: scrollCurve,
            alignment: 0.2, // Show field near top for better visibility
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        }

        // Then focus it
        _focusNodes[entry.key]?.requestFocus();
        return;
      }
    }
  }

  /// Announces the first validation error to assistive technologies.
  ///
  /// This is important for accessibility (a11y) so that screen reader users
  /// are notified when a form submission fails due to validation errors.
  void announceErrors() {
    final firstErrorKey = state.validations.entries.where((e) => !e.value.isValid).firstOrNull?.key;

    if (firstErrorKey != null) {
      final error = state.validations[firstErrorKey]?.errorMessage;
      final context = _contexts[firstErrorKey];

      if (error != null && context != null && context.mounted) {
        final view = View.of(context);
        final directionality = Directionality.of(context);

        SemanticsService.sendAnnouncement(
          view,
          error,
          directionality,
          assertiveness: Assertiveness.assertive,
        );
      }
    }
  }

  /// Returns an unmodifiable map of all current field values.
  Map<String, dynamic> toMap() => Map.unmodifiable(state.values);

  /// Returns a map containing only the values of fields that have been changed.
  Map<String, dynamic> getChangedValues() {
    final result = <String, dynamic>{};
    for (final entry in state.dirtyStates.entries) {
      if (entry.value) {
        result[entry.key] = state.values[entry.key];
      }
    }
    return result;
  }

  /// Updates multiple field values at once.
  /// This triggers validation for updated fields and is more efficient than
  /// multiple [setValue] calls.
  @override
  FormixBatchResult setValues(
    Map<FormixFieldID, dynamic> updates, {
    bool strict = false,
  }) {
    return super.setValues(updates, strict: strict);
  }

  /// Updates multiple field values using a type-safe [FormixBatch].
  @override
  FormixBatchResult applyBatch(FormixBatch batch, {bool strict = false}) {
    return super.applyBatch(batch, strict: strict);
  }

  /// Updates multiple field values from a raw map.
  FormixBatchResult updateFromMap(Map<String, dynamic> data) {
    final updates = <FormixFieldID, dynamic>{};
    for (final entry in data.entries) {
      final fieldId = FormixFieldID<dynamic>(entry.key);
      if (isFieldRegistered(fieldId)) {
        updates[fieldId] = entry.value;
      }
    }
    return setValues(updates);
  }

  /// Resets the form and sets a new set of initial values.
  /// This clears all dirty and touched states.
  @override
  void resetToValues(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      setInitialValueInternal(entry.key, entry.value);
    }
    reset(strategy: ResetStrategy.initialValues);
  }

  // Listener management for compatibility
  final _fieldListeners = <String, List<VoidCallback>>{};
  final _dirtyListeners = <void Function(bool)>{};

  /// Adds a listener that will be called whenever any field value changes.
  void addFieldListener<T>(FormixFieldID<T> fieldId, VoidCallback listener) {
    if (!_fieldListeners.containsKey(fieldId.key)) {
      _fieldListeners[fieldId.key] = [];
    }
    _fieldListeners[fieldId.key]!.add(listener);
  }

  /// Removes a field listener.
  void removeFieldListener<T>(FormixFieldID<T> fieldId, VoidCallback listener) {
    if (_fieldListeners.containsKey(fieldId.key)) {
      _fieldListeners[fieldId.key]!.remove(listener);
      if (_fieldListeners[fieldId.key]!.isEmpty) {
        _fieldListeners.remove(fieldId.key);
      }
    }
  }

  /// Adds a listener specifically for changes to the form's dirty state.
  void addDirtyListener(void Function(bool) listener) {
    _dirtyListeners.add(listener);
  }

  /// Removes a dirty state listener.
  void removeDirtyListener(void Function(bool) listener) {
    _dirtyListeners.remove(listener);
  }

  @override
  String toString() {
    return 'FormixController(fields: ${state.values.keys.toList()}, isValid: ${state.isValid}, isDirty: ${state.isDirty})';
  }
}
