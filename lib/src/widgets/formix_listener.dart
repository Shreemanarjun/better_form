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
    // Determine controller availability efficiently
    // We use addPostFrameCallback because the Formix widget might be built
    // in the same frame or slightly later if it's down the tree.
    // Actually, usually FormixListener is outside/above or sibling.

    // If Formix is already built:
    final controller = widget.formKey.currentState?.controller;

    if (controller != null) {
      _removeListener = controller.addFormListener(_handleStateChange);
    } else {
      // Retry in next frame if not ready yet
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctrl = widget.formKey.currentState?.controller;
        if (ctrl != null) {
          _removeListener = ctrl.addFormListener(_handleStateChange);
        }
      });
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
    return widget.child;
  }
}
