import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/form_analytics.dart';
import '../controllers/field.dart';
import '../controllers/riverpod_controller.dart';
import '../persistence/form_persistence.dart';
import '../enums.dart';
import '../i18n.dart';
import 'form_theme.dart';
import 'ancestor_validator.dart';

/// A form container widget that manages a [FormixController] and provides it
/// to descendant widgets via the widget tree and Riverpod.
///
/// Features:
/// *   **State Management**: Uses Riverpod to efficiently manage form data.
/// *   **Auto-Registration**: Fields register themselves with the controller on mount.
/// *   **Persistence**: Can automatically save and restore form state.
/// *   **Validation**: Supports global and per-field validation configurations.
/// *   **Analytics**: Integrated hooks for tracking form interactions.
///
/// Example:
/// ```dart
/// Formix(
///   initialValue: {'email': 'test@example.com'},
///   onChanged: (values) => print('Form changed: $values'),
///   child: Column(
///     children: [
///       FormixTextFormField(fieldId: FormixFieldID('email')),
///       ElevatedButton(
///         onPressed: () => Formix.controllerOf(context)?.submit(
///           onValid: (data) => print('Success: $data'),
///         ),
///         child: Text('Submit'),
///       ),
///     ],
///   ),
/// )
/// ```
class Formix extends StatefulWidget {
  /// Creates a [Formix].
  const Formix({
    super.key,
    this.controller,
    this.initialValue = const {},
    this.fields = const [],
    this.persistence,
    this.formId,
    this.onChanged,
    this.onChangedData,
    this.analytics,
    this.keepAlive = false,
    this.autovalidateMode = FormixAutovalidateMode.always,
    this.theme,
    this.initialData,
    this.messages,
    required this.child,
  });

  /// Optional explicit controller.
  final FormixController? controller;

  /// Optional analytics hook
  final FormixAnalytics? analytics;

  /// initial values for the form fields.
  final Map<String, dynamic> initialValue;

  /// Configuration for the fields in this form.
  final List<FormixFieldConfig<dynamic>> fields;

  /// Optional persistence handler.
  final FormixPersistence? persistence;

  /// Unique identifier for this form (required for persistence).
  final String? formId;

  /// Callback triggered whenever any value in the form changes.
  final void Function(Map<String, dynamic> values)? onChanged;

  /// Callback triggered whenever the entire form data changes.
  final void Function(FormixData data)? onChangedData;

  /// If true, prevents the form provider from being auto-disposed when the
  /// widget is unmounted. Useful for multi-step forms where you want to
  /// preserve data across navigation.
  final bool keepAlive;

  /// The autovalidate mode for the form.
  final FormixAutovalidateMode autovalidateMode;

  /// Optional visual theme for the form fields.
  final FormixThemeData? theme;

  /// Optional initial state for the form.
  final FormixData? initialData;

  /// Optional custom messages for validation errors.
  final FormixMessages? messages;

  /// The widget subtree.
  final Widget child;

  @override
  State<Formix> createState() => FormixState();

  /// Get the controller provider from the nearest [Formix] ancestor.
  static NotifierProvider<FormixController, FormixData>? of(
    BuildContext context,
  ) {
    final _FormixScope? scope = context.dependOnInheritedWidgetOfExactType<_FormixScope>();
    return scope?.controllerProvider;
  }

  /// Get the [FormixController] instance from the nearest [Formix] ancestor.
  static FormixController? controllerOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FormixScope>();
    if (scope == null) return null;
    try {
      return ProviderScope.containerOf(context).read(scope.controllerProvider.notifier);
    } catch (_) {
      return null;
    }
  }
}

/// State for [Formix], allowing external control via [GlobalKey].
///
/// Uses [AutomaticKeepAliveClientMixin] so that when [Formix] is placed inside
/// a [TabBarView], [PageView], or similar paging widget, its nested
/// [ProviderScope] is kept alive rather than being disposed mid-frame.
/// This prevents the Riverpod 3 error:
///   "setState() called after dispose(): _UncontrolledProviderScopeState"
class FormixState extends State<Formix> with AutomaticKeepAliveClientMixin {
  late final String _internalFormId;
  FormixParameter? _cachedParameter;
  NotifierProvider<FormixController, FormixData>? _cachedProvider;

  @override
  void initState() {
    super.initState();
    final typeName = widget.runtimeType.toString();
    _internalFormId = widget.formId ?? '${typeName}_${identityHashCode(this)}';
  }

  @override
  void didUpdateWidget(Formix oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.keepAlive != oldWidget.keepAlive) {
      updateKeepAlive();
    }

    final effectiveController = widget.controller ?? controller;

