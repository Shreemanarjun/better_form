# Formix AI Skill Description

This document describes the **Formix** library for Flutter. Use this context to generate high-quality, type-safe, and performant form code.

## 🧠 Core Philosophy
Formix is powered by **Riverpod**. It uses a **declarative** and **type-safe** approach.
- **Identifiers**: Every field MUST have a unique `FormixFieldID<T>`.
- **Root**: All fields MUST be descendants of a `Formix` widget.
- **Reactivity**: Use `FormixBuilder` to listen to state changes (validity, values, submission status). Do NOT use `setState` for form interactions.

## 🔑 Key Patterns

### 1. Defining Fields
**ALWAYS** define field IDs as static constants or top-level variables to ensure type safety.
```dart
static final emailField = FormixFieldID<String>('email');
static final ageField = FormixFieldID<int>('age');
static final termsField = FormixFieldID<bool>('terms');
```

### 2. Basic Setup
```dart
Formix(
  // Optional: Global validation mode (default: onUserInteraction)
  autovalidateMode: FormixAutovalidateMode.onUserInteraction,
  initialValue: const {'email': 'test@example.com'}, // Optional global defaults
  child: Column(
    children: [
      // ... fields
    ],
  ),
)
```

### 3. Validation (Fluent API)
Use `FormixValidators` for readable, chainable rules.
```dart
validator: FormixValidators.string()
  .required('Email is required')
  .email('Invalid email')
  .build(), // .build() for sync, .buildAsync() for async
```

### 4. Interactive UI
Use `FormixBuilder` to access `FormixScope`.
```dart
FormixBuilder(
  builder: (context, scope) {
    // scope.watchIsValid      (Reactive boolean)
    // scope.watchIsSubmitting (Reactive boolean)
    // scope.controller        (Methods: submit, reset, getValue)

    return ElevatedButton(
      onPressed: scope.watchIsValid
        ? () => scope.submit(onValid: (values) => print(values))
        : null,
      child: scope.watchIsSubmitting
        ? CircularProgressIndicator()
        : Text('Submit'),
    );
  },
)
```

## 🧱 Widget Catalog

### Root & Configuration
| Widget | Purpose | Example |
| :--- | :--- | :--- |
| `Formix` | The root widget. Provides the `FormixController` scope. | `Formix(child: ...)` |
| `FormixThemeData` | Style configuration for all descendant Formix widgets. | `Formix(theme: FormixThemeData(...))` |

### Core Reactivity
| Widget | Purpose | Example |
| :--- | :--- | :--- |
| `FormixBuilder` | Rebuilds UI based on form-wide state (valid, submitting). | `FormixBuilder(builder: (c, scope) => ...)` |
| `FormixListener` | Executes side effects (snackbars, nav) on state change. | `FormixListener(listener: (c, state) => ...)` |

### Standard Inputs
| Widget | Type `T` | Purpose |
| :--- | :--- | :--- |
| `FormixTextFormField` | `String` | Standard Material text input. |
| `FormixNumberFormField` | `num` / `int` / `double` | Type-safe numeric input. |
| `FormixCheckboxFormField` | `bool` | Checkbox with title/subtitle. |
| `FormixDropdownFormField` | `T` | Generic dropdown selection. |
| `FormixCupertinoTextFormField` | `String` | iOS-style text input. |
| `FormixAdaptiveTextFormField` | `String` | Adapts between Material/Cupertino using `FormixTheme`. |

### Headless & Custom (Raw)
Use these to wrap *any* widget or custom component.

| Widget | Purpose |
| :--- | :--- |
| `FormixRawFormField<T>` | Base headless widget. Exposes full `FormixFieldStateSnapshot`. |
| `FormixRawTextField<T>` | Specialized for text fields (manages `TextEditingController`). |
| `FormixRawStringField` | Convenience for `String`-only keys to avoid generics boilerplate. |
| `FormixRawNotifierField<T>` | Semantic alias emphasizing use of `state.valueNotifier`. |
| `FormixFieldWidget<T>` | Base class for creating reusable custom field widgets. |

### Layout & Logic
| Widget | Purpose |
| :--- | :--- |
| `FormixSection` | Group fields. `keepAlive: false` clears data when unmounted. |
| `FormixGroup` | Namespace fields (e.g. `user.name`). |
| `FormixFieldRegistry` | Lazy-load fields (for PageView/Tabs). |
| `FormixArray<T>` | Dynamic lists (add/remove items). |
| `SliverFormixArray<T>` | Dynamic lists for `CustomScrollView`. |

