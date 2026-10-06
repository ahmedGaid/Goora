import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/config/env.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/widgets/goora_route_map.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/location_source.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US7: live trip marker, share and SOS (FR-028 – FR-031, SC-006), ar + en.
final class FakeLocationSource implements LocationSource {
  final _positions = StreamController<TripPosition>.broadcast(sync: true);
  final watched = <String>[];

  void emit(String rideId, double progress) =>
      _positions.add(TripPosition(rideId: rideId, progress: progress, at: at(rideTuesday, 7, 30)));

  @override
  Stream<TripPosition> watch(String rideId) {
    watched.add(rideId);
    return _positions.stream.where((p) => p.rideId == rideId);
  }
}

final _going = Ride.idFor('sz-0725', rideTuesday, Leg.going);

Map<String, Object> _contacts() => {
      FakeTrustRepository.contactsKey: jsonEncode([
        TrustedContact(id: 'c1', name: 'Mona', phone: testPhone).toJson(),
      ]),
    };

Future<ProviderContainer> _pump(
  WidgetTester tester,
  TestClock clock,
  String locale, {
  RecordingDialer? dialer,
  RecordingSharer? sharer,
  LocationSource? location,
  Map<String, Object> extra = const {},
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.rider, locale: locale), ...extra},
    overrides: [
      ...dailyOverrides(clock, dialer: dialer, sharer: sharer),
      if (location != null) locationSourceProvider.overrideWithValue(location),
    ],
  );
  tester.view.physicalSize = const Size(390, 2600);
  await tester.pumpAndSettle();
  return c;
}

/// The driver checks in at my stop (Central St, 7:25): the trip is active.
Future<void> _driverArrives(WidgetTester tester, ProviderContainer c) async {
  final repo = c.read(dailyCommuteRepositoryProvider);
  await tester.runAsync(() => repo.arrivedAt(_going, 'central-st', at(rideTuesday, 7, 25)));
  c.invalidate(todayControllerProvider);
  await tester.pumpAndSettle();
}

double? _marker(WidgetTester tester) => tester
    .widget<GooraRouteMap>(find.descendant(of: find.byKey(const Key('live-map')), matching: find.byType(GooraRouteMap)))
    .driverProgress;

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] active trip: the marker follows the location stream, arrival countdown (US7/AC1)',
        (tester) async {
      final location = FakeLocationSource();
      final c = await _pump(tester, TestClock(at(rideTuesday, 7, 26)), code, location: location);
      // Before the driver arrives: no marker, the pickup countdown.
      expect(find.byKey(const Key('live-map')), findsNothing);
      expect(location.watched, isEmpty);

      await _driverArrives(tester, c);
      expect(location.watched, [_going]);
      expect(_marker(tester), 0);
      expect(find.text(l.arrivalInMin(39)), findsOneWidget, reason: '7:26 → 8:05');
      expect(find.byKey(const Key('pickup-countdown')), findsNothing);

      location.emit(_going, 0.25);
      await tester.pump();
      expect(_marker(tester), 0.25);
      location.emit(_going, 0.5);
      await tester.pump();
      expect(_marker(tester), 0.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] Share trip: route, driver, car, arrival and link — no home point (US7/AC2)', (tester) async {
      final sharer = RecordingSharer();
      await _pump(tester, TestClock(at(rideTuesday, 7, 13)), code, sharer: sharer);
      await tester.tap(find.byKey(const Key('share-trip')));
      await tester.pumpAndSettle();
      expect(sharer.shared, hasLength(1));
      final text = sharer.shared.single;
      final link = RegExp('${RegExp.escape(Env.shareBaseUrl)}/t/[0-9a-f]{16}\$').firstMatch(text)?.group(0);
      expect(link, isNotNull);
      expect(
        text,
        l.shareMessage(
          'Ahmed',
          l.carColour('Toyota Corolla', l.colourWhite),
          l.areaSheikhZayed,
          l.areaSmartVillage,
          l.timeAm('8:05'),
          link!,
        ),
      );
      const home = CorridorSeed.sheikhZayed;
      for (final leak in [home.id, '${home.point.lat}', '${home.point.lng}', 'sz-0725', rideTuesday.toIso()]) {
        expect(text, isNot(contains(leak)));
      }
    });

    testWidgets('[$code] SOS → Call 122 in two taps; alert reaches trusted contacts (US7/AC3, SC-006)',
        (tester) async {
      final dialer = RecordingDialer();
      final c = await _pump(tester, TestClock(at(rideTuesday, 7, 26)), code, dialer: dialer, extra: _contacts());
      await tester.tap(find.byKey(const Key('sos')));
      await tester.pumpAndSettle();
      expect(find.text(l.sosTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('sos-call')));
      await tester.pumpAndSettle();
      expect(dialer.dialled, ['122']);

      await tester.tap(find.byKey(const Key('sos-alert')));
      await tester.pumpAndSettle();
      expect(find.text(l.sosAlertSent), findsOneWidget);
      expect(find.byKey(const Key('sos-alert')), findsNothing);
      final raw = c.read(sharedPreferencesProvider).getString(FakeTrustRepository.sosKey)!;
      final alerts = [for (final e in jsonDecode(raw) as List) SosAlert.fromJson((e as Map).cast<String, Object?>())];
      expect(alerts, hasLength(1));
      expect(alerts.single.contactIds, ['c1']);
      expect(alerts.single.rideId, _going);
    });

    testWidgets('[$code] SOS with no trusted contacts: Call 122 + add one in Trust (US7/AC4)', (tester) async {
      final dialer = RecordingDialer();
      await _pump(tester, TestClock(at(rideTuesday, 7, 0)), code, dialer: dialer);
      await tester.tap(find.byKey(const Key('sos')));
      await tester.pumpAndSettle();
      expect(find.text(l.sosNoContacts), findsOneWidget);
      expect(find.byKey(const Key('sos-alert')), findsNothing);
      await tester.tap(find.byKey(const Key('sos-call')));
      await tester.pumpAndSettle();
      expect(dialer.dialled, ['122']);

      await tester.tap(find.byKey(const Key('sos-add-contact')));
      await tester.pumpAndSettle();
      expect(find.text(l.sosTitle), findsNothing);
      expect(find.text(l.trustedTitle), findsWidgets);
    });
  }

  testWidgets('simulated source: 5 s ticks from driver arrival to arrival, progress = elapsed ÷ trip time (R8)',
      (tester) async {
    final clock = TestClock(at(rideTuesday, 7, 35));
    final c = await _pump(tester, clock, 'en');
    final repo = c.read(dailyCommuteRepositoryProvider);
    await tester.runAsync(() => repo.arrivedAt(_going, 'central-st', at(rideTuesday, 7, 25)));
    final progress = <double>[];
    var done = false;
    final sub = c
        .read(locationSourceProvider)
        .watch(_going)
        .listen((p) => progress.add(p.progress), onDone: () => done = true);
    addTearDown(sub.cancel);
    // The first position reads the repository, then emits.
    await tester.pump();
    expect(progress, [0.25], reason: '10 of 40 minutes (7:25 → 8:05)');

    clock.now = at(rideTuesday, 7, 45);
    await tester.pump(const Duration(seconds: 4));
    expect(progress, hasLength(1), reason: 'next tick at 5 s');
    await tester.pump(const Duration(seconds: 1));
    expect(progress.last, 0.5);

    clock.now = at(rideTuesday, 8, 5);
    await tester.pump(const Duration(seconds: 5));
    expect(progress.last, 1);
    expect(done, isTrue, reason: 'the stream closes on arrival');
  });
}
