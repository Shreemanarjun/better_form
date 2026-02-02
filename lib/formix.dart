/// A type-safe form package for Flutter
library;

export 'package:flutter_riverpod/flutter_riverpod.dart';

// Core classes
export 'src/controllers/field_id.dart';
export 'src/controllers/field.dart';
export 'src/controllers/field_config.dart';
export 'src/controllers/validation.dart';
export 'src/controllers/form_state.dart';
export 'src/controllers/formix_controller.dart';
export 'src/controllers/riverpod_controller.dart';
export 'src/enums.dart';
export 'src/form_schema.dart';
export 'src/i18n.dart';

// Widgets
export 'src/widgets/formix.dart';
export 'src/widgets/formix_listener.dart';
export 'src/widgets/base_form_field.dart';
export 'src/widgets/checkbox_form_field.dart';
export 'src/widgets/dropdown_form_field.dart';
export 'src/widgets/form_status.dart';
export 'src/widgets/headless.dart';
export 'src/widgets/text_form_field.dart';
export 'src/widgets/number_form_field.dart';
export 'src/widgets/field_selector.dart';
export 'src/widgets/field_derivation.dart';
export 'src/widgets/dependent_field.dart';
export 'src/widgets/async_form_field.dart'; // Added
export 'src/widgets/formix_section.dart';
export 'src/widgets/form_builder.dart';
export 'src/widgets/form_array.dart';
export 'src/widgets/form_group.dart';
export 'src/widgets/navigation_guard.dart';
export 'src/controllers/riverpod_controller.dart'
    show groupValidProvider, groupDirtyProvider;
export 'src/persistence/form_persistence.dart';
export 'src/widgets/field_selector/formix_field_conditional_selector.dart';
export 'src/widgets/field_selector/formix_field_performance_monitor.dart';
export 'src/widgets/field_selector/formix_field_selector.dart';
export 'src/widgets/field_selector/formix_field_value_selector.dart';
export 'src/validators/validators.dart';
export 'src/analytics/form_analytics.dart';
export 'src/analytics/logging_form_analytics.dart';
export 'src/widgets/form_registry.dart';
