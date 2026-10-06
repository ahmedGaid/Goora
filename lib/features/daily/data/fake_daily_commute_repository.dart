import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/data/corridor_seed.dart';
import '../../commute/data/fake_commute_repository.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/commute_repository.dart';
import '../../commute/domain/geo.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/matching_service.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/domain/profile.dart';
import '../domain/absence.dart';
import '../domain/attendance_rules.dart';
import '../domain/backup_service.dart';
import '../domain/charge.dart';
import '../domain/check_in.dart';
import '../domain/daily_commute_repository.dart';
import '../domain/notice.dart';
import '../domain/privacy.dart';
import '../domain/ride.dart';
import '../domain/rotation_planner.dart';
import '../domain/schedule.dart';
import '../domain/trust.dart';
import 'daily_seed.dart';

/// Daily commute on fake data over shared_preferences (data-model "Fake
/// storage keys"). The person joins the seeded group as member [meId] with
/// the role and legs from their 001/002 profiles.
final class FakeDailyCommuteRepository implements DailyCommuteRepository {
  FakeDailyCommuteRepository(
    this._prefs, {
    required this._commute,
    required this._person,
    required this._now,
    List<CommuteGroup>? groups,
    this.waitlistAhead = CorridorSeed.waitlistAhead,
  }) : _groups = groups ?? CorridorSeed.groups;

  static const absencesKey = 'daily.absences';
  static const checkInsKey = 'daily.checkIns';
  static const outcomesKey = 'daily.outcomes';
  static const rideStateKey = 'daily.rideState';
  static const backupsKey = 'daily.backups';
  static const chargesKey = 'daily.charges';
  static const eventsKey = 'daily.events';
  static const noticesKey = 'daily.notices';
  static const privacyKey = 'trust.privacy';

  /// When the person joined (first read); trips before it never settle.
  static const joinedAtKey = 'daily.joinedAt';

  /// The last date the timed rules have run through.
  static const settledKey = 'daily.settledThrough';

  static const allKeys = [
    absencesKey,
    checkInsKey,
    outcomesKey,
    rideStateKey,
    backupsKey,
    chargesKey,
    eventsKey,
    noticesKey,
    joinedAtKey,
    settledKey,
  ];

  final SharedPreferences _prefs;
  final CommuteRepository _commute;
  final Profile? Function() _person;
  final Now _now;
  final List<CommuteGroup> _groups;

  /// People waiting for a seat on the corridor; a free cancellation's seat
  /// goes to them at the cut-off.
  final int waitlistAhead;

  final _noticeUpdates = StreamController<List<Notice>>.broadcast();

  @override
  String get meId => DailySeed.meId;

  // ---------------------------------------------------------------- group

  @override
  Future<CommuteGroup?> myGroup() async {
    final groupId = await _commute.joinedGroupId();
    if (groupId == null) return null;
    final seed = _groups.where((g) => g.id == groupId).firstOrNull;
    final person = _person();
    if (seed == null || person == null) return null;
    final group = seed.withMembers([...seed.members, _me(seed, person, await _commute.loadProfile())]);
    await _seedHistory(group);
    await _catchUp(group);
    // Three no-shows found while catching up remove the person (FR-009).
    if (await _commute.joinedGroupId() == null) return null;
    return group;
  }

  Member _me(CommuteGroup g, Profile person, CommuteProfile? commute) {
    final driver = person.role == Role.driver;
    final Set<Leg> legs;
    if (driver) {
      legs = commute?.driver?.trips.legs ?? const {Leg.going, Leg.ret};
    } else if (commute == null) {
      legs = const {Leg.going, Leg.ret};
    } else {
      // A rider rides the legs whose time fits this group (002 time limit);
      // another group covers the rest (US1/AC3).
      final limit = const MatchingLimits().timeMinutes;
      final fit = {
        if (commute.departure.diff(g.going) <= limit) Leg.going,
        if (commute.ret.diff(g.ret) <= limit) Leg.ret,
      };
      legs = fit.isEmpty ? const {Leg.going, Leg.ret} : fit;
    }
    final days = commute?.days.intersection(g.days);
    return Member(
      id: meId,
      firstName: person.firstName,
      initials: _initials(person),
      role: driver ? MemberRole.driver : MemberRole.rider,
      isWoman: person.gender == Gender.female,
      rating: DailySeed.myRating,
      reliability: 100,
      legs: legs,
      seats: driver ? commute?.driver?.seats : null,
      // Known because the work email is verified (seed trust data, FR-025).
      company: DailySeed.company,
      phone: person.phone.e164,
      privacy: PrivacyPreference.values.asNameMap()[_prefs.getString(privacyKey)] ?? PrivacyPreference.verifiedUsers,
      days: days == null || days.length == g.days.length ? null : days,
    );
  }

