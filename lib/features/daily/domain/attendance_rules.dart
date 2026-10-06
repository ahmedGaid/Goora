import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import 'absence.dart';

/// The brief's §6.5 numbers, in one place (FR-005 – FR-011).
final class AttendanceLimits {
  const AttendanceLimits({
    this.cutoff = const Clock.hm(21, 0),
    this.noShowWaitMinutes = 5,
    this.warnAt = 2,
    this.removeAt = 3,
  });

  /// On the calendar day before the ride.
  final Clock cutoff;
  final int noShowWaitMinutes;
  final int warnAt;
  final int removeAt;
}

enum NoShowStanding { ok, warning, removal }

/// Pure attendance and cancellation rules (research R3). Wall-clock Cairo
/// time in, no time zones. Mirrored in `supabase/functions/_shared/attendance.ts`.
abstract final class AttendanceRules {
  static const limits = AttendanceLimits();

  /// 9 PM on the calendar day before [rideDate], even if that day is not a
  /// working day.
  static WallTime cutoffFor(CalendarDate rideDate, {AttendanceLimits l = limits}) =>
      WallTime(rideDate.addDays(-1), l.cutoff);

  /// At or after the cut-off. 8:59:59 PM is free; 9:00 PM is late.
  static bool isLate(CalendarDate rideDate, WallTime madeAt, {AttendanceLimits l = limits}) =>
      !madeAt.isBefore(cutoffFor(rideDate, l: l));

  /// EGP owed for cancelling one trip: free before the cut-off, half the
  /// share after. Prices are even, so the half is exact (40 → 20).
  static int cancelCharge(CalendarDate rideDate, WallTime madeAt, int share, {AttendanceLimits l = limits}) =>
      isLate(rideDate, madeAt, l: l) ? share ~/ 2 : 0;

  static AbsenceKind cancelKind(CalendarDate rideDate, WallTime madeAt, {AttendanceLimits l = limits}) =>
      isLate(rideDate, madeAt, l: l) ? AbsenceKind.lateCancel : AbsenceKind.freeCancel;

  /// Cancelling is possible until the trip's pickup time; after that only the
  /// no-show path exists.
  static bool canCancel(WallTime pickup, WallTime madeAt) => madeAt.isBefore(pickup);

  /// A free cancellation's seat goes to the waitlist at the cut-off, so its
  /// undo ends then (when anyone is waiting). A late cancellation's seat is
  /// not given away, so it can be undone, and its charge removed, until
  /// pickup (founder decision 2026-10-06).
  static UndoResult canUndo(
    Absence absence,
    WallTime now, {
    required WallTime pickup,
    required bool waitlistWaiting,
    AttendanceLimits l = limits,
  }) {
    if (!now.isBefore(pickup)) return UndoResult.refusedTooLate;
    if (absence.kind == AbsenceKind.freeCancel &&
        waitlistWaiting &&
        !now.isBefore(cutoffFor(absence.date, l: l))) {
      return UndoResult.refusedSeatTaken;
    }
    return UndoResult.ok;
  }

  static WallTime noShowAvailableAt(WallTime arrivedAt, {AttendanceLimits l = limits}) =>
      arrivedAt.plusMinutes(l.noShowWaitMinutes);

  /// 4:59 after arrival: not yet. 5:00: allowed.
  static bool canMarkNoShow(WallTime arrivedAt, WallTime now, {AttendanceLimits l = limits}) =>
      !now.isBefore(noShowAvailableAt(arrivedAt, l: l));

  /// A no-show pays their full share.
  static int noShowCharge(int share) => share;

  /// No-shows in one calendar month; each trip counts (going + return = 2).
  static NoShowStanding standing(int noShowsThisMonth, {AttendanceLimits l = limits}) {
    if (noShowsThisMonth >= l.removeAt) return NoShowStanding.removal;
    if (noShowsThisMonth >= l.warnAt) return NoShowStanding.warning;
    return NoShowStanding.ok;
  }

  /// A driver who neither checked in nor cancelled by the first scheduled
  /// pickup + 5 minutes is a no-show (FR-010).
  static bool driverNoShow({
    required WallTime firstPickup,
    required WallTime now,
    required bool checkedIn,
    required bool cancelled,
    AttendanceLimits l = limits,
  }) =>
      !checkedIn && !cancelled && !now.isBefore(firstPickup.plusMinutes(l.noShowWaitMinutes));

  /// "Can't drive" follows the same cut-off; drivers owe no money, only
  /// reliability is affected.
  static bool driverCantDriveLate(CalendarDate rideDate, WallTime madeAt, {AttendanceLimits l = limits}) =>
      isLate(rideDate, madeAt, l: l);
}
