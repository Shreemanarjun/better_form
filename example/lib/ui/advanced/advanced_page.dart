import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';
import '../../constants/field_ids.dart';

// Advanced Example
class AdvancedExample extends ConsumerWidget {
  const AdvancedExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdvancedExampleContent();
  }
}

class AdvancedExampleContent extends ConsumerWidget {
  const AdvancedExampleContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BetterForm(
      initialValue: {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 25,
        'newsletter': true,
        'dob': '1999-01-01',
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Features',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const RiverpodFormStatus(),
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
            // For now, using a simple text field for DOB - could be enhanced with date picker
            RiverpodTextFormField(
              fieldId: BetterFormFieldID<String>('dob_text'),
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Enter your date of birth',
                prefixIcon: Icon(Icons.calendar_today),
              ),
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
            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = BetterForm.of(context)!;
                final controller = ref.read(controllerProvider.notifier);
                final formState = ref.watch(controllerProvider);

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final values = formState.values;
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
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
