import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_pill.dart';
import 'package:goora/core/widgets/goora_route_map.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/presentation/commute_controller.dart';
import 'package:goora/features/commute/presentation/commute_setup_screen.dart';
import 'package:goora/features/commute/presentation/labels.dart';
import 'package:goora/features/commute/presentation/match_result_screen.dart';
import 'package:goora/features/commute/presentation/no_match_screen.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/presentation/session_controller.dart';

import '../helpers/pump_app.dart';

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

MatchOutcome _outcome({required bool driver, bool found = true}) {
  final seeker = Seeker(
    role: driver ? MemberRole.driver : MemberRole.rider,
    home: _profile.home!.point,
    work: _profile.work!.point,
    departure: found ? _profile.departure : const Clock.hm(10, 0),
    ret: _profile.ret,
    days: _profile.days,
    legs: const {Leg.going, Leg.ret},
  );
  final result = MatchingService.match(seeker, CorridorSeed.groups);
  return MatchOutcome(
    profile: _profile,
    viewerIsDriver: driver,
    result: result,
    waitlistPosition: result.found ? null : 7,
  );
}

class _Seeded extends LastMatch {
  _Seeded(this.outcome);

  final MatchOutcome outcome;

  @override
  MatchOutcome? build() => outcome;
}

Future<void> _accessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

FilledButton _button(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(FilledButton)));

