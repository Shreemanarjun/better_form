# Formix Cookbook

This cookbook provides solutions to common problems you might face when using Formix.

## Table of Contents
1. [Multi-Step Form (Wizard)](#multi-step-form-wizard)
2. [Dynamic Arrays](#dynamic-arrays)
3. [Dependent Fields (e.g., Country & State)](#dependent-fields)
4. [Custom Form Field](#custom-form-field)
5. [Internationalization (i18n)](#internationalization-i18n)

---

## Multi-Step Form (Wizard)

To create a multi-step form, you generally want to maintain a single `Formix` controller to hold all the data, but conditionally render fields based on the current step.

```dart
class WizardForm extends StatefulWidget {
  @override
  _WizardFormState createState() => _WizardFormState();
}

class _WizardFormState extends State<WizardForm> {
  int _step = 0;
  final _controller = FormixController(); // Or use Riverpod/Provider

  @override
  Widget build(BuildContext context) {
    return Formix(
      controller: _controller,
      child: Column(
        children: [
          if (_step == 0) ...[
            FormixTextField('name', label: 'Name', validators: [FormixValidators.required()]),
            FormixTextField('email', label: 'Email', validators: [FormixValidators.email()]),
          ],
          if (_step == 1) ...[
             FormixNumberField('age', label: 'Age'),
             FormixTextField('address', label: 'Address'),
          ],

          Row(
            children: [
              if (_step > 0)
                ElevatedButton(onPressed: () => setState(() => _step--), child: Text('Back')),
              ElevatedButton(
                onPressed: () async {
                  // Validate current step fields before moving on?
                  // Currently Formix validates everything on submit.
                  // For manual step validation, you can check specific fields:
                  final errors = _controller.validate(
                    fields: _step == 0 ? ['name', 'email'] : ['age', 'address']
                  );

                  if (errors.isEmpty) {
                    if (_step == 1) {
                        _controller.submit(onValid: (values) => print(values));
                    } else {
                        setState(() => _step++);
                    }
                  }
                },
                child: Text(_step == 1 ? 'Submit' : 'Next'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
```

## Dynamic Arrays

Render a list of fields dynamically.

```dart
FormixArray<String>(
  id: FormixArrayID('emails'),
  itemBuilder: (context, index, itemValue) {
    return Row(
      children: [
        Expanded(
          child: FormixTextField(
            'emails.$index', // Unique key for each item
            initialValue: itemValue,
            validators: [FormixValidators.email()],
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => Formix.of(context).removeArrayItemAt(FormixArrayID('emails'), index),
        ),
      ],
    );
  },
  emptyBuilder: (context) => Text('No emails added.'),
),
ElevatedButton(
  onPressed: () => Formix.of(context).addArrayItem(FormixArrayID('emails'), ''),
  child: Text('Add Email'),
)
```

## Dependent Fields

To make one field depend on another (e.g., resetting 'City' when 'Country' changes), use `onChanged` or a `dependencies` configuration if available (advanced).

Simple approach:

```dart
FormixDropdownField(
  'country',
  items: ['US', 'CA', 'IN'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
  onChanged: (value, controller) {
    // Reset city when country changes
    controller.setValue('city', null);
  },
),
FormixListener(
  builder: (context, controller, _) {
    final country = controller.getValue<String>('country');
    final cities = _getCitiesForCountry(country); // method returning list based on country

    return FormixDropdownField(
      'city',
      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      enabled: country != null, // Disable if no country selected
    );
  }
)
```

## Custom Form Field

To create a custom field (e.g., a Rating Star field), extend `FormixFieldWidget` or wrap an existing widget.

For full custom painting/interaction:

```dart
class RatingField extends FormixFieldWidget<int> {
  RatingField(
    String key, {
    super.initialValue,
    super.validators,
  }) : super(key);

  @override
  FormixFieldState<int, RatingField> createState() => _RatingFieldState();
}

class _RatingFieldState extends FormixFieldState<int, RatingField> {
  @override
  Widget buildField(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final rating = index + 1;
        return IconButton(
          icon: Icon(
            rating <= (value ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => didChange(rating),
        );
      }),
    );
  }
}
```

## Internationalization (i18n)

Formix supports localization out of the box.

1. **Setup**: passing `messages` to the controller.

```dart
final controller = FormixController(
  messages: MyCustomFormixMessages(), // Extend FormixMessages
);
```

2. **Using Standard Validators**:
`FormixValidators.required()` automatically uses the localized string from `FormixMessages.required()`.

3. **Custom Messages**:
You can still override messages per field:
`FormixValidators.required('Must have a name!')`
