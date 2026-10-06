import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';

void main() {
  group('CalendarDate', () {
    test('weekday → Day for a known week (Sun 4 Oct 2026 … Sat 10 Oct)', () {
      final sunday = CalendarDate(2026, 10, 4);
      expect([for (var i = 0; i < 7; i++) sunday.addDays(i).weekday], Day.values);
    });

    test('month rollover', () {
      expect(CalendarDate(2026, 10, 31).addDays(1), CalendarDate(2026, 11, 1));
      expect(CalendarDate(2026, 11, 1).addDays(-1), CalendarDate(2026, 10, 31));
      expect(CalendarDate(2026, 2, 28).addDays(1), CalendarDate(2026, 3, 1));
    });

    test('year rollover', () {
      expect(CalendarDate(2026, 12, 31).addDays(1), CalendarDate(2027, 1, 1));
      expect(CalendarDate(2027, 1, 1).monthKey, '2027-01');
    });

    test('monthKey, daysUntil, iso round trip', () {
      final d = CalendarDate(2026, 10, 6);
      expect(d.monthKey, '2026-10');
      expect(d.daysUntil(CalendarDate(2026, 11, 3)), 28);
      expect(d.daysUntil(CalendarDate(2026, 10, 1)), -5);
      expect(CalendarDate.parse(d.toIso()), d);
      expect(d.toIso(), '2026-10-06');
    });
  });

  group('WallTime', () {
    final mon = CalendarDate(2026, 10, 5);
    final tue = mon.addDays(1);

    test('orders across midnight', () {
      final lateMon = WallTime(mon, const Clock.hm(23, 59), 59);
      final earlyTue = WallTime(tue, const Clock.hm(0, 0));
      expect(lateMon.isBefore(earlyTue), isTrue);
      expect(lateMon.secondsUntil(earlyTue), 1);
      expect(lateMon.plusSeconds(1), earlyTue);
      expect(earlyTue.plusMinutes(-1), WallTime(mon, const Clock.hm(23, 59)));
    });

    test('minutesUntil rounds remaining time up and counts across days', () {
      final at = WallTime(mon, const Clock.hm(7, 13), 30);
      expect(at.minutesUntil(WallTime(mon, const Clock.hm(7, 25))), 12);
      expect(WallTime(mon, const Clock.hm(21, 0)).minutesUntil(WallTime(tue, const Clock.hm(7, 0))), 600);
      expect(WallTime(tue, const Clock.hm(7, 30)).minutesUntil(WallTime(tue, const Clock.hm(7, 25))), -5);
    });

    test('json round trip keeps seconds', () {
      final t = WallTime(tue, const Clock.hm(7, 24), 59);
      expect(t.toJson(), '2026-10-06T07:24:59');
      expect(WallTime.fromJson(t.toJson()), t);
    });
  });
}
