import 'dart:async';

/// Abstract class for persisting form state
abstract class BetterFormPersistence {
  /// Save form state
  Future<void> saveFormState(String formId, Map<String, dynamic> values);

  /// Get saved form state
  Future<Map<String, dynamic>?> getSavedState(String formId);

  /// Clear saved state
  Future<void> clearSavedState(String formId);
}

/// InMemory persistence for testing or temporary sessions
class InMemoryFormPersistence implements BetterFormPersistence {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> values) async {
    _storage[formId] = Map.from(values);
  }

  @override
  Future<Map<String, dynamic>?> getSavedState(String formId) async {
    return _storage[formId];
  }

  @override
  Future<void> clearSavedState(String formId) async {
    _storage.remove(formId);
  }
}
