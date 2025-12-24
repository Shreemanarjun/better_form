# Better Form

A type-safe form management package for Flutter that provides compile-time type checking, runtime validation, and granular performance optimizations.

## Features

✅ **Compile-time type checking** with `BetterFormFieldID<T>`
✅ **Runtime type validation** with automatic type safety
✅ **Type-safe getters/setters** that prevent type mismatches
✅ **Type-safe listeners** for field-specific updates
✅ **Schema-based data extraction** with typed data maps
✅ **Dirty state tracking** for form and individual fields
✅ **Granular performance** - only affected widgets rebuild

## Getting Started

Add `better_form` to your `pubspec.yaml`:

```yaml
dependencies:
  better_form: ^0.0.1
```

Import the package:

```dart
import 'package:better_form/better_form.dart';
```

## Usage

### Quick Start with Controller

```dart
// 1. Define type-safe field IDs
const nameField = BetterFormFieldID<String>('name');
const ageField = BetterFormFieldID<int>('age');

// 2. Create controller with type-safe initial values
final initialValues = BetterFormInitialValue()
  ..set(nameField, 'John')
  ..set(ageField, 25);

final controller = BetterFormController(initialValueBuilder: initialValues);

// Optional: Pre-register fields with validators
controller.registerField(BetterFormField(
  id: nameField,
  initialValue: 'John',
  validator: (value) => value.isEmpty ? 'Required' : null,
));

// 3. Use in widget - fields auto-register on first use!
BetterForm(
  controller: controller,
  child: Column(
    children: [
      BetterTextFormField(fieldId: nameField, controller: controller),
      BetterNumberFormField(fieldId: ageField, controller: controller), // Auto-registered!
      ElevatedButton(
        onPressed: controller.isValid ? () => print(controller.value) : null,
        child: Text('Submit'),
      ),
    ],
  ),
);
```

### Context Access Anywhere

Access the form controller from anywhere in the widget tree:

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get controller from context
    final controller = BetterForm.of(context)!;

    return ElevatedButton(
      onPressed: () {
        // Access form state anywhere
        final name = controller.getValue(nameField);
        final isValid = controller.isValid;
        // ...
      },
      child: Text('Submit'),
    );
  }
}
```

### Simplified Custom Form Fields

Create custom form fields without boilerplate using the simplified APIs:

```dart
// Simple dropdown field
class PriorityField extends BetterFormFieldWidget<String> {
  const PriorityField({super.key, required super.fieldId, super.controller});

  @override
  PriorityFieldState createState() => PriorityFieldState();
}

class PriorityFieldState extends BetterFormFieldWidgetState<String> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value, // Current value
      items: ['Low', 'Medium', 'High'].map((priority) {
        return DropdownMenuItem(value: priority, child: Text(priority));
      }).toList(),
      onChanged: (newValue) => didChange(newValue!), // Simple API!
      decoration: InputDecoration(
        labelText: 'Priority',
        errorText: validation.errorMessage, // Validation result
        suffixIcon: isDirty ? Icon(Icons.edit) : null, // Dirty indicator
      ),
    );
  }
}

// Complex multi-value field
class TagsField extends BetterFormFieldWidget<List<String>> {
  const TagsField({super.key, required super.fieldId, super.controller});

  @override
  TagsFieldState createState() => TagsFieldState();
}

class TagsFieldState extends BetterFormFieldWidgetState<List<String>> {
  void addTag(String tag) {
    didChange([...value, tag]); // Update field value
  }

  void removeTag(String tag) {
    didChange(value.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Your custom UI here
        Wrap(
          children: value.map((tag) => Chip(
            label: Text(tag),
            onDeleted: () => removeTag(tag),
          )).toList(),
        ),
        if (validation.errorMessage != null)
          Text(validation.errorMessage!, style: TextStyle(color: Colors.red)),
      ],
    );
  }
}
```

### Controller APIs

```dart
final controller = BetterFormController();

// Get/set values with type safety
String name = controller.getValue(nameField);
controller.setValue(nameField, 'Jane');

// Check form state
bool isValid = controller.isValid;
bool hasChanges = controller.isDirty;
bool fieldDirty = controller.isFieldDirty(nameField);

// Validation
ValidationResult validation = controller.getValidation(nameField);

// Bulk operations
controller.patchValue({
  nameField: 'John',
  ageField: 30,
});

// Reset
controller.reset();
controller.resetInitialValues();
```

### Built-in Form Field Widgets

```dart
// Text input
BetterTextFormField(
  fieldId: nameField,
  controller: controller,
  decoration: InputDecoration(labelText: 'Name'),
)

// Number input
BetterNumberFormField(
  fieldId: ageField,
  controller: controller,
  decoration: InputDecoration(labelText: 'Age'),
)

