import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/attendance_rules.dart';
import 'package:goora/features/daily/domain/backup_service.dart';
import 'package:goora/features/daily/domain/privacy.dart';
import 'package:goora/features/daily/domain/reliability_rules.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/rotation_planner.dart';
import 'package:goora/features/daily/domain/schedule.dart';
import 'package:goora/features/daily/domain/trust.dart';

/// The 003 rules against test/fixtures/*_vectors.json — the same files the
/// Edge Function mirrors run (supabase/functions/_shared/*.test.ts).
/// Regenerate with `python test/fixtures/gen_daily_vectors.py`.
void main() {
  group('attendance', () {
    for (final c in _cases('attendance')) {
      test(c['name'] as String, () {
        final i = c['input'] as Map<String, dynamic>;
        expect(_attendance(c['fn'] as String, i), c['expect']);
      });
    }
  });

  group('reliability', () {
    for (final c in _cases('reliability')) {
      test(c['name'] as String, () {
        final today = CalendarDate.parse(c['today'] as String);
        final r = ReliabilityRules.compute([
          for (final e in (c['events'] as List).cast<Map<String, dynamic>>())
            ReliabilityEvent(
              personId: 'me',
              rideId: 'r',
              date: CalendarDate.parse(e['date'] as String),
              kind: ReliabilityEventKind.values.byName(e['kind'] as String),
            ),
        ], today);
        expect(
          {'percent': r.percent, 'monthLateCancels': r.monthLateCancels, 'monthNoShows': r.monthNoShows},
          c['expect'],
        );
      });
    }
  });

  group('rotation', () {
    for (final c in _cases('rotation')) {
      test(c['name'] as String, () {
        final days = RotationPlanner.plan(
          _group(c['group'] as Map<String, dynamic>),
          CalendarDate.parse(c['from'] as String),
          CalendarDate.parse(c['to'] as String),
          unavailable: {
            for (final u in (c['unavailable'] as List).cast<List<dynamic>>())
              (u[0] as String, CalendarDate.parse(u[1] as String), Leg.values.byName(u[2] as String)),
          },
        );
        expect([for (final d in days) [d.date.toIso(), d.going?.planned, d.ret?.planned]], c['expect']);
      });
    }
  });

  group('backup', () {
    for (final c in _cases('backup')) {
      test(c['name'] as String, () {
        final r = c['ride'] as Map<String, dynamic>;
        final ride = Ride(
          groupId: r['groupId'] as String,
          date: CalendarDate.parse(r['date'] as String),
          leg: Leg.values.byName(r['leg'] as String),
          driverId: null,
          passengers: [
            for (final p in (r['passengers'] as List).cast<Map<String, dynamic>>())
              Passenger(memberId: p['memberId'] as String, stopId: p['stopId'] as String),
          ],
          stops: const [],
        );
        final result = BackupService.findCover(ride, _group(c['group'] as Map<String, dynamic>), [
          for (final k in (c['candidates'] as List).cast<Map<String, dynamic>>()) _candidate(k),
        ]);
        expect({'cover': result.coverId, 'step': result.step?.name}, c['expect']);
      });
    }
  });
}

List<Map<String, dynamic>> _cases(String name) {
  final j = jsonDecode(File('test/fixtures/${name}_vectors.json').readAsStringSync()) as Map<String, dynamic>;
  return (j['cases'] as List).cast<Map<String, dynamic>>();
}

WallTime _wt(Object? s) => WallTime.fromJson(s! as String);

CalendarDate _date(Object? s) => CalendarDate.parse(s! as String);

