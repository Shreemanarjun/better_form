import 'package:better_form/better_form.dart';

// Field IDs for type safety
final nameField = BetterFormFieldID<String>('name');
final emailField = BetterFormFieldID<String>('email');
final ageField = BetterFormFieldID<int>('age');
final newsletterField = BetterFormFieldID<bool>('newsletter');
final passwordField = BetterFormFieldID<String>('password');
final confirmPasswordField = BetterFormFieldID<String>('confirmPassword');
final dobField = BetterFormFieldID<DateTime>('dob');
