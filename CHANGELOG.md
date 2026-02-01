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
- **Robust Dependency Logic**: Support for recursive A->B->C dependency chains with cycle detection
- **Async Submission Safety**: `submit()` now waits for all pending async validations to complete before proceeding

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