  static String _initials(Profile p) => [p.firstName, p.lastName]
      .where((s) => s.isNotEmpty)
      .map((s) => String.fromCharCode(s.runes.first).toUpperCase())
      .join();

  Future<void> _seedHistory(CommuteGroup g) async {
    if (!_prefs.containsKey(joinedAtKey)) await _prefs.setString(joinedAtKey, _now().toJson());
    if (_prefs.containsKey(eventsKey)) return;
    await _writeList(eventsKey, DailySeed.history(g, _now().date), (e) => e.toJson());
  }

  /// Anyone the fake knows: group members, other corridor groups' members,
  /// and network drivers.
  Member? _known(CommuteGroup g, String id) =>
      g.member(id) ??
      _groups.expand((o) => o.members).where((m) => m.id == id).firstOrNull ??
      DailySeed.networkDrivers.map((n) => n.member).where((m) => m.id == id).firstOrNull;

  /// The going stop a member boards at.
  Future<String> _stopIdOf(CommuteGroup g, Member m) async {
    if (m.id == meId) {
      final home = (await _commute.loadProfile())?.home?.point;
      return home == null ? g.goingStops.first.id : g.nearestStop(home).id;
    }
    final seeded = DailySeed.memberStops[m.id];
    return g.goingStops.any((s) => s.id == seeded) ? seeded! : g.goingStops.first.id;
  }

  // ------------------------------------------------------------- schedule

  @override
  Future<List<ScheduleDay>> schedule(CalendarDate from, CalendarDate to) async {
    final g = await myGroup();
    if (g == null) return const [];
    return _schedule(g, from, to);
  }

  List<ScheduleDay> _schedule(CommuteGroup g, CalendarDate from, CalendarDate to) {
    final absences = _absences().where((a) => !a.date.isBefore(from) && !a.date.isAfter(to)).toList();
    final backups = _backups();
    LegAssignment? apply(LegAssignment? a, CalendarDate date) {
      if (a == null || a.planned == null) return a;
      final away = absences.any((x) => x.driving && x.personId == a.planned && x.date == date && x.leg == a.leg);
      if (!away) return a;
      final b = backups.where((b) => b.date == date && b.leg == a.leg).firstOrNull;
      if (b == null) return LegAssignment(leg: a.leg, planned: a.planned, actual: null);
      return LegAssignment(
        leg: a.leg,
        planned: a.planned,
        actual: b.coverId,
        isBackup: true,
        backupStep: b.step,
        cover: _known(g, b.coverId),
      );
    }

    return [
      for (final d in RotationPlanner.plan(g, from, to))
        ScheduleDay(
          date: d.date,
          going: apply(d.going, d.date),
          ret: apply(d.ret, d.date),
          absences: [for (final a in absences) if (a.date == d.date) a],
        ),
    ];
  }

  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async {
    final g = await myGroup();
    return g == null ? null : _ride(g, date, leg);
  }

