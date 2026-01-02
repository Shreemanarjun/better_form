import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:better_form/better_form.dart';

// Headless Form Example
class HeadlessFormExample extends ConsumerWidget {
  const HeadlessFormExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HeadlessFormExampleContent();
  }
}

class HeadlessFormExampleContent extends ConsumerStatefulWidget {
  const HeadlessFormExampleContent({super.key});

  @override
  ConsumerState<HeadlessFormExampleContent> createState() =>
      _HeadlessFormExampleContentState();
}

class _HeadlessFormExampleContentState
    extends ConsumerState<HeadlessFormExampleContent> {
  @override
  Widget build(BuildContext context) {
    return BetterForm(
      initialValue: {
        'rating': 3,
        'feedback': '',
        'wouldRecommend': false,
        'satisfaction': 5,
      },
      fields: [
        BetterFormFieldConfig<int>(
          id: BetterFormFieldID<int>('rating'),
          initialValue: 3,
          validator: (value) {
            if (value < 1 || value > 5) return 'Rating must be between 1 and 5';
            return null;
          },
        ),
        BetterFormFieldConfig<String>(
          id: BetterFormFieldID<String>('feedback'),
          initialValue: '',
          validator: (value) {
            if (value.isEmpty) return 'Please provide feedback';
            if (value.length < 10) {
              return 'Feedback must be at least 10 characters';
            }
            return null;
          },
        ),
        BetterFormFieldConfig<bool>(
          id: BetterFormFieldID<bool>('wouldRecommend'),
          initialValue: false,
        ),
        BetterFormFieldConfig<int>(
          id: BetterFormFieldID<int>('satisfaction'),
          initialValue: 5,
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Headless Form Widgets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Custom form controls using headless widgets with full control over UI',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Custom Star Rating Widget
            const Text(
              'Star Rating (Headless)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            BetterFormFieldSelector<int>(
              fieldId: BetterFormFieldID<int>('rating'),
              builder: (context, info, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          onPressed: () {
                            final controller = BetterForm.controllerOf(context);
                            controller?.setValue(
                              BetterFormFieldID<int>('rating'),
                              starValue,
                            );
                          },
                          icon: Icon(
                            starValue <= (info.value ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    if (!info.validation.isValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          info.validation.errorMessage ?? '',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Custom Feedback Text Field with Character Counter
            const Text(
              'Feedback (Headless Text Field)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            BetterRawTextField<String>(
              fieldId: BetterFormFieldID<String>('feedback'),
              valueToString: (value) => value ?? '',
              stringToValue: (text) => text,
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: !snapshot.validation.isValid
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: snapshot.textController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tell us what you think...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: snapshot.didChange,
                        onEditingComplete: snapshot.markAsTouched,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!snapshot.validation.isValid)
                          Text(
                            snapshot.validation.errorMessage ?? '',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          '${snapshot.value?.length ?? 0}/500',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Custom Toggle Switch
            const Text(
              'Would Recommend (Headless)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            BetterFormFieldSelector<bool>(
              fieldId: BetterFormFieldID<bool>('wouldRecommend'),
              builder: (context, info, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (info.value ?? false)
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (info.value ?? false)
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Would you recommend this product?',
                          style: TextStyle(
                            fontSize: 16,
                            color: (info.value ?? false)
                                ? Colors.green.shade800
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Switch(
                        value: info.value ?? false,
                        onChanged: (value) {
                          final controller = BetterForm.controllerOf(context);
                          controller?.setValue(
                            BetterFormFieldID<bool>('wouldRecommend'),
                            value,
                          );
                        },
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Custom Slider for Satisfaction
            const Text(
              'Satisfaction Level (Headless)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            BetterFormFieldSelector<int>(
              fieldId: BetterFormFieldID<int>('satisfaction'),
              builder: (context, info, child) {
                final value = info.value ?? 5;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sentiment_dissatisfied,
                          color: Colors.red,
                        ),
                        Expanded(
                          child: Slider(
                            value: value.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (newValue) {
                              final controller = BetterForm.controllerOf(
                                context,
                              );
                              controller?.setValue(
                                BetterFormFieldID<int>('satisfaction'),
                                newValue.round(),
                              );
                            },
                          ),
                        ),
                        const Icon(
                          Icons.sentiment_satisfied,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        'Satisfaction: $value/10',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            const RiverpodFormStatus(),
            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final controllerProvider = BetterForm.of(context)!;
                ref.read(controllerProvider.notifier);
                final formState = ref.watch(controllerProvider);

                return ElevatedButton(
                  onPressed: () {
                    final values = formState.values;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Survey Results'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children:
                                [
                                      Text('Rating: ${values['rating']} stars'),
                                      Text('Feedback: ${values['feedback']}'),
                                      Text(
                                        'Would Recommend: ${values['wouldRecommend']}',
                                      ),
                                      Text(
                                        'Satisfaction: ${values['satisfaction']}/10',
                                      ),
                                    ]
                                    .map(
                                      (widget) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: widget,
                                      ),
                                    )
                                    .toList(),
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
                  child: const Text('Submit Survey'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
