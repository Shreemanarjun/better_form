import 'package:flutter/material.dart';
import 'package:formix/formix.dart';

// Derived Fields Example
class DerivedFieldsExample extends ConsumerWidget {
  const DerivedFieldsExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DerivedFieldsExampleContent();
  }
}

class DerivedFieldsExampleContent extends ConsumerStatefulWidget {
  const DerivedFieldsExampleContent({super.key});

  @override
  ConsumerState<DerivedFieldsExampleContent> createState() =>
      _DerivedFieldsExampleContentState();
}

class _DerivedFieldsExampleContentState
    extends ConsumerState<DerivedFieldsExampleContent> {
  @override
  Widget build(BuildContext context) {
    return Formix(
      formId: 'derived_fields_example',
      initialValue: {
        'firstName': '',
        'lastName': '',
        'fullName': '',
        'birthYear': 2000,
        'currentYear': DateTime.now().year,
        'age': 0,
        'price': 100.0,
        'quantity': 1,
        'total': 100.0,
        'discountPercent': 0.0,
        'finalTotal': 100.0,
      },
      fields: [
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('firstName'),
          initialValue: '',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('lastName'),
          initialValue: '',
        ),
        FormixFieldConfig<String>(
          id: FormixFieldID<String>('fullName'),
          initialValue: '',
        ),
        FormixFieldConfig<int>(
          id: FormixFieldID<int>('birthYear'),
          initialValue: 2000,
        ),
        FormixFieldConfig<int>(
          id: FormixFieldID<int>('currentYear'),
          initialValue: DateTime.now().year,
        ),
        FormixFieldConfig<int>(id: FormixFieldID<int>('age'), initialValue: 0),
        FormixFieldConfig<double>(
          id: FormixFieldID<double>('price'),
          initialValue: 100.0,
        ),
        FormixFieldConfig<int>(
          id: FormixFieldID<int>('quantity'),
          initialValue: 1,
        ),
        FormixFieldConfig<double>(
          id: FormixFieldID<double>('total'),
          initialValue: 100.0,
        ),
        FormixFieldConfig<double>(
          id: FormixFieldID<double>('discountPercent'),
          initialValue: 0.0,
        ),
        FormixFieldConfig<double>(
          id: FormixFieldID<double>('finalTotal'),
          initialValue: 100.0,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Derived Fields',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fields that automatically calculate values based on other fields',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Full Name Derivation
            const Text(
              'Full Name Calculation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FormixTextFormField(
                    fieldId: FormixFieldID<String>('firstName'),
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormixTextFormField(
                    fieldId: FormixFieldID<String>('lastName'),
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Full Name:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final fullName = ref.watch(
                        fieldValueProvider(FormixFieldID<String>('fullName')),
                      );
                      return Text(
                        fullName?.isEmpty ?? true
                            ? 'Enter names above'
                            : fullName!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Age Calculation
            const Text(
              'Age Calculation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            FormixNumberFormField(
              fieldId: FormixFieldID<int>('birthYear'),
              min: 1900,
              max: DateTime.now().year,
              decoration: const InputDecoration(
                labelText: 'Birth Year',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Calculated Age:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final age = ref.watch(
                        fieldValueProvider(FormixFieldID<int>('age')),
                      );
                      return Text(
                        '$age years old',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Shopping Cart Total
            const Text(
              'Shopping Cart Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FormixNumberFormField(
                    fieldId: FormixFieldID<double>('price'),
                    min: 0,
                    decoration: const InputDecoration(
                      labelText: 'Price per Item',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormixNumberFormField(
                    fieldId: FormixFieldID<int>('quantity'),
                    min: 1,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.shopping_cart),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Subtotal:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final total = ref.watch(
                        fieldValueProvider(FormixFieldID<double>('total')),
                      );
                      return Text(
                        '\$${total?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Discount
            FormixNumberFormField(
              fieldId: FormixFieldID<double>('discountPercent'),
              min: 0,
              max: 100,
              decoration: const InputDecoration(
                labelText: 'Discount (%)',
                prefixIcon: Icon(Icons.discount),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'Final Total:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final finalTotal = ref.watch(
                        fieldValueProvider(FormixFieldID<double>('finalTotal')),
                      );
                      return Text(
                        '\$${finalTotal?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Custom Field Derivation Implementation
            // This demonstrates how to implement field derivation without circular dependencies
            Consumer(
              builder: (context, ref, child) {
                final firstName =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<String>('firstName')),
                    ) ??
                    '';
                final lastName =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<String>('lastName')),
                    ) ??
                    '';
                final fullName = '$firstName $lastName'.trim();

                // Update the derived field value
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Formix.controllerOf(context);
                  if (controller != null) {
                    controller.setValue(
                      FormixFieldID<String>('fullName'),
                      fullName,
                    );
                  }
                });

                return const SizedBox.shrink();
              },
            ),

            Consumer(
              builder: (context, ref, child) {
                final birthYear =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<int>('birthYear')),
                    ) ??
                    2000;
                final currentYear =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<int>('currentYear')),
                    ) ??
                    DateTime.now().year;
                final age = currentYear - birthYear;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Formix.controllerOf(context);
                  if (controller != null) {
                    controller.setValue(FormixFieldID<int>('age'), age);
                  }
                });

                return const SizedBox.shrink();
              },
            ),

            Consumer(
              builder: (context, ref, child) {
                final price =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<double>('price')),
                    ) ??
                    0.0;
                final quantity =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<int>('quantity')),
                    ) ??
                    1;
                final total = price * quantity;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Formix.controllerOf(context);
                  if (controller != null) {
                    controller.setValue(FormixFieldID<double>('total'), total);
                  }
                });

                return const SizedBox.shrink();
              },
            ),

            Consumer(
              builder: (context, ref, child) {
                final total =
                    ref.watch(
                      fieldValueProvider(FormixFieldID<double>('total')),
                    ) ??
                    0.0;
                final discountPercent =
                    ref.watch(
                      fieldValueProvider(
                        FormixFieldID<double>('discountPercent'),
                      ),
                    ) ??
                    0.0;
                final discountAmount = total * (discountPercent / 100);
                final finalTotal = total - discountAmount;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = Formix.controllerOf(context);
                  if (controller != null) {
                    controller.setValue(
                      FormixFieldID<double>('finalTotal'),
                      finalTotal,
                    );
                  }
                });

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),
            const FormixFormStatus(),
          ],
        ),
      ),
    );
  }
}
