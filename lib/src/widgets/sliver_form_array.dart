import 'package:flutter/material.dart';
import '../../formix.dart';
import 'ancestor_validator.dart';

/// A sliver widget for managing dynamic lists of items in a form.
///
/// Use [SliverFormixArray] when you need to render a list of fields inside
/// a [CustomScrollView].
class SliverFormixArray<T> extends ConsumerStatefulWidget {
  /// Creates a sliver form array widget.
  const SliverFormixArray({
    super.key,
    required this.id,
    required this.itemBuilder,
    this.emptyBuilder,
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
  ///
  /// The returned widget will be automatically wrapped in a [SliverToBoxAdapter]
  /// if it is not already a sliver.
  final Widget Function(BuildContext context, FormixScope scope)? emptyBuilder;

  @override
  ConsumerState<SliverFormixArray<T>> createState() => _SliverFormixArrayState<T>();
}

class _SliverFormixArrayState<T> extends ConsumerState<SliverFormixArray<T>> {
  @override
  Widget build(BuildContext context) {
    final errorWidget = FormixAncestorValidator.validate(
      context,
      widgetName: 'SliverFormixArray',
      requireFormix: false,
    );

    if (errorWidget != null) {
      return SliverToBoxAdapter(child: errorWidget);
    }

    final provider = (Formix.of(context) ?? ref.watch(currentControllerProvider))!;

    // Keep provider alive efficiently without watching state changes.
    // This only triggers a rebuild if the controller instance itself changes.
    ref.watch(provider.notifier);

    try {
      final controller = ref.read(provider.notifier);
      final scope = FormixScope(
        context: context,
        ref: ref,
        controller: controller,
      );

      // Resolve the array ID based on surrounding form groups
      final resolvedId = FormixGroup.resolve(context, widget.id) as FormixArrayID<T>;

      // Watch the array value reactively
      final items = scope.watchArray(resolvedId);

      if (items.isEmpty && widget.emptyBuilder != null) {
        final child = widget.emptyBuilder!(context, scope);
        return SliverToBoxAdapter(child: child);
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final itemId = resolvedId.item(index);
            return FormixGroup(
              prefix: '${widget.id.key}[$index]',
              child: widget.itemBuilder(context, index, itemId, scope),
            );
          },
          childCount: items.length,
        ),
      );
    } catch (e) {
      return SliverToBoxAdapter(
        child: FormixConfigurationErrorWidget(
          message: 'Failed to initialize SliverFormixArray',
          details: e.toString().contains('No ProviderScope found')
              ? 'Missing ProviderScope. Please wrap your application (or this form) in a ProviderScope widget.\n\nExample:\nvoid main() {\n  runApp(ProviderScope(child: MyApp()));\n}'
              : 'Error: $e',
        ),
      );
    }
  }
}
