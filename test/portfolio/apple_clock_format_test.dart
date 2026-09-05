import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/widgets/apple_clock_format.dart';

void main() {
  test('formats midnight, noon, and afternoon on a 12-hour clock', () {
    expect(formatApple12HourTime(DateTime(2026, 9, 5)), '12:00');
    expect(formatApple12HourTime(DateTime(2026, 9, 5, 9, 5)), '9:05');
    expect(formatApple12HourTime(DateTime(2026, 9, 5, 12)), '12:00');
    expect(formatApple12HourTime(DateTime(2026, 9, 5, 13, 5)), '1:05');
    expect(formatApple12HourTime(DateTime(2026, 9, 5, 23, 59)), '11:59');
  });
}
