# Better Form 🚀

A high-performance, type-safe, and reactive form management package for Flutter built on Riverpod with automatic memory management.

**Better Form** provides a modern, declarative approach to form management with compile-time type safety, optimized performance through Riverpod selectors, auto-disposable controllers, and seamless integration with Flutter's reactive architecture.

## ✨ Features

- 🔒 **Type-Safe**: Define fields with `BetterFormFieldID<T>` for compile-time safety
- ⚡ **High-Performance**: Riverpod selectors prevent unnecessary rebuilds - only affected widgets update
- 🗑️ **Auto-Disposable**: Controllers automatically clean up memory when no longer needed
- 🎯 **Automatic Controller Management**: `BetterForm` widget handles controller creation automatically
- 🧩 **Flexible Field Widgets**: `RiverpodTextFormField`, `RiverpodNumberFormField`, `RiverpodCheckboxFormField`, etc.
- 🚦 **Smart Validation**: Field-level and cross-field validation with real-time feedback
- 🔄 **Form State Tracking**: Dirty state, validation status, and submission state
- 🔁 **Legacy Compatible**: Supports existing `BetterFormController` API for migration
- 📱 **Flutter Native**: Works with all Flutter form widgets and follows Material Design
- 🎨 **Provider Flexibility**: Support for custom controllers and BetterForm integration

## ⚡ Performance & Memory Management

### Riverpod Selectors for Optimal Performance

Better Form uses Riverpod selectors to ensure only affected widgets rebuild when form state changes:

```dart
// Before: Any field change → ALL widgets rebuild
final formState = ref.watch(controllerProvider); // Watches entire state
final value = formState.getValue(fieldId);

// After: Only specific field widgets rebuild
final value = ref.watch(fieldValueProvider(fieldId)); // Selective watching
final validation = ref.watch(fieldValidationProvider(fieldId));
final isDirty = ref.watch(fieldDirtyProvider(fieldId));
```

**Performance Benefits:**
- **Granular Updates**: Only widgets displaying changed data rebuild
- **Reduced CPU Usage**: Fewer unnecessary widget rebuilds
- **Better UX**: Smoother interactions in complex forms
- **Scalable**: Performance remains consistent with form size

### Auto-Disposable Controllers

Controllers automatically clean up when no longer needed:

```dart
// Automatic disposal - no manual cleanup required
final formControllerProvider = StateNotifierProvider.autoDispose.family<
    RiverpodFormController,
    FormState,
    Map<String, dynamic>>((ref, initialValue) {
  return RiverpodFormController(initialValue: initialValue);
  // Controller automatically disposed when provider is no longer used
});
```

**Memory Benefits:**
- **Leak Prevention**: Controllers disposed when widgets unmount
- **Resource Cleanup**: Automatic memory management
- **Long-Running Apps**: No memory accumulation over time
- **Zero Configuration**: Works out-of-the-box

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

### 2. Create Your Form (Declarative API - Recommended)

Use the `BetterForm` widget with declarative field configuration for automatic registration:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

