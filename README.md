# Better Form 🚀

A robust, type-safe, and reactive form management package for Flutter built on Riverpod.

**Better Form** provides a modern, declarative approach to form management with compile-time type safety, automatic state management, and seamless integration with Flutter's reactive architecture.

## ✨ Features

- 🔒 **Type-Safe**: Define fields with `BetterFormFieldID<T>` for compile-time safety
- ⚡ **Riverpod-Powered**: Built on Riverpod for efficient state management and dependency injection
- 🎯 **Automatic Controller Management**: `BetterForm` widget handles controller creation automatically
- 🧩 **Flexible Field Widgets**: `RiverpodTextFormField`, `RiverpodNumberFormField`, `RiverpodCheckboxFormField`, etc.
- 🚦 **Smart Validation**: Field-level and cross-field validation with real-time feedback
- 🔄 **Form State Tracking**: Dirty state, validation status, and submission state
- 🔁 **Legacy Compatible**: Supports existing `BetterFormController` API for migration
- 📱 **Flutter Native**: Works with all Flutter form widgets and follows Material Design

---

## 📦 Installation

Add `better_form` to your `pubspec.yaml`:

```yaml
dependencies:
  better_form: ^0.0.1
  flutter_riverpod: ^2.4.0  # Required peer dependency
```

---

## 🚀 Quick Start

### 1. Define Field IDs

Define your fields with type safety:

```dart
import 'package:better_form/better_form.dart';

// Define field IDs globally
final nameField = BetterFormFieldID<String>('name');
final emailField = BetterFormFieldID<String>('email');
final ageField = BetterFormFieldID<num>('age');
final newsletterField = BetterFormFieldID<bool>('newsletter');
```

### 2. Create Your Form

Use the `BetterForm` widget for automatic controller management:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

