# 👨‍🍳 Formix Cookbook

This guide provides proven patterns and detailed recipes for building high-quality, professional forms with **Formix**. Whether you're building a simple settings page or a complex clinical trial wizard, these patterns maximize both **User Experience (UX)** and **Developer Experience (DX)**.

---

## 📑 Table of Contents
1. [⚡ The Modern Login Form](#-the-modern-login-form)
2. [🧙‍♂️ Advanced Multi-Step Wizard](#-advanced-multi-step-wizard)
3. [📋 Dynamic Form Arrays (Lists)](#-dynamic-form-arrays-lists)
4. [🔗 Dependent Fields (Async)](#-dependent-fields-async)
5. [🧮 Computed Fields & Derivations](#-computed-fields--derivations)
6. [✨ Headless UI & Custom Components](#-headless-ui--custom-components)
7. [🛡️ Navigation Guards & Persistence](#-navigation-guards--persistence)
8. [🚀 Performance at Scale](#-performance-at-scale)

---

## ⚡ The Modern Login Form
**Problem:** You need a performant login form with validation, submitting state, and auto-focusing on errors.

**Solution:**
```dart
final emailField = FormixFieldID<String>('email');
final passwordField = FormixFieldID<String>('password');

Formix(
  child: Column(
    children: [
      FormixTextFormField(
        fieldId: emailField,
        decoration: InputDecoration(labelText: 'Email'),
        validator: FormixValidators.string().required().email().build(),
      ),
      FormixTextFormField(
        fieldId: passwordField,
        obscureText: true,
        decoration: InputDecoration(labelText: 'Password'),
        validator: FormixValidators.string().required().minLength(8).build(),
      ),
      FormixBuilder(
        builder: (context, scope) => ElevatedButton(
          onPressed: scope.watchIsSubmitting
            ? null
            : () => scope.submit(onValid: _doLogin),
          child: scope.watchIsSubmitting
            ? CircularProgressIndicator()
            : Text('Login'),
        ),
      ),
    ],
  ),
)
```
**💡 Why it works:**
- **DX:** `FormixValidators` provides a human-readable fluent API.
- **UX:** `scope.submit()` automatically scrolls to and focuses the first field with an error if validation fails.

---

## 🧙‍♂️ Advanced Multi-Step Wizard
**Problem:** Maintaining state across multiple pages while ensuring only the "current" step is validated before moving forward.

**Solution:** Use `FormixFieldRegistry` with `preserveStateOnDispose`.

```dart
int _step = 0;

Formix(
  child: Column(
    children: [
      // Only mount the current step.
      // Registration happens lazily, and state is preserved when switching.
      Expanded(
        child: switch(_step) {
          0 => _StepOneFields(), // Personal Info
          1 => _StepTwoFields(), // Address
          _ => _Summary(),
        },
      ),

      FormixBuilder(
        builder: (context, scope) => Row(
          children: [
            if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: Text('Back')),
            ElevatedButton(
              onPressed: () {
                // scope.validate() only validates REGISTERED fields.
                // Since only Step 1 is mounted, it only validates Step 1!
                if (scope.validate()) {
                  setState(() => _step++);
                }
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    ],
  ),
)
```
**💡 Why it works:**
- **DX:** No need for multiple `GlobalKeys` or manual state lifting.
- **UX:** `preserveStateOnDispose` ensures that if a user goes "Back" to Step 1, their previous answers are still there.

---

## 📋 Dynamic Form Arrays (Lists)
**Problem:** Collecting a variable number of items, like "Emergency Contacts" or "Hobbies".

**Solution:**
```dart
final contactsId = FormixArrayID<String>('contacts');

FormixArray<String>(
  id: contactsId,
  itemBuilder: (context, index, itemId, scope) {
    return ListTile(
      title: FormixTextFormField(
        fieldId: itemId, // Use the generated itemId for each row
        decoration: InputDecoration(labelText: 'Contact #${index + 1}'),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => scope.removeArrayItemAt(contactsId, index),
      ),
    );
  },
  emptyBuilder: (context, scope) => Center(child: Text('Add a contact')),
)
```
**💡 why it works:**
- **DX:** `itemId` is automatically scoped to the correct index in the underlying list.
- **UX:** Adding or removing items happens smoothly without losing focus on other fields in the list.

---

## 🔗 Dependent Fields (Async)
**Problem:** Selecting a "Country" should trigger a fetch for "Cities", and changing the country should clear the city selection.

**Solution:** Use `FormixDependentAsyncField`.

```dart
FormixDependentAsyncField<List<String>, String>(
  fieldId: cityOptionsField,
  dependency: countryField,
  resetField: cityField, // Auto-clears 'city' when 'country' changes
  future: (country) => api.fetchCities(country),
  builder: (context, state) {
    final cities = state.asyncState.value ?? [];
    return FormixDropdownFormField<String>(
      fieldId: cityField,
      enabled: cities.isNotEmpty,
      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
    );
  },
)
```
**💡 Why it works:**
- **DX:** Eliminates manual `isLoading` state management and `onChanged` resets.
- **UX:** Built-in race condition protection ensures that if a user switches countries twice quickly, only the *latest* request's results are applied.

---

## 🧮 Computed Fields & Derivations
**Problem:** You need a field that automatically calculates a value based on other fields (e.g., `Total = Quantity * Price`).

**Solution:** Use `FormixFieldDerivation`.

```dart
FormixFieldDerivation<double>(
  id: totalField,
  dependsOn: [quantityField, priceField],
  derive: (scope) {
    final qty = scope.getValue(quantityField) ?? 0;
    final price = scope.getValue(priceField) ?? 0.0;
    return qty * price;
  },
  builder: (context, value) => Text('Total: \$${value.toStringAsFixed(2)}'),
)
```

**Need a 1-to-1 sync?** Use `FormixFieldTransformer`:
```dart
FormixFieldTransformer<String, int>(
  sourceField: bioField,
  targetField: bioLengthField,
  transform: (bio) => bio?.length ?? 0,
)
```

---

## ✨ Headless UI & Custom Components
**Problem:** You want to use a fancy third-party widget (like a Wheel Picker or a Signature Pad) that doesn't know about Formix.

**Solution:** Use `FormixRawFormField`.

```dart
FormixRawFormField<Offset>(
  fieldId: signatureField,
  builder: (context, state) {
    return Column(
      children: [
        SignaturePad(
          points: state.value,
          onUpdate: (val) => state.didChange(val), // Sync back to Formix state
        ),
        if (state.hasError)
          Text(state.validation.errorMessage!, style: TextStyle(color: Colors.red)),
      ],
    );
  },
)
```

---

## 🛡️ Navigation Guards & Persistence
**Problem:** Users accidentally navigating away from a half-filled form or losing data on app restart.

**Solution:** `FormixNavigationGuard` and `FormixPersistence`.

```dart
FormixNavigationGuard(
  onPopInvoked: (didPop, isDirty) {
    if (isDirty && !didPop) {
      // Show "Discard Changes?" dialog
    }
  },
  child: Formix(
    formId: 'checkout_form',
    persistence: LocalStoragePersistence(), // Your implementation
    child: MyFormFields(),
  ),
)
```

---

## 🚀 Performance at Scale
**Problem:** You have a massive form (500+ fields) and typing is becoming laggy.

**Optimization Patterns:**
1. **Granular Rebuilds**: Always use `FormixBuilder` or `FormixFieldSelector` instead of wrapping your entire `Scaffold` in a single `Consumer`.
2. **Batching**: If you need to update 50 fields at once, use `scope.applyBatch(batch)` instead of 50 `setValue` calls.
3. **Lazy Registry**: In multi-step forms, wrap each step in a `FormixFieldRegistry`. This ensures that fields on Page 10 don't even exist in memory while the user is on Page 1.

---
 
**Pro-Tip:** Use the **Formix DevTools** (v2) to visualize your `Dependency Graph` in real-time. It helps you catch circular dependencies and see exactly why a validation re-triggered.
