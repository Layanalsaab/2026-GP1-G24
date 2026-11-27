import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/shared_ui/widgets/forms/select_field.dart';

void main() {
  test('a picked Other shows as "Other: what was typed"', () {
    expect(SelectField.otherText('SportsTech'), 'Other: SportsTech');
    expect(SelectField.otherText('  SportsTech  '), 'Other: SportsTech');
  });

  test('a picked Other with nothing typed shows as "Other"', () {
    expect(SelectField.otherText(''), 'Other');
    expect(SelectField.otherText('   '), 'Other');
  });
}
