import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/calendar_date.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/time/wall_time.dart';
import '../../../commute/data/providers.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/group.dart';
import '../../../commute/domain/matching_service.dart';
import '../../data/providers.dart';
import '../../domain/absence.dart';
import '../../domain/attendance_rules.dart';
import '../../domain/charge.dart';
import '../../domain/check_in.dart';
import '../../domain/daily_commute_repository.dart';
import '../../domain/notice.dart';
import '../../domain/ride.dart';
import '../../domain/schedule.dart';

part 'today_controller.g.dart';

/// One of my trips on a ride day.
final class LegPlan {
  const LegPlan({
    required this.date,
    required this.leg,
    required this.duty,
    required this.ride,
    required this.driver,
    required this.stop,
    required this.end,
    this.absence,
    this.checkIns = const [],
    this.outcomes = const [],
  });

  final CalendarDate date;
  final Leg leg;
  final Duty duty;
  final Ride? ride;

  /// Actual driver; null when nobody covers the leg.
  final Member? driver;

  /// Where I board: my going stop, or the work stop on the return leg.
  /// Times already include any reported delay.
  final Stop stop;

  /// When the trip is over (arrival).
  final WallTime end;
  final Absence? absence;

  /// Driver legs only: check-in state for the pickup screen.
  final List<StopCheckIn> checkIns;
  final List<PassengerOutcome> outcomes;

  WallTime get pickup => WallTime(date, stop.time);

  bool overAt(WallTime now) => ride?.endedAt != null || !now.isBefore(end);
}

final class DayPlan {
  const DayPlan(this.date, this.legs);

  final CalendarDate date;
  final List<LegPlan> legs;

  Iterable<LegPlan> get riding => legs.where((l) => l.duty == Duty.ride);
  Iterable<LegPlan> get driving => legs.where((l) => l.duty == Duty.drive);
  Iterable<LegPlan> get off => legs.where((l) => l.duty == Duty.off);

  LegPlan? leg(Leg leg) => legs.where((l) => l.leg == leg).firstOrNull;
}

/// Everything the Today tab shows (US1–US3).
final class TodayView {
  const TodayView({
    required this.now,
    required this.group,
    required this.me,
    required this.display,
    required this.target,
    required this.drive,
    required this.standing,
    this.otherLegs = const {},
  });

  const TodayView.removed(this.now)
      : group = null,
        me = null,
        display = null,
        target = null,
        drive = null,
        standing = NoShowStanding.removal,
        otherLegs = const {};

  final WallTime now;
  final CommuteGroup? group;
  final Member? me;

  /// The next day with a trip I take that is not over yet (today if any).
  final DayPlan? display;

  /// The first ride day after today: what "I can't come tomorrow" cancels.
  final DayPlan? target;

  /// Drivers: the next day I drive.
  final DayPlan? drive;
  final NoShowStanding standing;

  /// Rider legs another corridor group serves (US1/AC3): leg → that group's time.
  final Map<Leg, Clock> otherLegs;

  bool get removed => group == null;
  bool get isDriver => me?.role == MemberRole.driver;

  /// Riding legs of [display] that are still ahead.
  Iterable<LegPlan> get upcomingRides => display?.riding.where((l) => !l.overAt(now)) ?? const [];
}

@riverpod
class TodayController extends _$TodayController {
  static const lookAheadDays = 21;

  DailyCommuteRepository get _repo => ref.read(dailyCommuteRepositoryProvider);

  WallTime _now() => ref.read(nowProvider)();

  @override
  Future<TodayView> build() async {
    final now = ref.watch(nowProvider)();
    final repo = ref.watch(dailyCommuteRepositoryProvider);
    final g = await repo.myGroup();
    if (g == null) return TodayView.removed(now);
    final me = g.member(repo.meId)!;
    final profile = await ref.read(commuteRepositoryProvider).loadProfile();
    final home = profile?.home?.point;
    final myStop = home == null ? g.goingStops.first : g.nearestStop(home);

    final days = await repo.schedule(now.date, now.date.addDays(lookAheadDays));
    DayPlan? display;
    DayPlan? target;
    DayPlan? drive;
    for (final d in days) {
      if (display != null && target != null && (drive != null || me.role != MemberRole.driver)) break;
      final plan = await _plan(repo, g, me, myStop, d);
      if (plan.legs.isEmpty) continue;
      if (display == null && plan.legs.any((l) => l.duty != Duty.off && !l.overAt(now))) display = plan;
      if (target == null && d.date.isAfter(now.date)) target = plan;
      if (drive == null && plan.driving.any((l) => !l.overAt(now))) drive = plan;
    }

    return TodayView(
      now: now,
      group: g,
      me: me,
      display: display,
      target: target,
      drive: drive,
      standing: AttendanceRules.standing(await repo.noShowsInMonth(now.date.monthKey)),
      otherLegs: profile == null || me.role == MemberRole.driver ? const {} : await _otherLegs(g, me, profile),
    );
  }

