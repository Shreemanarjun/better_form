import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_transform/stream_transform.dart';

import '../controllers/field_id.dart';
import '../controllers/riverpod_controller.dart';
import 'formix.dart';

/// A widget that asynchronously transforms the value of one field to another in a type-safe way.
///
/// Use this when you have a direct 1-to-1 relationship between fields where
/// one field's value is derived asynchronously from another (e.g., fetching data based on input).
///
/// Supports debouncing to prevent excessive calls during rapid input.
///
/// Example:
/// ```dart
/// FormixFieldAsyncTransformer<String, String>(
///   sourceField: userIdField,
///   targetField: userNameField,
///   debounce: const Duration(milliseconds: 500),
///   transform: (userId) async {
///     if (userId == null) return null;
///     return await fetchUserName(userId);
///   },
/// )
/// ```
class FormixFieldAsyncTransformer<T, S> extends ConsumerStatefulWidget {
  /// Creates a [FormixFieldAsyncTransformer].
  const FormixFieldAsyncTransformer({
    super.key,
    required this.sourceField,
    required this.targetField,
    required this.transform,
    this.debounce,
    this.retransformOnSubmit = false,
  });

  /// The field to listen to.
  final FormixFieldID<T> sourceField;

  /// The field to update.
  final FormixFieldID<S> targetField;

  /// The asynchronous transformation function.
  final Future<S> Function(T? value) transform;

  /// Optional debounce duration.
  final Duration? debounce;

  /// Whether to re-run the transformation when the form is submitted.
  final bool retransformOnSubmit;

  @override
  ConsumerState<FormixFieldAsyncTransformer<T, S>> createState() => _FormixFieldAsyncTransformerState<T, S>();
}

class _FormixFieldAsyncTransformerState<T, S> extends ConsumerState<FormixFieldAsyncTransformer<T, S>> {
  FormixController? _controller;
  late VoidCallback _listener;
  final _inputController = StreamController<T?>.broadcast(sync: true);
  StreamSubscription<T?>? _subscription;
  VoidCallback? _formListenerRemover;
  bool _wasSubmitting = false;

  @override
  void initState() {
    super.initState();
    _listener = _onSourceChanged;
    _setupStream();
  }

  void _setupStream() {
    Stream<T?> stream = _inputController.stream;

    if (widget.debounce != null) {
      stream = stream.debounce(widget.debounce!);
    }

    _subscription = stream.listen(_performAsyncTransform);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = Formix.controllerOf(context);
    if (newController != _controller) {
      if (_controller != null) {
        _controller!.removeFieldListener(widget.sourceField, _listener);
        _formListenerRemover?.call();
        _formListenerRemover = null;
      }

      _controller = newController;
      if (_controller != null) {
        _controller!.addFieldListener(widget.sourceField, _listener);
        if (widget.retransformOnSubmit) {
          _formListenerRemover = _controller!.addFormListener(_onSubmitChanged);
        }
        // Initial transform
        if (mounted) {
          _onSourceChanged();
        }
      }
    }
  }

  @override
  void didUpdateWidget(FormixFieldAsyncTransformer<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.debounce != widget.debounce) {
      _subscription?.cancel();
      _setupStream();
    }

    if (oldWidget.retransformOnSubmit != widget.retransformOnSubmit) {
      if (widget.retransformOnSubmit) {
        _formListenerRemover = _controller?.addFormListener(_onSubmitChanged);
      } else {
        _formListenerRemover?.call();
        _formListenerRemover = null;
      }
    }

    if (oldWidget.sourceField != widget.sourceField) {
      if (_controller != null) {
        _controller!.removeFieldListener(oldWidget.sourceField, _listener);
        _controller!.addFieldListener(widget.sourceField, _listener);
      }
      _onSourceChanged();
    } else if (oldWidget.targetField != widget.targetField) {
      _onSourceChanged();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _inputController.close();
    _formListenerRemover?.call();
    if (_controller != null) {
      _controller!.removeFieldListener(widget.sourceField, _listener);
      // Ensure pending state is cleared when widget is disposed
      // Use microtask to avoid triggering rebuilds during parent disposal
      final controller = _controller!;
      Future.microtask(() {
        if (controller.mounted) {
          controller.setPending(widget.targetField, false);
        }
      });
      _controller = null;
    }
    super.dispose();
  }

  void _onSourceChanged() {
    if (!mounted || _controller == null) return;

    // Mark as pending. Use microtask since this might be called during build
    // (e.g. didChangeDependencies)
    Future.microtask(() {
      if (mounted && _controller != null) {
        _controller!.setPending(widget.targetField, true);
      }
    });

    // Get source value
    final dynamic rawValue = _controller!.getValue(widget.sourceField);
    final T? sourceValue = rawValue as T?;

    // Emit to stream for debouncing and processing
    _inputController.add(sourceValue);
  }

  void _onSubmitChanged(FormixData state) {
    if (!widget.retransformOnSubmit) return;

    final isSubmitting = state.isSubmitting;
    if (isSubmitting && !_wasSubmitting) {
      // Started submitting, re-trigger transform
      _onSourceChanged();
    }
    _wasSubmitting = isSubmitting;
  }

  Future<void> _performAsyncTransform(T? sourceValue) async {
    if (!mounted || _controller == null) return;

    try {
      // Transform
      final S newValue = await widget.transform(sourceValue);

      if (!mounted || _controller == null) return;

      // Get current target value to avoid infinite loops and unnecessary updates
      final dynamic rawTarget = _controller!.getValue(widget.targetField);
      final S? currentTarget = rawTarget as S?;

      if (currentTarget != newValue) {
        // Since we are in an async callback, we might not be in a build phase,
        // but setValue might trigger notifications. Riverpod handles this, but
        // it's good practice to be mindful.
        _controller!.setValue(widget.targetField, newValue);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Error in FormixFieldAsyncTransformer for ${widget.targetField}: $e',
        );
      }
    } finally {
      if (mounted && _controller != null) {
        _controller!.setPending(widget.targetField, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
