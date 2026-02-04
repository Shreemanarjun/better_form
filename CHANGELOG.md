## 0.0.5

### ✨ Accessibility & Semantics (shadcn-inspired)
- **Form Semantics**: The `Formix` widget now automatically reports as a `SemanticsRole.form`, improving structural navigation for screen readers.
- **Validation Semantics**: All fields (including headless ones) now communicate their validation status (`invalid`/`valid`) directly to the OS via `SemanticsValidationResult`.
- **Intelligent Announcements**: Added `FormixController.announceErrors()` which automatically reads out the first validation error to assistive technologies when a submission fails.

### 🚀 Standard Field Properties
- **Unified API**: All Formix fields (`Text`, `Number`, `Checkbox`, `Dropdown`) now support standard `FormField` properties:
  - `onSaved` & `onReset` hooks.
  - `enabled` state management.
  - `forceErrorText` for manual error overrides.
  - `errorBuilder` for custom error UI.
  - `autovalidateMode` for per-field validation control.
  - `restorationId` for state restoration.
- **Explicit Controller**: The `Formix` widget now supports an optional explicit `controller` parameter, allowing for manual instantiation while keeping the reactive provider benefits.

### 🛠️ Core Improvements & Fixes
- **Headless API**: `FormixFieldStateSnapshot` now exposes `enabled` and `errorBuilder`, making it easier to build high-quality custom components.
- **Validation Fix**: Fixed `RiverpodFormController.registerField` to strictly honor `autovalidateMode` during initial registration, preventing unwanted errors in `disabled` forms.
- **Type-Safe Value Retrieval**:
  - Reverted `getValue<T>` to return `T?` for better safety and backwards compatibility.
  - Added "smart fallback" to `getValue`: now recovers values from `initialValueMap` or field definitions if a field is not yet registered.
  - Introduced `requireValue<T>`: returns `T` and throws a descriptive `StateError` if the value is null.
- **New Field Transformers**:
  - `FormixFieldTransformer`: Synchronous 1-to-1 transformation between fields.
  - `FormixFieldAsyncTransformer`: Asynchronous transformation with built-in debounce and robust lifecycle management.
- **Hot Reload Support**: Fixed field definitions not updating during hot reload. `Formix` and `FormixSection` now reliably detect configuration changes and update the controller.
- **Riverpod Refactors**: Key widgets (`FormixFieldDerivation`, `FormixGroup`, `FormixListener`) upgraded to `ConsumerStatefulWidget` for better state access.
- **Hot Reload Support**: Fixed field definitions not updating during hot reload. `Formix` and `FormixSection` now reliably detect configuration changes and update the controller.
- **FormixSection Overhaul**: Refactored to `ConsumerStatefulWidget` for consistent lifecycle management.
  - Now supports synchronous registration to prevent lazy-loading race conditions.
  - Reliably handles `keepAlive` for preserving state in wizards and tabs.
- **Undo/Redo Stability**: Fixed history pollution where focus/touch events triggered unnecessary undo steps. History is now strictly value-based using deep equality checks.
- **Validation Fixes**:
  - `FormixAutovalidateMode.always` now correctly shows errors immediately upon registration for all field types.
  - Fixed input formatter ordering in `FormixTextFormField` and `FormixNumberFormField` to ensure config-level formatters (logic) run before widget-level formatters (UI).
- **New `FormixAsyncField`**: Added a dedicated widget for handling asynchronous data fetching within forms.
  - Features built-in race condition protection and retry logic.
  - Automatically re-triggers fetch on form reset (via `onRetry`).
  - Coordinated with the form's `isPending` state for submission safety.
- **New `FormixDependentAsyncField`**: A simplified widget for parent-child field relationships.
  - Automatically watches a dependency and executes a future.
  - **Improved Robustness**: Fixed lifecycle issues where fields could occasionally unregister during rapid state transitions.
  - Supports `resetField` to automatically clear dependent fields when the parent changes.
