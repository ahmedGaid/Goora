import '../../features/commute/domain/clock.dart';
import 'calendar_date.dart';

/// Cairo wall-clock time: a [CalendarDate] plus a [Clock] and seconds
/// (research R2). Seconds exist for the 5-minute no-show wait (4:59 vs 5:00).
final class WallTime implements Comparable<WallTime> {
  WallTime(this.date, this.time, [this.second = 0]) : assert(second >= 0 && second < 60);

  factory WallTime.of(DateTime local) =>
      WallTime(CalendarDate.of(local), Clock.hm(local.hour, local.minute), local.second);

  static WallTime fromJson(String s) {
    final [date, time] = s.split('T');
    final [h, m, sec] = time.split(':').map(int.parse).toList();
    return WallTime(CalendarDate.parse(date), Clock.hm(h, m), sec);
  }

  final CalendarDate date;
  final Clock time;
  final int second;

  static const _secondsPerDay = Clock.minutesPerDay * 60;

  int get _secondOfDay => time.minutes * 60 + second;

  WallTime plusSeconds(int seconds) {
    final total = _secondOfDay + seconds;
    final days = (total / _secondsPerDay).floor();
    final rest = total - days * _secondsPerDay;
    return WallTime(date.addDays(days), Clock(rest ~/ 60), rest % 60);
  }

  WallTime plusMinutes(int minutes) => plusSeconds(minutes * 60);

  /// Seconds from this moment to [other] (negative when [other] is earlier).
  int secondsUntil(WallTime other) =>
      date.daysUntil(other.date) * _secondsPerDay + other._secondOfDay - _secondOfDay;

  /// Whole minutes from this moment to [other], rounded up, so a countdown
  /// never shows 0 while time remains.
  int minutesUntil(WallTime other) {
    final s = secondsUntil(other);
    return s <= 0 ? -((-s) ~/ 60) : (s + 59) ~/ 60;
  }

  bool isBefore(WallTime other) => compareTo(other) < 0;
  bool isAfter(WallTime other) => compareTo(other) > 0;

  String toJson() =>
      '${date.toIso()}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}';

  @override
  int compareTo(WallTime other) {
    final byDate = date.compareTo(other.date);
    return byDate != 0 ? byDate : _secondOfDay.compareTo(other._secondOfDay);
  }

  @override
  bool operator ==(Object other) =>
      other is WallTime && other.date == date && other.time == time && other.second == second;

  @override
  int get hashCode => Object.hash(date, time, second);

  @override
  String toString() => toJson();
}
