import 'package:formix/formix.dart';

// Field IDs for type safety
final nameField = FormixFieldID<String>('name');
final emailField = FormixFieldID<String>('email');
final ageField = FormixFieldID<int>('age');
final newsletterField = FormixFieldID<bool>('newsletter');
final passwordField = FormixFieldID<String>('password');
final confirmPasswordField = FormixFieldID<String>('confirmPassword');
final dobField = FormixFieldID<DateTime>('dob');
