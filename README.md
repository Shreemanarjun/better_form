# Better Form 🚀

A high-performance, type-safe, and reactive form management package for Flutter built on Riverpod with automatic memory management.

## ✨ Features

- 🔒 **Type-Safe**: Define fields with `BetterFormFieldID<T>` for compile-time safety
- ⚡ **High-Performance**: Riverpod selectors prevent unnecessary rebuilds - only affected widgets update
- 🗑️ **Auto-Disposable**: Controllers automatically clean up memory when no longer needed
- 🧩 **Flexible Field Widgets**: Text, Number, Checkbox, Dropdown, and more
- 🚦 **Smart Validation**:
  - Synchronous & Async Validation
  - Debouncing support
  - Cross-field dependencies
- 💾 **State Persistence**: Automatically save/restore form progress
- 🏗️ **Sectional Forms**: Lazy-load and organize massive forms (100+ fields) with `BetterFormSection`
- 🎨 **Declarative API**: Define form structure clearly using `BetterFormFieldConfig`
- 📱 **Flutter Native**: Works with standard Flutter widgets

---

## 📦 Installation

Add `better_form` to your `pubspec.yaml`:

```yaml
dependencies:
  better_form: ^0.0.1
  flutter_riverpod: ^2.5.1
```

---

## 🚀 Basic Usage

### 1. Define Field IDs
Define unique, typed identifiers for your fields.

```dart
final nameField = BetterFormFieldID<String>('name');
final ageField = BetterFormFieldID<num>('age');
final termsField = BetterFormFieldID<bool>('terms');
```

### 2. Create the Form
Use `BetterForm` to initialize your form. It automatically creates and provides a `RiverpodFormController`.

```dart
BetterForm(
  initialValue: const {'name': '', 'age': 18, 'terms': false},
  fields: [
    BetterFormFieldConfig<String>(
      id: nameField,
      label: 'Full Name',
      validator: (val) => val.isEmpty ? 'Name required' : null,
    ),
    BetterFormFieldConfig<num>(
      id: ageField,
      label: 'Age',
      validator: (val) => val < 18 ? 'Must be 18+' : null,
    ),
  ],
  child: Column(
    children: [
      RiverpodTextFormField(fieldId: nameField),
      const SizedBox(height: 16),
      RiverpodNumberFormField(fieldId: ageField),
      const SizedBox(height: 16),
      RiverpodCheckboxFormField(
        fieldId: termsField,
        title: const Text('Accept Terms'),
      ),
      const SizedBox(height: 24),
      SubmitButton(),
    ],
  ),
)
```

### 3. Submit Data
Access the controller to validate and retrieve values.

```dart
Consumer(
  builder: (context, ref, child) {
    // Get the nearest form controller
    final controllerProvider = BetterForm.of(context)!;
    final formState = ref.watch(controllerProvider);
    final controller = ref.read(controllerProvider.notifier);

    return ElevatedButton(
      onPressed: formState.isValid ? () {
        if (controller.validate()) {
          print(formState.values); // {'name': 'John', 'age': 25, ...}
        }
      } : null,
      child: const Text('Submit'),
    );
  },
)
```

---

## 🚦 Smart Validation Guide

Better Form supports comprehensive validation strategies.

### Synchronous Validation
Simple checks that return immediately.
```dart
BetterFormFieldConfig<String>(
  id: nameField,
  validator: (val) {
    if (val.length < 3) return 'Too short';
    return null; // Valid
  }
)
```

### Asynchronous Validation with Debounce
Perfect for network checks (e.g., checking if a username is taken).
```dart
BetterFormFieldConfig<String>(
  id: usernameField,
  debounceDuration: const Duration(milliseconds: 500), // Wait for typing to stop
  asyncValidator: (value) async {
    final available = await api.checkAvailability(value);
    return available ? null : 'Username taken';
  },
)
```
*The field will automatically show a loading spinner while validating.*

### Cross-Field Validation
Validating one field based on another (e.g., "Confirm Password").
```dart
// Unlike per-field validators, this logic typically lives in your submit handler or
// a custom listener if you need real-time feedback.
if (formState.getValue(passwordField) != formState.getValue(confirmField)) {
  // Handle error manually or invalidate field
  controller.invalidateField(confirmField, 'Passwords must match');
}
```

---

## 🧩 Building Custom Form Fields

You can build any custom input widget that integrates with Better Form.

1. **Watch the State**: Use `fieldValueProvider` to get the current value.
2. **Update the State**: Use `controller.setValue` to update it.
3. **Show Errors**: Use `fieldValidationProvider` to see error messages.

