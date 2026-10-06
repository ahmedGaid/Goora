import '../../../core/time/calendar_date.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import 'absence.dart';

/// Whether [m] commutes on [leg] that day: riders on their legs, drivers on
/// every leg the group runs (they ride when not driving, FR-022a).
bool travelsOn(CommuteGroup g, Member m, CalendarDate date, Leg leg) =>
    m.daysIn(g).contains(date.weekday) && (m.role == MemberRole.driver || m.legs.contains(leg));

enum Duty { drive, ride, off }

/// §6.6 search order for a cover driver.
enum BackupStep { sameGroup, nearbyGroup, sameCompany, sameCommunity }

/// Who drives one leg on one date: the rotation's [planned] driver and the
/// [actual] one after absences and backups. A backup never changes the
/// fairness count, which uses [planned] only.
final class LegAssignment {
  const LegAssignment({
    required this.leg,
    required this.planned,
    required this.actual,
    this.isBackup = false,
    this.backupStep,
  });

  final Leg leg;
  final String? planned;

  /// Null = no cover.
  final String? actual;
  final bool isBackup;
  final BackupStep? backupStep;

  bool get covered => actual != null;
}

/// One ride day of a group.
final class ScheduleDay {
  const ScheduleDay({required this.date, this.going, this.ret, this.absences = const []});

  final CalendarDate date;
  final LegAssignment? going;
  final LegAssignment? ret;

  /// Every member's absences on this date.
  final List<Absence> absences;

  LegAssignment? assignment(Leg leg) => leg == Leg.going ? going : ret;

  Absence? absenceOf(String memberId, Leg leg) {
    for (final a in absences) {
      if (a.personId == memberId && a.leg == leg) return a;
    }
    return null;
  }

  /// [travels]: the member commutes on this leg (their rider legs, or any
  /// leg for drivers, who ride on the legs they are not driving; FR-022a).
  Duty dutyOf(String memberId, Leg leg, {required bool travels}) {
    final a = assignment(leg);
    if (a?.actual == memberId) return Duty.drive;
    if (!travels || absenceOf(memberId, leg) != null) return Duty.off;
    return Duty.ride;
  }
}