Future<void> _scrollTo(WidgetTester tester, Finder f) =>
    tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final tag = locale.languageCode;

    group('[$tag] commute setup', () {
      testWidgets('rider: defaults, places, no driver fields, find enabled once places set', (tester) async {
        await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.rider));
        expect(find.text(l.whereGo), findsOneWidget);
        expect(find.text(l.time(CommuteProfile.defaultDeparture)), findsOneWidget);
        expect(find.text(l.time(CommuteProfile.defaultReturn)), findsOneWidget);
        expect(find.text('7:30'), findsNothing, reason: 'time is always labelled AM/PM');
        for (final d in Day.values) {
          final pill = tester.widget<GooraPill>(find.byKey(Key('day-${d.name}')));
          expect(pill.selected, CommuteProfile.defaultDays.contains(d), reason: d.name);
        }
        expect(find.byKey(const Key('seats-stepper')), findsNothing);
        expect(_button(tester, 'find-commute').onPressed, isNull);

        await tester.tap(find.byKey(const Key('pick-home')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('place-home-sz')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('pick-work')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('place-work-sv')));
        await tester.pumpAndSettle();

        expect(find.text(l.areaSheikhZayed), findsWidgets);
        expect(find.byType(GooraRouteMap), findsOneWidget);
        expect(_button(tester, 'find-commute').onPressed, isNotNull);
        await _accessible(tester);
      });

      testWidgets('return before departure shows a hint and blocks find', (tester) async {
        final c = await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.rider));
        c.read(commuteControllerProvider.notifier)
          ..setHome(CorridorSeed.sheikhZayed)
          ..setWork(CorridorSeed.smartVillage)
          ..shiftReturn(-600);
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.byKey(const Key('setup-hint')));
        expect(find.text(l.returnHint), findsOneWidget);
        expect(_button(tester, 'find-commute').onPressed, isNull);
      });

      testWidgets('driver: brief demo pricing 40 (32–48), recovery 240 → 288 → 144', (tester) async {
        await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.driver));
        await _scrollTo(tester, find.byKey(const Key('recovery')));
        expect(find.text(l.suggestedPrice), findsOneWidget);
        expect(find.text(l.egpAmount(40)), findsOneWidget);
        expect(find.text(l.egpAmount(32)), findsOneWidget);
        expect(find.text(l.egpAmount(48)), findsOneWidget);
        expect(find.text(l.suggestedShort(40)), findsOneWidget);
        expect(find.text(l.egpAmount(240)), findsOneWidget);

        final raise = find.descendant(of: find.byKey(const Key('contribution-stepper')), matching: find.bySemanticsLabel(l.raiseContribution));
        for (var i = 0; i < 4; i++) {
          await tester.tap(raise);
          await tester.pump();
        }
        expect(find.text(l.aboveSuggested(8)), findsOneWidget);
        expect(find.text(l.egpAmount(288)), findsOneWidget);

        await tester.tap(raise); // already at max 48: no change
        await tester.pump();
        expect(find.text(l.egpAmount(288)), findsOneWidget);

        await _scrollTo(tester, find.byKey(const Key('trips-going')));
        await tester.tap(find.byKey(const Key('trips-going')));
        await tester.pumpAndSettle();
        expect(find.text(l.otherTripNote), findsOneWidget);
        await _scrollTo(tester, find.byKey(const Key('recovery')));
        expect(find.text(l.egpAmount(144)), findsOneWidget);
        await _accessible(tester);
      });

      testWidgets('switching language keeps every entered value', (tester) async {
        final c = await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.driver));
        c.read(commuteControllerProvider.notifier)
          ..setHome(CorridorSeed.october)
          ..setWork(CorridorSeed.smartVillage)
          ..shiftDeparture(15)
          ..toggleDay(Day.sat)
          ..setSeats(2)
          ..stepContribution(1);
        await tester.pumpAndSettle();
        final before = c.read(commuteControllerProvider).requireValue;
        await tester.tap(find.text(l.langBtn));
        await tester.pumpAndSettle();
        final after = c.read(commuteControllerProvider).requireValue;
        expect(after.home!.id, before.home!.id);
        expect(after.departure, before.departure);
        expect(after.days, before.days);
        expect(after.driver!.seats, 2);
        expect(after.driver!.contribution, before.driver!.contribution);
        final other = l10nFor(locale == ar ? en : ar);
        expect(find.text(other.areaOctober), findsWidgets);
        expect(find.text(other.time(after.departure)), findsOneWidget);
      });

      testWidgets('driver: fewer seats raises the suggestion and snaps the price', (tester) async {
        final c = await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.driver));
        c.read(commuteControllerProvider.notifier).setSeats(1);
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.byKey(const Key('recovery')));
        expect(find.text(l.suggestedShort(80)), findsOneWidget);
        expect(find.text(l.belowSuggested(16)), findsOneWidget, reason: '40 snaps to the new minimum 64');
      });
    });

    group('[$tag] match result', () {
      testWidgets('rider sees the group, stats, fee line, reasons and other options', (tester) async {
        final outcome = _outcome(driver: false);
        final main = outcome.result.main!;
        await pumpScreen(
          tester,
          const MatchResultScreen(),
          locale: locale,
          session: _session(Role.rider),
          overrides: [lastMatchProvider.overrideWith(() => _Seeded(outcome))],
        );
        expect(find.text(l.matchPercent(main.score)), findsOneWidget);
        expect(find.text(l.foundGroup), findsOneWidget);
        expect(find.text(l.membersCount(main.group.members.length + 1)), findsOneWidget);
        expect(find.text(l.routeLine(l.areaSheikhZayed, l.areaSmartVillage)), findsOneWidget);
        expect(find.text(l.feeLine(40)), findsOneWidget);
        for (final r in main.reasons) {
          await _scrollTo(tester, find.text(l.reason(r)));
        }
        await _scrollTo(tester, find.byKey(const Key('toggle-others')));
        expect(find.text(l.seeOthers), findsOneWidget);
        await tester.tap(find.byKey(const Key('toggle-others')));
        await tester.pumpAndSettle();
        expect(find.text(l.hideOthers), findsOneWidget);
        for (final alt in outcome.result.alternatives) {
          await _scrollTo(tester, find.text(l.matchPercent(alt.score)));
        }
        await _accessible(tester);
      });

      testWidgets('split legs show the return group line', (tester) async {
        final morningOnly = CorridorSeed.groups.first;
        final evening = CorridorSeed.groups[1];
        final seeker = Seeker(
          role: MemberRole.rider,
          home: _profile.home!.point,
          work: _profile.work!.point,
          departure: morningOnly.going,
          ret: evening.ret,
          days: _profile.days,
          legs: const {Leg.going, Leg.ret},
        );
        final result = MatchingService.match(seeker, [
          CommuteGroup(
            id: 'morning',
            origin: morningOnly.origin,
            destination: morningOnly.destination,
            destinationPoint: morningOnly.destinationPoint,
            pickupPoints: morningOnly.pickupPoints,
            going: morningOnly.going,
            ret: const Clock.hm(19, 0),
            days: morningOnly.days,
            members: morningOnly.members,
            price: 40,
            freeSeatsGoing: 2,
            freeSeatsReturn: 2,
            detourMinutes: 6,
          ),
          CommuteGroup(
            id: 'evening',
            origin: evening.origin,
            destination: evening.destination,
            destinationPoint: evening.destinationPoint,
            pickupPoints: evening.pickupPoints,
            going: const Clock.hm(9, 30),
            ret: evening.ret,
            days: evening.days,
            members: evening.members,
            price: 40,
            freeSeatsGoing: 2,
            freeSeatsReturn: 2,
            detourMinutes: 4,
          ),
        ]);
        expect(result.returnMatch?.group.id, 'evening');
        await pumpScreen(
          tester,
          const MatchResultScreen(),
          locale: locale,
          session: _session(Role.rider),
          overrides: [
            lastMatchProvider.overrideWith(
              () => _Seeded(MatchOutcome(profile: _profile, viewerIsDriver: false, result: result)),
            ),
          ],
        );
        await _scrollTo(tester, find.byKey(const Key('return-leg')));
        expect(find.text(l.returnLeg(l.time(evening.ret))), findsOneWidget);
      });

      testWidgets('driver sees riders only as verified riders (no names)', (tester) async {
        final outcome = _outcome(driver: true);
        await pumpScreen(
          tester,
          const MatchResultScreen(),
          locale: locale,
          session: _session(Role.driver),
          overrides: [lastMatchProvider.overrideWith(() => _Seeded(outcome))],
        );
        final handle = tester.ensureSemantics();
        expect(find.bySemanticsLabel(l.verifiedRiderWoman), findsOneWidget); // Sara
        expect(find.bySemanticsLabel(l.verifiedRider), findsOneWidget); // Youssef
        expect(find.text('SR'), findsNothing);
        expect(find.text('YS'), findsNothing);
        handle.dispose();
      });
    });

    testWidgets('[$tag] new screens fit at 1.3× text size', (tester) async {
      await pumpScreen(tester, const CommuteSetupScreen(), locale: locale, session: _session(Role.driver), textScale: 1.3);
      expect(tester.takeException(), isNull);
      for (final screen in const <Widget>[MatchResultScreen(), NoMatchScreen()]) {
        final found = screen is MatchResultScreen;
        await pumpScreen(
          tester,
          screen,
          locale: locale,
          session: _session(Role.rider),
          textScale: 1.3,
          overrides: [lastMatchProvider.overrideWith(() => _Seeded(_outcome(driver: false, found: found)))],
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('[$tag] no match: waitlist position and post a trip', (tester) async {
      final outcome = _outcome(driver: false, found: false);
      expect(outcome.result.found, isFalse);
      await pumpScreen(
        tester,
        const NoMatchScreen(),
        locale: locale,
        session: _session(Role.rider),
        overrides: [lastMatchProvider.overrideWith(() => _Seeded(outcome))],
      );
      expect(find.text(l.noMatch(7, l.areaSheikhZayed, l.areaSmartVillage)), findsOneWidget);
      expect(find.text(l.postReq), findsOneWidget);
      await _accessible(tester);
    });
  }
}
