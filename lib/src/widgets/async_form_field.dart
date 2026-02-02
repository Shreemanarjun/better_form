import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../formix.dart';

/// A widget that handles asynchronous values for a form field.
///
/// It waits for either an [asyncValue] (from Riverpod) or a [future] to resolve,
/// then populates the form field value and handles validation.
///
/// This is particularly useful for:
/// *   Loading data from an API to populate a field.
/// *   Dependent dropdowns where the second dropdown depends on an async result from the first.
/// *   Initial form data that is fetched asynchronously.
///
/// It also integrates perfectly with standard and asynchronous validators. When the
/// data resolves, the validation cycle is automatically triggered.
///
/// Example:
/// ```dart
/// FormixAsyncField<List<String>>(
///   fieldId: modelField,
///   future: api.fetchModels(selectedMake),
///   builder: (context, state) {
///     return FormixDropdownFormField<String>(
///       fieldId: modelField,
///       items: state.value?.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList() ?? [],
///     );
///   },
///   loadingBuilder: (context) => Text('Loading...'),
/// )
/// ```
class FormixAsyncField<T> extends FormixFieldWidget<T> {
  const FormixAsyncField({
    super.key,
    required super.fieldId,
    required this.builder,
    this.asyncValue,
    this.future,
    this.loadingBuilder,
    this.errorBuilder,
    this.keepPreviousData = false,
    this.debounce,
    this.manual = false,
    this.onRetry,
    this.dependencies,
    super.validator,
    super.asyncValidator,
    super.initialValue,
    super.controller,
  }) : assert(
         asyncValue != null || future != null || manual,
         'Must provide asyncValue, future, or be in manual mode',
       );

  /// Whether to keep and display the previous successful data while loading new data.
  /// Useful for preventing UI "flicker" during dependency changes.
  final bool keepPreviousData;

  /// Optional debounce duration before executing the [future].
  final Duration? debounce;

  /// Optional list of objects that trigger a refetch when changed.
  /// If not provided, [FormixAsyncField] will refetch whenever the [future] instance changes.
  final List<Object?>? dependencies;

  /// If true, the [future] will not be executed automatically.
  /// You must call `state.refresh()` to trigger the loading.
  final bool manual;

  /// An [AsyncValue] providing the data. Usually from `ref.watch(provider)`.
  final AsyncValue<T>? asyncValue;

  /// A [Future] that resolves to the data. Use this if not using Riverpod providers directly.
  final Future<T>? future;

  /// Optional callback to generate a new future when `refresh()` is called.
  /// If provided, this will be used to retry a failed operation.
  final Future<T> Function()? onRetry;

  /// Builder function that is called when data is available.
  final Widget Function(BuildContext context, FormixAsyncFieldState<T> state)
  builder;

  /// Optional builder shown while the data is loading.
  /// Defaults to a [CircularProgressIndicator].
  final WidgetBuilder? loadingBuilder;

  /// Optional builder shown if an error occurs during data loading.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  @override
  FormixAsyncFieldState<T> createState() => FormixAsyncFieldState<T>();
}

class FormixAsyncFieldState<T> extends FormixFieldWidgetState<T> {
  AsyncValue<T> _asyncState = const AsyncValue.loading();

  AsyncValue<T> get asyncState => _asyncState;

  int _activeFutureVersion = 0;
  Timer? _debounceTimer;
  Future<T>? _currentFuture;

  /// Force a re-execution (if using [future]) or refresh (if using [asyncValue]).
  Future<void> refresh() async {
    final widget = this.widget as FormixAsyncField<T>;
    if (widget.onRetry != null) {
      _currentFuture = widget.onRetry!();
    }
    _initAsyncState(force: true);
  }

  @override
  void initState() {
    super.initState();
    final widget = this.widget as FormixAsyncField<T>;
    _currentFuture = widget.future;

    // Ensure initial state is correctly set if asyncValue is provided
    if (widget.asyncValue != null) {
      _asyncState = widget.asyncValue!;
    }

    if (!widget.manual) {
      _initAsyncState();
    }
  }

  void _initAsyncState({bool force = false}) {
    final widget = this.widget as FormixAsyncField<T>;

    if (widget.asyncValue != null) {
      _asyncState = widget.asyncValue!;
      _syncValue();
      return;
    }

    if (_currentFuture != null) {
      if (widget.debounce != null && !force) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(widget.debounce!, () => _executeFuture());
      } else {
        _executeFuture();
      }
    } else {
      // If there's no future, ensure we're not stuck in pending
      _updatePendingState(false);
    }
  }

  void _executeFuture() {
    final widget =
        this.widget as FormixAsyncField<T>; // Still needed for keepPreviousData
    if (_currentFuture == null) return;

    final version = ++_activeFutureVersion;

    if (!widget.keepPreviousData || !_asyncState.hasValue) {
      setState(() {
        _asyncState = const AsyncValue.loading();
      });
      _updatePendingState(true);
    }

    _currentFuture!
        .then((data) {
          if (mounted && version == _activeFutureVersion) {
            setState(() {
              _asyncState = AsyncValue.data(data);
            });
            _updatePendingState(false);
            _syncValue();
          }
        })
        .catchError((e, st) {
          if (mounted && version == _activeFutureVersion) {
            setState(() {
              _asyncState = AsyncValue.error(e, st);
            });
            _updatePendingState(false);
          }
        });
  }

  void _updatePendingState(bool isPending) {
    if (hasController) {
      // Use microtask to avoid "Tried to modify a provider while the widget tree was building"
      // during initState/didUpdateWidget.
      Future.microtask(() {
        if (mounted && hasController) {
          controller.setPending(widget.fieldId, isPending);
        }
      });
    }
  }

  @override
  void didUpdateWidget(FormixAsyncField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final widget = this.widget as FormixAsyncField<T>;
    if (widget.asyncValue != oldWidget.asyncValue) {
      if (!widget.manual) {
        _initAsyncState();
      }
    } else if (widget.future != oldWidget.future) {
      final changed =
          widget.dependencies == null ||
          !const ListEquality().equals(
            widget.dependencies,
            oldWidget.dependencies,
          );

      if (changed) {
        // Update current future if the widget's future changed
        _currentFuture = widget.future;

        if (!widget.manual) {
          _initAsyncState();
        }
      }
    }
  }

  @override
  void onReset() {
    final widget = this.widget as FormixAsyncField<T>;
    if (!widget.manual) {
      refresh();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncValue() {
    if (_asyncState.hasValue &&
        !_asyncState.isLoading &&
        !_asyncState.hasError) {
      final val = _asyncState.value as T;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (!const DeepCollectionEquality().equals(value, val)) {
            didChange(val);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget as FormixAsyncField<T>;

    return _asyncState.when(
      data: (_) => widget.builder(context, this),
      error: (e, _) =>
          widget.errorBuilder?.call(context, e) ?? Text('Error: $e'),
      loading: () =>
          widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator()),
    );
  }
}
