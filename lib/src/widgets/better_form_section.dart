import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/riverpod_controller.dart';
import '../controllers/field_id.dart';
import 'riverpod_form_fields.dart'; // For BetterForm.of

/// A widget that registers a specific set of fields with the parent [BetterForm].
///
/// This is useful for:
/// 1. Organizing large forms into logical sections
/// 2. Lazy loading/registering fields (only when this section is built)
/// 3. Modularizing form definitions
///
/// Example:
/// ```dart
/// BetterForm(
///   child: ListView(
///     children: [
///       BetterFormSection(
///         fields: [ConfigA, ConfigB],
///         child: SectionA(),
///       ),
///       // SectionB fields are not registered until scrolled into view
///       BetterFormSection(
///         fields: [ConfigC, ConfigD],
///         child: SectionB(),
///       ),
///     ],
///   ),
/// )
/// ```
class BetterFormSection extends ConsumerWidget {
  const BetterFormSection({
    super.key,
    required this.fields,
    required this.child,
    this.keepAlive = true,
  });

  /// The fields to register when this section is built
  final List<BetterFormFieldConfig<dynamic>> fields;

  /// The child widget containing the form fields
  final Widget child;

  /// Whether to keep the field values/state when this section is disposed.
  /// Defaults to true (standard form behavior).
  /// If set to false, fields will be unregistered (and data potentially lost)
  /// when this widget is removed from the tree.
  final bool keepAlive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider = BetterForm.of(context);

    if (controllerProvider == null) {
      throw FlutterError(
        'BetterFormSection must be placed inside a BetterForm widget',
      );
    }

    // Use batch registration
    Future.microtask(() {
      final controller = ref.read(controllerProvider.notifier);
      final fieldsToRegister = fields
          .where((f) => !controller.isFieldRegistered(f.id))
          .map((f) => f.toField())
          .toList();

      if (fieldsToRegister.isNotEmpty) {
        controller.registerFields(fieldsToRegister);
      }
    });

    if (!keepAlive) {
      return _DisposableSection(
        controllerProvider: controllerProvider,
        fieldIds: fields.map((f) => f.id).toList(),
        child: child,
      );
    }

    return child;
  }
}

class _DisposableSection extends ConsumerStatefulWidget {
  const _DisposableSection({
    required this.controllerProvider,
    required this.fieldIds,
    required this.child,
  });

  final AutoDisposeStateNotifierProvider<
    RiverpodFormController,
    BetterFormState
  >
  controllerProvider;
  final List<BetterFormFieldID<dynamic>> fieldIds;
  final Widget child;

  @override
  ConsumerState<_DisposableSection> createState() => _DisposableSectionState();
}

class _DisposableSectionState extends ConsumerState<_DisposableSection> {
  late RiverpodFormController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = ref.read(widget.controllerProvider.notifier);
  }

  @override
  void dispose() {
    final ids = widget.fieldIds;
    final controller = _controller;

    // Use batch unregistration
    Future.microtask(() {
      if (controller.mounted) {
        controller.unregisterFields(ids);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