  Future<Ride?> _ride(CommuteGroup g, CalendarDate date, Leg leg) async {
    final day = _schedule(g, date, date).firstOrNull;
    final assignment = day?.assignment(leg);
    if (day == null || assignment == null) return null;
    final driverId = assignment.actual;
    final id = Ride.idFor(g.id, date, leg);
    final state = _rideState()[id] ?? const {};
    final delay = state['delay'] as int? ?? 0;
    final baseStops = leg == Leg.going ? g.goingStops : [g.workStop];
    final travelling = [
      for (final m in g.members)
        if (m.id != driverId &&
            travelsOn(g, m, date, leg) &&
            day.absences.every((a) => !(a.personId == m.id && a.leg == leg)))
          m,
    ];
    // The car never carries more than its seats (FR-022a). Riders keep their
    // seats first; an off-duty driver who doesn't fit drives their own car.
    final seats = driverId == null
        ? null
        : g.member(driverId)?.seats ??
            _backups().where((b) => b.date == date && b.leg == leg && b.coverId == driverId).firstOrNull?.seats;
    final seated = {
      for (final m in [
        ...travelling.where((m) => m.role == MemberRole.rider),
        ...travelling.where((m) => m.role == MemberRole.driver),
      ].take(seats ?? travelling.length))
        m.id,
    };
    final passengers = <Passenger>[
      for (final m in travelling)
        if (seated.contains(m.id))
          Passenger(memberId: m.id, stopId: leg == Leg.going ? await _stopIdOf(g, m) : g.workStop.id),
    ];
    return Ride(
      groupId: g.id,
      date: date,
      leg: leg,
      driverId: driverId,
      passengers: passengers,
      stops: [
        for (final s in baseStops) Stop(id: s.id, name: s.name, point: s.point, time: s.time.shift(delay)),
      ],
      delayMinutes: delay,
      confirmed: state['confirmed'] as bool? ?? false,
      arrivedStopIds: {for (final c in _checkIns()) if (c.rideId == id) c.stopId},
      startedAt: _time(state['startedAt']),
      endedAt: _time(state['endedAt']),
      seats: seats,
    );
  }

  static WallTime? _time(Object? s) => s == null ? null : WallTime.fromJson(s as String);

  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async =>
      _absences().where((a) => !a.date.isBefore(from) && !a.date.isAfter(to)).toList();

  @override
  Future<List<StopCheckIn>> checkIns(String rideId) async => _checkIns().where((c) => c.rideId == rideId).toList();

  @override
  Future<List<PassengerOutcome>> outcomes(String rideId) async =>
      _outcomes().where((o) => o.rideId == rideId).toList();

  // -------------------------------------------------------- rider actions

  @override
  Future<List<Charge>> cancel(CalendarDate date, Set<Leg> legs, WallTime madeAt) async {
    final g = await myGroup();
    if (g == null) return const [];
    final absences = _absences();
    final charges = _charges();
    final events = _events();
    final created = <Charge>[];
    for (final leg in Leg.values.where(legs.contains)) {
      final ride = await _ride(g, date, leg);
      if (ride == null || !ride.carries(meId)) continue;
      final pickup = ride.pickupAt(ride.passengers.firstWhere((p) => p.memberId == meId).stopId);
      if (!AttendanceRules.canCancel(pickup, madeAt)) throw const AttendanceRefused(RefusalReason.afterPickup);
      final kind = AttendanceRules.cancelKind(date, madeAt);
      absences.add(Absence(personId: meId, date: date, leg: leg, madeAt: madeAt, kind: kind));
      final amount = AttendanceRules.cancelCharge(date, madeAt, g.price);
      if (amount > 0 && ride.driverId != null) {
        final charge = Charge(
          id: 'lateCancel:${ride.id}:$meId',
          personId: meId,
          rideId: ride.id,
          reason: ChargeReason.lateCancel,
          amount: amount,
          owedTo: ride.driverId!,
        );
        charges.add(charge);
        created.add(charge);
        events.add(ReliabilityEvent(personId: meId, rideId: ride.id, date: date, kind: ReliabilityEventKind.lateCancel));
        await _notify(NoticeKind.lateCancelCharged, {'day': date.toIso(), 'leg': leg.name, 'amount': '$amount'});
      } else if (amount == 0) {
        await _notify(NoticeKind.seatOffered, {'day': date.toIso(), 'leg': leg.name});
      }
    }
    await _writeList(absencesKey, absences, (a) => a.toJson());
    await _writeList(chargesKey, charges, (c) => c.toJson());
    await _writeList(eventsKey, events, (e) => e.toJson());
    return created;
  }

  @override
  Future<UndoResult> undoCancel(CalendarDate date, WallTime now) async {
    final g = await myGroup();
    if (g == null) return UndoResult.refusedTooLate;
    final mine = _absences().where((a) => a.personId == meId && !a.driving && a.date == date).toList();
    if (mine.isEmpty) return UndoResult.ok;
    final stopId = await _stopIdOf(g, g.member(meId)!);
    for (final a in mine) {
      final stop = a.leg == Leg.going ? (g.goingStops.where((s) => s.id == stopId).firstOrNull ?? g.goingStops.first) : g.workStop;
      final result = AttendanceRules.canUndo(
        a,
        now,
        pickup: WallTime(date, stop.time),
        waitlistWaiting: waitlistAhead > 0,
      );
      if (result != UndoResult.ok) return result;
    }
    final rideIds = {for (final a in mine) Ride.idFor(g.id, date, a.leg)};
    await _writeList(
      absencesKey,
      _absences().where((a) => !(a.personId == meId && !a.driving && a.date == date)).toList(),
      (a) => a.toJson(),
    );
    await _writeList(
      chargesKey,
      _charges().where((c) => !(c.personId == meId && c.reason == ChargeReason.lateCancel && rideIds.contains(c.rideId))).toList(),
      (c) => c.toJson(),
    );
    await _writeList(
      eventsKey,
      _events()
          .where((e) => !(e.personId == meId && e.kind == ReliabilityEventKind.lateCancel && rideIds.contains(e.rideId)))
          .toList(),
      (e) => e.toJson(),
    );
    return UndoResult.ok;
  }

