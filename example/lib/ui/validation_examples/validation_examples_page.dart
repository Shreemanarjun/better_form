import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formix/formix.dart';

// Validation Examples
class ValidationExamples extends ConsumerWidget {
  const ValidationExamples({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ValidationExamplesContent();
  }
}

class ValidationExamplesContent extends ConsumerStatefulWidget {
  const ValidationExamplesContent({super.key});

  @override
  ConsumerState<ValidationExamplesContent> createState() =>
      _ValidationExamplesContentState();
}

class _ValidationExamplesContentState
    extends ConsumerState<ValidationExamplesContent> {
  @override
  Widget build(BuildContext context) {
    return Formix(
      initialValue: {
        'email': '',
        'password': '',
        'confirmPassword': '',
        'age': 18,
        'phone': '',
        'url': '',
        'creditCard': '',
        'zipCode': '',
        'username': '',
        'bio': '',
      },
      fields: [
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('email'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'Email is required';
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
            if (!emailRegex.hasMatch(value)) return 'Invalid email format';
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
            if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
              return 'Password must contain lowercase letter';
            }
            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
              return 'Password must contain uppercase letter';
            }
            if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
              return 'Password must contain number';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('confirmPassword'),
          initialValue: '',
          validator: (value) {
            final password = Formix.controllerOf(
              context,
            )?.getValue(FormixFieldID<String>('password'));
            if (value.isEmpty) return 'Please confirm your password';
            if (value != password) return 'Passwords do not match';
            return null;
          },
        ),
        FormixFieldConfig<num>(
          id: FormixFieldID<num>('age'),
          initialValue: 18,
          validator: (value) {
            if (value < 13) return 'Must be at least 13 years old';
            if (value > 120) return 'Age must be realistic';
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('phone'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'Phone number is required';
            final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
            if (!phoneRegex.hasMatch(value)) {
              return 'Invalid phone number format';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('url'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return null; // Optional field
            final urlRegex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
            if (!urlRegex.hasMatch(value)) return 'Invalid URL format';
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('creditCard'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return null; // Optional field
            final cleanValue = value.replaceAll(RegExp(r'\s+'), '');
            if (cleanValue.length < 13 || cleanValue.length > 19) {
              return 'Invalid credit card number length';
            }
            if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
              return 'Credit card must contain only digits';
            }
            // Luhn algorithm check
            if (!_isValidLuhn(cleanValue)) return 'Invalid credit card number';
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('zipCode'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'ZIP code is required';
            final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
            if (!zipRegex.hasMatch(value)) {
              return 'Invalid ZIP code format (12345 or 12345-6789)';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('username'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'Username is required';
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (value.length > 20) {
              return 'Username must be less than 20 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            return null;
          },
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
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Validation Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Different types of validation rules and error messages',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Email Validation
            const Text(
              'Email Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('email'),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // Password Validation
            const Text(
              'Password Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('password'),
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText:
                    'At least 8 chars, with uppercase, lowercase & number',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('confirmPassword'),
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Age Validation
            const Text(
              'Numeric Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodNumberFormField(
              fieldId: FormixFieldID<num>('age'),
              min: 0,
              max: 150,
              decoration: const InputDecoration(
                labelText: 'Age',
                hintText: '13-120 years',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            // Phone Validation
            const Text(
              'Phone Number Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('phone'),
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 (555) 123-4567',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),

            // URL Validation
            const Text(
              'URL Validation (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('url'),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Website URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),

            // Credit Card Validation
            const Text(
              'Credit Card Validation (Optional)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('creditCard'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Credit Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 16),

            // ZIP Code Validation
            const Text(
              'ZIP Code Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('zipCode'),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ZIP Code',
                hintText: '12345 or 12345-6789',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Username Validation
            const Text(
              'Username Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('username'),
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: '3-20 characters, letters/numbers/underscores',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Bio Validation (Length)
            const Text(
              'Text Length Validation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('bio'),
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell us about yourself (max 500 characters)',
                prefixIcon: Icon(Icons.text_fields),
              ),
            ),
            const SizedBox(height: 24),

            const RiverpodFormStatus(),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = Formix.of(context)!;
                final controller = ref.read(controllerProvider.notifier);
                ref.watch(controllerProvider);

                return ElevatedButton(
                  onPressed: () {
                    final isValid = controller.validate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isValid
                              ? 'All validations passed!'
                              : 'Some fields have errors',
                        ),
                        backgroundColor: isValid ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('Validate Form'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Luhn algorithm for credit card validation
  bool _isValidLuhn(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }
}