class UserRegistrationForm extends ConsumerWidget {
  const UserRegistrationForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BetterForm(
      initialValue: {
        'name': '',
        'email': '',
        'age': 18,
        'newsletter': false,
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RiverpodTextFormField(
              fieldId: nameField,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
            ),
            const SizedBox(height: 16),
            RiverpodTextFormField(
              fieldId: emailField,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            RiverpodNumberFormField(
              fieldId: ageField,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
              ),
              min: 0,
              max: 120,
            ),
            const SizedBox(height: 16),
            RiverpodCheckboxFormField(
              fieldId: newsletterField,
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 24),
            const RiverpodFormStatus(),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = BetterForm.of(context)!;
                final controller = ref.read(controllerProvider.notifier);
                final formState = ref.watch(controllerProvider);

                return ElevatedButton(
                  onPressed: formState.isValid ? () {
                    final values = formState.values;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Form submitted! ${values.length} fields')),
                    );
                  } : null,
                  child: const Text('Submit'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Add Validation

Register fields with validation:

```dart
// In your form setup or widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  return BetterForm(
    initialValue: {'email': '', 'password': ''},
    child: Builder(
      builder: (context) {
        // Register validation after BetterForm is in context
        final controllerProvider = BetterForm.of(context);
        if (controllerProvider != null) {
          final controller = ref.read(controllerProvider.notifier);

          // Register fields with validation
          controller.registerField(BetterFormField<String>(
            id: emailField,
            initialValue: '',
            validator: (value) => value.contains('@') ? null : 'Invalid email',
          ));

          controller.registerField(BetterFormField<String>(
            id: passwordField,
            initialValue: '',
            validator: (value) => value.length >= 6 ? null : 'Password too short',
          ));
        }

        return Column(
          children: [
            RiverpodTextFormField(fieldId: emailField),
            RiverpodTextFormField(fieldId: passwordField, obscureText: true),
          ],
        );
      },
    ),
  );
}
```

---

## 🧠 Advanced Features

### Custom Controller Management

For advanced use cases, you can manage controllers manually:

```dart
final myFormControllerProvider = StateNotifierProvider<RiverpodFormController, FormState>(
  (ref) => RiverpodFormController(initialValue: {'custom': 'value'}),
);

class CustomForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        myFormControllerProvider.overrideWith(
          (ref) => RiverpodFormController(initialValue: {'field': 'value'}),
        ),
      ],
      child: Column(
        children: [
          RiverpodTextFormField(
            fieldId: BetterFormFieldID<String>('field'),
            controllerProvider: myFormControllerProvider,
          ),
        ],
      ),
    );
  }
}
```

### Cross-Field Validation

Validate one field based on another's value:

```dart
controller.registerField(BetterFormField<String>(
  id: confirmPasswordField,
  initialValue: '',
  validator: (value) {
    final password = controller.getValue(passwordField);
    return value == password ? null : 'Passwords do not match';
  },
));
```

### Dynamic Field Visibility

Show/hide fields based on other field values:

```dart
class DynamicForm extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider = BetterForm.of(context)!;
    final formState = ref.watch(controllerProvider);
    final showExtra = formState.getValue(showExtraField) ?? false;

    return BetterForm(
      initialValue: {'showExtra': false, 'extra': ''},
      child: Column(
        children: [
          RiverpodCheckboxFormField(
            fieldId: showExtraField,
            title: const Text('Show extra field'),
          ),
          if (showExtra) ...[
            const SizedBox(height: 16),
            RiverpodTextFormField(
              fieldId: BetterFormFieldID<String>('extra'),
              decoration: const InputDecoration(labelText: 'Extra Info'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Form Reset Functionality

```dart
Consumer(
  builder: (context, ref, child) {
    final controllerProvider = BetterForm.of(context)!;
    final controller = ref.read(controllerProvider.notifier);

    return ElevatedButton(
      onPressed: () => controller.reset(),
      child: const Text('Reset Form'),
    );
  },
)
```

### Custom Field Widgets

Create custom form fields by extending `ConsumerStatefulWidget`:

```dart
class CustomColorPicker extends ConsumerStatefulWidget {
  const CustomColorPicker({
    super.key,
    required this.fieldId,
    this.controllerProvider,
  });

  final BetterFormFieldID<Color> fieldId;
  final StateNotifierProvider<RiverpodFormController, FormState>? controllerProvider;

  @override
  ConsumerState<CustomColorPicker> createState() => _CustomColorPickerState();
}

class _CustomColorPickerState extends ConsumerState<CustomColorPicker> {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerProvider = widget.controllerProvider ?? BetterForm.of(context) ?? formControllerProvider(const {});
    final controller = ref.read(controllerProvider.notifier);
    final formState = ref.watch(controllerProvider);
    final currentColor = formState.getValue(widget.fieldId) ?? Colors.blue;

    return GestureDetector(
      onTap: () => controller.setValue(widget.fieldId, Colors.red),
      child: Container(
        width: 50,
        height: 50,
        color: currentColor,
        child: const Center(child: Text('Tap to change')),
      ),
    );
  }
}
```

---

## 📚 API Reference

### Core Classes

#### `BetterFormFieldID<T>`
Type-safe field identifier.

```dart
final nameField = BetterFormFieldID<String>('name');
```

#### `BetterForm`
Automatically manages form controller and provides it to child widgets.

```dart
BetterForm(
  initialValue: {'field': 'value'},  // Map<String, dynamic>
  child: Widget(...),
)
```

### Form Field Widgets

#### `RiverpodTextFormField`
Text input field with validation.

```dart
RiverpodTextFormField(
  fieldId: nameField,
  controllerProvider: optionalCustomProvider,  // Optional
  decoration: InputDecoration(labelText: 'Name'),
  keyboardType: TextInputType.emailAddress,
  maxLength: 100,
)
```

#### `RiverpodNumberFormField`
Numeric input with min/max validation.

```dart
RiverpodNumberFormField(
  fieldId: ageField,
  controllerProvider: optionalCustomProvider,
  decoration: InputDecoration(labelText: 'Age'),
  min: 0,
  max: 120,
)
```

#### `RiverpodCheckboxFormField`
Boolean checkbox input.

```dart
RiverpodCheckboxFormField(
  fieldId: agreeField,
  controllerProvider: optionalCustomProvider,
  title: Text('I agree to terms'),
)
```

#### `RiverpodDropdownFormField<T>`
Dropdown selection input.

```dart
RiverpodDropdownFormField<String>(
  fieldId: priorityField,
  controllerProvider: optionalCustomProvider,
  items: const [
    DropdownMenuItem(value: 'low', child: Text('Low')),
    DropdownMenuItem(value: 'high', child: Text('High')),
  ],
)
```

#### `RiverpodFormStatus`
Displays current form state.

```dart
const RiverpodFormStatus()  // Shows validation and dirty status
```

### Controller API

#### `RiverpodFormController`
Form state management.

```dart
final controller = RiverpodFormController(
  initialValue: {'field': 'value'},
);

// Type-safe value access
String name = controller.getValue(nameField);
controller.setValue(nameField, 'New Name');

// Validation
bool isValid = controller.validate();

// Reset
controller.reset();

// Register fields with validation
controller.registerField(BetterFormField<String>(
  id: emailField,
  initialValue: '',
  validator: (value) => value.contains('@') ? null : 'Invalid email',
));
```

---

## 🎯 Best Practices

### 1. Use BetterForm for Automatic Management
```dart
// ✅ Recommended
BetterForm(
  initialValue: initialData,
  child: FormFields(...),
)

// ❌ Avoid manual controller management unless necessary
final controller = RiverpodFormController(...);
ProviderScope(overrides: [...], child: ...)
```

### 2. Define Field IDs Globally
```dart
// ✅ Good
class FieldIds {
  static final name = BetterFormFieldID<String>('name');
  static final email = BetterFormFieldID<String>('email');
}

// ❌ Avoid
final nameField = BetterFormFieldID<String>('name'); // Inside widget
```

### 3. Handle Validation Properly
```dart
// ✅ Register validation in build context
@override
Widget build(BuildContext context, WidgetRef ref) {
  return BetterForm(
    initialValue: {...},
    child: Builder(
      builder: (context) {
        final controllerProvider = BetterForm.of(context);
        if (controllerProvider != null) {
          final controller = ref.read(controllerProvider.notifier);
          // Register validation here
        }
        return FormFields(...);
      },
    ),
  );
}
```

### 4. Use Type-Safe Field Access
```dart
// ✅ Type-safe
String name = formState.getValue(nameField);

// ❌ Avoid dynamic access
dynamic name = formState.values['name'];
```

### 5. Leverage Form State
```dart
// ✅ Use RiverpodFormStatus for automatic state display
const RiverpodFormStatus()

// ✅ Check form state for conditional logic
final isValid = formState.isValid;
final isDirty = formState.isDirty;
```

---

## ⚠️ Limitations & Considerations

### Current Limitations

1. **Field Registration**: Fields must be registered with validation logic before use. This is typically done in the `build` method.

2. **Controller Scope**: Each `BetterForm` creates its own controller. For shared state across multiple forms, use manual controller management.

3. **Validation Timing**: Validation occurs on field change, not on blur. Consider implementing custom validation triggers if needed.

4. **Nested Forms**: Avoid nesting `BetterForm` widgets as they create separate controller scopes.

### Performance Considerations

- **Provider Creation**: `BetterForm` creates a new provider instance per form. For high-frequency form creation, consider reusing controllers.

- **Field Count**: Large forms (>50 fields) may benefit from manual controller management to optimize rebuilds.

- **Validation Complexity**: Complex cross-field validation may impact performance. Consider debouncing or optimizing validation logic.

### Migration from Other Form Libraries

Better Form is designed to be easy to adopt:

```dart
// From flutter_form_builder
// Before: FormBuilderTextField(name: 'email', validator: ...)
RiverpodTextFormField(fieldId: emailField)

// From form_field_validator
// Before: TextFormField(validator: EmailValidator(...))
controller.registerField(BetterFormField(
  id: emailField,
  validator: (value) => value.contains('@') ? null : 'Invalid email',
));
```

---

## 🤝 Contributing

We welcome contributions! Please:

1. **Report Issues**: Use GitHub issues for bugs and feature requests
2. **Submit PRs**: Ensure tests pass and code follows our style
3. **Add Tests**: New features should include comprehensive tests
4. **Update Docs**: Keep README and examples current

### Development Setup

```bash
# Clone and setup
git clone https://github.com/your-repo/better_form.git
cd better_form
flutter pub get

# Run tests
flutter test

# Run example
cd example && flutter run
```

---

## 📄 License

MIT License - see LICENSE file for details.

---

## 🙏 Acknowledgments

Built with ❤️ using [Riverpod](https://riverpod.dev) for state management and following Flutter's design principles.
