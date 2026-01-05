import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

class FormGroupsPage extends StatelessWidget {
  const FormGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Groups & Namespacing')),
      body: Formix(
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
              const FormixGroup(
                prefix: 'user',
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: FormixFieldID('name'),
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    RiverpodTextFormField(
                      fieldId: FormixFieldID('email'),
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
              const FormixGroup(
                prefix: 'address',
                child: Column(
                  children: [
                    RiverpodTextFormField(
                      fieldId: FormixFieldID('street'),
                      decoration: InputDecoration(labelText: 'Street'),
                    ),
                    RiverpodTextFormField(
                      fieldId: FormixFieldID('city'),
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
              const FormixGroup(
                prefix: 'delivery',
                child: FormixGroup(
                  prefix: 'notice',
                  child: RiverpodTextFormField(
                    fieldId: FormixFieldID('note'),
                    decoration: InputDecoration(
                      labelText: 'Special Instructions',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FormixBuilder(
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

class _GroupStatus extends FormixWidget {
  final String prefix;
  final String label;

  const _GroupStatus({required this.prefix, required this.label});

  @override
  Widget buildForm(BuildContext context, FormixScope scope) {
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
