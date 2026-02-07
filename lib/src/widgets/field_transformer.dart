import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../formix.dart';

/// A widget that transforms the value of one field to another in a type-safe way.
///
/// Use this when you have a direct 1-to-1 relationship between fields where
/// one field's value is derived strictly from another.
///
/// Example:
/// ```dart
/// FormixFieldTransformer<String, int>(
///   sourceField: textField,
///   targetField: lengthField,
///   transform: (text) => text?.length ?? 0,
/// )
/// ```
class FormixFieldTransformer<T, S> extends ConsumerStatefulWidget {
  /// Creates a [FormixFieldTransformer].
  const FormixFieldTransformer({
    super.key,
    required this.sourceField,
    required this.targetField,
    required this.transform,
  });

  /// The field to listen to.
  final FormixFieldID<T> sourceField;

  /// The field to update.
  final FormixFieldID<S> targetField;

  /// The transformation function.
  final S Function(T? value) transform;

  @override
  ConsumerState<FormixFieldTransformer<T, S>> createState() => _FormixFieldTransformerState<T, S>();
}

class _FormixFieldTransformerState<T, S> extends ConsumerState<FormixFieldTransformer<T, S>> {
  FormixController? _controller;
  Object? _initializationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var provider = Formix.of(context);
    if (provider == null) {
      try {
        provider = ref.watch(currentControllerProvider);
      } catch (_) {
        // ProviderScope missing
      }
    }

    if (provider == null) {
      if (mounted) {
        setState(() {
          _initializationError = 'FormixFieldTransformer used outside of Formix';
        });
      }
      return;
    }

    // Keep provider alive
    ref.watch(provider);
    try {
      final newController = ref.read(provider.notifier);
      if (newController != _controller) {
        _controller = newController;
        // Initial transform
        scheduleMicrotask(_transformValue);
      }
      _initializationError = null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializationError = e;
        });
      }
    }
  }

  void _transformValue() {
    if (!mounted || _controller == null) return;

    try {
      // Get source value
      final dynamic rawValue = _controller!.getValue(widget.sourceField);
      final T? sourceValue = rawValue as T?;

      // Transform
      final S newValue = widget.transform(sourceValue);

      // Get current target value to avoid infinite loops
      final dynamic rawTarget = _controller!.getValue(widget.targetField);
      final S? currentTarget = rawTarget as S?;

      if (currentTarget != newValue) {
        scheduleMicrotask(() {
          if (mounted && _controller != null) {
            _controller!.setValue(widget.targetField, newValue);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Error in FormixFieldTransformer for ${widget.targetField}: $e',
        );
      }
    }
  }

  @override
  void didUpdateWidget(FormixFieldTransformer<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if source or target field changed
    if (oldWidget.sourceField != widget.sourceField || oldWidget.targetField != widget.targetField) {
      // Re-transform with new fields
      scheduleMicrotask(_transformValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return FormixConfigurationErrorWidget(
        message: _initializationError is String ? _initializationError as String : 'Failed to initialize FormixFieldTransformer',
        details: _initializationError.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.'
            : 'Error: $_initializationError',
      );
    }

    // Listen to source field reactively using granular selector
    ref.listen(fieldValueProvider(widget.sourceField), (_, __) => _transformValue());

    return const SizedBox.shrink();
  }
}
