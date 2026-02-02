import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/riverpod_controller.dart';
import 'formix.dart'; // For Formix.of

/// A widget that registers a specific set of fields with the parent [Formix].
///
/// This is useful for:
/// 1. Organizing large forms into logical sections
/// 2. Lazy loading/registering fields (only when this section is built)
/// 3. Modularizing form definitions
///
/// Example:
/// ```dart
/// Formix(
///   child: ListView(
///     children: [
///       FormixSection(
///         fields: [ConfigA, ConfigB],
///         child: SectionA(),
///       ),
///       // SectionB fields are not registered until scrolled into view
///       FormixSection(
///         fields: [ConfigC, ConfigD],
///         child: SectionB(),
///       ),
///     ],
///   ),
/// )
/// ```
class FormixSection extends ConsumerStatefulWidget {
  const FormixSection({
    super.key,
    required this.fields,
    required this.child,
    this.keepAlive = true,
  });

  /// The fields to register when this section is built
  final List<FormixFieldConfig<dynamic>> fields;

  /// The child widget containing the form fields
  final Widget child;

  /// Whether to keep the field values/state when this section is disposed.
  /// Defaults to true (standard form behavior).
  /// If set to false, fields will be unregistered (and data potentially lost)
  /// when this widget is removed from the tree.
  final bool keepAlive;

  @override
  ConsumerState<FormixSection> createState() => _FormixSectionState();
}

class _FormixSectionState extends ConsumerState<FormixSection> {
  FormixController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initController();
    _registerFields();
  }

  void _initController() {
    final provider = Formix.of(context);
    if (provider == null) {
      throw FlutterError('FormixSection must be placed inside a Formix widget');
    }
    _controller = ref.read(provider.notifier);
  }

  void _registerFields() {
    if (_controller == null) return;
    final controller = _controller!;

    final fieldsToRegister = widget.fields
        .where((f) => !controller.isFieldRegistered(f.id))
        .map((f) => f.toField())
        .toList();

    if (fieldsToRegister.isNotEmpty) {
      controller.registerFields(fieldsToRegister);
    }
  }

  @override
  void didUpdateWidget(FormixSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fields != oldWidget.fields) {
      _registerFields();
    }
  }

  @override
  void dispose() {
    if (!widget.keepAlive && _controller != null) {
      final ids = widget.fields.map((f) => f.id).toList();
      final controller = _controller!;

      // Use batch unregistration
      Future.microtask(() {
        // Check if controller is still valid/mounted?
        // Actually FormixController might be disposed if Formix is disposed.
        // But if FormixSection is removed from tree while Formix stays, we unregister.
        // We use try-catch or checks?
        // FormixController doesn't have a 'mounted' property but RiverpodController does.
        if (controller.mounted) {
          controller.unregisterFields(ids);
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
