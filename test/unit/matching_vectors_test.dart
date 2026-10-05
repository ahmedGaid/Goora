import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';

/// Same file is run by supabase/functions/_shared/matching.test.ts.
/// Expected values come from an independent reference implementation.
void main() {
  final fixture = jsonDecode(File('test/fixtures/matching_vectors.json').readAsStringSync()) as Map<String, dynamic>;

  for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
    test(c['name'] as String, () {
      final result = MatchingService.match(
        seekerFromJson(c['seeker'] as Map<String, dynamic>),
        [for (final g in (c['groups'] as List).cast<Map<String, dynamic>>()) groupFromJson(g)],
      );
      final expected = c['expect'] as Map<String, dynamic>;
      expect(result.main?.group.id, expected['main']);
      expect(result.main?.score, expected['mainScore']);
      expect([for (final r in result.main?.reasons ?? const <Reason>[]) r.kind.name], expected['mainReasons']);
      expect(result.returnMatch?.group.id, expected['returnMatch']);
      expect(
        [for (final a in result.alternatives) [a.group.id, a.score]],
        expected['alternatives'],
      );
    });
  }
}

GeoPoint _point(Object? p) {
  final l = (p! as List).cast<num>();
  return GeoPoint(l[0].toDouble(), l[1].toDouble());
}

Clock _clock(Object? s) {
  final parts = (s! as String).split(':');
  return Clock.hm(int.parse(parts[0]), int.parse(parts[1]));
}

Set<Day> _days(Object? l) => {for (final d in (l! as List).cast<String>()) Day.values.byName(d)};

Set<Leg> _legs(Object? l) => {for (final d in (l! as List).cast<String>()) Leg.values.byName(d)};

Seeker seekerFromJson(Map<String, dynamic> j) => Seeker(
      role: MemberRole.values.byName(j['role'] as String),
      home: _point(j['home']),
      work: _point(j['work']),
      departure: _clock(j['departure']),
      ret: _clock(j['ret']),
      days: _days(j['days']),
      legs: _legs(j['legs']),
      isWoman: j['isWoman'] as bool,
      company: j['company'] as String?,
      compound: j['compound'] as String?,
      womenOnly: j['womenOnly'] as bool,
      sameCompanyOnly: j['sameCompanyOnly'] as bool,
      sameCompoundOnly: j['sameCompoundOnly'] as bool,
    );

CommuteGroup groupFromJson(Map<String, dynamic> j) => CommuteGroup(
      id: j['id'] as String,
      origin: Area.values.byName(j['origin'] as String),
      destination: Area.values.byName(j['destination'] as String),
      destinationPoint: _point(j['destinationPoint']),
      pickupPoints: [for (final p in j['pickupPoints'] as List) _point(p)],
      going: _clock(j['going']),
      ret: _clock(j['ret']),
      days: _days(j['days']),
      members: [
        for (final m in (j['members'] as List).cast<Map<String, dynamic>>())
          Member(
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
          ),
      ],
      price: j['price'] as int,
      freeSeatsGoing: j['freeSeatsGoing'] as int,
      freeSeatsReturn: j['freeSeatsReturn'] as int,
      detourMinutes: j['detourMinutes'] as int,
      womenOnly: j['womenOnly'] as bool,
      sameCompanyOnly: j['sameCompanyOnly'] as String?,
      sameCompoundOnly: j['sameCompoundOnly'] as String?,
    );
