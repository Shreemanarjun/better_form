## 0.0.1

### ✨ Initial Release

An elite, type-safe, and ultra-reactive form engine for Flutter powered by Riverpod.

#### 🔒 Core Features
* **True Type Safety**: Compile-time safety using `BetterFormFieldID<T>` and `BetterFormArrayID<T>`.
* **High Performance**: Granular rebuilds using Riverpod selectors—only affected widgets update.
* **Auto-Disposable**: Automatic memory management with Riverpod `autoDispose` controllers.
* **Declarative API**: Define form structure easily using `BetterFormFieldConfig`.

#### 🚥 Validation & Logic
* **Smart Validation**: Support for Sync, Async (with debounce), and Cross-field validation.
* **Dependency Tracking**: Automatic re-validation of dependent fields.
* **Field Derivation**: Computed fields based on other form values.

#### 🏗️ Advanced UI Components
* **Sectional Forms**: `BetterFormSection` for lazy-loading and organizing massive forms (100+ fields).
* **Form Arrays**: Managed dynamic lists with type safety.
* **Navigation Guard**: `BetterFormNavigationGuard` to prevent accidental data loss on dirty forms.
* **Performance Monitor**: `BetterFormFieldPerformanceMonitor` for tracking widget rebuilds.

#### 🎯 UX & Control
* **Programmatic Focus**: Jump to errors or specific fields via `BetterFormScope`.
* **Automated Scrolling**: Smooth scrolling to validation errors.
* **State Persistence**: Interface for saving/restoring form progress to local storage.

#### 🧩 Built-in Widgets
* `RiverpodTextFormField`
* `RiverpodNumberFormField`
* `RiverpodCheckboxFormField`
* `RiverpodDropdownFormField`
* `BetterDependentField`
* `BetterFormBuilder`
* `BetterFormWidget` (Base class for custom components)
