import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'field.dart';
import 'field_id.dart';
import 'validation.dart';
import 'form_state.dart';
import 'field_config.dart';
import 'formix_controller.dart';
import '../analytics/form_analytics.dart';
import '../i18n.dart';
import '../enums.dart';
import '../persistence/form_persistence.dart';
import '../devtools/formix_devtools.dart';

export 'form_state.dart';
export 'field_config.dart';
export 'formix_controller.dart';

/// Core logic for managing form state using Riverpod.
///
/// This controller handles field registration, value updates, sync/async validation,
/// cross-field dependencies, and state persistence.
///
/// **Listening to changes outside widgets:**
/// - Use `stream` to listen to all state changes
/// - Use `addListener` to register callbacks for specific events
/// - Access via `GlobalKey<FormixState>` for external control
class RiverpodFormController extends StateNotifier<FormixData> {
  /// Internationalization messages for validation errors
  final FormixMessages messages;
  @protected
  final Map<String, dynamic> initialValueMap = {};
  final Map<String, Timer> _debouncers = {};
  Timer? _submitDebounceTimer;
  DateTime? _lastSubmitTime;
  DateTime? _startTime;
  final Map<String, FormixField<dynamic>> _fieldDefinitions = {};
  // Inverse dependency graph: key -> list of dependents
  final Map<String, List<String>> _dependentsMap = {};

  @visibleForTesting
  int get registeredFieldsCount => _fieldDefinitions.length;

  // Undo/Redo History
  List<FormixData> _history = [];
  int _historyIndex = -1;
  bool _isRestoringHistory = false;
  static const int _maxHistoryLength =
      50; // Exposed for testing implicitly via max size checks

  @visibleForTesting
  int get historyCount => _history.length;

  bool _hasSubmittedSuccessfully = false;

  // Multi-Form Bindings
  final Map<String, StreamSubscription> _bindings = {};

  final Map<String, Duration> _validationDurations = {};

  /// Get validation durations for DevTools
  Map<String, Duration> get validationDurations =>
      Map.unmodifiable(_validationDurations);

  @visibleForTesting
  int get activeBindingsCount => _bindings.length;

  /// Stream controller for broadcasting state changes to external listeners
  final _stateController = StreamController<FormixData>.broadcast(sync: true);

  /// Stream of form state changes.
  ///
  /// Use this to listen to form changes outside of widgets:
  /// ```dart
  /// final subscription = controller.stream.listen((state) {
  ///   print('Form changed: ${state.values}');
  /// });
  /// // Don't forget to cancel when done
  /// subscription.cancel();
  /// ```
  @override
  Stream<FormixData> get stream => _stateController.stream;

  /// Registered listeners for form state changes
  final List<void Function(FormixData)> _formListeners = [];

  /// Add a listener that will be called whenever the form state changes.
  ///
  /// Returns a function that can be called to remove the listener.
  ///
  /// Example:
  /// ```dart
  /// final removeListener = controller.addFormListener((state) {
  ///   print('Values: ${state.values}');
  /// });
  ///
  /// // Later, remove the listener
  /// removeListener();
  /// ```
  VoidCallback addFormListener(void Function(FormixData state) listener) {
    _formListeners.add(listener);
    return () => removeFormListener(listener);
  }

  /// Remove a previously added listener
  void removeFormListener(void Function(FormixData state) listener) {
    _formListeners.remove(listener);
  }

  /// Notify all listeners and stream subscribers of state changes
  void _notifyFormListeners() {
    if (!mounted) return;

    // Notify stream subscribers
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }

    // Notify callback listeners
    for (final listener in _formListeners.toList()) {
      try {
        listener(state);
      } catch (e) {
        debugPrint('Error in form listener: $e');
      }
    }
  }

  /// Override state setter to automatically notify listeners
  @override
  set state(FormixData value) {
    if (!mounted) return;

    // Add to history if not restoring
    if (!_isRestoringHistory && (value != state)) {
      if (_historyIndex < _history.length - 1) {
        // Truncate future history
        _history = _history.sublist(0, _historyIndex + 1);
      }
      _history.add(value);
      if (_history.length > _maxHistoryLength) {
        _history.removeAt(0);
      } else {
        _historyIndex++;
      }
    }

    super.state = value;
    _notifyFormListeners();
  }

  @override
  FormixData get state => super.state;

  static FormixData _createInitialState(
    Map<String, dynamic> initialValues,
    List<FormixField> fields,
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

      final val = values[key];
      final mode = field.validationMode;
      final validator = field.wrappedValidator;

      if (mode == FormixAutovalidateMode.always &&
          validator != null &&
          val != null) {
        try {
          final result = validator(val);
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

    return FormixData(
      values: values,
      validations: validations,
      dirtyStates: dirtyStates,
      touchedStates: touchedStates,
    );
  }

  /// The persistence handler for this form
  final FormixPersistence? persistence;

  /// Unique identifier for this form (required for persistence)
  final String? formId;

  /// Optional analytics hook
  final FormixAnalytics? analytics;

  /// Creates a [RiverpodFormController].
  ///
  /// [initialValue] sets the starting values for the form.
  /// [fields] provides the configuration for form fields.
  /// [messages] allows overriding the default validation messages.
  /// [persistence] and [formId] enable state restoration across app restarts.
  RiverpodFormController({
    Map<String, dynamic> initialValue = const {},
    List<FormixField<dynamic>> fields = const [],
    this.messages = const DefaultFormixMessages(),
    this.persistence,
    this.formId,
    this.analytics,
  }) : super(_createInitialState(initialValue, fields)) {
    _startTime = DateTime.now();
    analytics?.onFormStarted(formId);
    initialValueMap.addAll(initialValue);
    registerFields(fields);
    _history = [state];
    _historyIndex = 0;
    _loadPersistedState();

    if (formId != null) {
      FormixDevToolsService.registerController(formId!, this);
    }
  }

  // --- Array Manipulation ---

  /// Adds an item to a form array
  void addArrayItem<T>(FormixArrayID<T> id, T item) {
    final currentList = getValue(id) ?? [];
    final newList = List<T>.from(currentList)..add(item);
    setValue(id, newList);
  }

  /// Removes an item at a specific index from a form array
  void removeArrayItemAt<T>(FormixArrayID<T> id, int index) {
    final currentList = getValue(id);
    if (currentList == null || index < 0 || index >= currentList.length) return;

    final newList = List<T>.from(currentList)..removeAt(index);
    setValue(id, newList);
  }

  /// Replaces an item at a specific index in a form array
  void replaceArrayItem<T>(FormixArrayID<T> id, int index, T item) {
    final currentList = getValue(id);
    if (currentList == null || index < 0 || index >= currentList.length) return;

    final newList = List<T>.from(currentList);
    newList[index] = item;
    setValue(id, newList);
  }

  /// Reorders items in a form array.
  ///
  /// Moves the item at [oldIndex] to [newIndex].
  void moveArrayItem<T>(FormixArrayID<T> id, int oldIndex, int newIndex) {
    final currentList = getValue(id);
    if (currentList == null ||
        oldIndex < 0 ||
        oldIndex >= currentList.length ||
        newIndex < 0 ||
        newIndex >= currentList.length) {
      return;
    }

    final newList = List<T>.from(currentList);
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    setValue(id, newList);
  }

  /// Clears all items from a form array
  void clearArray<T>(FormixArrayID<T> id) {
    setValue(id, <T>[]);
  }

  // --- Internals ---
  /// Internal helper to update initial value from subclasses
  @protected
  void setInitialValueInternal(String key, dynamic value) {
    initialValueMap[key] = value;
  }

  /// Get the current state of the form.
  FormixData get currentState => state;

  Future<void> _loadPersistedState() async {
    if (persistence != null && formId != null) {
      final savedValues = await persistence!.getSavedState(formId!);
      if (savedValues != null && mounted) {
        final newValues = Map<String, dynamic>.from(state.values);
        newValues.addAll(savedValues);

        final newValidations = Map<String, ValidationResult>.from(
          state.validations,
        );
        final newDirtyStates = Map<String, bool>.from(state.dirtyStates);

        for (final key in savedValues.keys) {
          if (_fieldDefinitions.containsKey(key)) {
            final field = _fieldDefinitions[key]!;
            final value = savedValues[key];

            final initial = initialValueMap[key];
            final isDirty = initial == null ? value != null : value != initial;
            newDirtyStates[key] = isDirty;

            if (field.validator != null) {
              try {
                final res = field.validator!(value);
                newValidations[key] = res != null
                    ? ValidationResult(isValid: false, errorMessage: res)
                    : ValidationResult.valid;
              } catch (_) {}
            }
          } else {
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

  /// Get the initial form value
  Map<String, dynamic> get initialValue => Map.unmodifiable(initialValueMap);

  /// Check if form is submitting
  bool get isSubmitting => state.isSubmitting;

  /// Check if a field is registered
  /// Returns true if a field with [fieldId] is currently registered.
  bool isFieldRegistered<T>(FormixFieldID<T> fieldId) {
    return _fieldDefinitions.containsKey(fieldId.key);
  }

  @override
  void dispose() {
    if (formId != null) {
      FormixDevToolsService.unregisterController(formId!);
    }
    if (!_hasSubmittedSuccessfully) {
      final duration = DateTime.now().difference(_startTime ?? DateTime.now());
      analytics?.onFormAbandoned(formId, duration);
    }
    for (var timer in _debouncers.values) {
      timer.cancel();
    }
    _submitDebounceTimer?.cancel();
    for (var sub in _bindings.values) {
      sub.cancel();
    }
    _bindings.clear();
    _stateController.close();
    _formListeners.clear();
    super.dispose();
  }

  /// Get field value with type safety
  T? getValue<T>(FormixFieldID<T> fieldId) {
    return state.getValue(fieldId);
  }

  /// Get field definition
  FormixField? getField(FormixFieldID<dynamic> fieldId) {
    return _fieldDefinitions[fieldId.key];
  }

  /// Set field value with type safety and validation
  void setValue<T>(FormixFieldID<T> fieldId, T value) {
    // Type check
    final expectedInitialValue = initialValueMap[fieldId.key];
    if (expectedInitialValue != null &&
        value != null &&
        value.runtimeType != expectedInitialValue.runtimeType &&
        !(value is num && expectedInitialValue is num)) {
      throw ArgumentError(
        'Type mismatch: expected ${expectedInitialValue.runtimeType}, got ${value.runtimeType}',
      );
    }

    final fieldDef = _fieldDefinitions[fieldId.key];

    // Apply transformer if available
    final transformer = fieldDef?.transformer;
    if (transformer != null) {
      value = transformer(value) as T;
    }

    if (value != getValue(fieldId)) {
      analytics?.onFieldChanged(formId, fieldId.key, value);
    }

    // State to be updated
    final newValues = Map<String, dynamic>.from(state.values);
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );

    // 1. Apply value and dirty state
    newValues[fieldId.key] = value;
    final initialValue = initialValueMap[fieldId.key];
    final isDirty = initialValue == null
        ? value != null
        : value != initialValue;
    newDirtyStates[fieldId.key] = isDirty;

    // 2. Determine fields to validate (self + transitive dependents)
    final fieldsToValidate = <String>{};
    final mode = fieldDef?.validationMode ?? FormixAutovalidateMode.always;
    if (mode == FormixAutovalidateMode.always ||
        (mode == FormixAutovalidateMode.onUserInteraction && isDirty)) {
      fieldsToValidate.add(fieldId.key);
    }

    // Collect ALL transitive dependents (preventing cycles)
    final transitiveDependents = _collectTransitiveDependents(fieldId.key);
    for (final depKey in transitiveDependents) {
      final depDef = _fieldDefinitions[depKey];
      if (depDef != null) {
        final depMode = depDef.validationMode;
        if (depMode == FormixAutovalidateMode.always ||
            depMode == FormixAutovalidateMode.onUserInteraction) {
          fieldsToValidate.add(depKey);
        }
      }
    }

    // 3. Run all synchronous validations
    for (final key in fieldsToValidate) {
      final val = newValues[key];
      final res = _performSyncValidation(
        key,
        val,
        newValues,
        currentValidations: newValidations,
      );
      newValidations[key] = res;
    }

    // 4. Update state ONCE with all sync changes
    // Calculate changed fields for delta updates
    final changedFields = <String>{fieldId.key}; // Value changed
    changedFields.addAll(fieldsToValidate); // Validations changed

    state = state.copyWith(
      values: newValues,
      dirtyStates: newDirtyStates,
      validations: newValidations,
      changedFields: changedFields,
    );

    // 5. Trigger async validations if necessary
    for (final key in fieldsToValidate) {
      final syncRes = newValidations[key]!;
      if (syncRes.isValid) {
        _triggerAsyncValidation(key, newValues[key]);
      }
    }

    if (persistence != null && formId != null) {
      persistence!.saveFormState(formId!, newValues);
    }
  }

  ValidationResult _performSyncValidation(
    String key,
    dynamic value,
    Map<String, dynamic> currentValues, {
    Map<String, ValidationResult>? currentValidations,
  }) {
    final sw = Stopwatch()..start();
    final fieldDef = _fieldDefinitions[key];
    if (fieldDef == null) return ValidationResult.valid;

    // We'll calculate the end result first then record the time
    ValidationResult calculate() {
      // 1. Standard Validator
      final validator = fieldDef.wrappedValidator;
      if (validator != null) {
        try {
          String? error = validator(value);
          if (error != null) {
            // Resolve placeholders if any
            error = messages.format(error, {
              'label': fieldDef.label ?? key,
              'value': value,
            });
            return ValidationResult(isValid: false, errorMessage: error);
          }
        } catch (e) {
          return ValidationResult(
            isValid: false,
            errorMessage: 'Validation error: ${e.toString()}',
          );
        }
      }

      // 2. Cross-field Validator
      final crossValidator = fieldDef.wrappedCrossFieldValidator;
      if (crossValidator != null) {
        try {
          // We create a temporary FormixData for the cross validator to see the NEW values
          final tempState = FormixData(
            values: currentValues,
            validations: currentValidations ?? state.validations,
            dirtyStates: state.dirtyStates,
            touchedStates: state.touchedStates,
          );
          String? error = crossValidator(value, tempState);
          if (error != null) {
            error = messages.format(error, {
              'label': fieldDef.label ?? key,
              'value': value,
            });
            return ValidationResult(isValid: false, errorMessage: error);
          }
        } catch (e) {
          return ValidationResult(
            isValid: false,
            errorMessage: 'Cross-validation error: ${e.toString()}',
          );
        }
      }

      return ValidationResult.valid;
    }

    final result = calculate();
    sw.stop();
    _validationDurations[key] = sw.elapsed;
    return result;
  }

  void _triggerAsyncValidation(String key, dynamic value) {
    final fieldDef = _fieldDefinitions[key];
    if (fieldDef == null) return;

    final asyncValidator = fieldDef.wrappedAsyncValidator;
    if (asyncValidator == null) return;

    _debouncers[key]?.cancel();

    // Set state to validating
    final currentValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    currentValidations[key] = ValidationResult.validating;
    state = state.copyWith(
      validations: currentValidations,
      changedFields: {key},
    );

    _debouncers[key] = Timer(
      fieldDef.debounceDuration ?? const Duration(milliseconds: 300),
      () async {
        if (!mounted) return;
        final sw = Stopwatch()..start();
        try {
          final error = await asyncValidator(value);
          sw.stop();
          _validationDurations[key] = sw.elapsed;

          if (!mounted) return;

          final latestValidations = Map<String, ValidationResult>.from(
            state.validations,
          );
          latestValidations[key] = error != null
              ? ValidationResult(isValid: false, errorMessage: error)
              : ValidationResult.valid;

          state = state.copyWith(
            validations: latestValidations,
            changedFields: {key},
          );
        } catch (e) {
          sw.stop();
          _validationDurations[key] = sw.elapsed;

          if (!mounted) return;
          final latestValidations = Map<String, ValidationResult>.from(
            state.validations,
          );
          latestValidations[key] = ValidationResult(
            isValid: false,
            errorMessage: 'Async validation error: $e',
          );
          state = state.copyWith(
            validations: latestValidations,
            changedFields: {key},
          );
        }
      },
    );
  }

  List<String> _getDependentsOf(String key) {
    if (_dependentsMap.containsKey(key)) {
      return List<String>.from(_dependentsMap[key]!);
    }
    return const [];
  }

  /// Recursively collects all fields that depend on the source field.
  /// Implement BFS queue to handle deep chains and cycle detection.
  Set<String> _collectTransitiveDependents(String sourceKey) {
    final result = <String>{};
    final queue = <String>{sourceKey};
    final visited = <String>{sourceKey};

    while (queue.isNotEmpty) {
      final currentKey = queue.first;
      queue.remove(currentKey);

      final directDependents = _getDependentsOf(currentKey);
      for (final depKey in directDependents) {
        if (!visited.contains(depKey)) {
          visited.add(depKey);
          result.add(depKey); // Add to result (dependents only, not source)
          queue.add(depKey);
        }
      }
    }
    return result;
  }

  /// Register multiple fields at once
  void registerFields(List<FormixField> fields) {
    if (fields.isEmpty) return;

    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);

    for (final field in fields) {
      final key = field.id.key;

      // Update dependency graph: Cleanup old dependencies
      if (_fieldDefinitions.containsKey(key)) {
        final oldField = _fieldDefinitions[key]!;
        for (final dep in oldField.dependsOn) {
          _dependentsMap[dep.key]?.remove(key);
        }
      }

      _validationDurations[key] = Duration.zero;

      _fieldDefinitions[key] = FormixField<dynamic>(
        id: FormixFieldID<dynamic>(field.id.key),
        initialValue: field.initialValue,
        validator: field.wrappedValidator,
        label: field.label,
        hint: field.hint,
        transformer: field.wrappedTransformer != null
            ? (dynamic val) => field.wrappedTransformer!(val)
            : null,
        asyncValidator: field.wrappedAsyncValidator,
        debounceDuration: field.debounceDuration,
        validationMode: field.validationMode,
        crossFieldValidator: field.wrappedCrossFieldValidator,
        dependsOn: field.dependsOn,
        inputFormatters: field.inputFormatters,
        textInputAction: field.textInputAction,
        onSubmitted: field.onSubmitted,
      );

      // Update dependency graph: Add new dependencies
      for (final dep in field.dependsOn) {
        _dependentsMap.putIfAbsent(dep.key, () => []).add(key);
      }

      if (!initialValueMap.containsKey(key)) {
        initialValueMap[key] = field.initialValue;
      }

      if (!newValues.containsKey(key)) {
        newValues[key] = field.initialValue;
      }
      if (!newDirtyStates.containsKey(key)) {
        newDirtyStates[key] = false;
      }
      if (!newTouchedStates.containsKey(key)) {
        newTouchedStates[key] = false;
      }
      if (!newValidations.containsKey(key)) {
        newValidations[key] = _performSyncValidation(
          key,
          field.initialValue,
          newValues,
          currentValidations: newValidations,
        );
      }
    }

    void updateState() {
      if (!mounted) return;
      state = state.copyWith(
        values: newValues,
        validations: newValidations,
        dirtyStates: newDirtyStates,
        touchedStates: newTouchedStates,
      );
    }

    bool isPersistent = false;
    try {
      final scheduler = WidgetsBinding.instance;
      isPersistent =
          scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks;
    } catch (_) {}

    if (isPersistent) {
      Future.microtask(updateState);
    } else {
      updateState();
    }
  }

  /// Register a field
  void registerField<T>(FormixField<T> field) {
    final key = field.id.key;

    // Update dependency graph: Cleanup old dependencies
    if (_fieldDefinitions.containsKey(key)) {
      final oldField = _fieldDefinitions[key]!;
      for (final dep in oldField.dependsOn) {
        _dependentsMap[dep.key]?.remove(key);
      }
    }

    _validationDurations[key] = Duration.zero;

    _fieldDefinitions[key] = FormixField<dynamic>(
      id: FormixFieldID<dynamic>(field.id.key),
      initialValue: field.initialValue,
      validator: field.wrappedValidator,
      label: field.label,
      hint: field.hint,
      transformer: field.wrappedTransformer != null
          ? (dynamic val) => field.wrappedTransformer!(val)
          : null,
      asyncValidator: field.wrappedAsyncValidator,
      debounceDuration: field.debounceDuration,
      validationMode: field.validationMode,
      crossFieldValidator: field.wrappedCrossFieldValidator,
      dependsOn: field.dependsOn,
      inputFormatters: field.inputFormatters,
      textInputAction: field.textInputAction,
      onSubmitted: field.onSubmitted,
    );

    // Update dependency graph: Add new dependencies
    for (final dep in field.dependsOn) {
      _dependentsMap.putIfAbsent(dep.key, () => []).add(key);
    }

    if (!initialValueMap.containsKey(key)) {
      initialValueMap[key] = field.initialValue;
    }

    void updateState() {
      if (!mounted) return;

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

      if (!currentValidations.containsKey(key)) {
        currentValidations[key] = _performSyncValidation(
          key,
          field.initialValue,
          currentValues,
          currentValidations: currentValidations,
        );
      }

      state = state.copyWith(
        values: currentValues,
        validations: currentValidations,
        dirtyStates: currentDirtyStates,
        touchedStates: currentTouchedStates,
      );
    }

    bool isPersistent = false;
    try {
      final scheduler = WidgetsBinding.instance;
      isPersistent =
          scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks;
    } catch (_) {}

    if (isPersistent) {
      Future.microtask(updateState);
    } else {
      updateState();
    }
  }

  /// Unregister multiple fields at once
  void unregisterFields(
    List<FormixFieldID> fieldIds, {
    bool preserveState = false,
  }) {
    if (fieldIds.isEmpty) return;

    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);

    for (final fieldId in fieldIds) {
      final key = fieldId.key;

      // Update graph
      final oldField = _fieldDefinitions[key];
      if (oldField != null) {
        for (final dep in oldField.dependsOn) {
          _dependentsMap[dep.key]?.remove(key);
        }
      }
      _dependentsMap.remove(key);

      _fieldDefinitions.remove(key);
      newValidations.remove(key);

      if (!preserveState) {
        newValues.remove(key);
        newDirtyStates.remove(key);
        newTouchedStates.remove(key);
      }
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
    );

    if (persistence != null && formId != null) {
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Unregister a field
  void unregisterField<T>(
    FormixFieldID<T> fieldId, {
    bool preserveState = false,
  }) {
    final key = fieldId.key;

    // Update graph
    final oldField = _fieldDefinitions[key];
    if (oldField != null) {
      for (final dep in oldField.dependsOn) {
        _dependentsMap[dep.key]?.remove(key);
      }
    }
    _dependentsMap.remove(key);

    _fieldDefinitions.remove(key);

    final newValues = Map<String, dynamic>.from(state.values);
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final newDirtyStates = Map<String, bool>.from(state.dirtyStates);
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);

    newValidations.remove(key);

    if (!preserveState) {
      newValues.remove(key);
      newDirtyStates.remove(key);
      newTouchedStates.remove(key);
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
    );

    if (persistence != null && formId != null) {
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Reset form to initial state or clear it
  void reset({ResetStrategy strategy = ResetStrategy.initialValues}) {
    final Map<String, dynamic> newValues;
    if (strategy == ResetStrategy.initialValues) {
      newValues = Map<String, dynamic>.from(initialValueMap);
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
      newValidations[key] = _performSyncValidation(
        key,
        newValues[key],
        newValues,
      );
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
      persistence!.saveFormState(formId!, newValues);
    }
  }

  /// Resets the form and sets a new set of initial values.
  /// This clears all dirty and touched states.
  void resetToValues(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      setInitialValueInternal(entry.key, entry.value);
    }
    reset(strategy: ResetStrategy.initialValues);
  }

  /// Reset specific fields
  void resetFields(
    List<FormixFieldID> fieldIds, {
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
        newValue = initialValueMap[key];
      } else {
        newValue = fieldDef.emptyValue ?? _getDefaultEmptyValue(fieldDef);
      }

      newValues[key] = newValue;
      newDirtyStates[key] = false;
      newTouchedStates[key] = false;
      newValidations[key] = _performSyncValidation(key, newValue, newValues);
    }

    state = state.copyWith(
      values: newValues,
      validations: newValidations,
      dirtyStates: newDirtyStates,
      touchedStates: newTouchedStates,
    );
  }

  /// Validate entire form
  /// Validate form (or specific fields)
  bool validate({List<FormixFieldID>? fields}) {
    final newValidations = Map<String, ValidationResult>.from(
      state.validations,
    );
    final values = state.values;
    final keysToValidate = fields?.map((f) => f.key) ?? _fieldDefinitions.keys;

    for (final key in keysToValidate) {
      if (!_fieldDefinitions.containsKey(key)) continue;
      final value = values[key];
      newValidations[key] = _performSyncValidation(key, value, values);
    }

    state = state.copyWith(validations: newValidations);

    // Trigger async validations for valid fields
    for (final key in keysToValidate) {
      if (_fieldDefinitions.containsKey(key) && newValidations[key]!.isValid) {
        _triggerAsyncValidation(key, values[key]);
      }
    }

    if (fields != null) {
      return fields.every((f) => state.validations[f.key]?.isValid ?? true);
    }
    return state.isValid;
  }

  /// Sets a manual error for a specific field.
  ///
  /// This is highly useful for displaying backend validation errors or
  /// specialized business logic errors that cannot be defined in a static validator.
  void setFieldError<T>(FormixFieldID<T> fieldId, String? error) {
    if (!mounted) return;
    final key = fieldId.key;
    final currentValidations = Map<String, ValidationResult>.from(
      state.validations,
    );

    currentValidations[key] = error != null
        ? ValidationResult(isValid: false, errorMessage: error)
        : ValidationResult.valid;

    state = state.copyWith(validations: currentValidations);
  }

  /// Manually set the validating state of a field.
  void setFieldValidating<T>(
    FormixFieldID<T> fieldId, {
    bool isValidating = true,
  }) {
    if (!mounted) return;
    final key = fieldId.key;
    final currentValidations = Map<String, ValidationResult>.from(
      state.validations,
    );

    currentValidations[key] = isValidating
        ? ValidationResult.validating
        : (currentValidations[key]?.isValidating ?? false
              ? ValidationResult.valid
              : currentValidations[key] ?? ValidationResult.valid);

    state = state.copyWith(validations: currentValidations);
  }

  /// Get validation result for field
  ValidationResult getValidation<T>(FormixFieldID<T> fieldId) {
    return state.getValidation(fieldId);
  }

  /// Check if field is dirty
  bool isFieldDirty<T>(FormixFieldID<T> fieldId) {
    return state.isFieldDirty(fieldId);
  }

  /// Check if field is touched
  bool isFieldTouched<T>(FormixFieldID<T> fieldId) {
    return state.isFieldTouched(fieldId);
  }

  /// Mark a field as touched
  void markAsTouched(FormixFieldID<dynamic> fieldId) {
    if (!isFieldRegistered(fieldId)) return;

    analytics?.onFieldTouched(formId, fieldId.key);

    if (state.touchedStates[fieldId.key] == true) return;

    final key = fieldId.key;
    final newTouchedStates = Map<String, bool>.from(state.touchedStates);
    newTouchedStates[key] = true;

    final fieldDef = _fieldDefinitions[key];
    if (fieldDef?.validationMode == FormixAutovalidateMode.onBlur) {
      final newValids = Map<String, ValidationResult>.from(state.validations);
      final value = state.values[key];
      newValids[key] = _performSyncValidation(key, value, state.values);

      state = state.copyWith(
        touchedStates: newTouchedStates,
        validations: newValids,
      );

      if (newValids[key]!.isValid) {
        _triggerAsyncValidation(key, value);
      }
    } else {
      state = state.copyWith(touchedStates: newTouchedStates);
    }
  }

  /// Submits the form with optional throttling and debouncing.
  ///
  /// [onValid] is called if the form is valid.
  /// [onError] is called if the form is invalid.
  /// [debounce] avoids multiple calls within a short time window (last one wins).
  /// [throttle] prevents new calls until the duration has passed (first one wins).
  Future<void> submit({
    required Future<void> Function(Map<String, dynamic> values) onValid,
    void Function(Map<String, ValidationResult> errors)? onError,
    Duration? debounce,
    Duration? throttle,
    bool optimistic = false,
  }) async {
    // 1. Throttling
    if (throttle != null) {
      final now = DateTime.now();
      if (_lastSubmitTime != null &&
          now.difference(_lastSubmitTime!) < throttle) {
        return; // Too soon
      }
      _lastSubmitTime = now;
    }

    // 2. Debouncing
    if (debounce != null) {
      _submitDebounceTimer?.cancel();
      final completer = Completer<void>();

      _submitDebounceTimer = Timer(debounce, () async {
        try {
          await _performSubmit(onValid, onError, optimistic);
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      });

      return completer.future;
    }

    // 3. Immediate execution
    await _performSubmit(onValid, onError, optimistic);
  }

  Future<void> _performSubmit(
    Future<void> Function(Map<String, dynamic> values) onValid,
    void Function(Map<String, ValidationResult> errors)? onError,
    bool optimistic,
  ) async {
    analytics?.onSubmitAttempt(formId, state.values);

    if (validate()) {
      setSubmitting(true);

      // Wait for any pending async validations
      while (state.validations.values.any((v) => v.isValidating)) {
        await stream.first;
        // Yield to prevent "Controller already firing" error if stream is sync
        await Future<void>.delayed(Duration.zero);
      }

      // Re-validate after async completions
      if (!state.isValid) {
        setSubmitting(false);
        if (onError != null) {
          onError(state.validations);
        }
        analytics?.onSubmitFailure(formId, state.validations);
        return;
      }

      Map<String, dynamic>? previousInitialValues;
      FormixData? previousState;

      if (optimistic) {
        previousInitialValues = Map.from(initialValueMap);
        previousState = state;
        // Optimistically set the form to "pristine" by syncing initial values
        resetToValues(state.values);
        // resetToValues resets isSubmitting to false, so we enable it again
        setSubmitting(true);
      }

      try {
        await onValid(state.values);
        _hasSubmittedSuccessfully = true;
        analytics?.onSubmitSuccess(formId);
      } catch (e) {
        if (optimistic &&
            previousInitialValues != null &&
            previousState != null) {
          // Revert optimistic changes
          initialValueMap.clear();
          initialValueMap.addAll(previousInitialValues);
          state = previousState.copyWith(isSubmitting: false);
        }
        rethrow;
      } finally {
        setSubmitting(false);
      }
    } else {
      if (onError != null) {
        onError(state.validations);
      }
      analytics?.onSubmitFailure(formId, state.validations);
    }
  }

  /// Set submitting state
  void setSubmitting(bool submitting) {
    state = state.copyWith(isSubmitting: submitting);
  }

  dynamic _getDefaultEmptyValue(FormixField<dynamic> field) {
    final initialValue = field.initialValue;
    if (initialValue is String) return '';
    if (initialValue is num) return 0;
    if (initialValue is bool) return false;
    if (initialValue is List) return [];
    if (initialValue is Map) return {};
    return null;
  }

  // --- Undo / Redo ---

  /// Whether undo is currently possible
  bool get canUndo => _historyIndex > 0;

  /// Whether redo is currently possible
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Undo the last change
  void undo() {
    if (!canUndo) return;

    _isRestoringHistory = true;
    try {
      _historyIndex--;
      state = _history[_historyIndex];
    } finally {
      _isRestoringHistory = false;
    }
  }

  /// Redo the previously undone change
  void redo() {
    if (!canRedo) return;

    _isRestoringHistory = true;
    try {
      _historyIndex++;
      state = _history[_historyIndex];
    } finally {
      _isRestoringHistory = false;
    }
  }

  // --- Optimistic Updates ---

  /// Manually set the pending state of a field
  void setPending<T>(FormixFieldID<T> fieldId, bool isPending) {
    if (!mounted) return;

    final newPendingStates = Map<String, bool>.from(state.pendingStates);
    newPendingStates[fieldId.key] = isPending;

    state = state.copyWith(pendingStates: newPendingStates);
  }

  /// Perform an optimistic update.
  ///
  /// 1. Updates the field value immediately.
  /// 2. Sets field to pending.
  /// 3. Executes [action].
  /// 4. If [action] fails, reverts the value (optional).
  Future<void> optimisticUpdate<T>({
    required FormixFieldID<T> fieldId,
    required T value,
    required Future<void> Function() action,
    bool revertOnError = true,
  }) async {
    final previousValue = getValue(fieldId);

    // 1. Update immediately
    setValue(fieldId, value);

    // 2. Set pending
    setPending(fieldId, true);

    try {
      // 3. Execute action
      await action();
    } catch (e) {
      // 4. Revert if needed
      if (revertOnError && previousValue != null) {
        setValue(fieldId, previousValue);
      }
      rethrow;
    } finally {
      if (mounted) {
        setPending(fieldId, false);
      }
    }
  }

  // --- Multi-Form Synchronization ---

  /// Binds a field in this form to a field in another form controller.
  ///
  /// Changes in [sourceController]'s [sourceField] will automatically update
  /// [targetField] in this form.
  ///
  /// Returns a function to unbind.
  VoidCallback bindField<T>(
    FormixFieldID<T> targetField, {
    required RiverpodFormController sourceController,
    required FormixFieldID<T> sourceField,
    bool twoWay = false,
  }) {
    final subKey = '${targetField.key}_bound_to_${sourceField.key}';

    // Unbind existing if any
    _bindings[subKey]?.cancel();

    // Subscribe to source
    final subscription = sourceController.stream.listen((sourceState) {
      final sourceValue = sourceState.getValue(sourceField);
      final currentTargetValue = getValue(targetField);

      if (sourceValue != currentTargetValue) {
        setValue(targetField, sourceValue as T);
      }
    });

    _bindings[subKey] = subscription;

    // Add two-way binding if requested (be careful of infinite loops!)
    // We avoid loops by checking value equality before setting.
    if (twoWay) {
      final reverseSubKey = '${subKey}_reverse';
      final reverseSub = stream.listen((targetState) {
        final targetValue = targetState.getValue(targetField);
        final currentSourceValue = sourceController.getValue(sourceField);

        if (targetValue != currentSourceValue) {
          sourceController.setValue(sourceField, targetValue as T);
        }
      });
      _bindings[reverseSubKey] = reverseSub;
    }

    return () {
      _bindings[subKey]?.cancel();
      _bindings.remove(subKey);
      if (twoWay) {
        _bindings['${subKey}_reverse']?.cancel();
        _bindings.remove('${subKey}_reverse');
      }
    };
  }
}

/// Provider for formix messages
final formixMessagesProvider = Provider.autoDispose<FormixMessages>((ref) {
  return const DefaultFormixMessages();
}, name: 'formixMessagesProvider');

/// Parameter for form controller provider family
@immutable
class FormixParameter {
  const FormixParameter({
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
    this.analytics,
  });

  final Map<String, dynamic> initialValue;
  final List<FormixFieldConfig> fields;
  final FormixPersistence? persistence;
  final String? formId;
  final FormixAnalytics? analytics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormixParameter &&
          const MapEquality().equals(initialValue, other.initialValue) &&
          const ListEquality().equals(fields, other.fields) &&
          persistence == other.persistence &&
          formId == other.formId &&
          analytics == other.analytics;

  @override
  int get hashCode =>
      const MapEquality().hash(initialValue) ^
      const ListEquality().hash(fields) ^
      persistence.hashCode ^
      formId.hashCode ^
      analytics.hashCode;
}

/// Provider for form controller with auto-disposal
final formControllerProvider = StateNotifierProvider.autoDispose
    .family<FormixController, FormixData, FormixParameter>((ref, param) {
      final messages = ref.watch(formixMessagesProvider);
      return FormixController(
        initialValue: param.initialValue,
        fields: param.fields.map((f) => f.toField()).toList(),
        messages: messages,
        persistence: param.persistence,
        formId: param.formId,
        analytics: param.analytics,
      );
    }, name: 'formControllerProvider');

/// Provider for the current controller provider (can be overridden)
final currentControllerProvider =
    Provider.autoDispose<
      AutoDisposeStateNotifierProvider<FormixController, FormixData>
    >((ref) {
      return formControllerProvider(const FormixParameter(initialValue: {}));
    }, name: 'currentControllerProvider');

/// Provider for field value with selector for performance
final fieldValueProvider = Provider.autoDispose
    .family<dynamic, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select((formState) => formState.getValue(fieldId)),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldValueProvider',
    );

/// Provider for field validation with selector for performance
final fieldValidationProvider = Provider.autoDispose
    .family<ValidationResult, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.getValidation(fieldId),
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldValidationProvider',
    );

/// Provider for field error message with selector for performance
final fieldErrorProvider = Provider.autoDispose
    .family<String?, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.getValidation(fieldId).errorMessage,
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldErrorProvider',
    );

final groupValidProvider = Provider.autoDispose.family<bool, String>(
  (ref, prefix) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(controllerProvider.select((s) => s.isGroupValid(prefix)));
  },
  dependencies: [currentControllerProvider],
  name: 'groupValidProvider',
);

/// Provider for watching if a field name group contains any modifications.
final groupDirtyProvider = Provider.autoDispose.family<bool, String>(
  (ref, prefix) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(controllerProvider.select((s) => s.isGroupDirty(prefix)));
  },
  dependencies: [currentControllerProvider],
  name: 'groupDirtyProvider',
);

