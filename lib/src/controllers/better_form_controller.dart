import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'riverpod_controller.dart';
import 'field_id.dart';
import 'validation.dart';
import '../enums.dart';
import '../i18n.dart';

/// A controller for managing form state that is compatible with vanilla Flutter.
///
/// While [RiverpodFormController] is pure Riverpod, [BetterFormController] adds
/// a compatibility layer that exposes [ValueNotifier]s and [ValueListenable]s.
/// This allows non-Riverpod widgets within your app to react to form changes
/// without needing access to [WidgetRef].
class BetterFormController extends RiverpodFormController {
  /// Creates a [BetterFormController].
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

  void _onStateChanged(BetterFormState state) {
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

    super.dispose();
  }

  /// Returns a [ValueNotifier] for the value of the specified field.
  ValueNotifier<T?> getFieldNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_valueNotifiers.containsKey(fieldId.key)) {
      return _valueNotifiers[fieldId.key] as ValueNotifier<T?>;
    }
    final notifier = ValueNotifier<T?>(getValue(fieldId));
    _valueNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Returns a [ValueListenable] for the value of the specified field.
  ValueListenable<T?> fieldValueListenable<T>(BetterFormFieldID<T> fieldId) {
    return getFieldNotifier(fieldId);
  }

  /// Returns a [ValueNotifier] for the validation result of the specified field.
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

  /// Returns a [ValueNotifier] for the dirty status of the specified field.
  ValueNotifier<bool> fieldDirtyNotifier<T>(BetterFormFieldID<T> fieldId) {
    if (_dirtyNotifiers.containsKey(fieldId.key)) {
      return _dirtyNotifiers[fieldId.key]!;
    }
    final notifier = ValueNotifier<bool>(isFieldDirty(fieldId));
    _dirtyNotifiers[fieldId.key] = notifier;
    return notifier;
  }

  /// Returns a [ValueNotifier] for the touched status of the specified field.
  ValueNotifier<bool> fieldTouchedNotifier<T>(BetterFormFieldID<T> fieldId) {
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

  // Focus Management
  final Map<String, FocusNode> _focusNodes = {};

  /// Registers a [FocusNode] to be associated with a specific field.
  /// Typically called by field widgets in their `initState`.
  void registerFocusNode<T>(BetterFormFieldID<T> fieldId, FocusNode node) {
    _focusNodes[fieldId.key] = node;
  }

  /// Requests focus for the specified field.
  void focusField<T>(BetterFormFieldID<T> id) {
    _focusNodes[id.key]?.requestFocus();
  }

  final Map<String, BuildContext> _contexts = {};

  /// Registers a [BuildContext] for a field, primarily for programmatic scrolling.
  void registerContext<T>(BetterFormFieldID<T> id, BuildContext context) {
    _contexts[id.key] = context;
  }

  /// Scrolls the UI to ensure the specified field is visible.
  void scrollToField<T>(
    BetterFormFieldID<T> id, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
    double alignment = 0.5,
    ScrollPositionAlignmentPolicy alignmentPolicy =
        ScrollPositionAlignmentPolicy.explicit,
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
  void focusFirstError() {
    for (final entry in state.validations.entries) {
      if (!entry.value.isValid) {
        _focusNodes[entry.key]?.requestFocus();
        return;
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
  /// This triggers validation for updated fields.
  void updateFromMap(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final fieldId = BetterFormFieldID<dynamic>(entry.key);
      if (isFieldRegistered(fieldId)) {
        setValue(fieldId, entry.value);
      }
    }
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
  final _fieldListeners = <VoidCallback>[];
  final _dirtyListeners = <void Function(bool)>{};

  /// Adds a listener that will be called whenever any field value changes.
  void addFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _fieldListeners.add(listener);
  }

  /// Removes a field listener.
  void removeFieldListener<T>(
    BetterFormFieldID<T> fieldId,
    VoidCallback listener,
  ) {
    _fieldListeners.remove(listener);
  }

  /// Adds a listener specifically for changes to the form's dirty state.
  void addDirtyListener(void Function(bool) listener) {
    _dirtyListeners.add(listener);
  }

  /// Removes a dirty state listener.
  void removeDirtyListener(void Function(bool) listener) {
    _dirtyListeners.remove(listener);
  }
}
