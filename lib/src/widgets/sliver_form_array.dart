import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'formix.dart';
import 'form_builder.dart';
import '../controllers/field_id.dart';
import 'form_group.dart';

/// A sliver widget for managing dynamic lists of items in a form.
///
/// Use [SliverFormixArray] when you need to render a list of fields inside
/// a [CustomScrollView].
class SliverFormixArray<T> extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = Formix.of(context);
    if (provider == null) {
      throw FlutterError('SliverFormixArray must be placed inside a Formix widget');
    }

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
      final child = emptyBuilder!(context, scope);
      return SliverToBoxAdapter(child: child);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final itemId = resolvedId.item(index);
          return FormixGroup(
            prefix: '${id.key}[$index]',
            child: itemBuilder(context, index, itemId, scope),
          );
        },
        childCount: items.length,
      ),
    );
  }
}
