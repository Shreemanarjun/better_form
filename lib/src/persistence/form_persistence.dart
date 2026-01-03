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
    _storage[formId] = _deepCopy(values);
  }

  /// Creates a deep copy of the map for data isolation
  Map<String, dynamic> _deepCopy(Map<String, dynamic> original) {
    final copy = <String, dynamic>{};

    for (final entry in original.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        copy[entry.key] = _deepCopy(value);
      } else if (value is List) {
        copy[entry.key] = List.from(value);
      } else {
        copy[entry.key] = value;
      }
    }

    return copy;
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
