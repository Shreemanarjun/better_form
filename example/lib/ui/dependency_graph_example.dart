import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

class DependencyGraphExample extends StatelessWidget {
  const DependencyGraphExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Formix(
      formId: 'dependency_graph_demo',
      fields: [
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('email'),
          initialValue: '',
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('username'),
          initialValue: '',
          // Explicitly depends on email
          dependsOn: [FormixFieldID<String>('email')],
          crossFieldValidator: (v, state) {
            final email = state.values['email'] as String? ?? '';
            if (email.contains('admin') && v != 'admin') {
              return 'Admins must use admin username';
            }
            return null;
          },
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('password'),
          initialValue: '',
          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('confirmPassword'),
          initialValue: '',
          // Explicitly depends on password
          dependsOn: [FormixFieldID<String>('password')],
          crossFieldValidator: (v, state) {
            final password = state.values['password'];
            if (v != password) return 'Passwords do not match';
            return null;
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dependency Graph Demo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Form ID: dependency_graph_demo',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This page demonstrates Formix\'s built-in dependency tracking. '
                  'By using the "dependsOn" property, you inform DevTools about '
                  'relationships between fields. Changes in a dependency will '
                  'automatically trigger re-validation of its dependents.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSection('User Info', [
              FormixTextFormField(
                fieldId: FormixFieldID<String>('email'),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Try typing "admin@example.com"',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              FormixTextFormField(
                fieldId: FormixFieldID<String>('username'),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
            ]),

            const SizedBox(height: 32),

            _buildSection('Security', [
              FormixTextFormField(
                fieldId: FormixFieldID<String>('password'),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              FormixTextFormField(
                fieldId: FormixFieldID<String>('confirmPassword'),
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
            ]),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text(
                    'Open Formix DevTools and check the "Dependency Graph" tab below the fields table!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const FormixFormStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
