import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/data/corridor_seed.dart';
import '../../commute/data/fake_commute_repository.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/commute_repository.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/matching_service.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/domain/profile.dart';
import '../domain/absence.dart';
import '../domain/attendance_rules.dart';
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

  static const allKeys = [
    absencesKey,
    checkInsKey,
    outcomesKey,
    rideStateKey,
    backupsKey,
    chargesKey,
    eventsKey,
    noticesKey,
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
    if (_prefs.containsKey(eventsKey)) return;
    await _writeList(eventsKey, DailySeed.history(g, _now().date), (e) => e.toJson());
  }

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
    LegAssignment? apply(LegAssignment? a, CalendarDate date) {
      if (a == null || a.planned == null) return a;
      final away = absences.any((x) => x.driving && x.personId == a.planned && x.date == date && x.leg == a.leg);
      return away ? LegAssignment(leg: a.leg, planned: a.planned, actual: null) : a;
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
    final passengers = <Passenger>[
      for (final m in g.members)
        if (m.id != driverId &&
            travelsOn(g, m, date, leg) &&
            day.absences.every((a) => !(a.personId == m.id && a.leg == leg)))
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
    final day = _schedule(g, date, date).firstOrNull;
    if (day == null) return const BackupResult.none();
    final absences = _absences();
    final events = _events();
    for (final leg in Leg.values.where(legs.contains)) {
      if (day.assignment(leg)?.planned != meId) continue;
      final late = AttendanceRules.driverCantDriveLate(date, madeAt);
      absences.add(Absence(
        personId: meId,
        date: date,
        leg: leg,
        madeAt: madeAt,
        kind: late ? AbsenceKind.lateCancel : AbsenceKind.freeCancel,
        driving: true,
      ));
      if (late) {
        events.add(ReliabilityEvent(
          personId: meId,
          rideId: Ride.idFor(g.id, date, leg),
          date: date,
          kind: ReliabilityEventKind.lateCantDrive,
        ));
      }
      // Backup search arrives with US4; until then riders hear there is no cover.
      await _notify(NoticeKind.noCover, {'day': date.toIso(), 'leg': leg.name}, toMe: false);
    }
    await _writeList(absencesKey, absences, (a) => a.toJson());
    await _writeList(eventsKey, events, (e) => e.toJson());
    return const BackupResult.none();
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
    await _settle(rideId);
  }

  @override
  Future<void> endTrip(String rideId, WallTime at) async {
    final started = _rideState()[rideId]?['startedAt'] != null;
    await _updateRide(rideId, (s) {
      s['endedAt'] = at.toJson();
      s['startedAt'] ??= at.toJson();
    });
    if (!started) await _settle(rideId);
  }

  /// Marks become final when the trip starts: each no-show owes the full
  /// share to the driver and counts toward the monthly standing; each
  /// passenger picked up keeps a trip (FR-008, FR-009).
  Future<void> _settle(String rideId) async {
    final g = await myGroup();
    if (g == null) return;
    final date = _dateOf(rideId);
    final ride = await _ride(g, date, _legOf(rideId));
    if (ride == null || ride.driverId == null) return;
    final charges = _charges();
    final events = _events();
    final noShows = <String>[];
    for (final o in _outcomes().where((o) => o.rideId == rideId)) {
      if (events.any((e) => e.rideId == rideId && e.personId == o.personId)) continue;
      if (o.outcome == Outcome.noShow) {
        noShows.add(o.personId);
        charges.add(Charge(
          id: 'noShow:$rideId:${o.personId}',
          personId: o.personId,
          rideId: rideId,
          reason: ChargeReason.noShow,
          amount: AttendanceRules.noShowCharge(g.price),
          owedTo: ride.driverId!,
        ));
        events.add(ReliabilityEvent(personId: o.personId, rideId: rideId, date: date, kind: ReliabilityEventKind.noShow));
      } else if (o.outcome == Outcome.pickedUp) {
        events.add(ReliabilityEvent(personId: o.personId, rideId: rideId, date: date, kind: ReliabilityEventKind.kept));
      }
    }
    await _writeList(chargesKey, charges, (c) => c.toJson());
    await _writeList(eventsKey, events, (e) => e.toJson());
    for (final personId in noShows) {
      await _notify(
        NoticeKind.noShowCharged,
        {'day': date.toIso(), 'amount': '${g.price}', 'leg': ride.leg.name},
        toMe: personId == meId,
      );
    }
    if (noShows.contains(meId)) await _applyStanding(date.monthKey);
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
}