// Checkbox
BetterCheckboxFormField(
  fieldId: isStudentField,
  controller: controller,
  title: Text('Student?'),
)
```

### Advanced Features

#### Field Listeners
```dart
BetterFormFieldListener<String>(
  fieldId: nameField,
  builder: (context, value, child) {
    return Text('Name: $value');
  },
);
```

#### Dirty State Listeners
```dart
BetterFormDirtyListener(
  builder: (context, isDirty, child) {
    return Text(isDirty ? 'Unsaved changes' : 'All saved');
  },
);
```

### ValueListenableBuilder Support

For more granular control, use `ValueListenableBuilder` to listen to specific field changes:

#### Listen to Field Value Changes
```dart
BetterFormFieldValueListenableBuilder<String>(
  fieldId: nameField,
  builder: (context, value, child) {
    return Text('Current name: $value');
  },
);
```

#### Listen to Field Validation Changes
```dart
BetterFormFieldValidationListenableBuilder<String>(
  fieldId: emailField,
  builder: (context, validation, child) {
    return Text(
      validation.isValid ? 'Valid' : validation.errorMessage ?? 'Invalid',
      style: TextStyle(color: validation.isValid ? Colors.green : Colors.red),
    );
  },
);
```

#### Listen to Field Dirty State Changes
```dart
BetterFormFieldDirtyListenableBuilder<String>(
  fieldId: nameField,
  builder: (context, isDirty, child) {
    return Text(isDirty ? 'Modified' : 'Unchanged');
  },
);
```

#### Combined Field Listening (Value + Validation + Dirty)
```dart
BetterFormFieldListenableBuilder<String>(
  fieldId: nameField,
  builder: (context, value, validation, isDirty) {
    return Container(
      color: validation.isValid ?
        (isDirty ? Colors.yellow : Colors.green) : Colors.red,
      child: Text('"$value" - ${validation.isValid ? "Valid" : "Invalid"}'),
    );
  },
);
```

#### Form-Level Dirty State with ValueListenableBuilder
```dart
BetterFormDirtyListenableBuilder(
  builder: (context, isDirty, child) {
    return Text('Form is ${isDirty ? "modified" : "saved"}');
  },
);
```

## API Reference

### BetterFormFieldID<T>

A type-safe identifier for form fields.

```dart
const fieldId = BetterFormFieldID<String>('fieldName');
```

### BetterFormField<T>

Defines a form field with validation and metadata.

```dart
BetterFormField(
  id: fieldId,
  initialValue: 'default',
  validator: (value) => value.isEmpty ? 'Required' : null,
  label: 'Field Label',
  hint: 'Field hint',
);
```

### BetterForm

The main form management class.

#### Methods:

- `T getValue<T>(BetterFormFieldID<T> fieldId)` - Get field value with type safety
- `void setValue<T>(BetterFormFieldID<T> fieldId, T value)` - Set field value with validation
- `bool isDirty<T>(BetterFormFieldID<T> fieldId)` - Check if field is dirty
- `ValidationResult getValidation<T>(BetterFormFieldID<T> fieldId)` - Get validation result
- `bool get isValid` - Check if entire form is valid
- `bool get hasDirtyFields` - Check if form has any dirty fields
- `Map<String, dynamic> extractData()` - Extract form data
- `void reset()` - Reset form to initial state
- `void addListener<T>(BetterFormFieldID<T> fieldId, VoidCallback listener)` - Add field listener
- `void removeListener<T>(BetterFormFieldID<T> fieldId, VoidCallback listener)` - Remove field listener

### BetterFormFieldMixin<T>

A mixin for widgets that need to rebuild when form fields change.

```dart
class MyFieldWidget extends StatefulWidget {
  // ...
}

class _MyFieldWidgetState extends State<MyFieldWidget>
    with BetterFormFieldMixin<String> {
  @override
  Widget build(BuildContext context) {
    // This widget will automatically rebuild when the field changes
    final value = widget.form.getValue(widget.fieldId);
    return Text(value);
  }
}
```

## Type Safety

The package provides compile-time type safety:

```dart
// ✅ This works - types match
form.setValue(nameField, 'John');  // String field, String value

// ❌ This won't compile - type mismatch
form.setValue(nameField, 123);     // String field, int value

// ✅ Runtime type checking prevents invalid assignments
try {
  // This would throw ArgumentError at runtime
  form.setValue(nameField, 123);
} catch (e) {
  print('Type mismatch prevented');
}
```

## Performance

- **Granular rebuilds**: Only widgets listening to changed fields rebuild
- **Efficient listeners**: Field-specific listener system
- **Dirty state tracking**: Avoid unnecessary validation and updates
- **Type-safe operations**: Compile-time checks prevent runtime errors

## Validation

Validation is performed automatically when values change:

```dart
final field = BetterFormField(
  id: emailField,
  initialValue: '',
  validator: (value) {
    if (value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Invalid email format';
    return null; // Valid
  },
);
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This package is licensed under the MIT License.