```dart
class MyCustomRatingField extends ConsumerWidget {
  final BetterFormFieldID<int> fieldId;
  const MyCustomRatingField({required this.fieldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Controller
    final controllerProvider = BetterForm.of(context)!;
    final controller = ref.read(controllerProvider.notifier);

    // 2. Watch specific field state
    final value = ref.watch(fieldValueProvider(fieldId)) ?? 0;
    final validation = ref.watch(fieldValidationProvider(fieldId));

    return Column(
      children: [
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(index < value ? Icons.star : Icons.star_border),
              onPressed: () => controller.setValue(fieldId, index + 1),
            );
          }),
        ),
        if (!validation.isValid)
          Text(validation.errorMessage!, style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

### 4. Simplified Usage with Builders or Base Classes
Custom widgets can leverage `BetterFormScope` for an effortless development experience. `BetterFormScope` provides high-performance reactive accessors and a powerful `submit` helper.

#### Using `BetterFormBuilder`
```dart
BetterFormBuilder(
  builder: (context, scope) {
    final isValid = scope.watchIsValid;
    final isSubmitting = scope.watchIsSubmitting;

    return ElevatedButton(
      onPressed: (isValid && !isSubmitting)
        ? () => scope.submit(onValid: (values) async => print(values))
        : null,
      child: Text(isSubmitting ? 'Submitting...' : 'Submit'),
    );
  },
)
```

#### Extending `BetterFormWidget`
```dart
class FormStatusPanel extends BetterFormWidget {
  const FormStatusPanel({super.key});

  @override
  Widget buildForm(BuildContext context, BetterFormScope scope) {
    // Rebuilds ONLY when 'name' or validation for 'email' changes
    final name = scope.watchValue(nameField);
    final emailError = scope.watchError(emailField);

    return Column(
      children: [
        if (name != null) Text('Welcome, $name'),
        if (emailError != null) Text(emailError, style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

---

## 🧠 Advanced Features

### 1. Lazy Loading & Sectional Forms
For massive forms (100+ fields), you can organize fields into sections using `BetterFormSection`. This allows:
- **Optimization**: Fields are only registered when the section is built (e.g., when scrolled into view in a `ListView`).
- **Organization**: Cleanly group logical parts of your form.
- **Dynamic Forms**: Easily add/remove entire sets of fields based on user interaction.

```dart
BetterForm(
  child: ListView(
    children: [
      // Standard header
      const Text('Profile Information'),

      // Registered immediately
      BetterFormSection(
        fields: [ firstNameConfig, lastNameConfig ],
        child: Column(children: [ ... ]),
      ),

      const SizedBox(height: 1000), // Long gap

      // Only registered when user scrolls down
      BetterFormSection(
        fields: [ bioConfig, websiteConfig ],
        keepAlive: true, // Keep values even if scrolled out of view
        child: ProfileBioSection(),
      ),
    ],
  ),
)
```

### 2. Cross-Field Dependencies
Use `BetterDependentField` to conditionally render UI based on other field values. This is much more efficient than rebuilding the whole form.

```dart
// Only show the "Spouse Name" field if "Marital Status" is "Married"
BetterDependentField<String>(
  fieldId: maritalStatusField,
  builder: (context, status) {
    if (status == 'Married') {
      return RiverpodTextFormField(
        fieldId: spouseNameField,
        decoration: const InputDecoration(labelText: 'Spouse Name'),
      );
    }
    return const SizedBox.shrink();
  },
)
```

### 2. State Persistence
Automatically save form progress to local storage (or any other source) so users don't lose data on app restart or crash.

Implement the simple `BetterFormPersistence` interface:

```dart
class MyPrefsPersistence implements BetterFormPersistence {
  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> values) async {
    // Save to SharedPreferences / Hive / Database
  }

  // ... implement getSavedState and clearSavedState
}
```

Then attach it to your form:

```dart
BetterForm(
  formId: 'registration_wizard', // Unique ID for this form
  persistence: MyPrefsPersistence(),
  child: ...
)
```

---

## ⚡ Performance Deep Dive

Better Form is built on **Riverpod**, which offers significant performance advantages compared to traditional `ChangeNotifier` or `setState` approaches for forms.

- **Selectors**: Typically, watching a FormController causes a rebuild whenever *any* field changes. Better Form exposes specific providers (`fieldValueProvider`, `fieldValidationProvider`) that use Riverpod's `select` syntax. A text field only rebuilds when *its specific value* changes, not when a sibling checkbox is toggled.
- **Auto-Dispose**: Controllers handle their own lifecycle. If a user navigates away, the form state is automatically cleaned up (unless you explicitly keep it alive), preventing memory leaks.

---

## ⚠️ Limitations

While powerful, be aware of current constraints:
- **Complex Nested Lists**: Arrays of objects (e.g., a dynamic list of addresses) are currently manual. You manage the list structure yourself and register fields with unique IDs (e.g., `address_0_street`, `address_1_street`). Direct `FormArray` support is planned.
- **Controller Access**: You must ensure `BetterForm` is an ancestor of your fields. If you need fields in a different route (e.g., a wizard flow), you'll need to pass the controller provider or lift the state up.

---

## 📚 API Reference

### Widgets
- **`BetterForm`**: Root widget context.
- **`BetterFormBuilder`**: Builder widget with controller and state.
- **`BetterFormWidget`**: Base class for custom form widgets.
- **`BetterFormSection`**: Lazy field registration and sectional organization.
- **`RiverpodTextFormField`**: Text input.
- **`RiverpodNumberFormField`**: Numeric input (int/double).
- **`RiverpodCheckboxFormField`**: Boolean checkbox.
- **`RiverpodDropdownFormField`**: Selection from list.
- **`BetterDependentField`**: Reactive builder for dependencies.
- **`RiverpodFormStatus`**: Debug/Status display.

### Classes
- **`BetterFormFieldID<T>`**: Typed identifier key.
- **`BetterFormFieldConfig<T>`**: Configuration (validator, label, initialValue, etc).
- **`RiverpodFormController`**: The brain ensuring state management.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
