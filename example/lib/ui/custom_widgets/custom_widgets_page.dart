import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

class CustomWidgetsPage extends StatefulWidget {
  const CustomWidgetsPage({super.key});

  @override
  State<CustomWidgetsPage> createState() => _CustomWidgetsPageState();
}

class _CustomWidgetsPageState extends State<CustomWidgetsPage> {
  static const _textId = FormixFieldID<String>('text_field');
  static const _checkboxId = FormixFieldID<bool>('checkbox_field');
  static const _dropdownId = FormixFieldID<String>('dropdown_field');
  static const _numberId = FormixFieldID<int>('number_field');
  static const _asyncId = FormixFieldID<String>('async_field');
  static const _selectorId = FormixFieldID<String>('selector_field');
  static const _arrayId = FormixArrayID<String>('string_array');
  static const _taxId = FormixFieldID<double>('tax_field');
  static const _zipCodeId = FormixFieldID<String>('zip_code_field');
  static const _cityId = FormixFieldID<String>('city_field');
  static const _countryId = FormixFieldID<String>('country_field');
  static const _dependentCityId = FormixFieldID<String>('dependent_city_field');

  final _formKey = GlobalKey<FormixState>();

  static String? _requiredValidator(dynamic value) {
    if (value == null) return 'This field is required';
    if (value is String && value.isEmpty) return 'This field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Formix(
      key: _formKey,
      // Initialize array with one item so it's not null/empty initially for demo
      initialValue: const <String, dynamic>{
        'string_array': ['Item 1'],
      },
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Custom Widgets Gallery',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This page demonstrates all library-provided custom widgets.',
              ),
              const SizedBox(height: 20),

