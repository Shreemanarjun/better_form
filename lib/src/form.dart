import 'package:flutter/material.dart';

import 'controller.dart';
import 'enums.dart';

/// Form state management with type safety
class BetterForm extends StatefulWidget {
  const BetterForm({
    super.key,
    required this.child,
    this.controller,
    this.onChanged,
    this.onFieldChanged,
    this.onDirtyChanged,
    this.autovalidateMode = BetterAutovalidateMode.alwaysAfterFirstValidation,
    this.initialValue = const {},
    this.initialValueBuilder,
    this.enabled = true,
  });

  final Widget child;
  final BetterFormController? controller;
  final VoidCallback? onChanged;
  final dynamic onFieldChanged;
  final dynamic onDirtyChanged;
  final BetterAutovalidateMode autovalidateMode;
  final Map<String, dynamic> initialValue;
  final BetterFormInitialValue? initialValueBuilder;
  final bool enabled;

  @override
  State<BetterForm> createState() => _BetterFormState();

  static BetterFormController? of(BuildContext context) {
    return _BetterFormScope.of(context);
  }
}

class _BetterFormState extends State<BetterForm> {
  late BetterFormController _controller;
  late final GlobalKey<FormState> _formKey;
  late final ValueNotifier<AutovalidateMode> _autovalidateMode;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        BetterFormController(
          initialValue: widget.initialValue,
          initialValueBuilder: widget.initialValueBuilder,
        );
    _formKey = GlobalKey<FormState>();

    _autovalidateMode = ValueNotifier(
      widget.autovalidateMode == BetterAutovalidateMode.always
          ? AutovalidateMode.always
          : widget.autovalidateMode == BetterAutovalidateMode.onUserInteraction
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
    );

    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(BetterForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller itself changes, or if initialValue/initialValueBuilder changes
    // and we are using an internal controller, we need to reinitialize the controller.
    if (widget.controller != oldWidget.controller ||
        (widget.controller == null &&
            (widget.initialValue != oldWidget.initialValue ||
                widget.initialValueBuilder != oldWidget.initialValueBuilder))) {
      // If the old controller was internal, dispose it.
      if (oldWidget.controller == null) {
        _controller.dispose();
      } else {
        // If the old controller was external, just remove its listener.
        _controller.removeListener(_onControllerChanged);
      }

      // Initialize the new controller.
      _controller =
          widget.controller ??
          BetterFormController(
            initialValue: widget.initialValue,
            initialValueBuilder: widget.initialValueBuilder,
          );
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onControllerChanged);
    }
    _autovalidateMode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    widget.onChanged?.call();
    setState(() {});
  }

  bool validate() {
    if (widget.autovalidateMode ==
        BetterAutovalidateMode.alwaysAfterFirstValidation) {
      _autovalidateMode.value = AutovalidateMode.always;
    }
    return _formKey.currentState?.validate() ?? false;
  }

  void save() {
    _formKey.currentState?.save();
  }

  bool saveAndValidate() {
    save();
    return validate();
  }

  void reset() {
    _controller.reset();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _autovalidateMode,
      builder: (context, mode, child) {
        return Form(
          key: _formKey,
          autovalidateMode: mode,
          child: _BetterFormScope(controller: _controller, child: child!),
        );
      },
      child: widget.child,
    );
  }
}

class _BetterFormScope extends InheritedWidget {
  const _BetterFormScope({
    required super.child,
    required BetterFormController controller,
  }) : _controller = controller;

  final BetterFormController _controller;

  static BetterFormController? of(BuildContext context) {
    return (context
                .getElementForInheritedWidgetOfExactType<_BetterFormScope>()
                ?.widget
            as _BetterFormScope?)
        ?._controller;
  }

  @override
  bool updateShouldNotify(_BetterFormScope oldWidget) =>
      oldWidget._controller != _controller;
}
