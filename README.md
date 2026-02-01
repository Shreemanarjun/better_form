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
- [🎮 Choosing Your API (Comparison)](#-choosing-your-api-comparison)
- [🏗️ The Three Pillars of Formix](#%EF%B8%8F-the-three-pillars-of-formix)
- [🎨 UI Components](#-ui-components)
  - [Available Fields](#available-fields)
  - [Custom Field Widgets](#custom-field-widgets)
- [🚥 Validation & UX](#%EF%B8%8F-validation--ux)
  - [Sync & Async Validation](#sync--async-validation)
  - [Manual/Backend Errors](#manualbackend-errors)
- [🛠️ Professional API Guide](#%EF%B8%8F-professional-api-guide)
- [🚀 Advanced Patterns](#-advanced-patterns)
- [💡 Pro Tips](#-pro-tips)

---

## 📦 Installation

```bash
flutter pub add formix
```

---

## ⚡ Quick Start

### 1. Define Fields
```dart
final emailField = FormixFieldID<String>('email');
final ageField = FormixFieldID<int>('age');
```

### 2. Build Form
```dart
Formix(
  child: Column(
    children: [
      RiverpodTextFormField(fieldId: emailField),
      RiverpodNumberFormField(fieldId: ageField),

      FormixBuilder(
        builder: (context, scope) => ElevatedButton(
          onPressed: scope.watchIsValid ? () => scope.submit() : null,
          child: Text('Submit'),
        ),
      ),
    ],
  ),
)
```

---

## 🎮 Choosing Your API (Comparison)

| API | Best For | Rebuilds UI? | DX Rank |
| :--- | :--- | :--- | :--- |
| **`FormixBuilder`** | Granular UI updates (Buttons, status labels) | ✅ Yes | ⭐️⭐️⭐️⭐️⭐️ |
| **`FormixListener`** | Side effects (Logic, Nav, Snackbar) | ❌ No | ⭐️⭐️⭐️⭐️⭐️ |
| **`GlobalKey`** | External Control (AppBar, FAB, Logic) | ❌ No | ⭐️⭐️⭐️⭐️ |
| **`ref.watch(fieldValueProvider)`** | Cross-field logic within Consumer | ✅ Yes | ⭐️⭐️⭐️⭐️ |

---

## 🎨 UI Components

### Available Fields
Formix comes with pre-built, high-performance widgets that work instantly:

- **`RiverpodTextFormField`**: Full-featured text input with auto-validation and dirty state indicators.
- **`RiverpodNumberFormField`**: Type-safe numeric input with support for `min`/`max` constraints.
- **`RiverpodCheckboxFormField`**: Reactive checkbox with built-in label support.
- **`RiverpodDropdownFormField<T>`**: Type-safe generic dropdown for selections.
- **`RiverpodFormStatus`**: A debug/status card that shows current form validity, dirty state, and submission progress.

### Custom Field Widgets
Need a custom UI? Extend `FormixFieldWidget` to create a fully integrated form field in seconds.

```dart
class MyCustomToggle extends FormixFieldWidget<bool> {
  const MyCustomToggle({super.key, required super.fieldId});

  @override
  Widget build(BuildContext context) {
    // Access value, validation, and dirty state directly!
    return Switch(
      value: value ?? false,
      onChanged: (v) => didChange(v), // Notifies the form
    );
  }
}
```

---

## 🚥 Validation & UX

Formix provides a multi-layered validation system designed for an elite user experience.

### Sync & Async Validation
Define rules in `FormixFieldConfig`. Sync rules run immediately on every keystroke, while Async rules are intelligently debounced.

```dart
FormixFieldConfig<String>(
  id: usernameField,
  // 🟢 Sync: Immediate feedback
  validator: (val) => val!.length < 3 ? 'Too short' : null,

  // 🔵 Async: Intelligent Debouncing (Default 300ms)
  asyncValidator: (val) async {
    final available = await checkUsername(val!);
    return available ? null : 'Username taken';
  },
  debounceDuration: const Duration(milliseconds: 500),
)
```

**UX Tip**: Formix widgets automatically show a `CircularProgressIndicator` while async rules are running! You can customize this by passing `loadingIcon` (or `validatingWidget` for checkboxes) to your field widget.

### Fluent Validation API
Define complex rules easily with the Zod-like `FormixValidators` API:

```dart
FormixFieldConfig<String>(
  id: emailField,
  validator: FormixValidators.string()
    .required()
    .email('Please enter a valid email')
    .minLength(5)
    .build(), // Returns a standard validator function
)
```

### Manual/Backend Errors
Sometimes errors come from the server after a submit attempt. Use `setFieldError` to inject these errors directly into your UI.

```dart
final controller = Formix.controllerOf(context);

try {
  await api.submit(data);
} catch (e) {
  if (e is ValidationError) {
    // Map backend errors to specific fields!
    controller?.setFieldError(emailField, 'Email already exists on server');
  }
}
```

---

## 🌍 Localization (i18n)

Formix speaks your language! It comes with built-in translations for **English, Spanish, French, German, Hindi, and Chinese**.

### 1. Automatic Usage (Zero Config)
Just use `FormixLocalizations.of(context)` in your validators. It automatically detects the active locale from `MaterialApp`.

```dart
validator: (value, context) {
  final messages = FormixLocalizations.of(context);
  if (value == null || value.isEmpty) {
    return messages.required('Email'); // Returns "Email is required" (or localized equivalent)
  }
  return null;
}
```

### 2. Using the Delegate (Optional)
For the best integration with Flutter's widget tree (and to strictly follow Flutter standards), you can add the delegate to your `MaterialApp`. **This is completely optional**—the method above works without it!

```dart
MaterialApp(
  localizationsDelegates: const [
    FormixLocalizations.delegate, // Optional: Add this
    GlobalMaterialLocalizations.delegate,
    // ...
  ],
  // ...
)
```

---

## 🏗️ The Three Pillars of Formix

### 1. Inside the Tree (Reactive UI)
Use `FormixBuilder` for code that lives inside the form and needs to react to state changes.
```dart
FormixBuilder(
  builder: (context, scope) => Text('Age: ${scope.watchValue(ageField)}'),
)
```

### 2. Outside the Tree (External Control)
Access the form from your `Scaffold`'s `AppBar` using a `GlobalKey`.
```dart
final _formKey = GlobalKey<FormixState>();
// ...
onPressed: () => _formKey.currentState?.controller.submit(...)
```

### 3. Listening to Changes (Side Effects)
Use `FormixListener` for navigation or snackbars. It doesn't trigger rebuilds.
```dart
FormixListener(
  formKey: _formKey,
  listener: (context, state) => print('Valid: ${state.isValid}'),
  child: Formix(key: _formKey, ...),
)
```

---

## 🚀 Advanced Patterns

### Dynamic Form Arrays
Manage lists of dynamic inputs easily with `FormixArray`.
```dart
FormixArray<String>(
  id: hobbiesId,
  itemBuilder: (context, index, itemId, scope) =>
    RiverpodTextFormField(fieldId: itemId),
)
```

### Computed & Derived Fields
Update fields automatically based on other values.
```dart
FormixFieldDerivation(
  dependencies: [priceField, quantityField],
  targetField: totalField,
  derive: (v) => (v[priceField] ?? 0.0) * (v[quantityField] ?? 1),
)
```

---

## 📊 Analytics & Debugging

Understand exactly how your users interact with your forms.

### Logging Analytics (Built-in)
See every field change, validation event, and submission in your debug console:

```dart
Formix(
  analytics: const LoggingFormAnalytics(), // Auto-logs to console in debug mode
  child: Column(
    children: [
      // ... fields
    ],
  ),
)
```

---

## 💡 Pro Tips

- 💡 **`keepAlive`**: Maintain state in TabViews/Steppers.
- 💡 **`Formix.of(context)`**: Quick access to the controller provider.
- 💡 **`FormixNavigationGuard`**: Block accidental "Back" button presses when the form is dirty.

---

## 🧬 Advanced Logic

### Multi-Form Synchronization
Link fields between completely separate forms (e.g., a "Profile" form and a "Checkout" form).

```dart
// In your business logic or init
checkoutController.bindField(
  billingAddress,
  sourceController: profileController,
  sourceField: profileAddress,
  twoWay: true, // Optional: Sync both ways
);
```

### Optimistic Updates
Perform immediate UI updates while waiting for async operations (like server saves). If the operation fails, the value automatically reverts.

```dart
await controller.optimisticUpdate(
  fieldId: usernameField,
  value: 'new_username',
  action: () async {
    await api.updateUsername('new_username');
  },
  revertOnError: true, // Default
);
```

### Undo/Redo History
Built-in state history allows you to implement undo/redo functionality effortlessly.

```dart
if (controller.canUndo) controller.undo();
if (controller.canRedo) controller.redo();
```

### Automatic Focus Management
Formix automatically handles focus traversal:
- **Enter-to-Next**: Pressing "Enter" on the keyboard focuses the next field.
- **Submit-to-Error**: On submission failure, the first invalid field is focused and scrolled into view.

```dart
// Enabled by default!
// Customize via textInputAction in FormixFieldConfig
FormixFieldConfig<String>(
  id: emailField,
  textInputAction: TextInputAction.next, // Default
)
```

---

<p align="center">Built with ❤️ for the Flutter Community</p>
