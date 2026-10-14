import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/marketplace/domain/booking_refund.dart';
import 'package:goora/features/marketplace/domain/driver_day_rules.dart';

/// 005 driver day rule + booking refund against
/// test/fixtures/marketplace_vectors.json — the same file
/// supabase/functions/_shared/marketplace.test.ts runs.
/// Regenerate with `python test/fixtures/gen_marketplace_vectors.py`.
void main() {
  final j = jsonDecode(File('test/fixtures/marketplace_vectors.json').readAsStringSync()) as Map<String, dynamic>;

  group('fit', () {
    for (final c in (j['fit'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final trips = (c['trips'] as List).cast<Map<String, dynamic>>().map(_trip).toList();
        expect(
          DriverDayRules.fit(trips, _candidate(c['candidate'] as Map<String, dynamic>)),
          _fit(c['expect'] as Map<String, dynamic>),
          reason: c['name'] as String,
        );
      });
    }
  });

  group('refund', () {
    for (final c in (j['refund'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        expect(
          BookingRefund.amount(paidTotal: c['paidTotal'] as int, fee: c['fee'] as int, owed: c['owed'] as int),
          c['expect'],
          reason: c['name'] as String,
        );
      });
    }
  });
}

Leg _leg(Object? s) => switch (s) {
  'going' => Leg.going,
  'return' => Leg.ret,
  _ => throw ArgumentError.value(s, 'leg'),
};

Area _area(Object? s) => Area.values.byName(s as String);

DayTrip _trip(Map<String, dynamic> t) => DayTrip(
  id: t['id'] as String,
  leg: _leg(t['leg']),
  from: _area(t['from']),
  to: _area(t['to']),
  departure: t['departure'] as int,
  durationMinutes: t['durationMinutes'] as int,
  seats: t['seats'] as int,
  taken: t['taken'] as int,
);

Candidate _candidate(Map<String, dynamic> c) => Candidate(
  leg: _leg(c['leg']),
  from: _area(c['from']),
  to: _area(c['to']),
  departure: c['departure'] as int,
  durationMinutes: c['durationMinutes'] as int,
  daily: c['daily'] as bool,
  leadsGroup: c['leadsGroup'] as bool,
);

TripFit _fit(Map<String, dynamic> e) => switch (e['kind']) {
  'join' => TripFit.join(e['tripId'] as String),
  'full' => TripFit.full(e['tripId'] as String),
  'create' => TripFit.create(e['tripsLeftAfter'] as int),
  'limitReached' => const TripFit.limitReached(),
  'doesntFit' => const TripFit.doesntFit(),
  'oneGroupOnly' => const TripFit.oneGroupOnly(),
  'overlap' => const TripFit.overlap(),
  final k => throw ArgumentError.value(k, 'kind'),
};
