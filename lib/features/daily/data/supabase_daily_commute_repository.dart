import 'dart:async';

import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../domain/absence.dart';
import '../domain/charge.dart';
import '../domain/check_in.dart';
import '../domain/daily_commute_repository.dart';
import '../domain/notice.dart';
import '../domain/ride.dart';
import '../domain/rotation_planner.dart';
import '../domain/schedule.dart';
import '../domain/trust.dart';

/// The daily commute on the server (003 tables and the `commute-day` Edge
/// Function; 011 research D17). Reads go to the 003 tables under their RLS
/// (own group only); every action is one `commute-day` call, where the 003
/// rules (the `_shared/*.ts` twins of the Dart rules) decide charges, undo
/// and backups on the Cairo clock. The rotation itself is the shared
/// [RotationPlanner], so the device and the server agree on who drives.
///
/// A ride the server has not stored yet is stored on first read (the `ride`
/// action, 013 D10), so it carries a real share token and each rider's own
/// stop; only when that call fails does the plan stand in. The "no cover"
/// day off goes to the server as the `noCover` action.
final class SupabaseDailyCommuteRepository implements DailyCommuteRepository {
  SupabaseDailyCommuteRepository(this._db);

  static const function = 'commute-day';

  final BackendGateway _db;

  /// Rides already asked the server to store this session: one call each, not one per read.
  final _opened = <String>{};
  final _noticeUpdates = StreamController<List<Notice>>.broadcast();

  @override
  String get meId => _db.userId ?? '';

  static WallTime? _at(Object? s) => s == null ? null : WallTime.of(DateTime.parse(s as String).toLocal());

  static Leg _leg(Object? s) => Leg.values.byName(s! as String);

  @override
  Future<CommuteGroup?> myGroup() async {
    final me = _db.userId;
    if (me == null) return null;
    final mine = await _db.select('group_members', where: [Filter.eq('user_id', me)], limit: 1);
    if (mine.isEmpty) return null;
    final id = mine.single['group_id']! as String;
    final g = (await _db.select('groups', where: [Filter.eq('id', id)])).singleOrNull;
    if (g == null) return null;
    final all =
        (await _db.rpc('groups_for', {'p_origin': g['origin_area'], 'p_destination': g['destination_area']}))! as List;
    final json = all.cast<Map<Object?, Object?>>().where((j) => j['id'] == id).firstOrNull;
    return json == null ? null : CommuteGroup.fromJson(json.cast<String, Object?>());
  }

  @override
  Future<List<ScheduleDay>> schedule(CalendarDate from, CalendarDate to) async {
    final g = await myGroup();
    if (g == null) return const [];
    final away = await _groupAbsences(g.id, from, to);
    final rides = {
      for (final r in await _db.select(
        'rides',
        where: [
          Filter.eq('group_id', g.id),
          Filter.gte('ride_date', from.toIso()),
          Filter.lte('ride_date', to.toIso()),
        ],
      ))
        r['id']! as String: r,
    };
    LegAssignment? apply(LegAssignment? a, CalendarDate date) {
      final r = a == null ? null : rides[Ride.idFor(g.id, date, a.leg)];
      if (a == null || r == null || r['driver_id'] == a.planned) return a;
      final step = r['backup_step'] as String?;
      return LegAssignment(
        leg: a.leg,
        planned: a.planned,
        actual: r['driver_id'] as String?,
        isBackup: r['driver_id'] != null,
        backupStep: step == null ? null : BackupStep.values.byName(step),
        cover: r['driver_id'] == null ? null : g.member(r['driver_id']! as String),
      );
    }

    return [
      for (final d in RotationPlanner.plan(g, from, to))
        ScheduleDay(
          date: d.date,
          going: apply(d.going, d.date),
          ret: apply(d.ret, d.date),
          absences: [
            for (final a in away)
              if (a.date == d.date) a,
          ],
        ),
    ];
  }

  Future<List<Absence>> _groupAbsences(String groupId, CalendarDate from, CalendarDate to) async => [
    for (final r in await _db.select(
      'absences',
      where: [
        Filter.eq('group_id', groupId),
        Filter.gte('ride_date', from.toIso()),
        Filter.lte('ride_date', to.toIso()),
      ],
    ))
      _absence(r),
  ];

