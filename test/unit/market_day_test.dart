import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/marketplace/domain/market_day.dart';

/// 005 research R13: next departure, next workday, labels, expiry.
void main() {
  final thu = CalendarDate(2026, 10, 15);
  final sun = CalendarDate(2026, 10, 18);
  const sevenThirty = Clock.hm(7, 30);

  test('the fixture dates are what the names say', () {
    expect(thu.weekday, Day.thu);
    expect(sun.weekday, Day.sun);
  });

  test('Thursday 21:00 → next workday is Sunday (Fri/Sat skipped)', () {
    expect(MarketDay.nextWorkday(sevenThirty, WallTime(thu, const Clock.hm(21, 0))), sun);
  });

  test('today when the time is still ahead', () {
    expect(MarketDay.nextWorkday(sevenThirty, WallTime(thu, const Clock.hm(7, 0))), thu);
  });

  test('exactly at departure counts as passed', () {
    expect(MarketDay.nextWorkday(sevenThirty, WallTime(thu, sevenThirty)), sun);
    expect(MarketDay.isExpired(thu, sevenThirty, WallTime(thu, sevenThirty)), isTrue);
    expect(MarketDay.isExpired(thu, sevenThirty, WallTime(thu, const Clock.hm(7, 29))), isFalse);
  });

  test('a once-a-week car leg that left today runs again in 7 days', () {
    expect(MarketDay.nextDeparture({Day.thu}, sevenThirty, WallTime(thu, const Clock.hm(9, 0))), thu.addDays(7));
  });

  test('no running days → null', () {
    expect(MarketDay.nextDeparture({}, sevenThirty, WallTime(thu, const Clock.hm(6, 0))), isNull);
  });

  test('labels: today, tomorrow, weekday', () {
    expect(MarketDay.labelFor(thu, thu), MarketDayLabel.today);
    expect(MarketDay.labelFor(thu.addDays(1), thu), MarketDayLabel.tomorrow);
    expect(MarketDay.labelFor(sun, thu), MarketDayLabel.weekday);
  });
}
