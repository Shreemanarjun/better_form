import 'package:flutter/material.dart';

import '../controller.dart';
import '../field_id.dart';
import '../field.dart';

/// Legacy form widget for backward compatibility
/// This widget provides a signals-based API while using Riverpod internally
class BetterForm extends StatefulWidget {
  const BetterForm({
    super.key,
    required this.controller,
    required this.child,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final BetterFormController controller;
  final Widget child;
  final AutovalidateMode autovalidateMode;

  @override
  State<BetterForm> createState() => _BetterFormState();

  static BetterFormController? of(BuildContext context) {
    final _BetterFormScope? scope =
        context.dependOnInheritedWidgetOfExactType<_BetterFormScope>();
    return scope?.controller;
  }
}

class _BetterFormState extends State<BetterForm> {
  @override
  Widget build(BuildContext context) {
    return _BetterFormScope(
      controller: widget.controller,
      child: widget.child,
    );
  }
}

class _BetterFormScope extends InheritedWidget {
  const _BetterFormScope({
    required super.child,
    required this.controller,
  });

  final BetterFormController controller;

  @override
  bool updateShouldNotify(_BetterFormScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Legacy text form field for backward compatibility
class BetterTextFormField extends StatefulWidget {
  const BetterTextFormField({
    super.key,
    required this.fieldId,
    this.initialValue,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.keyboardType,
    this.maxLength,
  });

  final BetterFormFieldID<String> fieldId;
  final String? initialValue;
  final String? Function(String? value)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final InputDecoration decoration;
  final void Function(String? value)? onChanged;
  final TextInputType? keyboardType;
  final int? maxLength;

  @override
  State<BetterTextFormField> createState() => _BetterTextFormFieldState();
}

class _BetterTextFormFieldState extends State<BetterTextFormField> {
  late final BetterFormController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = BetterForm.of(context);

    if (_controller != null) {
      // Register field if not already registered
      if (!_controller.isFieldRegistered(widget.fieldId)) {
        _controller.registerField(
          BetterFormField<String>(
            id: widget.fieldId,
            initialValue: widget.initialValue ?? '',
            validator: widget.validator,
          ),
        );
      }

      // Listen to field changes
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    }
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Text('BetterTextFormField must be used inside a BetterForm');
    }

    final currentValue = _controller.getValue(widget.fieldId) ?? '';
    final validation = _controller.getValidation(widget.fieldId);
    final isDirty = _controller.isFieldDirty(widget.fieldId);

    return TextFormField(
      initialValue: currentValue,
      keyboardType: widget.keyboardType,
      maxLength: widget.maxLength,
      decoration: widget.decoration.copyWith(
        errorText: validation.isValid ? null : validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      onChanged: (value) {
        _controller.setValue(widget.fieldId, value);
        widget.onChanged?.call(value);
      },
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
    );
  }
}

/// Legacy number form field for backward compatibility
class BetterNumberFormField extends StatefulWidget {
  const BetterNumberFormField({
    super.key,
    required this.fieldId,
    this.initialValue,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.decoration = const InputDecoration(),
    this.onChanged,
    this.min,
    this.max,
  });

  final BetterFormFieldID<num> fieldId;
  final num? initialValue;
  final String? Function(num? value)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final InputDecoration decoration;
  final void Function(num? value)? onChanged;
  final num? min;
  final num? max;

  @override
  State<BetterNumberFormField> createState() => _BetterNumberFormFieldState();
}

class _BetterNumberFormFieldState extends State<BetterNumberFormField> {
  late final BetterFormController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = BetterForm.of(context);

    if (_controller != null) {
      // Register field if not already registered
      if (!_controller.isFieldRegistered(widget.fieldId)) {
        _controller.registerField(
          BetterFormField<num>(
            id: widget.fieldId,
            initialValue: widget.initialValue ?? 0,
            validator: widget.validator,
          ),
        );
      }

      // Listen to field changes
      _controller.addFieldListener(widget.fieldId, _onFieldChanged);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.removeFieldListener(widget.fieldId, _onFieldChanged);
    }
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Text('BetterNumberFormField must be used inside a BetterForm');
    }

    final currentValue = _controller.getValue(widget.fieldId) ?? 0;
    final validation = _controller.getValidation(widget.fieldId);
    final isDirty = _controller.isFieldDirty(widget.fieldId);

    return TextFormField(
      initialValue: currentValue.toString(),
      keyboardType: TextInputType.number,
      decoration: widget.decoration.copyWith(
        errorText: validation.isValid ? null : validation.errorMessage,
        suffixIcon: isDirty ? const Icon(Icons.edit, size: 16) : null,
      ),
      onChanged: (value) {
        final number = num.tryParse(value);
        if (number != null) {
          // Validate range if specified
          if ((widget.min != null && number < widget.min!) ||
              (widget.max != null && number > widget.max!)) {
            // Invalid range - don't update
            return;
          }
          _controller.setValue(widget.fieldId, number);
          widget.onChanged?.call(number);
        }
      },
      validator: (value) {
        if (value == null) return null;
        final number = num.tryParse(value);
        if (number == null) return 'Invalid number';

        if (widget.min != null && number < widget.min!) {
          return 'Minimum value is ${widget.min}';
        }
        if (widget.max != null && number > widget.max!) {
          return 'Maximum value is ${widget.max}';
        }

        return widget.validator?.call(number);
      },
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
    );
  }
}

/// Legacy checkbox form field for backward compatibility
class BetterCheckboxFormField extends StatelessWidget {
  const BetterCheckboxFormField({
    super.key,
    required this.fieldId,
    this.initialValue,
    this.title,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.onChanged,
  });