  /// Sunday–Saturday of next week: the week after the coming Saturday.
  static List<CalendarDate> nextWeek(CalendarDate today) {
    var sunday = today.addDays(1);
    while (sunday.weekday != Day.sun) {
      sunday = sunday.addDays(1);
    }
    return [for (var i = 0; i < 7; i++) sunday.addDays(i)];
  }

  @override
  Future<List<Charge>> notComingNextWeek(WallTime madeAt) async {
    final g = await myGroup();
    if (g == null) return const [];
    final me = g.member(meId)!;
    final charges = <Charge>[];
    for (final date in nextWeek(madeAt.date)) {
      if (!g.days.contains(date.weekday) || !me.daysIn(g).contains(date.weekday)) continue;
      final day = _schedule(g, date, date).single;
      final drive = {for (final leg in Leg.values) if (day.assignment(leg)?.actual == meId) leg};
      final ride = {for (final leg in Leg.values) if (!drive.contains(leg) && travelsOn(g, me, date, leg)) leg};
      if (drive.isNotEmpty) await cantDrive(date, drive, madeAt);
      charges.addAll(await cancel(date, ride, madeAt));
    }
    return charges;
  }

  // ------------------------------------------------------- driver actions

  @override
  Future<void> setConfirmed(String rideId, bool confirmed) async {
    await _updateRide(rideId, (s) => s['confirmed'] = confirmed);
    await _notify(
      confirmed ? NoticeKind.driverConfirmed : NoticeKind.driverUnconfirmed,
      {'day': _dateOf(rideId).toIso()},
      toMe: false,
    );
  }

  @override
  Future<void> reportDelay(String rideId, int minutes) async {
    await _updateRide(rideId, (s) => s['delay'] = minutes);
    final g = await myGroup();
    final ride = g == null ? null : await _ride(g, _dateOf(rideId), _legOf(rideId));
    await _notify(
      NoticeKind.delay,
      {'minutes': '$minutes', if (ride != null) 'time': '${ride.stops.first.time.minutes}'},
      toMe: false,
    );
  }

  @override
  Future<BackupResult> cantDrive(CalendarDate date, Set<Leg> legs, WallTime madeAt) async {
    final g = await myGroup();
    if (g == null) return const BackupResult.none();
    return _driverOut(g, meId, date, legs, madeAt);
  }