              const Text(
                '1. FormixFormStatus',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const FormixFormStatus(),
              const SizedBox(height: 20),

              const Text(
                '2. FormixTextFormField & FormixSection',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<String>(
                    id: _textId,
                    initialValue: 'Initial Text',
                    validator: _requiredValidator,
                  ),
                ],
                child: const FormixTextFormField(
                  fieldId: _textId,
                  decoration: InputDecoration(labelText: 'Text Field'),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '3. FormixCheckboxFormField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<bool>(id: _checkboxId, initialValue: false),
                ],
                child: const FormixCheckboxFormField(
                  fieldId: _checkboxId,
                  title: Text('Checkbox Field'),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '4. FormixDropdownFormField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<String>(
                    id: _dropdownId,
                    validator: _requiredValidator,
                  ),
                ],
                child: FormixDropdownFormField<String>(
                  fieldId: _dropdownId,
                  decoration: const InputDecoration(
                    labelText: 'Dropdown Field',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Option A',
                      child: Text('Option A'),
                    ),
                    DropdownMenuItem(
                      value: 'Option B',
                      child: Text('Option B'),
                    ),
                    DropdownMenuItem(
                      value: 'Option C',
                      child: Text('Option C'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '5. FormixNumberFormField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<int>(id: _numberId, initialValue: 0),
                ],
                child: const FormixNumberFormField<int>(
                  fieldId: _numberId,
                  decoration: InputDecoration(labelText: 'Number Field (Int)'),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '6. FormixAsyncField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [FormixFieldConfig<String>(id: _asyncId)],
                child: FormixAsyncField<String>(
                  fieldId: _asyncId,
                  // Use dependencies: [] to prevent refreshing on rebuilds/hot-reload
                  dependencies: const [],
                  future: Future.delayed(
                    const Duration(seconds: 2),
                    () => 'Loaded from Async',
                  ),
                  loadingBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                  builder: (context, state) {
                    return ListTile(
                      title: const Text('Async Data'),
                      subtitle: Text(state.asyncState.value ?? 'No data'),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => state.refresh(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '7. FormixDependentField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Shows if checkbox is checked:'),
              FormixDependentField<bool>(
                fieldId: _checkboxId,
                builder: (context, isChecked) {
                  if (isChecked == true) {
                    return const Card(
                      color: Colors.greenAccent,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('Checkbox is CHECKED!'),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),

              const Text(
                '8. FormixFieldSelector',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<String>(
                    id: _selectorId,
                    initialValue: 'Type here to see details',
                  ),
                ],
                child: Column(
                  children: [
                    const FormixTextFormField(
                      fieldId: _selectorId,
                      decoration: InputDecoration(labelText: 'Selector Input'),
                    ),
                    const SizedBox(height: 8),
                    FormixFieldSelector<String>(
                      fieldId: _selectorId,
                      builder: (context, info, child) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Value: ${info.value}'),
                              Text('Is Dirty: ${info.isDirty}'),
                              Text('Is Valid: ${info.validation.isValid}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '9. FormixListener',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixListener(
                formKey: _formKey,
                listener: (context, state) {
                  // We can listen to state changes here
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: const Text(
                    'Listener is active on this form (watching global state)',
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '10. FormixArray',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              FormixBuilder(
                builder: (context, scope) {
                  return Column(
                    children: [
                      FormixArray<String>(
                        id: _arrayId,
                        itemBuilder: (context, index, itemId, scope) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FormixTextFormField(
                                    fieldId: itemId,
                                    decoration: InputDecoration(
                                      labelText: 'Item ${index + 1}',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      scope.removeArrayItemAt(_arrayId, index),
                                ),
                              ],
                            ),
                          );
                        },
                        emptyBuilder: (context, scope) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No items in array'),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        onPressed: () =>
                            scope.addArrayItem(_arrayId, 'New Item'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              const Text(
                '11. FormixFieldTransformer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Calculates 10% Tax from Price field:'),
              FormixSection(
                fields: [
                  FormixFieldConfig<double>(id: _taxId, initialValue: 0),
                ],
                child: Column(
                  children: [
                    const FormixNumberFormField<double>(
                      fieldId: _taxId,
                      decoration: InputDecoration(
                        labelText: 'Tax (10% of Price) - Auto Calculated',
                        prefixText: '\$ ',
                      ),
                      readOnly: true,
                    ),
                    FormixFieldTransformer<int, double>(
                      sourceField: _numberId,
                      targetField: _taxId,
                      transform: (price) => (price ?? 0) * 0.10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '12. FormixFieldAsyncTransformer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Simulates fetching City from Zip Code (Simulated Async):',
              ),
              FormixSection(
                fields: [
                  FormixFieldConfig<String>(id: _zipCodeId, initialValue: ''),
                  FormixFieldConfig<String>(id: _cityId, initialValue: ''),
                ],
                child: Column(
                  children: [
                    const FormixTextFormField(
                      fieldId: _zipCodeId,
                      decoration: InputDecoration(
                        labelText: 'Zip Code (Type "90210" for Beverly Hills)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const FormixTextFormField(
                      fieldId: _cityId,
                      decoration: InputDecoration(
                        labelText: 'City (Auto-Fetched)',
                        suffixIcon: Icon(Icons.location_city),
                      ),
                      readOnly: true,
                    ),
                    FormixFieldAsyncTransformer<String, String>(
                      sourceField: _zipCodeId,
                      targetField: _cityId,
                      debounce: const Duration(milliseconds: 800),
                      transform: (zip) async {
                        if (zip == null || zip.length < 3) return '';
                        await Future.delayed(const Duration(seconds: 2));
                        if (zip == '90210') return 'Beverly Hills';
                        if (zip == '10001') return 'New York';
                        return 'Unknown City';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '13. FormixDependentAsyncField',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('Fetch city options based on selected Country:'),
              FormixSection(
                fields: [
                  FormixFieldConfig<String>(id: _countryId),
                  FormixFieldConfig<String>(id: _dependentCityId),
                ],
                child: Column(
                  children: [
                    FormixDropdownFormField<String>(
                      fieldId: _countryId,
                      decoration: const InputDecoration(labelText: 'Country'),
                      items: const [
                        DropdownMenuItem(value: 'USA', child: Text('USA')),
                        DropdownMenuItem(
                          value: 'Canada',
                          child: Text('Canada'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FormixDependentAsyncField<List<String>, String>(
                      fieldId: const FormixFieldID('city_options'),
                      dependency: _countryId,
                      resetField: _dependentCityId,
                      future: (country) async {
                        if (country == null) return [];
                        await Future.delayed(const Duration(seconds: 1));
                        if (country == 'USA') {
                          return ['New York', 'LA', 'Chicago'];
                        }
                        if (country == 'Canada') {
                          return ['Toronto', 'Vancouver', 'Montreal'];
                        }
                        return [];
                      },
                      loadingBuilder: (context) =>
                          const LinearProgressIndicator(),
                      builder: (context, state) {
                        final cities = state.asyncState.value ?? [];
                        return FormixDropdownFormField<String>(
                          fieldId: _dependentCityId,
                          decoration: const InputDecoration(
                            labelText: 'Select City',
                          ),
                          items: cities
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          validator: (val) => val == null ? 'Required' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
