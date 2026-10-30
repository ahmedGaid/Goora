import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/map/pickup_pin.dart';
import 'package:goora/core/widgets/goora_pickup_map.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/presentation/commute_controller.dart';
import 'package:goora/features/commute/presentation/labels.dart';
import 'package:goora/features/commute/presentation/match_result_screen.dart';
import 'package:goora/features/daily/presentation/labels.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../../helpers/daily_fakes.dart';
import '../../helpers/pump_app.dart';

/// 012 US1 + US2: the pickup map on match result and on rider / driver Today.
final _phone = PhoneNumber.tryParse('01012345678')!;

Session _session(Role role) => Session(
      phone: _phone,
      profile: Profile(
        phone: _phone,
        firstName: 'Omar',
        lastName: 'Khaled',
        gender: Gender.male,
        role: role,
        frequency: Frequency.everyDay,
      ),
    );

const _profile = CommuteProfile(
  home: CorridorSeed.sheikhZayed,
  work: CorridorSeed.smartVillage,
  departure: CommuteProfile.defaultDeparture,
  ret: CommuteProfile.defaultReturn,
  days: CommuteProfile.defaultDays,
);

MatchOutcome _outcome() {
  final seeker = Seeker(
    role: MemberRole.rider,
    home: _profile.home!.point,
    work: _profile.work!.point,
    departure: _profile.departure,
    ret: _profile.ret,
    days: _profile.days,
    legs: const {Leg.going, Leg.ret},
  );
  return MatchOutcome(
    profile: _profile,
    viewerIsDriver: false,
    result: MatchingService.match(seeker, CorridorSeed.groups),
  );
}

class _Seeded extends LastMatch {
  _Seeded(this.outcome);

  final MatchOutcome outcome;

  @override
  MatchOutcome? build() => outcome;
}

List<PickupPin> _pins(WidgetTester tester, Finder card) => tester.widget<GooraPickupMap>(card).pins;

/// Every pin is one of [g]'s public stops — never the home point (FR-002).
void _expectOnlyStops(List<PickupPin> pins, CommuteGroup g) {
  final stops = [...g.goingStops, g.workStop];
  final home = CorridorSeed.sheikhZayed.point;
  for (final p in pins) {
    expect(stops.any((s) => s.point.lat == p.lat && s.point.lng == p.lng), isTrue, reason: '${p.place} is a stop');
    expect((p.lat, p.lng), isNot((home.lat, home.lng)));
  }
}

Future<void> _openSheet(WidgetTester tester, Finder card) async {
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('pickup-map-sheet')), findsOneWidget);
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] match result: viewer\'s stop + arrival on the map; tap opens it (US1)', (tester) async {
      final outcome = _outcome();
      final g = outcome.result.main!.group;
      final pickup = g.nearestStop(_profile.home!.point);
      await pumpScreen(
        tester,
        const MatchResultScreen(),
        locale: locale,
        session: _session(Role.rider),
        overrides: [oldCorridor(), lastMatchProvider.overrideWith(() => _Seeded(outcome))],
      );
      final card = find.byKey(const Key('match-map'));
      await tester.ensureVisible(card);
      final pins = _pins(tester, card);
      expect(pins.map((p) => p.kind), [PickupPinKind.pickup, PickupPinKind.arrival]);
      expect(pins.first.title, l.tlPickup(l.time(pickup.time)));
      expect(pins.first.place, l.stopName(pickup.name));
      expect(pins.last.title, l.tlArrival(l.time(g.arrivalTime)));
      expect(pins.last.place, l.stopName(g.workStop.name));
      _expectOnlyStops(pins, g);
      expect(find.descendant(of: card, matching: find.text(l.mapSketchNote)), findsOneWidget);
      await _openSheet(tester, card);
    });

    testWidgets('[$code] rider Today: my stop + arrival on the meeting-point card (US2)', (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.rider, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 7, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      await tester.pumpAndSettle();
      final view = c.read(todayControllerProvider).requireValue;
      final next = view.upcomingRides.first;
      final card = find.byKey(const Key('meeting-point-card'));
      expect(card, findsOneWidget);
      final pins = _pins(tester, card);
      expect(pins.first.place, l.stopName(next.stop.name));
      expect(pins.first.title, l.tlPickup(l.time(next.stop.time)));
      if (next.leg == Leg.going) {
        expect(pins.last.kind, PickupPinKind.arrival);
        expect(pins.last.title, l.tlArrival(l.time(next.end.time)));
      }
      _expectOnlyStops(pins, view.group!);
      await _openSheet(tester, card);
    });

    testWidgets('[$code] driver Today: every stop I drive, in order, then arrival (US2)', (tester) async {
      final c = await pumpGooraApp(
        tester,
        prefs: memberPrefs(role: Role.driver, locale: code),
        overrides: dailyOverrides(TestClock(at(rideTuesday, 6, 0))),
      );
      tester.view.physicalSize = const Size(390, 2600);
      await tester.pumpAndSettle();
      final view = c.read(todayControllerProvider).requireValue;
      final drive = view.drive!;
      final going = drive.driving.where((x) => x.leg == Leg.going).firstOrNull;
      final card = find.byKey(const Key('meeting-point-card'));
      expect(card, findsOneWidget);
      final pins = _pins(tester, card);
      if (going != null) {
        final stops = going.ride!.stops;
        expect([for (final p in pins.where((p) => p.kind == PickupPinKind.pickup)) p.place],
            [for (final s in stops) l.stopName(s.name)]);
        expect([for (final p in pins.where((p) => p.kind == PickupPinKind.pickup)) p.number],
            [for (var i = 1; i <= stops.length; i++) i]);
        expect(pins.last.kind, PickupPinKind.arrival);
      } else {
        expect(pins.single.place, l.stopName(view.group!.workStop.name));
      }
      _expectOnlyStops(pins, view.group!);
      await _openSheet(tester, card);
    });
  }
}
