import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

final hobbiesId = FormixArrayID<String>('hobbies');

class DynamicArrayPage extends StatelessWidget {
  const DynamicArrayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Formix(
      initialValue: const {
        'hobbies': ['Coding', 'Music'],
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Dynamic Form Array')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hobbies', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: FormixArray<String>(
                    id: hobbiesId,
                    itemBuilder: (context, index, itemId, scope) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: FormixTextFormField(
                          fieldId: itemId,
                          decoration: InputDecoration(
                            labelText: 'Hobby ${index + 1}',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              scope.removeArrayItemAt(hobbiesId, index),
                        ),
                      );
                    },
                    emptyBuilder: (context, scope) =>
                        const Center(child: Text('No hobbies added yet.')),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FormixBuilder(
          builder: (context, scope) => FloatingActionButton(
            onPressed: () => scope.addArrayItem(hobbiesId, 'New Hobby'),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
