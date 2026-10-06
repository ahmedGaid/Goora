import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';

/// freeCancel: before the 9 PM cut-off · lateCancel: at or after it ·
/// noCover: the rider took the day off because no driver was found (always free).
enum AbsenceKind { freeCancel, lateCancel, noCover }

/// One person missing one trip. Drivers' "Can't drive" is an absence with
/// [driving] set; drivers owe no money (FR-010).
final class Absence {
  const Absence({
    required this.personId,
    required this.date,
    required this.leg,
    required this.madeAt,
    required this.kind,
    this.driving = false,
  });

  final String personId;
  final CalendarDate date;
  final Leg leg;
  final WallTime madeAt;
  final AbsenceKind kind;
  final bool driving;

  bool get isLate => kind == AbsenceKind.lateCancel;

  Map<String, Object?> toJson() => {
        'personId': personId,
        'date': date.toIso(),
        'leg': leg.name,
        'madeAt': madeAt.toJson(),
        'kind': kind.name,
        'driving': driving,
      };

  static Absence fromJson(Map<String, Object?> j) => Absence(
        personId: j['personId']! as String,
        date: CalendarDate.parse(j['date']! as String),
        leg: Leg.values.byName(j['leg']! as String),
        madeAt: WallTime.fromJson(j['madeAt']! as String),
        kind: AbsenceKind.values.byName(j['kind']! as String),
        driving: j['driving'] as bool? ?? false,
      );
}

enum UndoResult { ok, refusedSeatTaken, refusedTooLate }

/// Why an attendance action was refused; the UI maps each to calm copy.
enum RefusalReason { afterPickup, noShowTooEarly, tripStarted, notOnRide }

final class AttendanceRefused implements Exception {
  const AttendanceRefused(this.reason);

  final RefusalReason reason;

  @override
  String toString() => 'AttendanceRefused(${reason.name})';
}