    // Ownership check: Formix only synchronizes state, it doesn't manage lifecycle if it doesn't own it.
    if (widget.messages != oldWidget.messages || widget.controller != oldWidget.controller) {
      effectiveController.updateMessages(widget.messages);
    }
  }

  @override
  void dispose() {
    // If we own the controller (internal), Riverpod handles its disposal via ref.onDispose.
    // If we don't own it (external), we should not dispose it as per user ownership semantics.
    // So we don't manually call dispose() on either here to avoid conflicts and timer issues.
    super.dispose();
  }

  FormixParameter _createParameter() {
    return FormixParameter(
      initialValue: widget.initialValue,
      fields: widget.fields,
      persistence: widget.persistence,
      formId: widget.formId,
      namespace: _internalFormId,
      analytics: widget.analytics,
      keepAlive: widget.keepAlive,
      autovalidateMode: widget.autovalidateMode,
      initialData: widget.initialData,
    );
  }

  /// The [NotifierProvider] that backs this form's state.
  ///
  /// Cached and recreated only when the form's configuration changes.
  /// Use this to read or watch form state via Riverpod outside of [Formix].
  NotifierProvider<FormixController, FormixData> get provider {
    final param = _createParameter();
    if (_cachedParameter == param && _cachedProvider != null) {
      return _cachedProvider!;
    }
    _cachedParameter = param;
    _cachedProvider = formControllerProvider(param);
    return _cachedProvider!;
  }

  /// Access the controller to perform actions like [submit] or [reset].
  FormixController get controller => ProviderScope.containerOf(context).read(provider.notifier);

  /// Access the current immutable state of the form.
  ///
  /// Note: This is a snapshot. To watch state reactively, use [FormixBuilder].
  FormixData get data => ProviderScope.containerOf(context).read(provider);

  /// }
  /// ```
  ///
  /// This property is now deprecated in favor of the public [provider] getter.

  /// Whether to keep this [Formix] alive when it is inside a paging widget
  /// such as [TabBarView] or [PageView].
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    // Required by AutomaticKeepAliveClientMixin — must be called before
    // anything else in build().
    super.build(context);

    // 1. Check for ProviderScope first
    final errorWidget = FormixAncestorValidator.validate(
      context,
      widgetName: 'Formix',
      requireFormix: false, // Formix is the one providing it
    );
    if (errorWidget != null) return errorWidget;

    final providerInstance = provider;
    final content = _FormixBody(
      provider: providerInstance,
      form: widget,
      child: _FieldRegistrar(
        controllerProvider: providerInstance,
        fields: widget.fields,
        child: _FormixScope(
          controllerProvider: providerInstance,
          fields: widget.fields,
          child: widget.child,
        ),
      ),
    );

    _cachedProvider = provider;

    return ProviderScope(
      key: ValueKey('${identityHashCode(widget.controller)}_${identityHashCode(widget.messages)}'),
      overrides: [
        if (widget.controller != null)
          provider.overrideWith(() => widget.controller!),

        if (widget.messages != null)
          formixMessagesProvider.overrideWithValue(widget.messages!),

        currentControllerProvider.overrideWithValue(provider),
        fieldValueProvider,
        fieldValidationProvider,
        fieldErrorProvider,
        fieldValidatingProvider,
        fieldIsValidProvider,
        fieldDirtyProvider,
        fieldTouchedProvider,
        fieldPendingProvider,
        fieldValidationModeProvider,
        formValidProvider,
        formDirtyProvider,
        formSubmittingProvider,
        formCurrentStepProvider,
        formDataProvider,
        groupValidProvider,
        groupDirtyProvider,
      ],
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        role: SemanticsRole.form,
        child: widget.theme != null ? FormixTheme(data: widget.theme!, child: content) : content,
      ),
    );
  }
}

class _FormixScope extends InheritedWidget {
  const _FormixScope({
    required super.child,
    required this.controllerProvider,
    required this.fields,
  });

  FormixController get controller {
    throw UnimplementedError('Obsolete. Use Formix.controllerOf(context)');
  }

  final NotifierProvider<FormixController, FormixData> controllerProvider;
  final List<FormixFieldConfig<dynamic>> fields;

  @override
  bool updateShouldNotify(_FormixScope oldWidget) {
    return controllerProvider != oldWidget.controllerProvider || !const ListEquality().equals(fields, oldWidget.fields);
  }
}

class _FormixBody extends ConsumerWidget {
  const _FormixBody({
    required this.provider,
    required this.form,
    required this.child,
  });

  final NotifierProvider<FormixController, FormixData> provider;
  final Formix form;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TIE provider lifecycle to the Formix widget.
    // By listening to the provider, we keep it alive as long as Formix is mounted
    // WITHOUT causing whole-form rebuilds when the state changes.
    ref.listen(provider, (_, __) {});

    // If keepAlive is true, we might do something else, but Riverpod's keepAlive is
    // handled at the provider level. FormixParameter has a keepAlive flag.

    if (form.onChanged != null) {
      ref.listen(provider.select((s) => s.values), (previous, next) {
        if (previous != next) {
          form.onChanged!(next);
        }
      });
    }

    if (form.onChangedData != null) {
      ref.listen(provider, (previous, next) {
        if (previous != next) {
          form.onChangedData!(next);
        }
      });
    }

    return child;
  }
}

class _FieldRegistrar extends ConsumerStatefulWidget {
  const _FieldRegistrar({
    required this.controllerProvider,
    required this.fields,
    required this.child,
  });

  final NotifierProvider<FormixController, FormixData> controllerProvider;
  final List<FormixFieldConfig<dynamic>> fields;
  final Widget child;

  @override
  ConsumerState<_FieldRegistrar> createState() => _FieldRegistrarState();
}

class _FieldRegistrarState extends ConsumerState<_FieldRegistrar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerFields();
  }

  void _registerFields() {
    final controller = ref.read(widget.controllerProvider.notifier);

    final fieldsToRegister = <FormixField>[];

    for (final config in widget.fields) {
      final field = config.toField();
      if (!controller.isFieldRegistered(config.id)) {
        fieldsToRegister.add(field);
      } else {
        // Check if we need to update the definition
        // Note: We use the existing field definition comparison if possible,
        // but FormixField doesn't implement ==.
        // So we assume if widget.fields changed (triggering didUpdateWidget),
        // we should re-register.
      }
    }

    if (fieldsToRegister.isNotEmpty) {
      controller.registerFields(fieldsToRegister);
    }
  }

  @override
  void didUpdateWidget(_FieldRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(widget.fields, oldWidget.fields)) {
      // Configuration changed (e.g. hot reload or dynamic fields).
      // Re-register ALL fields to ensure definitions are updated.
      // registerFields handles standardizing updates without data loss.
      final controller = ref.read(widget.controllerProvider.notifier);
      controller.registerFields(widget.fields.map((f) => f.toField()).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