  /// [driverId] can't drive [legs] on [date]: the absence (and, from the
  /// cut-off, a reliability event; drivers owe no money), then a cover in
  /// §6.6 order, and the riders told either way (FR-014, FR-017 – FR-020).
  /// The no-cover notice goes out now, so riders have it by 9 PM at the
  /// latest. [search] false = the demo's "no cover" scenario.
  Future<BackupResult> _driverOut(
    CommuteGroup g,
    String driverId,
    CalendarDate date,
    Set<Leg> legs,
    WallTime madeAt, {
    bool search = true,
  }) async {
    final day = _schedule(g, date, date).firstOrNull;
    if (day == null) return const BackupResult.none();
    final out = [for (final leg in Leg.values) if (legs.contains(leg) && day.assignment(leg)?.planned == driverId) leg];
    if (out.isEmpty) return const BackupResult.none();
    final late = AttendanceRules.driverCantDriveLate(date, madeAt);
    await _writeList(
      absencesKey,
      [
        ..._absences(),
        for (final leg in out)
          Absence(
            personId: driverId,
            date: date,
            leg: leg,
            madeAt: madeAt,
            kind: late ? AbsenceKind.lateCancel : AbsenceKind.freeCancel,
            driving: true,
          ),
      ],
      (a) => a.toJson(),
    );
    if (late) {
      await _writeList(
        eventsKey,
        [
          ..._events(),
          for (final leg in out)
            ReliabilityEvent(
              personId: driverId,
              rideId: Ride.idFor(g.id, date, leg),
              date: date,
              kind: ReliabilityEventKind.lateCantDrive,
            ),
        ],
        (e) => e.toJson(),
      );
    }
    await _writeList(
      backupsKey,
      _backups()..removeWhere((b) => b.date == date && out.contains(b.leg)),
      (b) => b.toJson(),
    );

    final driverName = _known(g, driverId)?.firstName ?? '';
    final results = <BackupResult>[];
    for (final leg in out) {
      final ride = await _ride(g, date, leg);
      final candidates = ride == null || !search ? const <BackupCandidate>[] : await _candidates(g, ride);
      final result = ride == null ? const BackupResult.none() : BackupService.findCover(ride, g, candidates);
      results.add(result);
      final params = {'day': date.toIso(), 'leg': leg.name, 'driver': driverName};
      if (result.found) {
        final chosen = candidates.firstWhere((c) => c.member.id == result.coverId && c.step == result.step);
        await _writeList(
          backupsKey,
          [
            ..._backups(),
            _Backup(date: date, leg: leg, coverId: chosen.member.id, step: chosen.step, seats: chosen.freeSeats),
          ],
          (b) => b.toJson(),
        );
        await _notify(NoticeKind.backupCover, {...params, 'cover': chosen.member.firstName}, toMe: driverId != meId);
      } else {
        await _notify(NoticeKind.noCover, params, toMe: driverId != meId);
      }
    }
    return results.where((r) => r.found).firstOrNull ?? const BackupResult.none();
  }

  /// Who could cover [ride], by search step (research R6). Seeded drivers'
  /// homes are approximated by their pickup stop; other groups' drivers by
  /// their group's pickup point.
  Future<List<BackupCandidate>> _candidates(CommuteGroup g, Ride ride) async {
    final date = ride.date;
    final away = {for (final a in _absences()) if (a.date == date && a.leg == ride.leg) a.personId};
    final inGroup = {for (final m in g.members) m.id};
    final profile = await _commute.loadProfile();
    final riders = [for (final p in ride.passengers) ?g.member(p.memberId)];
    Seeker seeker(GeoPoint home, GeoPoint work, Clock going, Clock ret, Set<Day> days) => Seeker(
          role: MemberRole.driver,
          home: home,
          work: work,
          departure: going,
          ret: ret,
          days: days,
          legs: const {Leg.going, Leg.ret},
        );

    return [
      // 1. The group's other drivers who drive this leg (off duty that day).
      for (final m in g.drivers)
        if (m.legs.contains(ride.leg))
          BackupCandidate(
            member: m,
            step: BackupStep.sameGroup,
            seeker: m.id == meId && profile?.home != null && profile?.work != null
                ? seeker(profile!.home!.point, profile.work!.point, profile.departure, profile.ret, m.daysIn(g))
                : seeker(await _stopPointOf(g, m), g.destinationPoint, g.going, g.ret, m.daysIn(g)),
            freeSeats: m.seats ?? 0,
            available: !away.contains(m.id),
          ),
      // 2. Drivers of other corridor groups on duty that leg and day.
      for (final other in _groups)
        if (other.id != g.id)
          for (final d in RotationPlanner.plan(other, date, date))
            if (d.assignment(ride.leg)?.planned case final id? when !inGroup.contains(id))
              BackupCandidate(
                member: other.member(id)!,
                step: BackupStep.nearbyGroup,
                seeker: seeker(other.pickupPoints.first, other.destinationPoint, other.going, other.ret, other.days),
                freeSeats: other.freeSeats(ride.leg),
              ),
      // 3–4. Network drivers sharing a company, then a compound, with a passenger.
      for (final n in DailySeed.networkDrivers)
        if (riders.any((r) => r.company != null && r.company == n.member.company))
          BackupCandidate(
            member: n.member,
            step: BackupStep.sameCompany,
            seeker: seeker(n.home, g.destinationPoint, n.going, n.ret, g.days),
            freeSeats: n.member.seats ?? 0,
          )
        else if (riders.any((r) => r.compound != null && r.compound == n.member.compound))
          BackupCandidate(
            member: n.member,
            step: BackupStep.sameCommunity,
            seeker: seeker(n.home, g.destinationPoint, n.going, n.ret, g.days),
            freeSeats: n.member.seats ?? 0,
          ),
    ];
  }

