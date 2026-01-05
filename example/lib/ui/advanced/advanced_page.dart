import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formix/formix.dart';
import '../../constants/field_ids.dart';

// Advanced Example
class AdvancedExample extends ConsumerWidget {
  const AdvancedExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdvancedExampleContent();
  }
}

class AdvancedExampleContent extends ConsumerStatefulWidget {
  const AdvancedExampleContent({super.key});

  @override
  ConsumerState<AdvancedExampleContent> createState() =>
      _AdvancedExampleContentState();
}

class _AdvancedExampleContentState
    extends ConsumerState<AdvancedExampleContent> {
  @override
  Widget build(BuildContext context) {
    return Formix(
      initialValue: {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 25,
        'newsletter': true,
        'country': 'US',
        'bio': '',
        'password': '',
        'confirmPassword': '',
      },
      fields: [
        FormixFieldConfig<String>(
          id: nameField,
          initialValue: 'John Doe',
          validator: (value) {
            if (value.isEmpty) return 'Name is required';
            if (value.length < 2) return 'Name must be at least 2 characters';
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: emailField,
          initialValue: 'john@example.com',
          validator: (value) {
            if (value.isEmpty) return 'Email is required';
            // Use static constant if available or standard pattern
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
              return 'Invalid email format';
            }
            return null;
          },
        ),
        FormixFieldConfig<num>(
          id: ageField,
          initialValue: 25,
          validator: (value) {
            if (value < 13) return 'Must be at least 13 years old';
            if (value > 120) return 'Age must be realistic';
            return null;
          },
        ),
        FormixFieldConfig<bool>(id: newsletterField, initialValue: true),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('country'),
          initialValue: 'US',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('bio'),
          initialValue: '',
          validator: (value) {
            if (value.length > 500) {
              return 'Bio must be less than 500 characters';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('password'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'Password is required';
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('confirmPassword'),
          initialValue: '',
          validator: (value) {
            // Cross-field validation will be handled by a custom mechanism
            // For now, just validate that it's not empty
            if (value.isEmpty) return 'Please confirm your password';
            return null;
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Features Showcase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comprehensive example with validation, async operations, and form state management',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Auto-validation modes demo
            const Text(
              'Auto-Validation Modes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                'This form uses automatic validation on user interaction. Try typing in fields to see validation in action.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),

            // Form fields
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
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            RiverpodNumberFormField(
              fieldId: ageField,
              min: 0,
              max: 150,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            RiverpodDropdownFormField<String>(
              fieldId: FormixFieldID<String>('country'),
              items: const [
                DropdownMenuItem(value: 'US', child: Text('United States')),
                DropdownMenuItem(value: 'CA', child: Text('Canada')),
                DropdownMenuItem(value: 'UK', child: Text('United Kingdom')),
                DropdownMenuItem(value: 'DE', child: Text('Germany')),
                DropdownMenuItem(value: 'FR', child: Text('France')),
                DropdownMenuItem(value: 'JP', child: Text('Japan')),
              ],
              decoration: const InputDecoration(
                labelText: 'Country',
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 16),

            RiverpodCheckboxFormField(
              fieldId: newsletterField,
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 16),

            // Password fields with confirmation
            const Text(
              'Password Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('password'),
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('confirmPassword'),
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Bio field with length limit
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('bio'),
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself (max 500 characters)',
                prefixIcon: Icon(Icons.text_fields),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),
            const RiverpodFormStatus(),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = Formix.of(context)!;
                final controller = ref.read(controllerProvider.notifier);
                final formState = ref.watch(controllerProvider);

                // Custom cross-field validation for password confirmation
                final password = formState.values['password'] as String?;
                final confirmPassword =
                    formState.values['confirmPassword'] as String?;
                final hasPasswordMismatch =
                    password != null &&
                    confirmPassword != null &&
                    password.isNotEmpty &&
                    confirmPassword.isNotEmpty &&
                    password != confirmPassword;

                // Update confirm password validation if there's a mismatch
                if (hasPasswordMismatch) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final newValidations = Map<String, ValidationResult>.from(
                      formState.validations,
                    );
                    newValidations['confirmPassword'] = ValidationResult(
                      isValid: false,
                      errorMessage: 'Passwords do not match',
                    );
                    // Update the controller's state directly
                    (controller as dynamic).state = formState.copyWith(
                      validations: newValidations,
                    );
                  });
                }

                final isValid = formState.isValid && !hasPasswordMismatch;
                final isDirty = formState.isDirty;

                return Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isValid
                              ? () async {
                                  // Simulate async submission
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Submitting...'),
                                    ),
                                  );

                                  await Future.delayed(
                                    const Duration(seconds: 2),
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile updated successfully!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Profile'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final values = formState.values;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Form Values'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: values.entries.map((entry) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          '${entry.key}: ${entry.value}',
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('Show Values'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => controller.reset(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isValid
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isValid
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isValid ? Icons.check_circle : Icons.error,
                            color: isValid ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isValid
                                  ? 'Form is valid and ready to submit'
                                  : 'Form has validation errors',
                              style: TextStyle(
                                color: isValid
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isDirty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Modified',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