Object? _attendance(String fn, Map<String, dynamic> i) => switch (fn) {
      'cancel' => () {
          final ride = _date(i['rideDate']);
          final made = _wt(i['madeAt']);
          final charges = [
            for (final _ in i['legs'] as List) AttendanceRules.cancelCharge(ride, made, i['share'] as int),
          ];
          return {
            'cutoff': AttendanceRules.cutoffFor(ride).toJson(),
            'late': AttendanceRules.isLate(ride, made),
            'kind': AttendanceRules.cancelKind(ride, made).name,
            'charges': charges,
            'total': charges.fold<int>(0, (a, b) => a + b),
          };
        }(),
      'canCancel' => AttendanceRules.canCancel(_wt(i['pickup']), _wt(i['madeAt'])),
      'undo' => () {
          final a = i['absence'] as Map<String, dynamic>;
          final date = _date(a['date']);
          return AttendanceRules.canUndo(
            Absence(
              personId: 'me',
              date: date,
              leg: Leg.going,
              madeAt: WallTime(date.addDays(-2), const Clock.hm(12, 0)),
              kind: AbsenceKind.values.byName(a['kind'] as String),
            ),
            _wt(i['now']),
            pickup: _wt(i['pickup']),
            waitlistWaiting: i['waitlistWaiting'] as bool,
          ).name;
        }(),
      'noShow' => {
          'availableAt': AttendanceRules.noShowAvailableAt(_wt(i['arrivedAt'])).toJson(),
          'allowed': AttendanceRules.canMarkNoShow(_wt(i['arrivedAt']), _wt(i['now'])),
        },
      'standing' => AttendanceRules.standing(i['count'] as int).name,
      'driverNoShow' => AttendanceRules.driverNoShow(
          firstPickup: _wt(i['firstPickup']),
          now: _wt(i['now']),
          checkedIn: i['checkedIn'] as bool,
          cancelled: i['cancelled'] as bool,
        ),
      'noShowCharge' => AttendanceRules.noShowCharge(i['share'] as int),
      _ => throw ArgumentError(fn),
    };

GeoPoint _point(Object? p) {
  final l = (p! as List).cast<num>();
  return GeoPoint(l[0].toDouble(), l[1].toDouble());
}

Clock _clock(Object? s) {
  final [h, m] = (s! as String).split(':').map(int.parse).toList();
  return Clock.hm(h, m);
}

Set<Day> _days(Object? l) => {for (final d in (l! as List).cast<String>()) Day.values.byName(d)};

Set<Leg> _legs(Object? l) => {for (final d in (l! as List).cast<String>()) Leg.values.byName(d)};

Member _member(Map<String, dynamic> m) => Member(
      id: m['id'] as String,
      firstName: m['firstName'] as String,
      initials: m['initials'] as String,
      role: MemberRole.values.byName(m['role'] as String),
      isWoman: m['isWoman'] as bool,
      company: m['company'] as String?,
      compound: m['compound'] as String?,
      rating: (m['rating'] as num).toDouble(),
      reliability: (m['reliability'] as num).toDouble(),
      legs: _legs(m['legs']),
      privacy: PrivacyPreference.values.byName(m['privacy'] as String),
      days: m['days'] == null ? null : _days(m['days']),
    );

CommuteGroup _group(Map<String, dynamic> j) => CommuteGroup(
      id: j['id'] as String,
      origin: Area.values.byName(j['origin'] as String),
      destination: Area.values.byName(j['destination'] as String),
      destinationPoint: _point(j['destinationPoint']),
      pickupPoints: [for (final p in j['pickupPoints'] as List) _point(p)],
      going: _clock(j['going']),
      ret: _clock(j['ret']),
      days: _days(j['days']),
      members: [for (final m in (j['members'] as List).cast<Map<String, dynamic>>()) _member(m)],
      price: j['price'] as int,
      freeSeatsGoing: j['freeSeatsGoing'] as int,
      freeSeatsReturn: j['freeSeatsReturn'] as int,
      detourMinutes: j['detourMinutes'] as int,
      womenOnly: j['womenOnly'] as bool,
      sameCompanyOnly: j['sameCompanyOnly'] as String?,
      sameCompoundOnly: j['sameCompoundOnly'] as String?,
      rotationStart: j['rotationStart'] == null ? null : _date(j['rotationStart']),
    );

BackupCandidate _candidate(Map<String, dynamic> k) {
  final s = k['seeker'] as Map<String, dynamic>;
  return BackupCandidate(
    member: _member(k['member'] as Map<String, dynamic>),
    step: BackupStep.values.byName(k['step'] as String),
    seeker: Seeker(
      role: MemberRole.driver,
      home: _point(s['home']),
      work: _point(s['work']),
      departure: _clock(s['departure']),
      ret: _clock(s['ret']),
      days: _days(s['days']),
      legs: const {Leg.going, Leg.ret},
    ),
    freeSeats: k['freeSeats'] as int,
    available: k['available'] as bool,
  );
}