  Future<GeoPoint> _stopPointOf(CommuteGroup g, Member m) async {
    final id = await _stopIdOf(g, m);
    return g.goingStops.firstWhere((s) => s.id == id).point;
  }

  /// Debug demo (research R11): the driver planned for next Tuesday can't
  /// drive, with a cover found or ([cover] false) none. Returns that date.
  Future<CalendarDate?> demoDriverOut({required bool cover}) async {
    final g = await myGroup();
    if (g == null) return null;
    final now = _now();
    for (var date = now.date.addDays(1); !date.isAfter(now.date.addDays(14)); date = date.addDays(1)) {
      if (date.weekday != Day.tue || !g.days.contains(date.weekday)) continue;
      final day = _schedule(g, date, date).single;
      final driverId = day.going?.planned ?? day.ret?.planned;
      if (driverId == null) return null;
      await _driverOut(g, driverId, date, const {Leg.going, Leg.ret}, now, search: cover);
      return date;
    }
    return null;
  }

  @override
  Future<void> arrivedAt(String rideId, String stopId, WallTime at) async {
    final list = _checkIns()..removeWhere((c) => c.rideId == rideId && c.stopId == stopId);
    list.add(StopCheckIn(rideId: rideId, stopId: stopId, arrivedAt: at));
    await _writeList(checkInsKey, list, (c) => c.toJson());
    await _notify(NoticeKind.driverArrived, {'stop': stopId}, toMe: false);
  }

  @override
  Future<void> mark(String rideId, String personId, Outcome outcome, WallTime at) async {
    final g = await myGroup();
    final ride = g == null ? null : await _ride(g, _dateOf(rideId), _legOf(rideId));
    if (ride == null || !ride.carries(personId)) throw const AttendanceRefused(RefusalReason.notOnRide);
    if (ride.startedAt != null || ride.endedAt != null) throw const AttendanceRefused(RefusalReason.tripStarted);
    if (outcome == Outcome.noShow) {
      final stopId = ride.passengers.firstWhere((p) => p.memberId == personId).stopId;
      final arrived = _checkIns().where((c) => c.rideId == rideId && c.stopId == stopId).firstOrNull;
      if (arrived == null || !AttendanceRules.canMarkNoShow(arrived.arrivedAt, at)) {
        throw const AttendanceRefused(RefusalReason.noShowTooEarly);
      }
    }
    final list = _outcomes()..removeWhere((o) => o.rideId == rideId && o.personId == personId);
    list.add(PassengerOutcome(rideId: rideId, personId: personId, outcome: outcome, markedAt: at));
    await _writeList(outcomesKey, list, (o) => o.toJson());
  }

  @override
  Future<void> startTrip(String rideId, WallTime at) async {
    await _updateRide(rideId, (s) => s['startedAt'] = at.toJson());
    await _settleRide(rideId);
  }

  @override
  Future<void> endTrip(String rideId, WallTime at) async {
    await _updateRide(rideId, (s) {
      s['endedAt'] = at.toJson();
      s['startedAt'] ??= at.toJson();
    });
    await _settleRide(rideId);
  }

  Future<void> _settleRide(String rideId) async {
    final g = await myGroup();
    final ride = g == null ? null : await _ride(g, _dateOf(rideId), _legOf(rideId));
    if (g != null && ride != null) await _settle(g, ride);
  }

