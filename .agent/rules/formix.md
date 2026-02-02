# Formix Library Usage Rules

Expert guidance for building high-performance, type-safe forms with Formix.

## Core Concepts

- **Type Safety**: Always use `FormixFieldID<T>` for field identification. Avoid string keys.
- **Pillars of Formix**:
    1.  **Reactive UI**: Use `FormixBuilder`, `FormixFieldWidget`, or `FormixDependentField` for components that need to rebuild on state changes.
    2.  **External Control**: Prefer using Riverpod's `WidgetRef` to access `formControllerProvider` directly. `GlobalKey<FormixState>` is also supported for legacy use cases.
    3.  **Side Effects**: Use `FormixListener` for non-UI actions like navigation, showing Snackbars, or logging.
- **Form Groups**: Use `FormixGroup` to create nested namespaces for fields (e.g., `user.address.city`).
- **Persistence**: Use `FormixPersistence` to save and restore form state across app restarts or sessions.
- **Schema-Based Forms**: Use `FormFieldSchema` and `SchemaBasedFormController` when your form structure is dynamic or defined in code (e.g., JSON-driven forms).

## Best Practices

### 1. Field Definitions
- Define `FormixFieldID` constants at the top of your file or in a dedicated schema file.
- Use specific types (e.g., `FormixFieldID<String>`, `FormixFieldID<int>`) to ensure type safety throughout the form.

### 2. Validation
- **Sync Validation**: Use the `validator` property in `FormixFieldConfig` for immediate feedback.
- **Async Validation**: Use `asyncValidator` for server-side checks. Formix handles debouncing automatically.
- **Fluent API**: Use `FormixValidators` (e.g., `FormixValidators.string().required().email().build()`) for cleaner, readable validation rules.
    - Use `.build()` for synchronous validators.
    - Use `.buildAsync()` if you've added `.async()` rules to the chain.
- **Backend Errors**: After API submission, use `controller.setFieldError(fieldId, error)` to map server errors back to specific fields.

### 3. Form Hierarchy & Groups
- **Logical Nesting**: Use `FormixGroup` for logical sections of a form (e.g., a "User" section and an "Address" section).
- **Prefixes**: Fields within a `FormixGroup` automatically resolve their IDs with the group's prefix.
- **Shared Schemas**: Groups make it easy to reuse field IDs across different parts of the form without naming collisions.

### 4. API Selection
- **Granular Rebuilds**: Wrap only the necessary widgets in `FormixBuilder` or `FormixDependentField` to optimize performance.
- **External Control**: Use `ref.read(formControllerProvider(...).notifier)` in callbacks or providers to interact with the form state programmatically.
- **Cross-Field Logic**: Use `ref.watch(fieldValueProvider(fieldId))` within a `ConsumerWidget` for logic that depends on multiple fields.
- **Side Effects**: Always prefer `FormixListener` over `FormixBuilder` for navigation or snackbars to avoid unnecessary rebuilds.

### 5. Advanced Patterns
- **Dynamic Lists**: Use `FormixArray<T>` for managing dynamic lists of inputs (e.g., multiple phone numbers).
- **Derived Fields**: Use `FormixFieldDerivation` to calculate values based on other fields (e.g., `total = price * quantity`).
- **Form Synchronization**: Use `controller.bindField` to sync values between separate forms.
- **Undo/Redo**: Use `controller.undo()` and `controller.redo()` to implement history features.
- **Persistence**: Provide a `FormixPersistence` implementation to the `Formix` widget to auto-save state. Always provide a `formId` when using persistence.
- **Schema-Based Forms**: For complex, metadata-driven forms, use `FormSchema`. This allows you to define the entire form structure in a single object and use `SchemaBasedFormController` for centralized logic.

### 6. Field Registration
- **Pre-registration**: Register important fields in the `Formix(fields: [...])` property to ensure they exist even before their widgets are mounted.
- **Lazy Registration**: Use `FormixSection` or `FormixFieldRegistry` for fields that only appear conditionally or in multi-step forms.

### 7. Custom Field Widgets
- **Extend `FormixFieldWidget<T>`**: When creating custom form components, extend `FormixFieldWidget` to inherit automatic focus management, validation integration, and value tracking.
- **Use `didChange(T value)`**: Call `didChange` from your custom widget to notify the form engine of value updates.
- **Mixins**: Use `FormixFieldTextMixin<T>` if your custom field relies on a `TextEditingController`.

- **Navigation Guard**: Use `FormixNavigationGuard` to prevent users from accidentally leaving a dirty form.
- **Focus Management**: Formix handles "Enter-to-Next" and "Submit-to-Error" focus automatically. Ensure your `TextInputAction` is set correctly in `FormixFieldConfig`.
- **Keep Alive**: Set `keepAlive: true` in `Formix` if it's placed inside a `TabView` or `Stepper` to preserve state.
- **Optimistic Updates**: Use `controller.optimisticUpdate` for a "snappy" UI when saving individual fields to a server.
- **Dropdowns**: Use `FormixDropdownFormField` which internally uses `InputDecorator` + `DropdownButton` (avoiding deprecated `DropdownButtonFormField`) for long-term support and flexibility.
- **Async Data**: For fields that require async data (like dynamic dropdowns), prefer `FormixAsyncField` over manual `FutureProvider` + `Consumer` patterns. `FormixAsyncField` provides built-in race condition protection, retry/refresh logic, and submission-safety (automatically blocking `submit` while loading).

## Localization
- Use `FormixLocalizations.of(context)` within validators to provide localized error messages.
- Add `FormixLocalizations.delegate` to your `MaterialApp` if you need standard Flutter i18n support.

## Analytics & Debugging
- Enable `LoggingFormAnalytics` during development to see all form events in the console: `Formix(analytics: const LoggingFormAnalytics(), ...)`
- Use `FormixFormStatus` widget to visualize form state (validity, dirty state, submission status) during debugging.
