import 'package:flutter/material.dart';
import 'package:better_form/better_form.dart';

final field1Id = BetterFormFieldID<String>('field_1');
final field2Id = BetterFormFieldID<String>('field_2');
final field3Id = BetterFormFieldID<String>('field_3');
final field4Id = BetterFormFieldID<String>('field_4');
final field5Id = BetterFormFieldID<String>('field_5');

class ProgrammaticControlPage extends StatelessWidget {
  const ProgrammaticControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Control')),
      body: BetterForm(
        fields: [
          BetterFormFieldConfig<String>(id: field1Id),
          BetterFormFieldConfig<String>(id: field2Id),
          BetterFormFieldConfig<String>(
            id: field3Id,
            validator: (val) => val.isEmpty ? 'Required' : null,
          ),
          BetterFormFieldConfig<String>(id: field4Id),
          BetterFormFieldConfig<String>(id: field5Id),
        ],
        child: BetterFormBuilder(
          builder: (context, scope) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => scope.focusField(field5Id),
                        child: const Text('Focus Last'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => scope.scrollToField(field5Id),
                        child: const Text('Scroll Last'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => scope.focusFirstError(),
                        child: const Text('Focus Error'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildField(field1Id, 'First Field'),
                          const SizedBox(height: 200),
                          _buildField(field2Id, 'Second Field'),
                          const SizedBox(height: 200),
                          _buildField(field3Id, 'Third Field (Mandatory)'),
                          const SizedBox(height: 200),
                          _buildField(field4Id, 'Fourth Field'),
                          const SizedBox(height: 200),
                          _buildField(field5Id, 'Last Field'),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildField(BetterFormFieldID<String> id, String label) {
    return RiverpodTextFormField(
      fieldId: id,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
