import 'package:flutter/material.dart';
import 'form_builder.dart';

/// A widget that displays the current status of a Formix form.
///
/// It watches the form's dirty, valid, and submitting states and updates
/// automatically.
class FormixFormStatus extends StatelessWidget {
  /// Creates a [FormixFormStatus].
  const FormixFormStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return FormixBuilder(
      builder: (context, scope) {
        final isDirty = scope.watchIsFormDirty;
        final isValid = scope.watchIsValid;
        final isSubmitting = scope.watchIsSubmitting;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Form Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isDirty ? Icons.edit_note : Icons.check_circle_outline,
                      size: 16,
                      color: isDirty ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(isDirty ? 'Modified' : 'Pristine'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isValid ? Icons.verified_user : Icons.error_outline,
                      size: 16,
                      color: isValid ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text('Valid: $isValid'),
                  ],
                ),
                if (isSubmitting) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text(
                    'Submitting...',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