- **Robust Reset Logic**: Form resets are now tracked via an internal `resetCount`, ensuring the `onReset` hook is reliably triggered for all fields regardless of their previous dirty state.
- **Improved Pending State Management**: Fixed "Tried to modify a provider while the widget tree was building" error by moving pending state updates to microtasks.
- **Multi-Step Form Reliability**: Fixed a bug where navigating back to a previous page in a multi-step form would show "required" validation errors even if fields were filled. Formix now correctly validates against preserved values during re-registration.
- **Dropdown Field**: Migrated `FormixDropdownFormField` to use `InputDecorator` + `DropdownButton`. Now defensively handles values not present in the items list to prevent crashes during dynamic transitions.
- **Global Validation Mode**:
  - Introduced form-level `autovalidateMode` in `Formix` widget and `FormixController`.
  - Added `FormixAutovalidateMode.auto` as the default for all fields, allowing them to inherit the form's global setting or explicitly override it.
  - Improved `onUserInteraction` logic to ensure consistent feedback when values are changed and then reverted to their initial state.
- **Infinite Loop Fix**: Optimized `FormixController` listener notifications to prevent infinite loops when fields trigger state changes during updates (e.g., in `FormixFieldAsyncTransformer`).
- **Robust Bulk Update API**:
  - Added `FormixBatch` for compile-time type-safe batch building with a new fluent `setValue().to()` API for guaranteed lint enforcement.
  - Added `FormixBatchResult` for detailed reporting on batch failures (type mismatches, missing fields).
  - Both `setValues` and `updateFromMap` now return results instead of throwing, with an optional `strict: true` mode for developers who prefer immediate crashes during debugging.
- **High-Performance Dependency Tracking**:
  - Re-engineered `_collectTransitiveDependents` with a high-speed BFS implementation using an index-based queue, reducing traversal time for 100,000-field chains from **332ms to ~160ms**.
  - Optimized internal dependents map access with zero-allocation iterables.
- **Async Validation Stability**:
  - Fixed a critical race condition where `submit()` could hang indefinitely if called while an async validation was already pending.
  - Corrected `pendingCount` double-increment bug during concurrent validation cycles.
  - Consolidated "validating" state transitions into primary batch updates, eliminating redundant UI rebuilds.
- **Optimized State Engine**:
  - Implemented **Lazy Map Cloning** for validation results, avoiding O(N) penalties when field values change but validation results remain constant.
  - Shared `FormixData` validation contexts across batch updates to drastically reduce GC pressure in cross-field validation chains.
  - Replaced functional filter/map operations in hot paths with high-performance manual loops for count calculations.
- **Validation Fixes**:
  - Fixed `onUserInteraction` mode regression where valid results weren't properly cached to track the "previously validated" state.
  - Corrected `FormixAutovalidateMode.always` behavior during initial field registration.
- **DevTools Integration**: Forms without an explicit `formId` now automatically register with DevTools using their internal namespace as a fallback, ensuring full visibility.

### 🛠️ Developer Experience
- **FormixBuilder Enhancements**: Improved reactive data access patterns with better scoping.
- **New `FormixWidget`**: Added base class for creating reusable, context-aware form components with less boilerplate.

### 🧪 Testing
- **Advanced Async Test Suite**: Added comprehensive tests for `FormixDependentAsyncField` and `FormixAsyncField`:
  - Rapid dependency change handling and debounce verification.
  - State preservation during async loading unmounts.
  - Validation error clearing on field resets.
- **Additional Test Coverage**:
  - Dynamic Array Fields (Contacts List)
  - Multi-Step Wizards with State Preservation
  - Complex Validation Scenarios & Input Formatting
  - Hot Reload & Lifecycle Behavior
  - Performance & Memory Leaks (5000+ fields, rapid typing stress tests)

## 0.0.4

### 🛠️ DevTools Integration
- **DevTools Extension**: Added a dedicated DevTools extension for real-time form state inspection and debugging
  - 🔍 Visual form state tree with field values, validation states, and metadata
  - ⚡ Performance monitoring for form rebuilds and validation execution
  - 🔗 Deep link integration for quick access from running applications
  - 🌐 Built with Flutter Web and fully integrated with the DevTools ecosystem

