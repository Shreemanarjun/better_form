# Formix 🚀

<p align="center">
  <img src="https://zmozkivkhopoeutpnnum.supabase.co/storage/v1/object/public/images/formix.png" alt="Formix Logo" width="200"/>
</p>

<p align="center">
<a href="https://pub.dev/packages/formix"><img src="https://img.shields.io/pub/v/formix.svg" alt="Pub"></a>
<a href="https://github.com/Shreemanarjun/formix/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
<img src="https://img.shields.io/badge/coverage-93%25-brightgreen" alt="Code Coverage">
<img src="https://img.shields.io/badge/tests-1000%2B-brightgreen" alt="Tests">
<img src="https://img.shields.io/badge/version-0.0.1-blue" alt="Version">
</p>

<p align="center">
  <a href="https://formix.shreeman.dev"><strong>Full Documentation</strong></a>
</p>

An elite, type-safe, and ultra-reactive form engine for Flutter. Powered by Riverpod, Formix delivers lightning-fast performance and effortless memory management, whether you're building a simple contact form or a massive, multi-section enterprise dashboard.

## 📦 Installation

Add `formix` to your `pubspec.yaml`:

```yaml
dependencies:
  formix: ^0.0.1
  flutter_riverpod: ^2.5.1
```

Or run:
```bash
flutter pub add formix
```

---

## ⚡ Quick Start (For Beginners)

The fastest way to build a type-safe form in 3 minutes.

### 1. Define your fields
```dart
final emailField = FormixFieldID<String>('email');
final ageField = FormixFieldID<int>('age');
```

### 2. Wrap your app in a Scope
```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

### 3. Build the Form
```dart
Formix(
  child: Column(
    children: [
      RiverpodTextFormField(
        fieldId: emailField,
        decoration: InputDecoration(labelText: 'Email'),
      ),
      RiverpodNumberFormField(
        fieldId: ageField,
        decoration: InputDecoration(labelText: 'Age'),
      ),
      FormixBuilder(
        builder: (context, scope) => ElevatedButton(
          onPressed: () => scope.submit(
            onValid: (values) => print('Saving: $values'),
          ),
          child: Text('Submit'),
        ),
      ),
    ],
  ),
)
```

---

## ✨ Features

- 🔒 **True Type Safety**: No more `map['key'] as String`. Use `FormixFieldID<T>`.
- 🚀 **Extreme Performance**: Only the specific field widget rebuilds when its value changes.
- 🗑️ **Zero Memory Leaks**: Controllers are automatically disposed via Riverpod's `autoDispose`.
- 🚥 **Flexible Validation**: Sync, Async, Debounced, and Cross-field rules.
- 🏗️ **Lazy Sections**: Built for massive forms. Register fields only when UI is built.
- 💾 **Persistence**: Built-in support for saving draft state automatically.
- 🎯 **UX First**: Automated scrolling to errors, focus management, and navigation guards.
- 🔑 **GlobalKey Access**: Control forms from anywhere using `GlobalKey<FormixState>` (like FormBuilder).
- 🔔 **Form Callbacks**: React to changes with `onChanged` for auto-save and analytics.
- 🎭 **Multi-Form Support**: Parallel and nested forms with complete state isolation.

---

## 📖 Essential Guide

### Defining Field Configuration
While `Formix` works with zero setup, you can define rules globally or locally using `FormixFieldConfig`.

```dart
Formix(
  fields: [
    FormixFieldConfig<String>(
      id: emailField,
      label: 'User Email',
      validator: (val) => val.contains('@') ? null : 'Invalid email',
      initialValue: 'guest@example.com',
    ),
  ],
  child: ...
)
```

### Accessing Values & State
Use `FormixScope` (via `FormixBuilder` or `FormixWidget`) for the cleanest API.

```dart
FormixBuilder(
  builder: (context, scope) {
    // Reactive: Rebuilds whenever 'age' changes
    final age = scope.watchValue(ageField);

    // Non-reactive: Get value without rebuilt
    final currentAge = scope.getValue(ageField);

    return Text('Age is $age');
  },
)
```

---

## 🛠️ Professional Guide

### 1. Custom Field Implementation
Extend `FormixFieldWidget` to create pixel-perfect custom inputs with zero boilerplate.

```dart
class CustomToggleField extends FormixFieldWidget<bool> {
  const CustomToggleField({required super.fieldId});