  Future<DayPlan> _plan(DailyCommuteRepository repo, CommuteGroup g, Member me, Stop myStop, ScheduleDay d) async {
    final tripMinutes = g.arrivalTime.minutes - g.going.minutes;
    final legs = <LegPlan>[];
    for (final leg in Leg.values) {
      final assignment = d.assignment(leg);
      if (assignment == null || !travelsOn(g, me, d.date, leg)) continue;
      final ride = await repo.ride(d.date, leg);
      final duty = d.dutyOf(me.id, leg, travels: true);
      final base = leg == Leg.going ? myStop : g.workStop;
      final stop = ride?.stop(base.id) ?? base;
      final delay = ride?.delayMinutes ?? 0;
      final endClock = leg == Leg.going ? g.arrivalTime.shift(delay) : g.ret.shift(tripMinutes + delay);
      final driving = duty == Duty.drive && ride != null;
      legs.add(LegPlan(
        date: d.date,
        leg: leg,
        duty: duty,
        ride: ride,
        driver: assignment.actual == null ? null : g.member(assignment.actual!),
        stop: stop,
        end: WallTime(d.date, endClock),
        absence: d.absenceOf(me.id, leg),
        checkIns: driving ? await repo.checkIns(ride.id) : const [],
        outcomes: driving ? await repo.outcomes(ride.id) : const [],
      ));
    }
    return DayPlan(d.date, legs);
  }

  /// For each leg this group does not carry me on, the corridor group whose
  /// time fits it best (002 matching), if any.
  Future<Map<Leg, Clock>> _otherLegs(CommuteGroup g, Member me, CommuteProfile profile) async {
    final missing = Leg.values.where((l) => !me.legs.contains(l)).toSet();
    if (missing.isEmpty || profile.home == null || profile.work == null) return const {};
    final seeker = Seeker(
      role: MemberRole.rider,
      home: profile.home!.point,
      work: profile.work!.point,
      departure: profile.departure,
      ret: profile.ret,
      days: profile.days,
      legs: missing,
      isWoman: me.isWoman,
    );
    final others = (await ref.read(commuteRepositoryProvider).groupsFor(g.origin, g.destination))
        .where((o) => o.id != g.id)
        .toList();
    final result = MatchingService.match(seeker, others);
    return {
      for (final leg in missing)
        for (final m in [result.main, result.returnMatch])
          if (m != null && m.legs.contains(leg)) leg: m.group.timeFor(leg),
    };
  }

  Future<T> _act<T>(Future<T> Function(DailyCommuteRepository repo, WallTime now) action) async {
    final result = await action(_repo, _now());
    ref.invalidateSelf();
    await future;
    return result;
  }

  // Rider actions.
  Future<List<Charge>> cancel(CalendarDate date, Set<Leg> legs) => _act((r, now) => r.cancel(date, legs, now));

  Future<UndoResult> undo(CalendarDate date) => _act((r, now) => r.undoCancel(date, now));

  Future<List<Charge>> notComingNextWeek() => _act((r, now) => r.notComingNextWeek(now));

  // Driver actions.
  Future<void> setConfirmed(DayPlan day, bool confirmed) => _act((r, _) async {
        for (final l in day.driving) {
          await r.setConfirmed(l.ride!.id, confirmed);
        }
      });

  Future<void> reportDelay(String rideId, int minutes) => _act((r, _) => r.reportDelay(rideId, minutes));

  Future<BackupResult> cantDrive(DayPlan day) =>
      _act((r, now) => r.cantDrive(day.date, {for (final l in day.driving) l.leg}, now));

  Future<void> arrivedAt(String rideId, String stopId) => _act((r, now) => r.arrivedAt(rideId, stopId, now));

  Future<void> mark(String rideId, String personId, Outcome outcome) =>
      _act((r, now) => r.mark(rideId, personId, outcome, now));

  Future<void> startTrip(String rideId) => _act((r, now) => r.startTrip(rideId, now));

  Future<void> endTrip(String rideId) => _act((r, now) => r.endTrip(rideId, now));
}

/// In-app inbox (research R11), newest first.
@riverpod
Stream<List<Notice>> notices(Ref ref) =>
    ref.watch(dailyCommuteRepositoryProvider).notices().map((l) => l.reversed.toList());
