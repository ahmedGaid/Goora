import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';

void main() {
  test('31 Jan + 1 month → 28 Feb in a non-leap year', () {
    expect(CalendarDate(2026, 1, 31).addMonths(1), CalendarDate(2026, 2, 28));
  });

  test('31 Jan + 1 month → 29 Feb in a leap year', () {
    expect(CalendarDate(2028, 1, 31).addMonths(1), CalendarDate(2028, 2, 29));
  });

  test('31 Mar + 1 month → 30 Apr', () {
    expect(CalendarDate(2026, 3, 31).addMonths(1), CalendarDate(2026, 4, 30));
  });

  test('31 Dec + 1 month → 31 Jan next year', () {
    expect(CalendarDate(2026, 12, 31).addMonths(1), CalendarDate(2027, 1, 31));
  });

  test('a mid-month date is unaffected by clamping', () {
    expect(CalendarDate(2026, 1, 15).addMonths(1), CalendarDate(2026, 2, 15));
  });
}
