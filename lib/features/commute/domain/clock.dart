/// A time of day in minutes since midnight (no date, no time zone).
final class Clock implements Comparable<Clock> {
  const Clock(this.minutes) : assert(minutes >= 0 && minutes < minutesPerDay);

  const Clock.hm(int hour, int minute) : this(hour * 60 + minute);

  static const minutesPerDay = 24 * 60;

  final int minutes;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;
  bool get isAm => hour < 12;

  /// 12-hour clock text with Western digits, e.g. `7:30` (AM/PM added by l10n).
  String get h12 => '${(hour + 11) % 12 + 1}:${minute.toString().padLeft(2, '0')}';

  int diff(Clock other) => (minutes - other.minutes).abs();

  /// Moves by [delta] minutes, staying within the same day.
  Clock shift(int delta) => Clock((minutes + delta).clamp(0, minutesPerDay - 1));

  @override
  int compareTo(Clock other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) => other is Clock && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;
}