  static Absence _absence(Row r) => Absence(
    personId: r['user_id']! as String,
    date: CalendarDate.parse(r['ride_date']! as String),
    leg: _leg(r['leg']),
    madeAt: _at(r['made_at'])!,
    kind: AbsenceKind.values.byName(r['kind']! as String),
    driving: (r['driving'] as bool?) ?? false,
  );

  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async {
    final g = await myGroup();
    if (g == null) return null;
    final day = (await schedule(date, date)).firstOrNull;
    final assignment = day?.assignment(leg);
    if (day == null || assignment == null) return null;
    final id = Ride.idFor(g.id, date, leg);
    var row = (await _db.select('rides', where: [Filter.eq('id', id)])).singleOrNull;
    if (row == null && assignment.actual != null && _opened.add(id)) {
      try {
        await _call({'action': 'ride', 'date': date.toIso(), 'leg': leg.name});
        row = (await _db.select('rides', where: [Filter.eq('id', id)])).singleOrNull;
      } on BackendFailure {
        // Offline or refused: the plan stands in for this read and the next one asks again.
        _opened.remove(id);
      }
    }
    final driverId = row == null ? assignment.actual : row['driver_id'] as String?;
    final seated = row == null
        ? null
        : [
            for (final p in await _db.select('ride_passengers', where: [Filter.eq('ride_id', id)]))
              Passenger(memberId: p['user_id']! as String, stopId: p['stop_id']! as String),
          ];
    final passengers =
        seated ??
        [
          for (final m in g.members)
            if (m.id != driverId &&
                travelsOn(g, m, date, leg) &&
                day.absences.every((a) => !(a.personId == m.id && a.leg == leg)))
              // Before the server stores the ride: the group's first stop going,
              // its work stop back (the stored ride has each rider's own stop).
              Passenger(memberId: m.id, stopId: leg == Leg.going ? g.goingStops.first.id : g.workStop.id),
        ];
    final delay = (row?['delay_minutes'] as int?) ?? 0;
    final arrived = row == null ? const <String>{} : {for (final c in await checkIns(id)) c.stopId};
    return Ride(
      groupId: g.id,
      date: date,
      leg: leg,
      driverId: driverId,
      passengers: passengers,
      stops: [
        for (final s in leg == Leg.going ? g.goingStops : [g.workStop])
          Stop(id: s.id, name: s.name, point: s.point, time: s.time.shift(delay)),
      ],
      delayMinutes: delay,
      confirmed: (row?['confirmed'] as bool?) ?? false,
      arrivedStopIds: arrived,
      startedAt: _at(row?['started_at']),
      endedAt: _at(row?['ended_at']),
      shareToken: row?['share_token'] as String?,
      seats: row?['seats'] as int?,
    );
  }

  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async {
    final g = await myGroup();
    return g == null ? const [] : _groupAbsences(g.id, from, to);
  }

  @override
  Future<List<StopCheckIn>> checkIns(String rideId) async => [
    for (final r in await _db.select('pickup_check_ins', where: [Filter.eq('ride_id', rideId)]))
      StopCheckIn(rideId: rideId, stopId: r['stop_id']! as String, arrivedAt: _at(r['arrived_at'])!),
  ];

  @override
  Future<List<PassengerOutcome>> outcomes(String rideId) async => [
    for (final r in await _db.select('passenger_outcomes', where: [Filter.eq('ride_id', rideId)]))
      PassengerOutcome(
        rideId: rideId,
        personId: r['user_id']! as String,
        outcome: Outcome.values.byName(r['outcome']! as String),
        markedAt: _at(r['marked_at'])!,
      ),
  ];

  // Actions: one commute-day call each ---------------------------------------------------

  /// A 409 `{refused}` the app knows becomes [AttendanceRefused].
  Future<Map<Object?, Object?>> _call(Row body) async {
    try {
      return ((await _db.invoke(function, body)) as Map?) ?? const {};
    } on BackendRefused catch (e) {
      final reason = RefusalReason.values.asNameMap()[e.reason];
      if (reason != null) throw AttendanceRefused(reason);
      rethrow;
    }
  }

  List<Charge> _charges(Map<Object?, Object?> out) => [
    for (final c in ((out['charges'] as List?) ?? const []).cast<Map<Object?, Object?>>())
      Charge(
        id: '${c['rideId']}:${c['reason']}',
        personId: meId,
        rideId: c['rideId']! as String,
        reason: ChargeReason.values.byName(c['reason']! as String),
        amount: c['amount']! as int,
        owedTo: (c['owedTo'] as String?) ?? '',
      ),
  ];

  static List<String> _legs(Set<Leg> legs) => [
    for (final l in Leg.values)
      if (legs.contains(l)) l.name,
  ];

  @override
  Future<List<Charge>> cancel(CalendarDate date, Set<Leg> legs, WallTime madeAt) async =>
      _charges(await _call({'action': 'cancel', 'date': date.toIso(), 'legs': _legs(legs)}));

