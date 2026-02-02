import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

class AsyncFieldSubmissionPage extends ConsumerWidget {
  const AsyncFieldSubmissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Field & Submission')),
      body: const AsyncFieldSubmissionContent(),
    );
  }
}

class AsyncFieldSubmissionContent extends ConsumerStatefulWidget {
  const AsyncFieldSubmissionContent({super.key});

  @override
  ConsumerState<AsyncFieldSubmissionContent> createState() =>
      _AsyncFieldSubmissionContentState();
}

class _AsyncFieldSubmissionContentState
    extends ConsumerState<AsyncFieldSubmissionContent> {
  final countryField = const FormixFieldID<String>('country');
  final cityField = const FormixFieldID<String>('city');
  final cityOptionsField = const FormixFieldID<List<String>>('cityOptions');
  final nameField = const FormixFieldID<String>('name');

  // Simulated API
  Future<List<String>> fetchCities(String? country) async {
    if (country == null || country.isEmpty) return [];
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    if (country == 'USA') return ['New York', 'Los Angeles', 'Chicago'];
    if (country == 'India') return ['Mumbai', 'Delhi', 'Bangalore'];
    if (country == 'UK') return ['London', 'Manchester', 'Birmingham'];
    return ['Other'];
  }

  @override
  Widget build(BuildContext context) {
    return Formix(
      fields: [
        FormixFieldConfig<String>(
          id: nameField,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ),
        FormixFieldConfig<String>(id: countryField, initialValue: 'USA'),
        FormixFieldConfig<String>(
          id: cityField,
          validator: (value) =>
              value == null || value.isEmpty ? 'Select a city' : null,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Async Dependent Fields',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FormixTextFormField(
              fieldId: nameField,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            FormixDropdownFormField<String>(
              fieldId: countryField,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'USA', child: Text('USA')),
                DropdownMenuItem(value: 'India', child: Text('India')),
                DropdownMenuItem(value: 'UK', child: Text('UK')),
              ],
            ),
            const SizedBox(height: 16),

            // Use FormixAsyncField to fetch cities when country changes
            Consumer(
              builder: (context, ref, child) {
                final form = Formix.of(context)!;
                final countryValue = ref.watch(
                  form.select((s) => s.values[countryField.key] as String?),
                );

                return FormixAsyncField<List<String>>(
                  fieldId: cityOptionsField,
                  // We provide a unique key based on the country so the future is re-initialized
                  key: ValueKey(countryValue),
                  future: fetchCities(countryValue),
                  keepPreviousData: true,
                  loadingBuilder: (context) => const LinearProgressIndicator(),
                  builder: (context, state) {
                    final cities = state.asyncState.value ?? [];
                    return FormixDropdownFormField<String>(
                      fieldId: cityField,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      items: cities
                          .map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            const FormixFormStatus(),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final form = Formix.of(context)!;
                final formState = ref.watch(form);
                final controller = ref.read(form.notifier);

                final isSubmitting = formState.isSubmitting;
                final isValid = formState.isValid;
                final isPending = formState.isPending;

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isValid && !isSubmitting && !isPending)
                        ? () async {
                            controller.setSubmitting(true);

                            // Simulate submission
                            await Future.delayed(const Duration(seconds: 2));

                            if (context.mounted) {
                              controller.setSubmitting(false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Submitted: ${formState.values}',
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Submit Form'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
