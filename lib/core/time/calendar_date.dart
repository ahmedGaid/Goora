import '../../features/commute/domain/commute_profile.dart';

/// A date without a time or time zone (research R2). Rules compare dates in
/// Cairo wall-clock terms, so summer-time shifts cannot move a boundary.
final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(int year, int month, int day) : this._(DateTime.utc(year, month, day));

  /// For dates already known to be valid (seed data); no normalising.
  const CalendarDate.ymd(this.year, this.month, this.day);

  CalendarDate._(DateTime utc)
      : year = utc.year,
        month = utc.month,
        day = utc.day;

  /// The calendar date of a local [DateTime].
  factory CalendarDate.of(DateTime local) => CalendarDate(local.year, local.month, local.day);

  /// Parses `yyyy-mm-dd`.
  factory CalendarDate.parse(String iso) {
    final parts = iso.split('-').map(int.parse).toList();
    return CalendarDate(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Sunday-first weekday (`DateTime.weekday` is Monday = 1 … Sunday = 7).
  Day get weekday => Day.values[_utc.weekday % 7];

  CalendarDate addDays(int days) => CalendarDate._(_utc.add(Duration(days: days)));

  /// `2026-10`: the key no-show counts reset on.
  String get monthKey => '$year-${_two(month)}';

  /// Whole days from this date to [other] (negative when [other] is earlier).
  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;
  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  String toIso() => '$year-${_two(month)}-${_two(day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  int compareTo(CalendarDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
