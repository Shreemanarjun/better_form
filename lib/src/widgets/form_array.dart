import 'package:flutter/material.dart';
import '../../formix.dart';

/// A widget for managing dynamic lists of items in a form.
///
/// Use [FormixArray] when you need to render a list of fields that can be
/// dynamically added or removed.
class FormixArray<T> extends ConsumerWidget {
  /// Creates a form array widget.
  const FormixArray({
    super.key,
    required this.id,
    required this.itemBuilder,
    this.emptyBuilder,
    this.scrollable = false,
  });

  /// The unique identifier for this array.
  final FormixArrayID<T> id;

  /// Builder function for individual items.
  ///
  /// Receives the [index] and a unique [itemId] that can be used for
  /// [FormixTextFormField] or other field widgets.
  final Widget Function(
    BuildContext context,
    int index,
    FormixFieldID<T> itemId,
    FormixScope scope,
  )
  itemBuilder;

  /// Optional builder when the array is empty.
  final Widget Function(BuildContext context, FormixScope scope)? emptyBuilder;

  /// Whether to use a [ListView] instead of a [Column].
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = Formix.of(context);
    if (provider == null) {
      return const FormixConfigurationErrorWidget(
        message: 'FormixArray used outside of Formix',
        details: 'FormixArray must be placed inside a Formix widget.',
      );
    }

    try {
      final controller = ref.read(provider.notifier);
      final scope = FormixScope(
        context: context,
        ref: ref,
        controller: controller,
      );

      // Resolve the array ID based on surrounding form groups
      final resolvedId = FormixGroup.resolve(context, id) as FormixArrayID<T>;

      // Watch the array value reactively
      final items = scope.watchArray(resolvedId);

      if (items.isEmpty && emptyBuilder != null) {
        return emptyBuilder!(context, scope);
      }

      Widget buildItem(int index) {
        final itemId = resolvedId.item(index);
        return FormixGroup(
          prefix: '${id.key}[$index]',
          child: itemBuilder(context, index, itemId, scope),
        );
      }

      if (scrollable) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) => buildItem(index),
        );
      }

      return Column(
        children: List.generate(items.length, (index) {
          return buildItem(index);
        }),
      );
    } catch (e) {
      return FormixConfigurationErrorWidget(
        message: 'Failed to initialize FormixArray',
        details: e.toString().contains('No ProviderScope found') ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.' : 'Error: $e',
      );
    }
  }
}
