import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/riverpod_controller.dart';
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

    // Schedule registration to avoid modifying provider during build
    Future.microtask(() {
      // Check if context/ref is still valid.
      // For a ConsumerWidget, reading inside microtask might be tricky if widget is unmounted.
      // But we have the provider reference.
      // However, we need the Ref associated with the container.
      // The 'ref' passed to build is valid.
      // But 'ref.read' on a provider usually works.
      final controller = ref.read(controllerProvider.notifier);
      for (final fieldConfig in fields) {
        if (!controller.isFieldRegistered(fieldConfig.id)) {
          controller.registerField(fieldConfig.toField());
        }
      }
    });

    if (!keepAlive) {
      return _DisposableSection(
        controllerProvider: controllerProvider,
        fields: fields,
        child: child,
      );
    }

    return child;
  }
}

class _DisposableSection extends ConsumerStatefulWidget {
  const _DisposableSection({
    required this.controllerProvider,
    required this.fields,
    required this.child,
  });

  final AutoDisposeStateNotifierProvider<RiverpodFormController, FormState>
  controllerProvider;
  final List<BetterFormFieldConfig<dynamic>> fields;
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
    final fields = widget.fields;
    final controller = _controller;

    // Schedule unregistration to avoid modifying provider during dispose/build
    Future.microtask(() {
      if (controller.mounted) {
        for (final field in fields) {
          controller.unregisterField(field.id);
        }
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