  /// Marks become final when the trip starts: each no-show owes the full
  /// share to the driver and counts toward the monthly standing; everyone
  /// else on board kept the trip, and so did its driver (FR-008, FR-009,
  /// FR-036). A no-show is only ever an explicit mark. Settling twice changes
  /// nothing. The fake knows the person's own trips and the riders of the car
  /// they drive.
  Future<void> _settle(CommuteGroup g, Ride ride) async {
    final driverId = ride.driverId;
    if (driverId == null) return;
    final drivenByMe = driverId == meId;
    // The person's car never came: that is a driver no-show, not a trip.
    if (drivenByMe && ride.arrivedStopIds.isEmpty && ride.startedAt == null) return;
    final charges = _charges();
    final events = _events();
    final marks = {for (final o in _outcomes()) if (o.rideId == ride.id) o.personId: o.outcome};
    bool settled(String personId) => events.any((e) => e.rideId == ride.id && e.personId == personId);
    void record(String personId, ReliabilityEventKind kind) =>
        events.add(ReliabilityEvent(personId: personId, rideId: ride.id, date: ride.date, kind: kind));

    final people = [
      for (final p in ride.passengers)
        if ((drivenByMe || p.memberId == meId) && !settled(p.memberId)) p.memberId,
      if (drivenByMe && !settled(meId)) meId,
    ];
    if (people.isEmpty) return;
    final noShows = <String>[];
    for (final personId in people) {
      if (personId != driverId && marks[personId] == Outcome.noShow) {
        noShows.add(personId);
        charges.add(Charge(
          id: 'noShow:${ride.id}:$personId',
          personId: personId,
          rideId: ride.id,
          reason: ChargeReason.noShow,
          amount: AttendanceRules.noShowCharge(g.price),
          owedTo: driverId,
        ));
        record(personId, ReliabilityEventKind.noShow);
      } else {
        record(personId, ReliabilityEventKind.kept);
      }
    }
    await _writeList(chargesKey, charges, (c) => c.toJson());
    await _writeList(eventsKey, events, (e) => e.toJson());
    for (final personId in noShows) {
      await _notify(
        NoticeKind.noShowCharged,
        {'day': ride.date.toIso(), 'amount': '${g.price}', 'leg': ride.leg.name},
        toMe: personId == meId,
      );
    }
    if (noShows.contains(meId)) await _applyStanding(ride.date.monthKey);
  }

  /// What the server's timed jobs do, run on read in the fake: a driver who
  /// neither checked in nor cancelled by first pickup + 5 min is a no-show
  /// (FR-010), and a trip whose arrival time has passed settles its marks
  /// even without "End trip" (research R11). Only trips from the moment the
  /// person joined count.
  Future<void> _catchUp(CommuteGroup g) async {
    final now = _now();
    final joined = WallTime.fromJson(_prefs.getString(joinedAtKey)!);
    final through = _prefs.getString(settledKey);
    var date = through == null ? joined.date : CalendarDate.parse(through);
    if (date.isBefore(joined.date)) date = joined.date;
    for (; !date.isAfter(now.date); date = date.addDays(1)) {
      for (final leg in Leg.values) {
        final ride = await _ride(g, date, leg);
        if (ride == null || ride.driverId == null || ride.firstPickup.isBefore(joined)) continue;
        final noShow = ride.driverId == meId &&
            AttendanceRules.driverNoShow(
              firstPickup: ride.firstPickup,
              now: now,
              checkedIn: ride.arrivedStopIds.isNotEmpty || ride.startedAt != null,
              // A driver who cancelled is no longer the ride's driver.
              cancelled: false,
            );
        if (noShow) {
          await _recordDriverNoShow(ride);
        } else if (!now.isBefore(WallTime(date, g.endFor(leg).shift(ride.delayMinutes)))) {
          await _settle(g, ride);
        }
      }
    }
    await _prefs.setString(settledKey, now.date.toIso());
  }

  /// Same standing as riders: 2 in a month → warning, 3 → removal (FR-009).
  Future<void> _recordDriverNoShow(Ride ride) async {
    final events = _events();
    if (events.any((e) => e.rideId == ride.id && e.personId == meId)) return;
    events.add(ReliabilityEvent(personId: meId, rideId: ride.id, date: ride.date, kind: ReliabilityEventKind.noShow));
    await _writeList(eventsKey, events, (e) => e.toJson());
    await _notify(NoticeKind.driverNoShow, {'day': ride.date.toIso(), 'leg': ride.leg.name});
    await _applyStanding(ride.date.monthKey);
  }

  /// Second no-show this month → warning; third → removal from the group,
  /// keeping the commute profile so matching can start again (FR-009).
  Future<void> _applyStanding(String monthKey) async {
    switch (AttendanceRules.standing(await noShowsInMonth(monthKey))) {
      case NoShowStanding.ok:
        break;
      case NoShowStanding.warning:
        await _notify(NoticeKind.noShowWarning, const {});
      case NoShowStanding.removal:
        await _prefs.remove(FakeCommuteRepository.membershipKey);
        await _notify(NoticeKind.removed, const {});
    }
  }

  // ------------------------------------------------------------- results

  @override
  Future<List<Charge>> chargesOwed() async => _charges().where((c) => c.personId == meId).toList();

