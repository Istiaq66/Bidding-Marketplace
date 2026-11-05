import 'package:app/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatMoney uses dollars, two decimals and grouping', () {
    expect(formatMoney(5), r'$5.00');
    expect(formatMoney(105.5), r'$105.50');
    expect(formatMoney(1250), r'$1,250.00');
    expect(formatMoney(1234567.891), r'$1,234,567.89');
  });
}
