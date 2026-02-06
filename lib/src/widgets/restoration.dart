import 'package:flutter/widgets.dart';
import '../controllers/form_state.dart';

/// A [RestorableValue] that stores a [FormixData].
///
/// This allows you to integrate Formix with Flutter's [RestorationMixin].
class RestorableFormixData extends RestorableValue<FormixData> {
  /// Creates a [RestorableFormixData] with an optional [initialValue].
  RestorableFormixData([FormixData initialValue = const FormixData()]) : _initialValue = initialValue;

  final FormixData _initialValue;

  @override
  FormixData createDefaultValue() => _initialValue;

  @override
  void didUpdateValue(FormixData? oldValue) {
    if (value != oldValue) {
      notifyListeners();
    }
  }

  @override
  FormixData fromPrimitives(Object? data) {
    if (data == null) return const FormixData();
    return FormixData.fromMap(Map<String, dynamic>.from(data as Map));
  }

  @override
  Object? toPrimitives() {
    return value.toMap();
  }
}
