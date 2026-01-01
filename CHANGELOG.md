## 0.1.0

### 🚀 Major Performance & Memory Improvements

* **Riverpod Selectors for Optimal Performance**: Implemented granular state watching using Riverpod selectors
  - Only affected widgets rebuild when form state changes
  - Significant performance improvements for complex forms
  - Reduced CPU usage and smoother user interactions

* **Auto-Disposable Controllers**: Controllers now automatically clean up memory using `StateNotifierProvider.autoDispose`
  - Prevents memory leaks in long-running applications
  - Zero-configuration automatic disposal
  - Better resource management

* **Enhanced Provider Architecture**: Improved controller provider management
  - Flexible controller binding with `currentControllerProvider`
  - Support for custom controllers and BetterForm integration
  - Proper dependency management for optimal rebuilds

### 🔧 API Improvements

* **Updated Provider Types**: Changed to `AutoDisposeStateNotifierProvider` for automatic disposal
* **Enhanced Widget APIs**: All form field widgets updated with new provider types
* **Better Type Safety**: Improved generic type handling throughout the library

### 🧪 Testing Enhancements

* **Comprehensive Test Coverage**: Added tests for auto-disposal and provider behavior
* **Performance Verification**: Tests ensure optimal rebuild behavior
* **Memory Safety**: Tests verify proper cleanup and disposal

### 📚 Documentation Updates

* **Updated README**: Comprehensive documentation of performance features and auto-disposal
* **Performance Section**: Detailed explanation of Riverpod selectors and benefits
* **Memory Management**: Documentation of auto-disposal features
* **Best Practices**: Updated with performance considerations

### 🗂️ Code Organization Improvements

* **Controller Folder Structure**: Organized controller files into dedicated folder
  - `controllers/controller.dart`: Legacy `BetterFormController`
  - `controllers/riverpod_controller.dart`: `RiverpodFormController` and providers
  - `controllers/field.dart`: Field definitions and configurations
  - `controllers/field_id.dart`: Type-safe field identifiers
  - `controllers/validation.dart`: Validation result classes
* **Widget File Separation**: Split large widget file into focused modules
  - `widgets/text_form_field.dart`: `RiverpodTextFormField` implementation
  - `widgets/number_form_field.dart`: `RiverpodNumberFormField` implementation
  - `widgets/riverpod_form_fields.dart`: Core form widgets and BetterForm
  - `widgets/base_form_field.dart`: Base form field widget classes
  - `widgets/field_selector.dart`: Field selection and listening widgets
  - `widgets/field_derivation.dart`: Field derivation and computed values
  - `widgets/compatibility_widgets.dart`: Legacy widget compatibility
  - `widgets/value_listenable_listeners.dart`: Value listenable builders
* **Better Maintainability**: Smaller, focused files for easier development
* **Clear Separation**: Logical grouping of related functionality
* **Scalable Architecture**: Easy to add new controllers and widgets

### ✨ New Features

* **Declarative Field Configuration**: New `BetterFormFieldConfig` class for declarative field definition
  - Automatic field registration with `BetterForm.fields` parameter
  - No more manual field registration in build methods
  - Cleaner, more intuitive API for form definition

* **Automatic Field Registration**: Fields defined in `BetterForm.fields` are automatically registered
  - Eliminates the need for manual `controller.registerField()` calls
  - Fields are registered when the form builds
  - Maintains backward compatibility with manual registration

### 🔄 Backward Compatibility

* **Maintained API Compatibility**: Existing code continues to work unchanged
* **Migration Path**: Clear upgrade path from manual to declarative field registration
* **Legacy Support**: Manual field registration API still supported for advanced use cases

## 0.0.1

* Initial release with basic form management functionality
* Riverpod-based state management
* Type-safe field definitions
* Basic validation support
* Form field widgets (text, number, checkbox, dropdown)
* Form state tracking (dirty, valid, submitting)
