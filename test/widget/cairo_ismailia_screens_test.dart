import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/presentation/commute_controller.dart';
import 'package:goora/features/commute/presentation/commute_setup_screen.dart';
import 'package:goora/features/commute/presentation/labels.dart';
import 'package:goora/features/commute/presentation/match_result_screen.dart';
import 'package:goora/features/commute/presentation/no_match_screen.dart';
import 'package:goora/features/daily/presentation/labels.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 006 P6 (T031–T037): the walk screens on Cairo ↔ Ismailia, ar + en —
/// corridor names, stops, times and prices only; nothing from the old
/// corridor and no raw coordinates (FR-008, SC-005).

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

/// New Cairo → Ismailia at 06:30, back 16:30: the seeded `ci-nc-0630` group.
const _ncToIsmailia = CommuteProfile(
  home: CairoIsmailiaSeed.homeNewCairo,
  work: CairoIsmailiaSeed.workIsmailia,
  departure: Clock.hm(6, 30),
  ret: Clock.hm(16, 30),
  days: CommuteProfile.defaultDays,
);

/// A Tuesday in November: an Arabic "6 أكتوبر" date can't pass for the old
/// area name.
final _tue = CalendarDate(2026, 11, 3);

Override _cairo() => activeCorridorProvider.overrideWithBuild((ref, notifier) => Corridors.cairoIsmailia);

class _Seeded extends LastMatch {
  _Seeded(this.outcome);

  final MatchOutcome outcome;

  @override
  MatchOutcome? build() => outcome;
}

MatchOutcome _match(CommuteProfile p) {
  final seeker = Seeker(
    role: MemberRole.rider,
    home: p.home!.point,
    work: p.work!.point,
    departure: p.departure,
    ret: p.ret,
    days: p.days,
    legs: const {Leg.going, Leg.ret},
  );
  final result = MatchingService.match(seeker, CairoIsmailiaSeed.groups);
  return MatchOutcome(profile: p, viewerIsDriver: false, result: result, waitlistPosition: result.found ? null : 7);
}

/// Every string on screen, both locales checked: no old-corridor area or
/// stop name, and nothing that looks like a coordinate (30.03, 31.4700).
void _onlyCorridor(WidgetTester tester, String where) {
  final shown = [for (final t in tester.widgetList<RichText>(find.byType(RichText))) t.text.toPlainText()].join('\n');
  for (final l in [l10nFor(ar), l10nFor(en)]) {
    for (final old in [
      l.areaSheikhZayed,
      l.areaOctober,
      l.areaSmartVillage,
      for (final s in [StopName.mainGate, StopName.centralSt, StopName.gasStation, StopName.smartVillageGate2]) l.stopName(s),
    ]) {
      expect(shown.contains(old), isFalse, reason: '$where shows "$old"');
    }
  }
  expect(RegExp(r'\d{2}\.\d{2,}').stringMatch(shown), isNull, reason: '$where shows a raw coordinate');
}

/// ≥ 44 px targets with labels (T038, goora-brand).
Future<void> _accessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

