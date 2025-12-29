import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';
import '../../constants/field_ids.dart';

// Basic Form Example
class BasicFormExample extends ConsumerWidget {
  const BasicFormExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(formControllerProvider({'name': '', 'email': '', 'age': 0, 'newsletter': false}).notifier);
    final formState = ref.watch(formControllerProvider({'name': '', 'email': '', 'age': 0, 'newsletter': false}));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Form Fields',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          RiverpodTextFormField(
            fieldId: nameField,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          RiverpodTextFormField(
            fieldId: emailField,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          RiverpodNumberFormField(
            fieldId: ageField,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'Enter your age',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 16),
          RiverpodCheckboxFormField(
            fieldId: newsletterField,
            title: const Text('Subscribe to newsletter'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final values = formState.values;
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
    );
  }
}