// Define field IDs globally
final nameField = BetterFormFieldID<String>('name');
final emailField = BetterFormFieldID<String>('email');
final ageField = BetterFormFieldID<num>('age');
final newsletterField = BetterFormFieldID<bool>('newsletter');

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
      fields: const [
        BetterFormFieldConfig<String>(
          id: nameField,
          initialValue: '',
          validator: _validateName,
          label: 'Full Name',
          hint: 'Enter your full name',
        ),
        BetterFormFieldConfig<String>(
          id: emailField,
          initialValue: '',
          validator: _validateEmail,
          label: 'Email',
          hint: 'Enter your email',
        ),
        BetterFormFieldConfig<num>(
          id: ageField,
          initialValue: 18,
          validator: _validateAge,
          label: 'Age',
          hint: 'Enter your age',
        ),
        BetterFormFieldConfig<bool>(
          id: newsletterField,
          initialValue: false,
          label: 'Newsletter',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            RiverpodTextFormField(fieldId: nameField),
            const SizedBox(height: 16),
            RiverpodTextFormField(
              fieldId: emailField,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            RiverpodNumberFormField(
              fieldId: ageField,
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

  static String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Invalid email format';
    return null;
  }

  static String? _validateAge(num? value) {
    if (value == null) return 'Age is required';
    if (value < 0) return 'Age cannot be negative';
    if (value > 120) return 'Age must be realistic';
    return null;
  }
}
```

### 2b. Create Your Form (Manual API - Legacy)

For advanced use cases or migration from existing code:

```dart
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
      child: Builder(
        builder: (context) {
          // Manual field registration in build context
          final controllerProvider = BetterForm.of(context);
          if (controllerProvider != null) {
            final controller = ref.read(controllerProvider.notifier);
            // Register validation here (legacy approach)
            controller.registerField(BetterFormField<String>(
              id: emailField,
              initialValue: '',
              validator: (value) => value.contains('@') ? null : 'Invalid email',
            ));
          }

          return Column(
            children: [
              RiverpodTextFormField(fieldId: nameField),
              RiverpodTextFormField(fieldId: emailField),
              // ... other fields
            ],
          );
        },
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

## 📋 FormFieldSchema - Declarative Form Definition

For complex forms with advanced validation, dynamic behavior, and type safety, Better Form provides a **declarative schema system** that defines your entire form structure in one place.

### Schema-Based Form Definition

Define your form using schema classes instead of imperative widget configuration:

```dart
import 'package:better_form/better_form.dart';

// Define field IDs
final nameField = BetterFormFieldID<String>('name');
final emailField = BetterFormFieldID<String>('email');
final ageField = BetterFormFieldID<num>('age');
final newsletterField = BetterFormFieldID<bool>('newsletter');
final spouseNameField = BetterFormFieldID<String>('spouseName');

// Create form schema
final userRegistrationSchema = FormSchema(
  name: 'User Registration',
  description: 'Register a new user account',
  fields: [
    // Text field with validation
    TextFieldSchema(
      id: nameField,
      initialValue: '',
      label: 'Full Name',
      hint: 'Enter your full name',
      isRequired: true,
      minLength: 2,
      maxLength: 50,
    ),

    // Email with pattern validation
    TextFieldSchema(
      id: emailField,
      initialValue: '',
      label: 'Email Address',
      hint: 'Enter your email',
      isRequired: true,
      validator: (value) => value.contains('@') ? null : 'Invalid email',
    ),

    // Number with range validation
    NumberFieldSchema(
      id: ageField,
      initialValue: 18,
      label: 'Age',
      hint: 'Enter your age',
      min: 0,
      max: 120,
    ),

    // Boolean field
    BooleanFieldSchema(
      id: newsletterField,
      initialValue: false,
      label: 'Newsletter',
    ),

    // Conditional field - only visible when married
    ConditionalFieldSchema<String>(
      id: spouseNameField,
      initialValue: '',
      label: 'Spouse Name',
      visibilityCondition: (formState) =>
        formState['maritalStatus'] == 'married',
      isRequired: true,
    ),
  ],
  submitButtonText: 'Create Account',
  resetButtonText: 'Clear Form',
);
```

### Using Schema with SchemaBasedFormController

```dart
class SchemaBasedRegistrationForm extends ConsumerStatefulWidget {
  const SchemaBasedRegistrationForm({super.key});

  @override
  ConsumerState<SchemaBasedRegistrationForm> createState() =>
      _SchemaBasedRegistrationFormState();
}

class _SchemaBasedRegistrationFormState
    extends ConsumerState<SchemaBasedRegistrationForm> {
  late final SchemaBasedFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SchemaBasedFormController(schema: userRegistrationSchema);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Render visible fields based on schema
            ..._controller.visibleFields.map((fieldSchema) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFieldForSchema(fieldSchema),
              );
            }),

            const SizedBox(height: 24),

            // Form status
            Consumer(
              builder: (context, ref, child) {
                // You could watch form state here
                return const SizedBox.shrink();
              },
            ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.reset(),
                    child: Text(userRegistrationSchema.resetButtonText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(userRegistrationSchema.submitButtonText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldForSchema(FormFieldSchema<dynamic> schema) {
    final fieldId = schema.id;

    // Build appropriate widget based on schema type
    if (schema is TextFieldSchema) {
      return RiverpodTextFormField(
        fieldId: fieldId as BetterFormFieldID<String>,
        decoration: InputDecoration(
          labelText: schema.label,
          hintText: schema.hint,
        ),
        keyboardType: schema.keyboardType,
      );
    } else if (schema is NumberFieldSchema) {
      return RiverpodNumberFormField(
        fieldId: fieldId as BetterFormFieldID<num>,
        decoration: InputDecoration(
          labelText: schema.label,
          hintText: schema.hint,
        ),
        min: schema.min,
        max: schema.max,
      );
    } else if (schema is BooleanFieldSchema) {
      return RiverpodCheckboxFormField(
        fieldId: fieldId as BetterFormFieldID<bool>,
        title: Text(schema.label ?? ''),
      );
    }

    // Fallback for unsupported schema types
    return const SizedBox.shrink();
  }

  Future<void> _handleSubmit() async {
    // Validate form using schema
    final validationResult = await _controller.validateForm();

    if (validationResult.isValid) {
      // Submit form
      final submitResult = await _controller.submitForm();

      if (submitResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${submitResult.error}')),
        );
      }
    } else {
      // Show validation errors
      final errors = validationResult.allErrors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation errors: ${errors.join(", ")}')),
      );
    }
  }
}
```

### Advanced Schema Features

#### Async Validation
```dart
TextFieldSchema(
  id: usernameField,
  initialValue: '',
  label: 'Username',
  asyncValidator: (value) async {
    // Simulate API call to check username availability
    await Future.delayed(const Duration(milliseconds: 500));
    final response = await api.checkUsernameAvailability(value);

    if (!response.available) {
      return 'Username "${value}" is already taken';
    }
    return null;
  },
)
```

#### Cross-Field Validation
```dart
FormSchema(
  fields: [...],
  onValidate: (values) async {
    final password = values['password'];
    final confirmPassword = values['confirmPassword'];

    if (password != confirmPassword) {
      return ['Passwords do not match'];
    }

    // Additional business logic validation
    if (password.length < 8) {
      return ['Password must be at least 8 characters'];
    }

    return []; // No errors
  },
)
```

#### Selection Fields with Options
```dart
SelectionFieldSchema<String>(
  id: countryField,
  initialValue: 'US',
  label: 'Country',
  options: ['US', 'CA', 'UK', 'DE', 'FR'],
  isRequired: true,
)
```

#### Date Fields with Range Validation
```dart
DateFieldSchema(
  id: birthDateField,
  initialValue: DateTime.now().subtract(const Duration(days: 365 * 18)),
  label: 'Birth Date',
  minDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
  maxDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
)
```

### Schema Benefits

#### ✅ **Type Safety**
- Compile-time guarantees for field types
- IntelliSense support for all schema properties
- Runtime type checking for form values

#### ✅ **Maintainability**
- Single source of truth for form structure
- Easy to modify validation rules
- Clear separation of form logic from UI

#### ✅ **Reusability**
- Share schemas across different UI implementations
- Apply same validation in multiple contexts
- Build complex forms from reusable components

#### ✅ **Advanced Features**
- Conditional field visibility
- Async validation with API calls
- Cross-field validation logic
- Built-in validation rules (min/max, patterns, etc.)

#### ✅ **Developer Experience**
- Full IDE support with autocompletion
- Clear error messages and validation feedback
- Easy debugging and testing

### When to Use FormFieldSchema

**Use FormFieldSchema when you need:**
- Complex validation rules with multiple conditions
- Dynamic forms with conditional fields
- API-driven validation (username availability, etc.)
- Type-safe form definitions with compile-time guarantees
- Reusable form logic across different screens
- Advanced form behaviors (conditional visibility, cross-field validation)

**Use Widget-Based Approach when you have:**
- Simple forms with basic validation
- One-off forms with unique requirements
- Rapid prototyping
- Minimal validation needs

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
    final controllerProvider = widget.controllerProvider ?? BetterForm.of(context) ?? formControllerProvider(const BetterFormParameter(initialValue: {}));
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

1. **Field Registration (Widget Approach)**: When using the widget-based approach, fields must be registered with validation logic before use. This is typically done in the `build` method. For automatic registration, use the declarative `BetterForm.fields` parameter or `FormFieldSchema`.

2. **Controller Scope**: Each `BetterForm` creates its own controller. For shared state across multiple forms, use manual controller management.

3. **Validation Timing**: Validation occurs on field change by default. For blur-based validation, implement custom validation triggers.

4. **Nested Forms**: Avoid nesting `BetterForm` widgets as they create separate controller scopes.

5. **Schema-Based Forms**: `SchemaBasedFormController` requires manual widget building. Future versions may include pre-built schema-aware widgets.

6. **Async Validation**: Complex async validation may require debouncing to prevent excessive API calls.

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
