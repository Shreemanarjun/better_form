import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formix/formix.dart';

// Conditional Fields Example
class ConditionalFormExample extends ConsumerWidget {
  const ConditionalFormExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ConditionalFormExampleContent();
  }
}

class ConditionalFormExampleContent extends ConsumerStatefulWidget {
  const ConditionalFormExampleContent({super.key});

  @override
  ConsumerState<ConditionalFormExampleContent> createState() =>
      _ConditionalFormExampleContentState();
}

class _ConditionalFormExampleContentState
    extends ConsumerState<ConditionalFormExampleContent> {
  @override
  Widget build(BuildContext context) {
    return Formix(
      initialValue: {
        'accountType': 'personal',
        'companyName': '',
        'taxId': '',
        'firstName': '',
        'lastName': '',
        'hasNewsletter': false,
        'newsletterFrequency': 'weekly',
        'contactMethod': 'email',
        'phoneNumber': '',
        'preferredTime': 'morning',
      },
      fields: [
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('accountType'),
          initialValue: 'personal',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('companyName'),
          initialValue: '',
          validator: (value) {
            final accountType = Formix.controllerOf(
              context,
            )?.getValue(FormixFieldID<String>('accountType'));
            if (accountType == 'business' && (value?.isEmpty ?? true)) {
              return 'Company name is required for business accounts';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('taxId'),
          initialValue: '',
          validator: (value) {
            final accountType = Formix.controllerOf(
              context,
            )?.getValue(FormixFieldID<String>('accountType'));
            if (accountType == 'business' && (value?.isEmpty ?? true)) {
              return 'Tax ID is required for business accounts';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('firstName'),
          initialValue: '',
          validator: (value) {
            if (value == null || value.isEmpty) return 'First name is required';
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('lastName'),
          initialValue: '',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Last name is required';
            return null;
          },
        ),
        FormixFieldConfig<bool>(
          id: FormixFieldID<bool>('hasNewsletter'),
          initialValue: false,
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('newsletterFrequency'),
          initialValue: 'weekly',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('contactMethod'),
          initialValue: 'email',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('phoneNumber'),
          initialValue: '',
          validator: (value) {
            final contactMethod = Formix.controllerOf(
              context,
            )?.getValue(FormixFieldID<String>('contactMethod'));
            if ((contactMethod == 'phone' || contactMethod == 'sms') &&
                (value?.isEmpty ?? true)) {
              return 'Phone number is required for ${contactMethod == 'phone' ? 'phone' : 'SMS'} contact';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('preferredTime'),
          initialValue: 'morning',
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conditional Fields',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fields that show/hide based on other field values',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Account Type Selection
            const Text('Account Type'),
            const SizedBox(height: 8),
            RiverpodDropdownFormField<String>(
              fieldId: FormixFieldID<String>('accountType'),
              items: const [
                DropdownMenuItem(
                  value: 'personal',
                  child: Text('Personal Account'),
                ),
                DropdownMenuItem(
                  value: 'business',
                  child: Text('Business Account'),
                ),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),

            // Conditional Business Fields
            Consumer(
              builder: (context, ref, child) {
                final accountType = ref.watch(
                  fieldValueProvider(FormixFieldID<String>('accountType')),
                );
                if (accountType == 'business') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RiverpodTextFormField(
                        fieldId: FormixFieldID<String>('companyName'),
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business_center),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RiverpodTextFormField(
                        fieldId: FormixFieldID<String>('taxId'),
                        decoration: const InputDecoration(
                          labelText: 'Tax ID',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Personal Information (always shown)
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('firstName'),
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            RiverpodTextFormField(
              fieldId: FormixFieldID<String>('lastName'),
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Newsletter Subscription
            RiverpodCheckboxFormField(
              fieldId: FormixFieldID<bool>('hasNewsletter'),
              title: const Text('Subscribe to newsletter'),
            ),
            const SizedBox(height: 16),

            // Conditional Newsletter Frequency
            Consumer(
              builder: (context, ref, child) {
                final hasNewsletter = ref.watch(
                  fieldValueProvider(FormixFieldID<bool>('hasNewsletter')),
                );
                if (hasNewsletter == true) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Newsletter Frequency'),
                      const SizedBox(height: 8),
                      RiverpodDropdownFormField<String>(
                        fieldId: FormixFieldID<String>('newsletterFrequency'),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.schedule),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Contact Method
            const Text('Preferred Contact Method'),
            const SizedBox(height: 8),
            RiverpodDropdownFormField<String>(
              fieldId: FormixFieldID<String>('contactMethod'),
              items: const [
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'phone', child: Text('Phone')),
                DropdownMenuItem(value: 'sms', child: Text('SMS')),
              ],
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.contact_mail),
              ),
            ),
            const SizedBox(height: 16),

            // Conditional Phone Number
            Consumer(
              builder: (context, ref, child) {
                final contactMethod = ref.watch(
                  fieldValueProvider(FormixFieldID<String>('contactMethod')),
                );
                if (contactMethod == 'phone' || contactMethod == 'sms') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiverpodTextFormField(
                        fieldId: FormixFieldID<String>('phoneNumber'),
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Conditional Preferred Time (only for phone calls)
                      if (contactMethod == 'phone') ...[
                        const Text('Preferred Call Time'),
                        const SizedBox(height: 8),
                        RiverpodDropdownFormField<String>(
                          fieldId: FormixFieldID<String>('preferredTime'),
                          items: const [
                            DropdownMenuItem(
                              value: 'morning',
                              child: Text('Morning (9 AM - 12 PM)'),
                            ),
                            DropdownMenuItem(
                              value: 'afternoon',
                              child: Text('Afternoon (12 PM - 5 PM)'),
                            ),
                            DropdownMenuItem(
                              value: 'evening',
                              child: Text('Evening (5 PM - 9 PM)'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.access_time),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),
            const RiverpodFormStatus(),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = Formix.of(context)!;
                ref.read(controllerProvider.notifier);
                final formState = ref.watch(controllerProvider);

                return ElevatedButton(
                  onPressed: () {
                    final values = formState.values;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Form Values'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: values.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text('${entry.key}: ${entry.value}'),
                              );
                            }).toList(),
                          ),
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
                  child: const Text('Show Form Values'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