  @override
  Widget buildForm(BuildContext context, FormixScope scope) {
    final value = scope.watchValue(fieldId) ?? false;

    return SwitchListTile(
      value: value,
      onChanged: (v) => scope.setValue(fieldId, v),
      title: Text('Toggle Me'),
    );
  }
}
```

### 2. Data Loss Prevention
Use `FormixNavigationGuard` to stop users from accidentally navigating away after they've spent time filling out a form.

```dart
Formix(
  child: FormixNavigationGuard(
    // Shows a default confirmation dialog if form is dirty
    child: MyFormBody(),
  ),
)
```

### 3. Sectional & Lazy Scaling
For huge forms, use `FormixSection`. Fields are only registered when they enter the widget tree.

```dart
ListView(
  children: [
    FormixSection(
      fields: [ /* Section 1 Configs */ ],
      child: StepOneWidgets(),
    ),
    FormixSection(
      fields: [ /* Section 2 Configs */ ],
      child: StepTwoWidgets(),
    ),
  ],
)
```

### 4. Performance Monitoring
During development, use `FormixFieldPerformanceMonitor` to ensure your custom widgets aren't rebuilding too often.

```dart
FormixFieldPerformanceMonitor<String>(
  fieldId: nameField,
  builder: (context, info, rebuildCount) {
    return Column(
      children: [
        Text('Rebuilds: $rebuildCount'),
        MyWidget(info.value),
      ],
    );
  },
)
```

### 4. Simplified Usage with Builders or Base Classes
Custom widgets can leverage `FormixScope` for an effortless development experience. `FormixScope` provides high-performance reactive accessors and a powerful `submit` helper.

#### Using `FormixBuilder`
```dart
FormixBuilder(
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

#### Extending `FormixWidget`
```dart
class FormStatusPanel extends FormixWidget {
  const FormStatusPanel({super.key});

  @override
  Widget buildForm(BuildContext context, FormixScope scope) {
    // Rebuilds ONLY when 'name' or validation for 'email' changes
    final name = scope.watchValue(nameField);
    final emailError = scope.watchError(emailField);
    final isValidating = scope.watchIsValidating(emailField);

    return Column(
      children: [
        if (name != null) Text('Welcome, $name'),
        if (isValidating) const CircularProgressIndicator(),
        if (emailError != null) Text(emailError, style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

### 5. External Form Control with GlobalKey
Access and control your form from outside its widget tree using `GlobalKey<FormixState>` - perfect for AppBar actions, floating buttons, or external validation triggers.

```dart
class MyFormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormixState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Access form from anywhere!
              final controller = _formKey.currentState?.controller;
              final data = _formKey.currentState?.data;

              if (data?.isValid ?? false) {
                print('Saving: ${data?.values}');
                controller?.submit(
                  onValid: (values) async {
                    await saveToServer(values);
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Formix(
        key: _formKey,
        initialValue: {'name': 'John', 'email': 'john@example.com'},
        child: Column(
          children: [
            RiverpodTextFormField(fieldId: nameField),
            RiverpodTextFormField(fieldId: emailField),
          ],
        ),
      ),
    );
  }
}
```

### 6. Form Change Callbacks
React to any value change in your form with the `onChanged` callback - ideal for auto-save, analytics, or real-time validation.

```dart
Formix(
  initialValue: {'name': '', 'email': ''},
  onChanged: (values) {
    // Triggered whenever ANY field changes
    print('Form updated: $values');

    // Auto-save draft
    saveDraft(values);

    // Track analytics
    analytics.logFormProgress(values.length);
  },
  child: MyFormFields(),
)
```

### 7. Multiple Forms: Parallel & Nested
Formix seamlessly handles multiple independent forms on the same screen, or nested forms for complex hierarchical data.

#### Parallel Forms (Independent)
```dart
Column(
  children: [
    // Form 1: User Info
    Formix(
      key: ValueKey('user_form'),
      initialValue: {'name': 'Alice'},
      child: Column(
        children: [
          Text('User Information'),
          RiverpodTextFormField(fieldId: nameField),
          FormixBuilder(
            builder: (context, scope) => ElevatedButton(
              onPressed: () => scope.submit(
                onValid: (values) => saveUser(values),
              ),
              child: Text('Save User'),
            ),
          ),
        ],
      ),
    ),

    Divider(),

    // Form 2: Company Info (completely independent)
    Formix(
      key: ValueKey('company_form'),
      initialValue: {'company': 'Acme Corp'},
      child: Column(
        children: [
          Text('Company Information'),
          RiverpodTextFormField(fieldId: companyField),
          FormixBuilder(
            builder: (context, scope) => ElevatedButton(
              onPressed: () => scope.submit(
                onValid: (values) => saveCompany(values),
              ),
              child: Text('Save Company'),
            ),
          ),
        ],
      ),
    ),
  ],
)
```

#### Nested Forms (Hierarchical)
```dart
// Outer form: Order details
Formix(
  initialValue: {'orderId': '12345', 'status': 'pending'},
  child: Column(
    children: [
      RiverpodTextFormField(fieldId: orderIdField),
      RiverpodTextFormField(fieldId: statusField),

      // Inner form: Shipping address (isolated scope)
      Formix(
        initialValue: {
          'street': '123 Main St',
          'city': 'New York',
          'zip': '10001',
        },
        child: FormixBuilder(
          builder: (context, scope) {
            // This scope only sees shipping fields
            return Column(
              children: [
                Text('Shipping Address'),
                RiverpodTextFormField(fieldId: streetField),
                RiverpodTextFormField(fieldId: cityField),
                RiverpodTextFormField(fieldId: zipField),
                ElevatedButton(
                  onPressed: () => scope.submit(
                    onValid: (address) => validateAddress(address),
                  ),
                  child: Text('Validate Address'),
                ),
              ],
            );
          },
        ),
      ),
    ],
  ),
)
```

**Key Benefits:**
- ✅ Each form maintains its own state, validation, and dirty tracking
- ✅ Nested forms can share field IDs without conflicts
- ✅ Submit, reset, and validation are scoped to each form
- ✅ Perfect for wizards, multi-step flows, or complex data entry

#### Multi-Step Wizard with Validation
Build complex multi-step forms with independent validation per step using GlobalKey for external control:

```dart
class RegistrationWizard extends StatefulWidget {
  @override
  State<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends State<RegistrationWizard> {
  int _currentStep = 0;

  // GlobalKeys for each step
  final _step1Key = GlobalKey<FormixState>();
  final _step2Key = GlobalKey<FormixState>();
  final _step3Key = GlobalKey<FormixState>();

  // Field IDs
  final nameField = FormixFieldID<String>('name');
  final emailField = FormixFieldID<String>('email');
  final addressField = FormixFieldID<String>('address');
  final cityField = FormixFieldID<String>('city');
  final termsField = FormixFieldID<bool>('terms');

  bool _canProceed() {
    final currentKey = [_step1Key, _step2Key, _step3Key][_currentStep];
    return currentKey.currentState?.data.isValid ?? false;
  }

  void _onStepContinue() {
    if (_canProceed()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
      } else {
        _submitForm();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix errors before continuing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: _onStepContinue,
      onStepCancel: () => setState(() => _currentStep--),
      steps: [
        Step(
          title: Text('Personal Info'),
          content: ProviderScope(
            child: Formix(
              key: _step1Key,
              fields: [
                FormixFieldConfig<String>(
                  id: nameField,
                  validator: (v) => v.isEmpty ? 'Required' : null,
                ),
                FormixFieldConfig<String>(
                  id: emailField,
                  validator: (v) => v.contains('@') ? null : 'Invalid email',
                ),
              ],
              child: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: nameField,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  RiverpodTextFormField(
                    fieldId: emailField,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Step(
          title: Text('Address'),
          content: ProviderScope(
            child: Formix(
              key: _step2Key,
              fields: [
                FormixFieldConfig<String>(
                  id: addressField,
                  validator: (v) => v.isEmpty ? 'Required' : null,
                ),
                FormixFieldConfig<String>(
                  id: cityField,
                  validator: (v) => v.isEmpty ? 'Required' : null,
                ),
              ],
              child: Column(
                children: [
                  RiverpodTextFormField(
                    fieldId: addressField,
                    decoration: InputDecoration(labelText: 'Street Address'),
                  ),
                  RiverpodTextFormField(
                    fieldId: cityField,
                    decoration: InputDecoration(labelText: 'City'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Step(
          title: Text('Confirm'),
          content: ProviderScope(
            child: Formix(
              key: _step3Key,
              fields: [
                FormixFieldConfig<bool>(
                  id: termsField,
                  validator: (v) => v ? null : 'Must accept terms',
                ),
              ],
              child: FormixBuilder(
                builder: (context, scope) {
                  final accepted = scope.watchValue(termsField) ?? false;
                  return CheckboxListTile(
                    title: Text('I accept the terms and conditions'),
                    value: accepted,
                    onChanged: (v) => scope.setValue(termsField, v ?? false),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

**See the full example**: Check `example/lib/ui/multi_step_form/multi_step_form_page.dart` for a complete 4-step registration form with validation, progress tracking, and data collection.

### 8. Dynamic Form Arrays
Manage lists of dynamic inputs easily with `FormixArray`.

```dart
final friendsArray = FormixArrayID<String>('friends');

FormixArray<String>(
  id: friendsArray,
  builder: (context, index, friendId, scope) {
    return Row(
      children: [
        Expanded(child: RiverpodTextFormField(fieldId: friendId)),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => scope.removeArrayItemAt(friendsArray, index),
        ),
      ],
    );
  },
)

// Add new items via scope
scope.addArrayItem(friendsArray, 'New Friend');
```

---

## 🧠 Advanced Features

### 1. Lazy Loading & Sectional Forms
For massive forms (100+ fields), you can organize fields into sections using `FormixSection`. This allows:
- **Optimization**: Fields are only registered when the section is built (e.g., when scrolled into view in a `ListView`).
- **Organization**: Cleanly group logical parts of your form.
- **Dynamic Forms**: Easily add/remove entire sets of fields based on user interaction.

```dart
Formix(
  child: ListView(
    children: [
      // Standard header
      const Text('Profile Information'),

      // Registered immediately
      FormixSection(
        fields: [ firstNameConfig, lastNameConfig ],
        child: Column(children: [ ... ]),
      ),

      const SizedBox(height: 1000), // Long gap

      // Only registered when user scrolls down
      FormixSection(
        fields: [ bioConfig, websiteConfig ],
        keepAlive: true, // Keep values even if scrolled out of view
        child: ProfileBioSection(),
      ),
    ],
  ),
)
```

### 2. Cross-Field Dependencies
Use `FormixDependentField` to conditionally render UI based on other field values. This is much more efficient than rebuilding the whole form.

```dart
// Only show the "Spouse Name" field if "Marital Status" is "Married"
FormixDependentField<String>(
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

### 3. Programmatic Control
Directly control focus and scrolling within your form through the `FormixScope`.

```dart
FormixBuilder(
  builder: (context, scope) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => scope.focusField(emailField),
          child: Text('Jump to Email'),
        ),
        ElevatedButton(
          onPressed: () => scope.focusFirstError(),
          child: Text('Fix Errors'),
        ),
        ElevatedButton(
          onPressed: () => scope.scrollToField(lastFieldId),
          child: Text('Scroll to Bottom'),
        ),
      ],
    );
  },
)
```

### 2. State Persistence
Automatically save form progress to local storage (or any other source) so users don't lose data on app restart or crash.

Implement the simple `FormixPersistence` interface:

```dart
class MyPrefsPersistence implements FormixPersistence {
  @override
  Future<void> saveFormState(String formId, Map<String, dynamic> values) async {
    // Save to SharedPreferences / Hive / Database
  }

  // ... implement getSavedState and clearSavedState
}
```

Then attach it to your form:

```dart
Formix(
  formId: 'registration_wizard', // Unique ID for this form
  persistence: MyPrefsPersistence(),
  child: ...
)
```

---

## 💡 Pro Tips: Usability & State Management

Enhance your form's resilience and user experience with these three powerful features.

### 1. `keepAlive`: Preserving State Across Navigation
By default, Formix automatically disposes of its state when the widget is unmounted to save memory. However, in multi-step forms (like wizards or tabs) where the user navigates back and forth, you don't want to lose their data.

Set `keepAlive: true` to preserve the form state in memory even if the widget is temporarily removed from the tree.

```dart
Formix(
  keepAlive: true, // Prevents auto-disposal
  child: MyFormStep(),
)
```

### 2. `formId`: Identification for Persistence
When using `FormixPersistence` to save drafts, `formId` is **required**. It acts as the unique key to store and retrieve data for this specific form instance.

```dart
Formix(
  formId: 'user_onboarding_v1', // Must be unique across the app
  persistence: MyLocalPersistence(),
  child: ...
)
```

### 3. Off-Stage Widget Registering
In complex layouts like `IndexedStack`, `PageView`, or tabs, some field widgets might be "off-stage" (not yet built). By default, Formix only knows about fields that have been rendered. This causes issues if you try to `validate()` a form where required fields haven't been built yet—they effectively don't exist.

To fix this, **pre-register** your fields by passing them to the `Formix` constructor. This ensures the controller knows about them immediately, allowing for full validation even if the UI is hidden.

```dart
final nameField = FormixFieldID<String>('name');
final bioField = FormixFieldID<String>('bio');

Formix(
  // Register fields upfront so validation works even if widgets aren't built
  fields: [
    FormixFieldConfig<String>(id: nameField, validator: (v) => v.isNotEmpty ? null : 'Required'),
    FormixFieldConfig<String>(id: bioField, validator: (v) => v.isNotEmpty ? null : 'Required'),
  ],
  child: IndexedStack(
    index: _currentIndex,
    children: [
      // Step 1: Visible
      RiverpodTextFormField(fieldId: nameField),

      // Step 2: Hidden (Off-stage), but still validated thanks to 'fields' above!
      RiverpodTextFormField(fieldId: bioField),
    ],
  ),
)
```

---


## 🚦 Error Handling & Advanced UI

### Focus & Error Management
Guide your users directly to what needs fixing.

```dart
scope.submit(
  onInvalid: (errors) {
    // Automatically focus the first field with an error
    // and scroll it into view.
    scope.focusFirstError();
  },
  onValid: (values) async {
    try {
      await api.save(values);
    } catch (e) {
      // Manually set an error from the server
      scope.setFieldError(emailField, 'Account already exists');
    }
  }
)
```

### Handling Async Validation
Formix automatically handles the "Validating" state. You can customize the loading UI:

```dart
FormixFieldConfig<String>(
  id: usernameField,
  asyncValidator: (val) => checkRepo(val),
  // debouncing is default to 300ms
  debounceDuration: Duration(seconds: 1),
)
```

### Common Pitfalls (Troubleshooting)

| Issue | Solution |
| :--- | :--- |
| **"No Formix found"** | Ensure all fields are descendants of a `Formix` widget. |
| **"No Material widget found"** | `RiverpodTextFormField` and others require a `Material` / `Scaffold` ancestor. |
| **Field doesn't rebuild** | Ensure you are using `scope.watchValue(id)` or `ref.watch(fieldValueProvider(id))`. |
| **Custom field not registering** | If using `FormixFieldWidget`, it registers itself. If building from scratch, use `FormixSection` or `controller.registerField`. |

---

### Widgets
- **`Formix`**: Root widget context.
- **`FormixBuilder`**: Builder widget with controller and state.
- **`FormixWidget`**: Base class for custom form widgets.
- **`FormixSection`**: Lazy field registration and sectional organization.
- **`RiverpodTextFormField`**: Text input.
- **`RiverpodNumberFormField`**: Numeric input (int/double).
- **`RiverpodCheckboxFormField`**: Boolean checkbox.
- **`RiverpodDropdownFormField`**: Selection from list.
- **`FormixDependentField`**: Reactive builder for dependencies.
- **`RiverpodFormStatus`**: Debug/Status display.

### Classes
- **`FormixFieldID<T>`**: Typed identifier key.
- **`FormixFieldConfig<T>`**: Configuration (validator, label, initialValue, etc).
- **`FormixState`**: The immutable state containing all field values and errors.
- **`RiverpodFormController`**: The brain ensuring state management.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
