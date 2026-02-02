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
- [🎮 Usage Guide](#-usage-guide)
    - [Basic Login Form](#basic-login-form)
    - [Using Dropdowns & Checkboxes](#using-dropdowns--checkboxes)
- [🎮 Core Concepts](#-core-concepts)
- [🧱 Widget Reference](#-widget-reference)
    - [Standard Fields](#standard-fields)
    - [Form Organization](#form-organization)
    - [Reactive UI & Logic](#reactive-ui--logic)
    - [Headless & Custom Widgets](#headless--custom-widgets)
- [🚥 Validation](#-validation)
- [🕹️ Controlling the Form](#-controlling-the-form)
- [🧪 Advanced Features](#-advanced-features)
- [⚡ Performance](#-performance)
- [📊 Analytics & Debugging](#-analytics--debugging)

---

## 📦 Installation

```bash
flutter pub add formix
```

---

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

## 🎮 Usage Guide

### Basic Login Form
Here is a complete, real-world example of a login form with validation and loading state.

```dart
class LoginForm extends StatelessWidget {
  static final emailField = FormixFieldID<String>('email');
  static final passwordField = FormixFieldID<String>('password');

  @override
  Widget build(BuildContext context) {
    return Formix(
      child: Column(
        children: [
          FormixTextFormField(
            fieldId: emailField,
            decoration: InputDecoration(labelText: 'Email'),
            validator: FormixValidators.string().required().email().build(),
          ),
          FormixTextFormField(
            fieldId: passwordField,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
            validator: FormixValidators.string().required().minLength(8).build(),
          ),
          SizedBox(height: 20),
          FormixBuilder(
            builder: (context, scope) {
              if (scope.watchIsSubmitting) {
                return CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: scope.watchIsValid
                    ? () => scope.submit(onValid: (values) async {
                        await authService.login(
                          values[emailField.key],
                          values[passwordField.key]
                        );
                      })
                    : null,
                child: Text('Login'),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### Using Dropdowns & Checkboxes

```dart
final roleField = FormixFieldID<String>('role');
final termsField = FormixFieldID<bool>('terms');

// ... inside Formix
FormixDropdownFormField<String>(
  fieldId: roleField,
  items: [
    DropdownMenuItem(value: 'admin', child: Text('Admin')),
    DropdownMenuItem(value: 'user', child: Text('User')),
  ],
  decoration: InputDecoration(labelText: 'Select Role'),
),

FormixCheckboxFormField(
  fieldId: termsField,
  title: Text('I agree to terms'),
  validator: (val) => val == true ? null : 'Required',
),
```

### Async Data & Dependent Dropdowns
Use `FormixAsyncField` for fields that require asynchronous data fetching (e.g., from an API) or depend on other field values. It automatically manages loading states, race conditions, and integrates with the form's `isPending` status.

```dart
FormixAsyncField<List<String>>(
  fieldId: cityOptionsField,
  // The future is re-triggered automatically if dependencies in the closure change
  future: api.fetchCities(ref.watch(fieldValueProvider(countryField))),
  // Optional: automatically re-trigger on form reset
  onRetry: () => api.fetchCities(ref.read(fieldValueProvider(countryField))),
  keepPreviousData: true,
  loadingBuilder: (context) => LinearProgressIndicator(),
  builder: (context, state) {
    final cities = state.asyncState.value ?? [];
    return FormixDropdownFormField<String>(
      fieldId: cityField,
      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      decoration: InputDecoration(labelText: 'City'),
    );
  },
)
```

> **Pro Tip**: `controller.submit()` automatically waits for all `FormixAsyncField` widgets to finish loading before executing your `onValid` callback.

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

### Accessing Formix
There are three ways to access the form controller, depending on your context:

#### 1. Inside the UI (`FormixBuilder`)
Best for reactive UI updates (buttons, visibility).
```dart
FormixBuilder(
  builder: (context, scope) {
    // scope.controller gives you full access
    return ElevatedButton(onPressed: scope.reset);
  }
)
```

#### 2. Using GlobalKey (External Access)
Best for specialized use cases where you need to control the form from a completely different part of the tree.
```dart
final _formKey = GlobalKey<FormixState>();

// ... Formix(key: _formKey, ...)

void submitFromAppBar() {
  _formKey.currentState?.controller.submit();
}
```

#### 3. Using Riverpod (`WidgetRef`)
Best for complex logic, side effects, or extracting logic to separate providers.
```dart
// Reading properties
final isValid = ref.watch(formControllerProvider(param).select((s) => s.isValid));

// Executing actions
ref.read(formControllerProvider(param).notifier).reset();
```

### 🎮 Controller API Reference
The `FormixController` is your command center.

#### State Updates
| Method | Description |
| :--- | :--- |
| `setValue(val)` | Updates the field value. |
| `reset()` | Resets all fields to initial values. |
| `resetField(id)` | Resets a specific field. |
| `markAsDirty(id)` | Manually marks a field as dirty. |

#### Validation
| Method | Description |
| :--- | :--- |
| `validate()` | Triggers validation for all fields. |
| `validateField(id)` | Validates a single field. |
| `setFieldError(id, msg)` | Sets an external error (e.g. from backend). |

#### Focus & Navigation
| Method | Description |
| :--- | :--- |
| `focusField(id)` | Moves focus to the specified field. |
| `focusFirstError()` | Automatically scrolls to the first invalid field. |

#### Advanced
| Method | Description |
| :--- | :--- |
| `undo()` / `redo()` | Navigates history stack. |
| `snapshot()` | Creates a restoration point. |
| `bindField(id, target)` | Syncs two fields together. |


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

### Navigation Guard
Prevent users from losing work when navigation occurs.

```dart
FormixNavigationGuard(
  onPopInvoked: (didPop, isDirty) {
    if (isDirty && !didPop) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Discard changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text('Cancel')
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(c); // Close dialog
                Navigator.pop(context); // Pop screen
              },
              child: Text('Discard')
            ),
          ],
        ),
      );
    }
  },
  child: Formix(...),
)
```

### Persistence
Auto-save form state to local storage (e.g., SharedPreferences).

```dart
class MyFormPersistence extends FormixPersistence {
  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> state) async {
    await prefs.setString(formId, jsonEncode(state));
  }

  @override
  Future<Map<String, dynamic>?> loadFormState(String formId) async {
    final str = prefs.getString(formId);
    return str != null ? jsonDecode(str) : null;
  }
}

// Usage
Formix(
  formId: 'user_profile',
  persistence: MyFormPersistence(),
  ...
)
```

### Undo/Redo
History is tracked automatically.

```dart
FormixBuilder(
  builder: (context, scope) => Row(
    children: [
      IconButton(
        icon: Icon(Icons.undo),
        onPressed: scope.canUndo ? scope.undo : null,
      ),
      IconButton(
        icon: Icon(Icons.redo),
        onPressed: scope.canRedo ? scope.redo : null,
      ),
    ],
  ),
)
```

---

## ⚡ Performance

Formix is engineered for massive scale.

- **Granular Rebuilds**: Uses `select` to only rebuild exact widgets that change.
- **O(1) Updates**: Field updates are constant time, regardless of form size.
- **Scalability**: Tested with **5000+ active fields** maintaining 60fps interaction.
- **Lazy Evaluation**: Validation and dependency chains are optimized to run only when necessary.

### Stress Test Results (M1 Pro)
- **1000 Fields Mount**: <10ms
- **Typing Latency**: 0ms overhead
- **Bulk Updates**: ~50ms for 500 fields

---

## 📊 Analytics & Debugging

- **Logging**: Enable `LoggingFormAnalytics` to see every value change and validation event in the console.
- **DevTools**: Inspect the form state tree and performance metrics using the Formix DevTools extension.

---

<p align="center">Built with ❤️ for the Flutter Community</p>
