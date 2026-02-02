# Formix 🚀

<p align="center">
  <img src="https://zmozkivkhopoeutpnnum.supabase.co/storage/v1/object/public/images/formix.png" alt="Formix Logo" width="200"/>
</p>

<p align="center">
<a href="https://pub.dev/packages/formix"><img src="https://img.shields.io/pub/v/formix.svg" alt="Pub"></a>
<a href="https://github.com/Shreemanarjun/formix/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
<img src="https://img.shields.io/badge/coverage-93%25-brightgreen" alt="Code Coverage">
<img src="https://img.shields.io/badge/tests-passed-brightgreen" alt="Tests">
</p>

**An elite, type-safe, and ultra-reactive form engine for Flutter.**

Powered by Riverpod, Formix delivers lightning-fast performance, zero boilerplate, and effortless state management. Whether it's a simple login screen or a complex multi-step wizard, Formix scales with you.

---

## 📑 Table of Contents
- [📦 Installation](#-installation)
- [⚡ Quick Start](#-quick-start)
- [🎮 Core Concepts](#-core-concepts)
- [🧱 Widget Reference](#-widget-reference)
    - [Standard Fields](#standard-fields)
    - [Form Organization](#form-organization)
    - [Reactive UI & Logic](#reactive-ui--logic)
    - [Headless & Custom Widgets](#headless--custom-widgets)
- [🚥 Validation](#-validation)
- [🕹️ Controlling the Form](#-controlling-the-form)
- [🧪 Advanced Features](#-advanced-features)
- [📊 Analytics & Debugging](#-analytics--debugging)

---

## 📦 Installation

```bash
flutter pub add formix
```

## ⚡ Quick Start

### 1. Define Fields
Always use `FormixFieldID<T>` for type-safe field identification.

```dart
final emailField = FormixFieldID<String>('email');
final ageField = FormixFieldID<int>('age');
```

### 2. Build Form
```dart
Formix(
  child: Column(
    children: [
      FormixTextFormField(fieldId: emailField),
      FormixNumberFormField(fieldId: ageField),

      FormixBuilder(
        builder: (context, scope) => ElevatedButton(
          onPressed: scope.watchIsValid ? () => scope.submit(onValid: _submit) : null,
          child: Text('Submit'),
        ),
      ),
    ],
  ),
)
```

---

## 🎮 Core Concepts

### The Three Pillars

| Pattern | Best For | Usage |
| :--- | :--- | :--- |
| **Reactive UI** | Updating buttons, labels, or visibility. | `FormixBuilder(builder: (c, scope) => ...)` |
| **External Control** | Logic outside the widget tree (AppBar buttons). | `ref.read(formControllerProvider(...).notifier)` |
| **Side Effects** | Navigation, Snackbars, Logging. | `FormixListener` |

### Side Effects (`FormixListener`)
Use `FormixListener` to execute one-off actions (like showing a dialog, navigation, or logging) in response to state changes. **It does not rebuild the UI.**

```dart
FormixListener(
  formKey: _formKey,
  listener: (context, state) {
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form has ${state.errorCount} errors!')),
      );
    }
  },
  child: Formix(key: _formKey, ...),
)
```

---

## 🧱 Widget Reference

### Standard Fields
Formix includes high-performance widgets out of the box:

- **`FormixTextFormField`**: Full-featured text input with auto-validation and focus management.
- **`FormixNumberFormField<T extends num>`**: Type-safe numeric input (`int` or `double`).
- **`FormixCheckboxFormField`**: Boolean selection.
- **`FormixDropdownFormField<T>`**: Type-safe generic dropdown for selections.

### Form Organization
Manage complex hierarchies and performance:

| Widget | Purpose | Usage |
| :--- | :--- | :--- |
| **`FormixGroup`** | Namespaces fields (e.g. `user.address`). | `FormixGroup(prefix: 'address', child: ...)` |
| **`FormixArray<T>`** | Manage dynamic lists of inputs. | `FormixArray(id: FormixArrayID('items'), ...)` |
| **`FormixSection`** | Persists data when swiping away (wizard/tabs). | `FormixSection(keepAlive: true, ...)` |
| **`FormixFieldRegistry`** | Lazy-loads fields only when mounted. | `FormixFieldRegistry(fields: [...], ...)` |

### Reactive UI & Logic
Make your forms "alive":

- **`FormixBuilder`**: Access `FormixScope` for reactive UI components (buttons, progress bars).
- **`FormixDependentField<T>`**: Only rebuilds when a *specific* field changes.
    ```dart
    FormixDependentField<bool>(
      fieldId: hasPetField,
      builder: (context, hasPet) => hasPet ? PetForm() : SizedBox(),
    )
    ```
- **`FormixFieldSelector`**: Fine-grained selection of field state changes (value vs validation).
- **`FormixFieldDerivation`**: Computes values automatically (e.g., `Total = Price * Qty`).
- **`FormixFormStatus`**: Pre-built dashboard showing validity, dirty state, and submission info.

### Headless & Custom Widgets
100% UI control with zero state-management headache.

#### `FormixRawFormField<T>` (Headless)
Perfect for using third-party UI libraries (like Shadcn or Material).
```dart
FormixRawFormField<String>(
  fieldId: nameField,
  builder: (context, state) => MyInput(
    value: state.value,
    error: state.validation.errorMessage,
    onChanged: state.didChange,
  ),
)
```

#### `FormixFieldWidget` (Base Class)
Extend this to build your own reusable Formix-enabled components. It handles all controller wiring and focus management automatically. See also `FormixFieldTextMixin` for text fields.

#### `FormixWidget`
Base class for non-field components (like summaries) that need access to `FormixScope`.

---

## 🚥 Validation

### Fluent API (`FormixValidators`)
Define readable, type-safe validation rules. Use `.build()` for synchronous and `.buildAsync()` for asynchronous rules.

```dart
// String Validation
FormixValidators.string()
  .required('Email is mandatory')
  .email('Invalid format')
  .minLength(6)
  .pattern(RegExp(r'...'))
  .build()

// Number Validation
FormixValidators.number<int>()
  .required()
  .positive()
  .min(18, 'Must be an adult')
  .max(99)
  .build()
```

### Async Validation
Async validators are debounced automatically to optimize server performance.

```dart
FormixFieldConfig(
  id: usernameField,
  asyncValidator: (val) async => await checkAvailability(val) ? null : 'Taken',
  debounceDuration: Duration(milliseconds: 500),
)
```

---

## 🕹️ Controlling the Form

### Using `WidgetRef` (Recommended)
While `BuildContext` works, using Riverpod's `WidgetRef` is often more reliable for external logic.

```dart
void resetForm(WidgetRef ref) {
  // Use ref to reach the controller directly
  ref.read(formControllerProvider(_myParam).notifier).reset();
}
```

### Programmatic Actions
- **`controller.setValue`**: Change values from code.
- **`controller.setFieldError`**: Map backend errors to specific fields.
- **`controller.focusField`**: Programmatically move focus.
- **`controller.undo()` / `controller.redo()`**: Built-in history management.

### Cross-Field Validation
Validate fields based on the state of other fields.
```dart
FormixFieldConfig(
  id: confirmField,
  crossFieldValidator: (value, state) {
    if (value != state.getValue(passwordField)) return 'No match';
    return null;
  },
)
```

---

## 🧪 Advanced Features

- **`Navigation Guard`**: Use `FormixNavigationGuard` to prevent accidental exits from dirty forms.
- **`Persistence`**: Implement `FormixPersistence` for auto-save/restore functionality.
- **`Form Binding`**: Use `controller.bindField` to sync data between separate forms in real-time.
- **`Undo/Redo`**: Seamless history management for every input.

---

## 📊 Analytics & Debugging

- **Logging**: Enable `LoggingFormAnalytics` to see every value change and validation event in the console.
- **DevTools**: Inspect the form state tree and performance metrics using the Formix DevTools extension.

---

<p align="center">Built with ❤️ for the Flutter Community</p>
