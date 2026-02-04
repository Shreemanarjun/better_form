import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'formix.dart';
import 'form_builder.dart';
import '../controllers/field_id.dart';
import 'form_group.dart';

/// A sliver version of [FormixArray] for better performance in [CustomScrollView].
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
  final Widget Function(
    BuildContext context,
    int index,
    FormixFieldID<T> itemId,
    FormixScope scope,
  )
  itemBuilder;

  /// Optional builder when the array is empty.
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

    final resolvedId = FormixGroup.resolve(context, id) as FormixArrayID<T>;
    final items = scope.watchArray(resolvedId);

    if (items.isEmpty && emptyBuilder != null) {
      return SliverToBoxAdapter(child: emptyBuilder!(context, scope));
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
