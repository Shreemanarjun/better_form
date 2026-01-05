import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'better_form.dart';
import 'form_builder.dart';
import '../controllers/field_id.dart';
import '../controllers/better_form_controller.dart';
import '../controllers/riverpod_controller.dart';
import 'form_group.dart';

/// A widget for managing dynamic lists of items in a form.
///
/// Use [BetterFormArray] when you need to render a list of fields that can be
/// dynamically added or removed.
class BetterFormArray<T> extends ConsumerWidget {
  /// Creates a form array widget.
  const BetterFormArray({
    super.key,
    required this.id,
    required this.itemBuilder,
    this.emptyBuilder,
    this.scrollable = false,
  });

  /// The unique identifier for this array.
  final BetterFormArrayID<T> id;

  /// Builder function for individual items.
  ///
  /// Receives the [index] and a unique [itemId] that can be used for
  /// [RiverpodTextFormField] or other field widgets.
  final Widget Function(
    BuildContext context,
    int index,
    BetterFormFieldID<T> itemId,
    BetterFormScope scope,
  )
  itemBuilder;

  /// Optional builder when the array is empty.
  final Widget Function(BuildContext context, BetterFormScope scope)?
  emptyBuilder;

  /// Whether to use a [ListView] instead of a [Column].
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = BetterForm.of(context);
    if (provider == null) {
      throw FlutterError(
        'BetterFormArray must be placed inside a BetterForm widget',
      );
    }

    final controller = ref.read(provider.notifier) as BetterFormController;
    final scope = BetterFormScope(
      context: context,
      ref: ref,
      controller: controller,
    );

    // Resolve the array ID based on surrounding form groups
    final resolvedId =
        BetterFormGroup.resolve(context, id) as BetterFormArrayID<T>;

    // Watch the array value reactively
    final items = scope.watchArray(resolvedId);

    if (items.isEmpty && emptyBuilder != null) {
      return emptyBuilder!(context, scope);
    }

    Widget buildItem(int index) {
      final itemId = resolvedId.item(index);
      return BetterFormGroup(
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
  }
}
