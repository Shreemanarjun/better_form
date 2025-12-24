import 'package:flutter/material.dart';
import 'package:better_form/better_form.dart';

// Field IDs for type safety
final nameField = BetterFormFieldID<String>('name');
final emailField = BetterFormFieldID<String>('email');
final ageField = BetterFormFieldID<int>('age');
final newsletterField = BetterFormFieldID<bool>('newsletter');
final passwordField = BetterFormFieldID<String>('password');
final confirmPasswordField = BetterFormFieldID<String>('confirmPassword');
final dobField = BetterFormFieldID<DateTime>('dob');

void main() {
  runApp(const BetterFormExampleApp());
}

class BetterFormExampleApp extends StatelessWidget {
  const BetterFormExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Form Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// Custom Date Form Field for the example
class BetterDateFormField extends BetterFormFieldWidget<DateTime> {
  const BetterDateFormField({
    super.key,
    required super.fieldId,
    super.controller,
    super.validator,
    super.initialValue,
    this.label,
  });

  final String? label;

  @override
  BetterFormFieldWidgetState<DateTime> createState() =>
      _BetterDateFormFieldState();
}

class _BetterDateFormFieldState extends BetterFormFieldWidgetState<DateTime> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text((widget as BetterDateFormField).label ?? 'Select Date'),
      subtitle: Text(value.toString().split(' ')[0]),
      trailing: const Icon(Icons.calendar_today),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          didChange(picked);
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Better Form Examples'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basic Form', icon: Icon(Icons.edit)),
            Tab(text: 'Validation', icon: Icon(Icons.check_circle)),
            Tab(text: 'Advanced', icon: Icon(Icons.settings)),
            Tab(text: 'Listeners', icon: Icon(Icons.visibility)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BasicFormExample(),
          ValidationExample(),
          AdvancedExample(),
          ListenersExample(),
        ],
      ),
    );
  }
}

// Basic Form Example
class BasicFormExample extends StatefulWidget {
  const BasicFormExample({super.key});

  @override
  State<BasicFormExample> createState() => _BasicFormExampleState();
}

class _BasicFormExampleState extends State<BasicFormExample> {
  final controller = BetterFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BetterForm(
        controller: controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Form Fields',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: nameField,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: emailField,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            BetterNumberFormField(
              fieldId: ageField,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            BetterCheckboxFormField(
              fieldId: newsletterField,
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final values = controller.value;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Form values: $values'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: const Text('Show Values'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.reset(),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Validation Example
class ValidationExample extends StatefulWidget {
  const ValidationExample({super.key});

  @override
  State<ValidationExample> createState() => _ValidationExampleState();
}

class _ValidationExampleState extends State<ValidationExample> {
  final controller = BetterFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    if (value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Invalid email format';
    return null;
  }

  String? _validateAge(int value) {
    if (value < 18) return 'Must be 18 or older';
    if (value > 120) return 'Age seems unrealistic';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirmPassword(String value) {
    final password = controller.getValue(passwordField);
    if (value != password) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BetterForm(
        controller: controller,
        autovalidateMode: BetterAutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Validation',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: nameField,
              validator: _validateName,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: emailField,
              validator: _validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email *',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            BetterNumberFormField(
              fieldId: ageField,
              validator: _validateAge,
              decoration: const InputDecoration(
                labelText: 'Age *',
                hintText: 'Enter your age',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: passwordField,
              validator: _validatePassword,
              decoration: const InputDecoration(
                labelText: 'Password *',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: confirmPasswordField,
              validator: _validateConfirmPassword,
              decoration: const InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Trigger validation by getting all values (this runs validators)
                      final _ = controller.value;
                      if (controller.isValid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Form is valid! ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fix the errors'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Validate & Save'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.reset(),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Advanced Example
class AdvancedExample extends StatefulWidget {
  const AdvancedExample({super.key});

  @override
  State<AdvancedExample> createState() => _AdvancedExampleState();
}

class _AdvancedExampleState extends State<AdvancedExample> {
  final controller = BetterFormController(
    initialValueBuilder: BetterFormInitialValue()
      ..set(nameField, 'John Doe')
      ..set(emailField, 'john@example.com')
      ..set(ageField, 25)
      ..set(newsletterField, true)
      ..set(dobField, DateTime(1999, 1, 1)),
  );

  @override
  void initState() {
    super.initState();
    controller.addFieldListener(dobField, _onDobChanged);
  }

  void _onDobChanged() {
    final dob = controller.getValue(dobField);
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    controller.setValue(ageField, age);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BetterForm(
        controller: controller,
        autovalidateMode: BetterAutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form State',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BetterFormDirtyListener(
                      builder: (context, isDirty, child) {
                        return Text(
                          'Form is ${isDirty ? 'dirty' : 'clean'}',
                          style: TextStyle(
                            color: isDirty ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    BetterFormValidationListener(
                      builder: (context, isValid, child) {
                        return Text(
                          'Is Valid: $isValid',
                          style: TextStyle(
                            color: isValid ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: nameField,
              validator: (value) =>
                  value.isEmpty ? 'Name cannot be empty' : null,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: emailField,
              validator: (value) =>
                  !value.contains('@') ? 'Please enter a valid email' : null,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            BetterDateFormField(fieldId: dobField, label: 'Date of Birth'),
            const SizedBox(height: 16),
            BetterNumberFormField(
              fieldId: ageField,
              validator: (value) => value < 18 ? 'Must be at least 18' : null,
              decoration: const InputDecoration(
                labelText: 'Age (Derived from DoB)',
                hintText: 'Enter your age',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            BetterCheckboxFormField(
              fieldId: newsletterField,
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final values = controller.value;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Form Values'),
                        content: SingleChildScrollView(
                          child: Text(values.toString()),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Values'),
                ),
                ElevatedButton.icon(
                  onPressed: () => controller.reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.resetInitialValues();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Initial values updated')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save as Initial'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Listeners Example
class ListenersExample extends StatefulWidget {
  const ListenersExample({super.key});

  @override
  State<ListenersExample> createState() => _ListenersExampleState();
}

class _ListenersExampleState extends State<ListenersExample> {
  final controller = BetterFormController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: BetterForm(
        controller: controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field Listeners',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Real-time Field Monitoring',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BetterFormFieldListener<String>(
                      fieldId: nameField,
                      builder: (context, value, child) {
                        return Text('Name: ${value ?? 'Not set'}');
                      },
                    ),
                    const SizedBox(height: 8),
                    BetterFormFieldListener<String>(
                      fieldId: emailField,
                      builder: (context, value, child) {
                        return Text('Email: ${value ?? 'Not set'}');
                      },
                    ),
                    const SizedBox(height: 8),
                    BetterFormFieldListener<int>(
                      fieldId: ageField,
                      builder: (context, value, child) {
                        return Text('Age: ${value ?? 'Not set'}');
                      },
                    ),
                    const SizedBox(height: 8),
                    BetterFormFieldListener<bool>(
                      fieldId: newsletterField,
                      builder: (context, value, child) {
                        return Text(
                          'Newsletter: ${value == true ? 'Subscribed' : 'Not subscribed'}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: nameField,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            BetterTextFormField(
              fieldId: emailField,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            BetterNumberFormField(
              fieldId: ageField,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            BetterCheckboxFormField(
              fieldId: newsletterField,
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BetterFormDirtyListener(
                      builder: (context, isDirty, child) {
                        return Row(
                          children: [
                            Icon(
                              isDirty ? Icons.edit : Icons.check_circle,
                              color: isDirty ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Form is ${isDirty ? 'modified' : 'unchanged'}',
                              style: TextStyle(
                                color: isDirty ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