### Reactivity & Selectors
Fine-grained performance optimization.

| Widget | Purpose |
| :--- | :--- |
| `FormixFieldSelector<T>` | Rebuilds only when specific aspects (value, valid, dirty) change. |
| `FormixFieldValueSelector<T>` | Simplified selector watching *only* the value. |
| `FormixFieldConditionalSelector<T>` | Rebuilds only if a custom condition is met. |
| `FormixFieldPerformanceMonitor<T>` | Debug tool to count rebuilds of a field. |

### Async & Dependent
| Widget | Purpose |
| :--- | :--- |
| `FormixDependentField<T>` | Rebuilds subtree when dependency changes. |
| `FormixDependentAsyncField<T,D>` | Fetch data dependent on another field (Country -> City). |
| `FormixFieldTransformer` | 1-to-1 Sync transform (e.g. Trim string). |
| `FormixFieldAsyncTransformer` | Async 1-to-1 transform with debounce (User ID -> User Profile). |
| `FormixFieldDerivation` | Compute value from multiple dependencies (Qty * Price). |

### Utilities
| Widget | Purpose |
| :--- | :--- |
| `FormixNavigationGuard` | Prevents accidental pops with unsaved changes. |
| `FormixFormStatus` | Debug dashboard (Dirty count, Error count). |
| `RestorableFormixData` | (Data Class) Integration with `RestorationMixin`. |

## 🌐 Internationalization (I18n)

Formix provides built-in localization support for common validation messages.

**Supported Locales:** `en`, `es`, `fr`, `de`, `hi`, `zh`.

### Setup
Add `FormixLocalizations.delegate` to your `MaterialApp`.

```dart
MaterialApp(
  localizationsDelegates: const [
    FormixLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    // ...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    // ...
  ],
)
```

### Usgae in Custom Validators
```dart
validator: (value, context) {
   final messages = FormixLocalizations.of(context);
   if (value == null) return messages.required('Field Name');
   return null;
}
```

## 💾 Persistence

Automatically save and restore form state (e.g., across app restarts or crashes).

### 1. Simple Persistence (In-Memory/Testing)
```dart
Formix(
  formId: 'user_profile_v1', // REQUIRED unique ID
  persistence: InMemoryFormPersistence(),
  child: ...
)
```

### 2. Custom Persistence (e.g., SharedPreferences/Hive)
Implement `FormixPersistence`.

```dart
class MyPrefsPersistence extends FormixPersistence {
  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> values) async {
    // Save to native storage
  }

  @override
  Future<Map<String, dynamic>?> getSavedState(String formId) async {
     // Retrieve from native storage
  }

  @override
  Future<void> clearSavedState(String formId) async {
    // Clear storage
  }
}
```

## 📊 Analytics

Track user interactions with your forms.

```dart
class MyAnalytics extends FormixAnalytics {
  @override
  void onFieldChanged(String? formId, String key, dynamic value) {
    print('Field $key changed to $value');
  }

  @override
  void onSubmitFailure(String? formId, Map<String, dynamic> errors) {
    print('Form failed with errors: ${errors.keys}');
  }

  // ... implement other hooks (onFormStarted, onFieldTouched, etc.)
}

// Usage
Formix(
  analytics: MyAnalytics(),
  child: ...
)
```

## 🛠️ DevTools

Formix integrates directly with Flutter DevTools to inspect form state.

- **Auto-Enabled:** Works automatically in **Debug Mode**.
- **Features:**
    - View live values, errors, and dirty states.
    - Inspect dependency graphs.
    - "Time Travel" debugging (Undo/Redo history).
    - Modify field values directly from DevTools.
    - Force validation or submission.

No additional code setup is required.

## ✅ Advanced Validators

Formix uses a fluent API for validation, powered by `FormixValidators` and `FormixValidationKeys` for translation.

```dart
validator: FormixValidators.string()
  .required()          // Uses default 'required' message key
  .email()             // Uses 'invalidEmail' key
  .minLength(8)        // Uses 'minLength' key with param
  .custom((val) => val.contains('admin') ? 'Forbidden' : null)
  .build()
```