  final BetterFormFieldID<bool> fieldId;
  final bool? initialValue;
  final Widget? title;
  final String? Function(bool? value)? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final void Function(bool? value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = BetterForm.of(context);
    if (controller == null) {
      return const Text('BetterCheckboxFormField must be used inside a BetterForm');
    }

    // Register field if not already registered
    if (!controller.isFieldRegistered(fieldId)) {
      controller.registerField(
        BetterFormField<bool>(
          id: fieldId,
          initialValue: initialValue ?? false,
          validator: validator,
        ),
      );
    }

    final currentValue = controller.getValue(fieldId) ?? false;
    final validation = controller.getValidation(fieldId);
    final isDirty = controller.isFieldDirty(fieldId);

    return CheckboxListTile(
      value: currentValue,
      title: title,
      subtitle: validation.isValid
          ? (isDirty
                  ? const Text('Modified', style: TextStyle(fontSize: 12))
                  : null)
          : Text(
              validation.errorMessage ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
      onChanged: enabled
          ? (value) {
              controller.setValue(fieldId, value ?? false);
              onChanged?.call(value);
            }
          : null,
    );
  }
}

/// Legacy form field listener for backward compatibility
class BetterFormFieldListener<T> extends StatefulWidget {
  const BetterFormFieldListener({
    super.key,
    required this.fieldId,
    required this.builder,
    this.child,
  });

  final BetterFormFieldID<T> fieldId;
  final Widget Function(BuildContext context, T? value, Widget? child) builder;
  final Widget? child;

  @override
  State<BetterFormFieldListener<T>> createState() =>
      _BetterFormFieldListenerState<T>();
}

class _BetterFormFieldListenerState<T> extends State<BetterFormFieldListener<T>> {
  late final BetterFormController? _controller;
  late final ValueNotifier<T?> _notifier;

  @override
  void initState() {
    super.initState();
    _controller = BetterForm.of(context);

    if (_controller != null) {
      _notifier = _controller.getFieldNotifier(widget.fieldId);
      _notifier.addListener(_onValueChanged);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _notifier.removeListener(_onValueChanged);
    }
    super.dispose();
  }

  void _onValueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Text('BetterFormFieldListener must be used inside a BetterForm');
    }

    final value = _controller.getValue(widget.fieldId);
    return widget.builder(context, value, widget.child);
  }
}

/// Legacy form validation listener for backward compatibility
class BetterFormValidationListener extends StatefulWidget {
  const BetterFormValidationListener({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext context, bool isValid, Widget? child) builder;
  final Widget? child;

  @override
  State<BetterFormValidationListener> createState() =>
      _BetterFormValidationListenerState();
}

class _BetterFormValidationListenerState
    extends State<BetterFormValidationListener> {
  late final BetterFormController? _controller;
  late final ValueNotifier<bool> _notifier;

  @override
  void initState() {
    super.initState();
    _controller = BetterForm.of(context);

    if (_controller != null) {
      _notifier = _controller.isValidNotifier;
      _notifier.addListener(_onValidationChanged);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _notifier.removeListener(_onValidationChanged);
    }
    super.dispose();
  }

  void _onValidationChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Text('BetterFormValidationListener must be used inside a BetterForm');
    }

    // Use the notifier value since it's updated when validation changes
    final isValid = _notifier.value;
    return widget.builder(context, isValid, widget.child);
  }
}

/// Legacy form dirty listener for backward compatibility
class BetterFormDirtyListener extends StatefulWidget {
  const BetterFormDirtyListener({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget Function(BuildContext context, bool isDirty, Widget? child) builder;
  final Widget? child;

  @override
  State<BetterFormDirtyListener> createState() =>
      _BetterFormDirtyListenerState();
}

class _BetterFormDirtyListenerState extends State<BetterFormDirtyListener> {
  late final BetterFormController? _controller;
  late final ValueNotifier<bool> _notifier;

  @override
  void initState() {
    super.initState();
    _controller = BetterForm.of(context);

    if (_controller != null) {
      _notifier = _controller.isDirtyNotifier;
      _notifier.addListener(_onDirtyChanged);
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _notifier.removeListener(_onDirtyChanged);
    }
    super.dispose();
  }

  void _onDirtyChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Text('BetterFormDirtyListener must be used inside a BetterForm');
    }

    // Use the notifier value since it's updated when dirty state changes
    final isDirty = _notifier.value;
    return widget.builder(context, isDirty, widget.child);
  }
}
