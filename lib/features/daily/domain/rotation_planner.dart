import '../../../core/time/calendar_date.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import 'schedule.dart';

/// Fair driver rotation (brief §6.4, FR-022, SC-005, research R5).
///
/// Per leg, independently, over consecutive 4-week periods from the group's
/// `rotationStart`: each ride day goes to the eligible driver with the fewest
/// drives on that leg this period; ties → longest since their last drive on
/// that leg → lowest member id. With equal availability this is round-robin,
/// so max − min ≤ 1 per leg per period. Returns *planned* drivers only;
/// absences and backups are applied on top by the repository.
abstract final class RotationPlanner {
  static const periodDays = 28;

  /// Used when a group has no `rotationStart` (a Sunday).
  static final defaultStart = CalendarDate(2026, 1, 4);

  static List<ScheduleDay> plan(
    CommuteGroup g,
    CalendarDate from,
    CalendarDate to, {
    Set<(String, CalendarDate, Leg)> unavailable = const {},
  }) {
    final start = g.rotationStart ?? defaultStart;
    int periodOf(CalendarDate d) => (start.daysUntil(d) / periodDays).floor();

    final counts = {for (final leg in Leg.values) leg: <String, int>{}};
    final lastDrive = {for (final leg in Leg.values) leg: <String, CalendarDate>{}};
    final days = <ScheduleDay>[];

    // Simulate from the start of [from]'s period so the window never changes
    // who drives.
    var period = periodOf(from);
    for (var date = start.addDays(period * periodDays); !date.isAfter(to); date = date.addDays(1)) {
      if (periodOf(date) != period) {
        period = periodOf(date);
        for (final c in counts.values) {
          c.clear();
        }
      }
      if (!g.days.contains(date.weekday)) continue;

      final assignments = <Leg, LegAssignment?>{};
      for (final leg in Leg.values) {
        final legDrivers = g.drivers.where((d) => d.legs.contains(leg)).toList();
        if (legDrivers.isEmpty) {
          assignments[leg] = null;
          continue;
        }
        final eligible = legDrivers
            .where((d) => d.daysIn(g).contains(date.weekday) && !unavailable.contains((d.id, date, leg)))
            .toList()
          ..sort((a, b) => _compare(a.id, b.id, counts[leg]!, lastDrive[leg]!));
        final pick = eligible.isEmpty ? null : eligible.first.id;
        if (pick != null) {
          counts[leg]![pick] = (counts[leg]![pick] ?? 0) + 1;
          lastDrive[leg]![pick] = date;
        }
        assignments[leg] = LegAssignment(leg: leg, planned: pick, actual: pick);
      }
      if (!date.isBefore(from)) {
        days.add(ScheduleDay(date: date, going: assignments[Leg.going], ret: assignments[Leg.ret]));
      }
    }
    return days;
  }

  static int _compare(String a, String b, Map<String, int> counts, Map<String, CalendarDate> last) {
    final byCount = (counts[a] ?? 0).compareTo(counts[b] ?? 0);
    if (byCount != 0) return byCount;
    final la = last[a];
    final lb = last[b];
    if (la != lb) {
      if (la == null) return -1;
      if (lb == null) return 1;
      return la.compareTo(lb);
    }
    return a.compareTo(b);
  }
}
