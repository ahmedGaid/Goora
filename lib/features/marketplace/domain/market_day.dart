import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';

enum MarketDayLabel { today, tomorrow, weekday }

/// Which day a seat, offer or request is for (005 research R13). There is no
/// date picker: a time resolves to its next occurrence that hasn't left yet.
abstract final class MarketDay {
  static const workdays = {Day.sun, Day.mon, Day.tue, Day.wed, Day.thu};

  /// Today when [departure] is still ahead and today runs, else the next
  /// running day within 7 days; null when [days] is empty.
  static CalendarDate? nextDeparture(Set<Day> days, Clock departure, WallTime now) {
    for (var i = 0; i <= 7; i++) {
      final date = now.date.addDays(i);
      if (!days.contains(date.weekday)) continue;
      if (i > 0 || now.isBefore(WallTime(date, departure))) return date;
    }
    return null;
  }

  /// The next Sun–Thu occurrence of [departure], today included if still ahead.
  static CalendarDate nextWorkday(Clock departure, WallTime now) => nextDeparture(workdays, departure, now)!;

  static MarketDayLabel labelFor(CalendarDate date, CalendarDate today) => switch (today.daysUntil(date)) {
    0 => MarketDayLabel.today,
    1 => MarketDayLabel.tomorrow,
    _ => MarketDayLabel.weekday,
  };

  /// A request expires, and seats and offers stop listing, once now ≥ its
  /// date + time — exactly at departure counts as passed.
  static bool isExpired(CalendarDate date, Clock departure, WallTime now) => !now.isBefore(WallTime(date, departure));
}
