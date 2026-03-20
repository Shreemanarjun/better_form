import 'package:formix/formix.dart';
void main() {
  const ageField = FormixFieldID<int>('age');
  var field = const FormixField<int>(id: ageField, initialValue: 0);
  print(field.isTypeValid('wrong type'));
}