  @override
  Future<int> noShowsInMonth(String monthKey) async => _events()
      .where((e) => e.personId == meId && e.kind == ReliabilityEventKind.noShow && e.date.monthKey == monthKey)
      .length;

  @override
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to) async =>
      _events().where((e) => e.personId == meId && !e.date.isBefore(from) && !e.date.isAfter(to)).toList();

  // ------------------------------------------------------------- notices

  @override
  Stream<List<Notice>> notices() async* {
    yield _notices();
    yield* _noticeUpdates.stream;
  }

  @override
  Future<void> markRead(String noticeId) async {
    await _writeList(
      noticesKey,
      [for (final n in _notices()) n.id == noticeId ? n.markedRead() : n],
      (n) => n.toJson(),
    );
    _noticeUpdates.add(_notices());
  }

  @override
  Future<void> chooseNoCoverOption(CalendarDate date, Leg leg, NoCoverOption option) async {
    if (option != NoCoverOption.dayOff) return;
    final list = _absences()
      ..add(Absence(personId: meId, date: date, leg: leg, madeAt: _now(), kind: AbsenceKind.noCover));
    await _writeList(absencesKey, list, (a) => a.toJson());
  }

  Future<void> _notify(NoticeKind kind, Map<String, String> params, {bool toMe = true}) async {
    final list = _notices();
    list.add(Notice(id: 'n${list.length + 1}', kind: kind, createdAt: _now(), params: params, toMe: toMe));
    await _writeList(noticesKey, list, (n) => n.toJson());
    _noticeUpdates.add(_notices());
  }

  /// Debug "Reset demo data" (research R11).
  Future<void> reset() async {
    for (final key in allKeys) {
      await _prefs.remove(key);
    }
    _noticeUpdates.add(const []);
  }

  // ------------------------------------------------------------- storage

  static CalendarDate _dateOf(String rideId) => CalendarDate.parse(rideId.split(':')[1]);

  static Leg _legOf(String rideId) => rideId.endsWith(':going') ? Leg.going : Leg.ret;

  Map<String, Map<String, Object?>> _rideState() {
    final raw = _prefs.getString(rideStateKey);
    if (raw == null) return {};
    return {
      for (final e in (jsonDecode(raw) as Map).entries) e.key as String: (e.value as Map).cast<String, Object?>(),
    };
  }

  Future<void> _updateRide(String rideId, void Function(Map<String, Object?> state) change) async {
    final all = _rideState();
    final state = all.putIfAbsent(rideId, () => {});
    change(state);
    await _prefs.setString(rideStateKey, jsonEncode(all));
  }

  List<T> _readList<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) fromJson((e as Map).cast<String, Object?>())];
  }

  Future<void> _writeList<T>(String key, List<T> items, Map<String, Object?> Function(T) toJson) =>
      _prefs.setString(key, jsonEncode([for (final i in items) toJson(i)]));

  List<Absence> _absences() => _readList(absencesKey, Absence.fromJson);
  List<StopCheckIn> _checkIns() => _readList(checkInsKey, StopCheckIn.fromJson);
  List<PassengerOutcome> _outcomes() => _readList(outcomesKey, PassengerOutcome.fromJson);
  List<Charge> _charges() => _readList(chargesKey, Charge.fromJson);
  List<ReliabilityEvent> _events() => _readList(eventsKey, ReliabilityEvent.fromJson);
  List<Notice> _notices() => _readList(noticesKey, Notice.fromJson);
  List<_Backup> _backups() => _readList(backupsKey, _Backup.fromJson);
}

/// A cover driver standing in for one leg on one date.
final class _Backup {
  const _Backup({required this.date, required this.leg, required this.coverId, required this.step, required this.seats});

  final CalendarDate date;
  final Leg leg;
  final String coverId;
  final BackupStep step;

  /// Seats free in the cover's car that leg.
  final int seats;

  Map<String, Object?> toJson() =>
      {'date': date.toIso(), 'leg': leg.name, 'coverId': coverId, 'step': step.name, 'seats': seats};

  static _Backup fromJson(Map<String, Object?> j) => _Backup(
        date: CalendarDate.parse(j['date']! as String),
        leg: Leg.values.byName(j['leg']! as String),
        coverId: j['coverId']! as String,
        step: BackupStep.values.byName(j['step']! as String),
        seats: j['seats']! as int,
      );
}
