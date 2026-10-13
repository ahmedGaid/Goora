import '../../../core/time/calendar_date.dart';
import 'driver_day_rules.dart';

/// A driver's trips on one date (005 data-model.md): the 003 schedule legs
/// they actually drive plus their offered trips that count (R5). Derived —
/// feeds `DriverDayRules.fit` and `tripsLeft`.
final class DriverDay {
  const DriverDay({required this.date, required this.trips, required this.leadsGroup});

  final CalendarDate date;
  final List<DayTrip> trips;

  /// The driver already drives a daily commute group.
  final bool leadsGroup;

  int get tripsLeft => DriverDayRules.tripsLeft(trips);
}