### 🔒 Type Safety & Reliability
- **Strict Null Safety**: Comprehensive null-safety across all validators and widgets
- **Integration Testing**: Expanded integration tests for complex scenarios

### 🎯 User Experience Enhancements
- **Rich Error Placeholders**: Dynamic errors like `Field {label} must be at least {min} characters`
- **Built-in Masking & Formatting**: Input formatters in `FieldConfig`
- **Automatic Focus Management**: Submit-to-Error and Enter-to-Next implemented

### 🧠 Advanced State Management
- **Undo/Redo History**: Snapshots for state restoration and history
- **Optimistic Field Updates**: Pending state for server round-trips
- **Multi-Form Synchronization**: "Binding" API to link fields between separate forms

- **Improved error messages and validation feedback**
- **Fluent Validators**: New `FormixValidators` API for readable chainable rules
- **Logging Analytics**: Built-in debug logger for form events
- **Robust Dependency Logic**: Support for recursive A->B->C dependency chains with cycle detection. Optimized to O(N) (10,000-field chain updates in ~70ms).
- **Correct Undo/Redo Behavior**: Implemented semantic equality for form state to prevent duplicate history entries.
- **Async Submission Safety**: `submit()` now waits for all pending async validations to complete before proceeding
- **Partial Validation**: `validate(fields: [...])` allows validating specific subsets of fields (e.g., for Steppers)

### ⚡ Performance Optimizations
- **Delta Updates**: O(1) complexity for field updates (was O(N)), enabling forms with 1000+ fields
- **Lazy Step Initialization**: "Sleep" background steps to save memory in 50+ step forms
- **Form Analytics Hook**: Track completion time and abandonment points
- **Built-in Localization**: Support for 6 languages out-of-the-box (En, Es, Fr, De, Hi, Zh)
- **Zero Configuration**: Works automatically with standard Flutter `MaterialApp`
- **Optional Delegate**: New `FormixLocalizations.delegate` for seamless integration (completely optional)
- **Reviewable Messages**: Fallback mechanism to `Localizations.localeOf(context)` if delegate is missing

### 🔧 Developer Experience
- Enhanced visual debugging tools through DevTools extension
- Better form state introspection capabilities
- Improved error messages and validation feedback

## 0.0.3
- Upgraded flutter_riverpod to ^2.6.1


## 0.0.2

- Updated logo URL


## 0.0.1

### ✨ Initial Release

An elite, type-safe, and ultra-reactive form engine for Flutter powered by Riverpod.

#### 🔒 Core Features
* **True Type Safety**: Compile-time safety using `FormixFieldID<T>` and `FormixArrayID<T>`.
* **High Performance**: Granular rebuilds using Riverpod selectors—only affected widgets update.
* **Auto-Disposable**: Automatic memory management with Riverpod `autoDispose` controllers.
* **Declarative API**: Define form structure easily using `FormixFieldConfig`.

#### 🚥 Validation & Logic
* **Smart Validation**: Support for Sync, Async (with debounce), and Cross-field validation.
* **Dependency Tracking**: Automatic re-validation of dependent fields.
* **Field Derivation**: Computed fields based on other form values.

#### 🏗️ Advanced UI Components
* **Sectional Forms**: `FormixSection` for lazy-loading and organizing massive forms (100+ fields).
* **Form Arrays**: Managed dynamic lists with type safety.
* **Navigation Guard**: `FormixNavigationGuard` to prevent accidental data loss on dirty forms.
* **Performance Monitor**: `FormixFieldPerformanceMonitor` for tracking widget rebuilds.

#### 🎯 UX & Control
* **Programmatic Focus**: Jump to errors or specific fields via `FormixScope`.
* **Automated Scrolling**: Smooth scrolling to validation errors.
* **State Persistence**: Interface for saving/restoring form progress to local storage.

#### 🧩 Built-in Widgets
* `RiverpodTextFormField`
* `RiverpodNumberFormField`
* `RiverpodCheckboxFormField`
* `RiverpodDropdownFormField`
* `FormixDependentField`
* `FormixBuilder`
* `FormixWidget` (Base class for custom components)
