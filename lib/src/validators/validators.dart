import 'dart:async';
import 'package:meta/meta.dart';
import 'validation_keys.dart';

/// A fluent API for creating field validators.
/// Inspired by Zod and other schema validation libraries.
class FormixValidators {
  /// Start a validator chain for a String field.
  static StringValidator string() => StringValidator([]);

  /// Start a validator chain for a Numeric field.
  static NumberValidator<T> number<T extends num>() => NumberValidator<T>([]);

  /// Start a validator chain for any type.
  static GenericValidator<T> any<T>() => GenericValidator<T>([]);
}

/// Base class for validator chains including async support.
abstract class ValidatorChain<T, Self extends ValidatorChain<T, Self>> {
  @protected
  final List<String? Function(T?)> syncValidators;

  @protected
  final List<Future<String?> Function(T?)> asyncValidators = [];

  ValidatorChain(this.syncValidators);

  Self _add(String? Function(T?) validator) {
    syncValidators.add(validator);
    return this as Self;
  }

  /// Mark the field as required.
  Self required([String? message]) {
    return _add((val) {
      if (val == null) return message ?? FormixValidationKeys.required;
      if (val is String && val.trim().isEmpty) {
        return message ?? FormixValidationKeys.required;
      }
      return null;
    });
  }

  /// Add a custom validation rule.
  Self custom(String? Function(T?) validator) => _add(validator);

  /// Add an asynchronous validation rule.
  Self async(Future<String?> Function(T?) validator) {
    asyncValidators.add(validator);
    return this as Self;
  }

  /// Builds the combined synchronous validator.
  String? Function(T?) build() {
    return (T? value) {
      for (final validator in syncValidators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Builds the combined asynchronous validator.
  Future<String?> Function(T?) buildAsync() {
    return (T? value) async {
      // Async validators only run if sync validators pass
      final syncError = build()(value);
      if (syncError != null) return null;

      for (final validator in asyncValidators) {
        final error = await validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

class StringValidator extends ValidatorChain<String, StringValidator> {
  StringValidator(super.syncValidators);

  StringValidator email([String? message]) {
    return _add((val) {
      if (val == null || val.isEmpty) return null;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(val)) {
        return message ?? FormixValidationKeys.invalidEmail;
      }
      return null;
    });
  }

  StringValidator minLength(int length, [String? message]) {
    return _add((val) {
      if (val == null || val.isEmpty) return null;
      if (val.length < length) {
        return message ??
            FormixValidationKeys.withParam(
              FormixValidationKeys.minLength,
              length,
            );
      }
      return null;
    });
  }

  StringValidator maxLength(int length, [String? message]) {
    return _add((val) {
      if (val == null || val.isEmpty) return null;
      if (val.length > length) {
        return message ??
            FormixValidationKeys.withParam(
              FormixValidationKeys.maxLength,
              length,
            );
      }
      return null;
    });
  }

  StringValidator pattern(RegExp regex, [String? message]) {
    return _add((val) {
      if (val == null || val.isEmpty) return null;
      if (!regex.hasMatch(val)) {
        return message ?? FormixValidationKeys.invalidFormat;
      }
      return null;
    });
  }
}

class NumberValidator<T extends num>
    extends ValidatorChain<T, NumberValidator<T>> {
  NumberValidator(super.syncValidators);

  NumberValidator<T> min(T min, [String? message]) {
    return _add((val) {
      if (val == null) return null;
      if (val < min) {
        return message ??
            FormixValidationKeys.withParam(FormixValidationKeys.min, min);
      }
      return null;
    });
  }

  NumberValidator<T> max(T max, [String? message]) {
    return _add((val) {
      if (val == null) return null;
      if (val > max) {
        return message ??
            FormixValidationKeys.withParam(FormixValidationKeys.max, max);
      }
      return null;
    });
  }

  NumberValidator<T> positive([String? message]) => min(
    0 as T,
    message ?? FormixValidationKeys.withParam(FormixValidationKeys.min, 0),
  );
}

class GenericValidator<T> extends ValidatorChain<T, GenericValidator<T>> {
  GenericValidator(super.syncValidators);
}