/// Provider for field 'isValidating' state with selector for performance
final fieldValidatingProvider = Provider.autoDispose
    .family<bool, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.getValidation(fieldId).isValidating,
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldValidatingProvider',
    );

/// Provider for field 'isValid' state with selector for performance
final fieldIsValidProvider = Provider.autoDispose
    .family<bool, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.getValidation(fieldId).isValid,
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldIsValidProvider',
    );

/// Provider for field dirty state with selector for performance
final fieldDirtyProvider = Provider.autoDispose
    .family<bool, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.isFieldDirty(fieldId),
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldDirtyProvider',
    );

/// Provider for field touched state with selector for performance
final fieldTouchedProvider = Provider.autoDispose
    .family<bool, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.isFieldTouched(fieldId),
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldTouchedProvider',
    );

/// Provider for form validity with selector for performance
final formValidProvider = Provider.autoDispose<bool>(
  (ref) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(
      controllerProvider.select((formState) => formState.isValid),
    );
  },
  dependencies: [currentControllerProvider],
  name: 'formValidProvider',
);

/// Provider for form dirty state with selector for performance
final formDirtyProvider = Provider.autoDispose<bool>(
  (ref) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(
      controllerProvider.select((formState) => formState.isDirty),
    );
  },
  dependencies: [currentControllerProvider],
  name: 'formDirtyProvider',
);

/// Provider for form submitting state with selector for performance
final formSubmittingProvider = Provider.autoDispose<bool>(
  (ref) {
    final controllerProvider = ref.watch(currentControllerProvider);
    return ref.watch(
      controllerProvider.select((formState) => formState.isSubmitting),
    );
  },
  dependencies: [currentControllerProvider],
  name: 'formSubmittingProvider',
);

/// Provider for field pending state with selector for performance
final fieldPendingProvider = Provider.autoDispose
    .family<bool, FormixFieldID<dynamic>>(
      (ref, fieldId) {
        final controllerProvider = ref.watch(currentControllerProvider);
        return ref.watch(
          controllerProvider.select(
            (formState) => formState.isFieldPending(fieldId),
          ),
        );
      },
      dependencies: [currentControllerProvider],
      name: 'fieldPendingProvider',
    );
