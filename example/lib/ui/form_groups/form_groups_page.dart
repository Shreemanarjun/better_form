import 'package:flutter/material.dart';
import 'package:better_form/better_form.dart';

class FormGroupsPage extends StatelessWidget {
  const FormGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Groups & Namespacing')),
      body: BetterForm(
        initialValue: const {
          'user.name': 'John Doe',
          'address.city': 'New York',
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Info',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const BetterFormGroup(
                prefix: 'user',
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: BetterFormFieldID('name'),
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    RiverpodTextFormField(
                      fieldId: BetterFormFieldID('email'),
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const BetterFormGroup(
                prefix: 'address',
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: BetterFormFieldID('street'),
                      decoration: InputDecoration(labelText: 'Street'),
                    ),
                    RiverpodTextFormField(
                      fieldId: BetterFormFieldID('city'),
                      decoration: InputDecoration(labelText: 'City'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Nested Group (Delivery Notice)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const BetterFormGroup(
                prefix: 'delivery',
                child: BetterFormGroup(
                  prefix: 'notice',
                  child: RiverpodTextFormField(
                    fieldId: BetterFormFieldID('note'),
                    decoration: InputDecoration(
                      labelText: 'Special Instructions',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              BetterFormBuilder(
                builder: (context, scope) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final nested = scope.toNestedMap();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Nested JSON Output'),
                              content: Text(nested.toString()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('View Nested JSON'),
                      ),
                      const SizedBox(height: 16),
                      _GroupStatus(prefix: 'user', label: 'User Info'),
                      _GroupStatus(prefix: 'address', label: 'Address'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupStatus extends BetterFormWidget {
  final String prefix;
  final String label;

  const _GroupStatus({required this.prefix, required this.label});

  @override
  Widget buildForm(BuildContext context, BetterFormScope scope) {
    final isValid = scope.watchGroupIsValid(prefix);
    final isDirty = scope.watchGroupIsDirty(prefix);

    return ListTile(
      title: Text('$label Status'),
      subtitle: Text('Valid: $isValid, Modified: $isDirty'),
      trailing: Icon(
        isValid ? Icons.check_circle : Icons.error,
        color: isValid ? Colors.green : Colors.red,
      ),
    );
  }
}