  @override
  Future<UndoResult> undoCancel(CalendarDate date, WallTime now) async {
    try {
      await _db.invoke(function, {'action': 'undo', 'date': date.toIso()});
      return UndoResult.ok;
    } on BackendRefused catch (e) {
      return e.reason == 'seatTaken' ? UndoResult.refusedSeatTaken : UndoResult.refusedTooLate;
    }
  }

  @override
  Future<List<Charge>> notComingNextWeek(WallTime madeAt) async => _charges(await _call({'action': 'notNextWeek'}));

  @override
  Future<void> setConfirmed(String rideId, bool confirmed) =>
      _call({'action': confirmed ? 'confirm' : 'unconfirm', 'rideId': rideId});

  @override
  Future<void> reportDelay(String rideId, int minutes) =>
      _call({'action': 'delay', 'rideId': rideId, 'minutes': minutes});

  @override
  Future<BackupResult> cantDrive(CalendarDate date, Set<Leg> legs, WallTime madeAt) async {
    final out = await _call({'action': 'cantDrive', 'date': date.toIso(), 'legs': _legs(legs)});
    final cover = out['cover'] as Map?;
    return cover == null
        ? const BackupResult.none()
        : BackupResult.covered(cover['memberId']! as String, BackupStep.values.byName(cover['step']! as String));
  }

  @override
  Future<void> arrivedAt(String rideId, String stopId, WallTime at) =>
      _call({'action': 'arrive', 'rideId': rideId, 'stopId': stopId});

  @override
  Future<void> mark(String rideId, String personId, Outcome outcome, WallTime at) =>
      _call({'action': 'mark', 'rideId': rideId, 'personId': personId, 'outcome': outcome.name});

  @override
  Future<void> startTrip(String rideId, WallTime at) => _call({'action': 'start', 'rideId': rideId});

  @override
  Future<void> endTrip(String rideId, WallTime at) => _call({'action': 'end', 'rideId': rideId});

  // Results -------------------------------------------------------------------------------

  @override
  Future<List<Charge>> chargesOwed() async {
    final me = _db.userId;
    if (me == null) return const [];
    return [
      for (final r in await _db.select('charges', where: [Filter.eq('user_id', me)], orderBy: 'created_at'))
        Charge(
          id: r['id']! as String,
          personId: me,
          rideId: r['ride_id']! as String,
          reason: ChargeReason.values.byName(r['reason']! as String),
          amount: r['amount']! as int,
          owedTo: (r['owed_to'] as String?) ?? '',
        ),
    ];
  }

  @override
  Future<int> noShowsInMonth(String monthKey) async {
    final events = await _events();
    return events.where((e) => e.kind == ReliabilityEventKind.noShow && e.date.monthKey == monthKey).length;
  }

  @override
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to) async => [
    for (final e in await _events())
      if (!e.date.isBefore(from) && !e.date.isAfter(to)) e,
  ];

  Future<List<ReliabilityEvent>> _events() async {
    final me = _db.userId;
    if (me == null) return const [];
    return [
      for (final r in await _db.select('reliability_events', where: [Filter.eq('user_id', me)]))
        ReliabilityEvent(
          personId: me,
          rideId: r['ride_id']! as String,
          date: CalendarDate.parse(r['ride_date']! as String),
          kind: ReliabilityEventKind.values.byName(r['kind']! as String),
        ),
    ];
  }

  // Notices -------------------------------------------------------------------------------

  Future<List<Notice>> _notices() async {
    final me = _db.userId;
    if (me == null) return const [];
    final known = NoticeKind.values.asNameMap();
    return [
      for (final r in await _db.select(
        'notices',
        where: [Filter.eq('user_id', me)],
        orderBy: 'created_at',
        descending: true,
      ))
        if (known[r['kind']] case final kind?)
          Notice(
            id: r['id']! as String,
            kind: kind,
            createdAt: _at(r['created_at'])!,
            params: {for (final e in ((r['params'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
            read: r['read_at'] != null,
          ),
    ];
  }

  /// The current list, then a fresh one after every [markRead].
  @override
  Stream<List<Notice>> notices() async* {
    yield await _notices();
    yield* _noticeUpdates.stream;
  }

  @override
  Future<void> markRead(String noticeId) async {
    await _db.update(
      'notices',
      {'read_at': DateTime.now().toUtc().toIso8601String()},
      where: [Filter.eq('id', noticeId)],
    );
    _noticeUpdates.add(await _notices());
  }

  @override
  Future<void> chooseNoCoverOption(CalendarDate date, Leg leg, NoCoverOption option) async {
    if (option != NoCoverOption.dayOff) return;
    try {
      await _call({'action': 'noCover', 'date': date.toIso(), 'leg': leg.name});
    } on BackendRefused {
      // A driver covers after all: there is no day off to record, and nothing was charged.
    }
  }
}
