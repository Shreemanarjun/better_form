import 'package:flutter/material.dart';
import '../../formix.dart';

/// A widget that listens to form state changes externally via [GlobalKey].
///
/// This is the easiest way to listen to form changes outside the form widget tree
/// while ensuring proper cleanup (auto-disposal) of listeners.
///
/// Example:
/// ```dart
/// FormixListener(
///   formKey: myFormKey,
///   listener: (context, state) {
///     if (state.isValid) {
///       print('Form is valid!');
///     }
///   },
///   child: Container(),
/// )
/// ```
class FormixListener extends ConsumerStatefulWidget {
  /// Creates a [FormixListener].
  const FormixListener({
    super.key,
    required this.formKey,
    required this.listener,
    required this.child,
  });

  /// The GlobalKey of the [Formix] widget to listen to.
  final GlobalKey<FormixState> formKey;

  /// Callback called whenever the form state changes.
  final void Function(BuildContext context, FormixData state) listener;

  /// The child widget.
  final Widget child;

  @override
  ConsumerState<FormixListener> createState() => _FormixListenerState();
}

class _FormixListenerState extends ConsumerState<FormixListener> {
  VoidCallback? _removeListener;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(FormixListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formKey != oldWidget.formKey) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    try {
      // Determine controller availability efficiently
      final FormixState? formState = widget.formKey.currentState;
      final controller = formState?.controller;

      if (controller != null) {
        _removeListener = controller.addFormListener(_handleStateChange);
        _initializationError = null;
      } else {
        // Retry in next frame if not ready yet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          try {
            final ctrl = widget.formKey.currentState?.controller;
            if (ctrl != null) {
              _removeListener = ctrl.addFormListener(_handleStateChange);
              setState(() {
                _initializationError = null;
              });
            } else {
              setState(() {
                _initializationError = 'Formix not found at provided GlobalKey';
              });
            }
          } catch (e) {
            setState(() {
              _initializationError = e;
            });
          }
        });
      }
    } catch (e) {
      _initializationError = e;
    }
  }

  void _handleStateChange(FormixData state) {
    if (!mounted) return;
    widget.listener(context, state);
  }

  void _unsubscribe() {
    _removeListener?.call();
    _removeListener = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return FormixConfigurationErrorWidget(
        message: _initializationError is String ? _initializationError as String : 'Failed to initialize FormixListener',
        details: _initializationError.toString().contains('No ProviderScope found')
            ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.'
            : 'Error: $_initializationError',
      );
    }
    return widget.child;
  }
}