Future<void> _go(WidgetTester tester, ProviderContainer c, String route) async {
  c.read(routerProvider).go(route);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: route);
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    group('[$code] setup and match (T031, T032)', () {
      testWidgets('the home and work pickers list the corridor places only', (tester) async {
        await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.rider), overrides: [_cairo()]);
        await tester.tap(find.byKey(const Key('pick-home')));
        await tester.pumpAndSettle();
        for (final p in CairoIsmailiaSeed.homePlaces) {
          expect(find.byKey(Key('place-${p.id}')), findsOneWidget, reason: p.id);
        }
        expect(find.byKey(const Key('place-home-sz')), findsNothing);
        _onlyCorridor(tester, 'home picker');
        await _accessible(tester);
        await tester.tap(find.byKey(const Key('place-home-heli')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pick-work')));
        await tester.pumpAndSettle();
        for (final p in CairoIsmailiaSeed.workPlaces) {
          expect(find.byKey(Key('place-${p.id}')), findsOneWidget, reason: p.id);
        }
        expect(find.byKey(const Key('place-work-sv')), findsNothing);
        await tester.tap(find.byKey(const Key('place-work-ism')));
        await tester.pumpAndSettle();
        expect(find.text(l.areaHeliopolis), findsWidgets);
        expect(find.text(l.areaIsmailia), findsWidgets);
        _onlyCorridor(tester, 'setup');
      });

      testWidgets('match: route, 6:30 from the New Cairo meeting point, arrival 8:15 in Ismailia, 76 + 8',
          (tester) async {
        final outcome = _match(_ncToIsmailia);
        final g = outcome.result.main!.group;
        expect(g.id, 'ci-nc-0630');
        expect(g.arrivalTime, const Clock.hm(8, 15), reason: '06:30 + 105 min');
        final pickup = g.nearestStop(_ncToIsmailia.home!.point);
        await pumpScreen(
          tester,
          const MatchResultScreen(),
          locale: locale,
          session: _session(Role.rider),
          overrides: [
            _cairo(),
            riderPricingProvider.overrideWith((ref) => PricingMode.perTrip),
            riderPayMethodProvider.overrideWith((ref) => PaymentMethod.instapay),
            lastMatchProvider.overrideWith(() => _Seeded(outcome)),
          ],
        );
        expect(find.text(l.routeLine(l.areaNewCairo, l.areaIsmailia)), findsOneWidget);
        expect(find.text(l.timeDays(l.time(const Clock.hm(6, 30)), l.daysSummary(g.days))), findsOneWidget);
        expect(find.text(l.stopLine(l.tlPickup(l.time(pickup.time)), l.stopNewCairoMeet)), findsOneWidget);
        expect(find.text(l.stopLine(l.tlArrival(l.time(const Clock.hm(8, 15))), l.stopIsmailiaMeet)), findsOneWidget);
        expect(find.text(l.priceWithFee(76, 8)), findsOneWidget, reason: '300 ÷ (3 + 1) → 76, fee 8');
        // T035 bidi: each locale's names are its own script; the lines follow the locale.
        for (final k in ['match-pickup', 'match-arrival']) {
          expect(directionOf(tester, find.byKey(Key(k))), code == 'ar' ? TextDirection.rtl : TextDirection.ltr, reason: k);
        }
        _onlyCorridor(tester, 'match result');
        await _accessible(tester);
      });

      testWidgets('match, a new cash rider: "Pay 75 EGP cash"', (tester) async {
        await pumpScreen(
          tester,
          const MatchResultScreen(),
          locale: locale,
          session: _session(Role.rider),
          overrides: [
            _cairo(),
            riderPricingProvider.overrideWith((ref) => PricingMode.trial),
            lastMatchProvider.overrideWith(() => _Seeded(_match(_ncToIsmailia))),
          ],
        );
        expect(find.text(l.priceCash(75)), findsOneWidget, reason: '76 rounded to a multiple of 5');
      });

      testWidgets('no match names the route and offers to post a trip', (tester) async {
        final outcome = _match(_ncToIsmailia.copyWith(home: CairoIsmailiaSeed.homeHeliopolis, departure: const Clock.hm(10, 0)));
        expect(outcome.result.found, isFalse);
        await pumpScreen(
          tester,
          const NoMatchScreen(),
          locale: locale,
          session: _session(Role.rider),
          overrides: [_cairo(), lastMatchProvider.overrideWith(() => _Seeded(outcome))],
        );
        expect(find.text(l.noMatch(7, l.areaHeliopolis, l.areaIsmailia)), findsOneWidget);
        expect(find.text(l.postReq), findsOneWidget);
        _onlyCorridor(tester, 'no match');
      });

      // T035: the new names at 1.3× text, in both directions.
      for (final (name, screen) in [
        ('setup', const CommuteSetupScreen()),
        ('match', const MatchResultScreen()),
        ('no match', const NoMatchScreen()),
      ]) {
        testWidgets('$name at 1.3× text: no overflow', (tester) async {
          final p = name == 'no match'
              ? _ncToIsmailia.copyWith(home: CairoIsmailiaSeed.homeTenthOfRamadan, departure: const Clock.hm(10, 0))
              : _ncToIsmailia;
          final c = await pumpScreen(
            tester,
            screen,
            locale: locale,
            session: _session(Role.rider),
            textScale: 1.3,
            overrides: [_cairo(), lastMatchProvider.overrideWith(() => _Seeded(_match(p)))],
          );
          if (name == 'setup') {
            c.read(commuteControllerProvider.notifier)
              ..setHome(CairoIsmailiaSeed.homeTenthOfRamadan)
              ..setWork(CairoIsmailiaSeed.workIsmailia);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
        });
      }
    });

    // T033, T034, T035, T037: a member's walk through the app.
    group('[$code] walk (T033, T034, T037)', () {
      for (final scale in [1.0, 1.3]) {
        testWidgets('member rider at $scale×: Today, Week, Wallet', (tester) async {
          final c = await pumpGooraApp(
            tester,
            prefs: memberPrefs(role: Role.rider, locale: code, commute: _ncToIsmailia, groupId: 'ci-nc-0630'),
            overrides: dailyOverrides(TestClock(at(_tue, 6, 0)), corridor: Corridors.cairoIsmailia),
          );
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.view.physicalSize = const Size(390, 3200);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(find.text(l.routeLine(l.areaNewCairo, l.areaIsmailia)), findsWidgets);
          expect(find.text(l.stopNewCairoMeet), findsWidgets);
          expect(find.text(l.tlArrival(l.time(const Clock.hm(8, 15)))), findsOneWidget);
          expect(find.text(l.priceCompany(75)), findsOneWidget, reason: 'company plan: 76 to the nearest 5, no fee');
          _onlyCorridor(tester, 'Today');

          await _go(tester, c, Routes.week);
          _onlyCorridor(tester, 'Week');
          await _go(tester, c, Routes.wallet);
          _onlyCorridor(tester, 'Wallet');
        });

        // A member riding today is offered no extra seat, so the marketplace
        // walk is a once rider's.
        testWidgets('once rider at $scale×: Empty seats and Post your trip', (tester) async {
          final c = await pumpGooraApp(
            tester,
            prefs: memberPrefs(role: Role.rider, locale: code, commute: _ncToIsmailia, member: false),
            overrides: dailyOverrides(TestClock(at(_tue, 6, 0)), corridor: Corridors.cairoIsmailia),
          );
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.view.physicalSize = const Size(390, 3200);
          await tester.pumpAndSettle();

          await _go(tester, c, Routes.emptySeats);
          expect(find.text('Tarek'), findsOneWidget, reason: 'New Cairo → Ismailia, going');
          _onlyCorridor(tester, 'Empty seats, going');
          await tester.tap(find.byKey(const Key('leg-return')));
          await tester.pumpAndSettle();
          expect(find.text('Heba'), findsOneWidget, reason: 'Ismailia → New Cairo sits on the return side');
          expect(find.textContaining(l.stopIsmailiaMeet), findsWidgets);
          _onlyCorridor(tester, 'Empty seats, return');

          await _go(tester, c, Routes.postTrip);
          expect(tester.widget<GooraPill>(find.byKey(const Key('from-newCairo'))).selected, isTrue);
          expect(tester.widget<GooraPill>(find.byKey(const Key('to-ismailia'))).selected, isTrue);
          _onlyCorridor(tester, 'Post your trip');
        });

        testWidgets('driver at $scale×: Find riders and Offer a trip', (tester) async {
          final c = await pumpGooraApp(
            tester,
            prefs: memberPrefs(
              role: Role.driver,
              locale: code,
              member: false,
              commute: _ncToIsmailia.copyWith(
                driver: const DriverOffer(seats: 3, trips: DrivenTrips.both, contribution: 76),
              ),
            ),
            overrides: dailyOverrides(TestClock(at(_tue, 6, 0)), corridor: Corridors.cairoIsmailia),
          );
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.view.physicalSize = const Size(390, 3200);
          await tester.pumpAndSettle();

          await _go(tester, c, Routes.findRiders);
          for (final a in Corridors.cairoIsmailia.areas) {
            expect(find.byKey(Key('area-${a.name}')), findsOneWidget, reason: '$a');
          }
          expect(find.byKey(Key('area-${Area.sheikhZayed.name}')), findsNothing);
          _onlyCorridor(tester, 'Find riders');

          await _go(tester, c, Routes.offerTrip);
          expect(tester.widget<GooraPill>(find.byKey(const Key('from-newCairo'))).selected, isTrue);
          expect(tester.widget<GooraPill>(find.byKey(const Key('to-ismailia'))).selected, isTrue);
          _onlyCorridor(tester, 'Offer a trip');
        });
      }
    });
  }
}
