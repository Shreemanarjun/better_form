import 'package:flutter/material.dart' hide FormState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../field_id.dart';
import '../riverpod_controller.dart';

/// A form widget that automatically manages a Riverpod controller provider
/// and makes it available to all child Riverpod form fields
class BetterForm extends ConsumerWidget {
  const BetterForm({
    super.key,
    this.initialValue = const {},
    required this.child,
  });

  final Map<String, dynamic> initialValue;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Create a unique controller provider for this form instance
    final controllerProvider = formControllerProvider(initialValue);

    return _BetterFormScope(
      controllerProvider: controllerProvider,
      child: child,
    );
  }

  /// Get the controller provider from the nearest BetterForm ancestor
  static StateNotifierProvider<RiverpodFormController, FormState>? of(
    BuildContext context,
  ) {
    final _BetterFormScope? scope = context
        .dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controllerProvider;
  }
}

class _BetterFormScope extends InheritedWidget {
  const _BetterFormScope({
    required super.child,
    required this.controllerProvider,
  });

  final StateNotifierProvider<RiverpodFormController, FormState>
  controllerProvider;

  @override
  bool updateShouldNotify(_BetterFormScope oldWidget) {
    return controllerProvider != oldWidget.controllerProvider;
  }
}

/// Riverpod-based text form field
class RiverpodTextFormField extends ConsumerStatefulWidget {
  const RiverpodTextFormField({
    super.key,
    required this.fieldId,
    this.decoration,
    this.keyboardType,
    this.maxLength,
    this.controllerProvider,
  });

  final BetterFormFieldID<String> fieldId;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final int? maxLength;
  final StateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  ConsumerState<RiverpodTextFormField> createState() =>
      _RiverpodTextFormFieldState();
}

class _RiverpodTextFormFieldState extends ConsumerState<RiverpodTextFormField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerProvider =
        widget.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});
    final controller = ref.read(controllerProvider.notifier);
    final formState = ref.watch(controllerProvider);

    final value = formState.getValue(widget.fieldId);
    final validation = formState.getValidation(widget.fieldId);
    final isDirty = formState.isFieldDirty(widget.fieldId);

    // Update controller text when value changes externally
    if (_textController.text != (value ?? '')) {
      _textController.text = value ?? '';
    }

    return TextFormField(
      controller: _textController,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        errorText: validation.isValid ? null : validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      onChanged: (newValue) => controller.setValue(widget.fieldId, newValue),
    );
  }
}

/// Riverpod-based number form field
class RiverpodNumberFormField extends ConsumerStatefulWidget {
  const RiverpodNumberFormField({
    super.key,
    required this.fieldId,
    this.decoration,
    this.min,
    this.max,
    this.controllerProvider,
  });

  final BetterFormFieldID<num> fieldId;
  final InputDecoration? decoration;
  final num? min;
  final num? max;
  final StateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  ConsumerState<RiverpodNumberFormField> createState() =>
      _RiverpodNumberFormFieldState();
}

class _RiverpodNumberFormFieldState
    extends ConsumerState<RiverpodNumberFormField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerProvider =
        widget.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});
    final controller = ref.read(controllerProvider.notifier);
    final formState = ref.watch(controllerProvider);

    final value = formState.getValue(widget.fieldId);
    final validation = formState.getValidation(widget.fieldId);
    final isDirty = formState.isFieldDirty(widget.fieldId);

    // Update controller text when value changes externally
    final displayValue = value?.toString() ?? '0';
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    return TextFormField(
      controller: _textController,
      keyboardType: TextInputType.number,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        errorText: validation.isValid ? null : validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      onChanged: (text) {
        final number = num.tryParse(text);
        if (number != null) {
          // Validate range if specified
          if ((widget.min != null && number < widget.min!) ||
              (widget.max != null && number > widget.max!)) {
            // Invalid range - revert to current value
            final currentValue = formState.getValue(widget.fieldId);
            _textController.text = currentValue?.toString() ?? '0';
            return;
          }
          controller.setValue(widget.fieldId, number);
        } else if (text.isEmpty) {
          // Allow empty input, but don't update value yet
          return;
        } else {
          // Invalid number - revert to current value
          final currentValue = formState.getValue(widget.fieldId);
          _textController.text = currentValue?.toString() ?? '0';
        }
      },
    );
  }
}

/// Riverpod-based checkbox form field
class RiverpodCheckboxFormField extends ConsumerWidget {
  const RiverpodCheckboxFormField({
    super.key,
    required this.fieldId,
    this.title,
    this.controllerProvider,
  });

  final BetterFormFieldID<bool> fieldId;
  final Widget? title;
  final StateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});
    final controller = ref.read(controllerProvider.notifier);
    final formState = ref.watch(controllerProvider);

    final value = formState.getValue(fieldId);
    final validation = formState.getValidation(fieldId);
    final isDirty = formState.isFieldDirty(fieldId);

    return CheckboxListTile(
      value: value ?? false,
      title: title,
      subtitle: validation.isValid
          ? (isDirty
                ? const Text('Modified', style: TextStyle(fontSize: 12))
                : null)
          : Text(
              validation.errorMessage ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
      onChanged: (newValue) => controller.setValue(fieldId, newValue ?? false),
    );
  }
}

/// Riverpod-based dropdown form field
class RiverpodDropdownFormField<T> extends ConsumerWidget {
  const RiverpodDropdownFormField({
    super.key,
    required this.fieldId,
    required this.items,
    this.decoration,
    this.controllerProvider,
  });

  final BetterFormFieldID<T> fieldId;
  final List<DropdownMenuItem<T>> items;
  final InputDecoration? decoration;
  final StateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});
    final controller = ref.read(controllerProvider.notifier);
    final formState = ref.watch(controllerProvider);

    final value = formState.getValue(fieldId);
    final validation = formState.getValidation(fieldId);
    final isDirty = formState.isFieldDirty(fieldId);

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      decoration: (decoration ?? const InputDecoration()).copyWith(
        errorText: validation.isValid ? null : validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      onChanged: (newValue) {
        if (newValue != null) {
          controller.setValue(fieldId, newValue);
        }
      },
    );
  }
}

/// Riverpod-based form status widget
class RiverpodFormStatus extends ConsumerWidget {
  const RiverpodFormStatus({super.key, this.controllerProvider});

  final StateNotifierProvider<RiverpodFormController, FormState>?
  controllerProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider =
        this.controllerProvider ??
        BetterForm.of(context) ??
        formControllerProvider(const {});
    final formState = ref.watch(controllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Form Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(formState.isDirty ? 'Form is dirty' : 'Form is clean'),
            Text('Is Valid: ${formState.isValid}'),
            if (formState.isSubmitting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              const Text('Submitting...'),
            ],
          ],
        ),
      ),
    );
  }
}
