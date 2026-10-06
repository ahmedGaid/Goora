import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/check_in.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US2 on the Today screen (SC-002, FR-005 – FR-009), ar + en.
Future<ProviderContainer> _pump(WidgetTester tester, TestClock clock, String locale, {Map<String, Object> extra = const {}}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.rider, locale: locale), ...extra},
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
  return c;
}

/// Two no-shows earlier this month (October 2026).
Map<String, Object> _twoNoShows() => {
      FakeDailyCommuteRepository.eventsKey: jsonEncode([
        for (final day in [1, 4])
          ReliabilityEvent(
            personId: 'me',
            rideId: Ride.idFor('sz-0725', CalendarDate(2026, 10, day), Leg.going),
            date: CalendarDate(2026, 10, day),
            kind: ReliabilityEventKind.noShow,
          ).toJson(),
      ]),
    };

void main() {
  final mon = rideTuesday.addDays(-1);

  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;
    final whenTue = l.relTomorrowDay(l.dayTue);

    testWidgets('[$code] 2 taps to cancel with the exact charge; free banner + undo', (tester) async {
      await _pump(tester, TestClock(at(mon, 20, 0)), code);
      await tester.tap(find.byKey(const Key('cant-come'))); // tap 1
      await tester.pumpAndSettle();
      expect(find.text(l.freeCancelPreview), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cancel'))); // tap 2
      await tester.pumpAndSettle();
      expect(find.text(l.offTitle(whenTue)), findsOneWidget);
      expect(find.text(l.offBody), findsOneWidget);
      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('off-banner')), findsNothing);
    });

    testWidgets('[$code] after 9 PM both legs show 40 before confirming, then the late banner', (tester) async {
      await _pump(tester, TestClock(at(mon, 21, 5)), code);
      await tester.tap(find.byKey(const Key('cant-come')));
      await tester.pumpAndSettle();
      expect(find.text(l.lateCancelPreview(40)), findsOneWidget);
      await tester.tap(find.byKey(const Key('cancel-leg-ret')));
      await tester.pumpAndSettle();
      expect(find.text(l.lateCancelPreview(20)), findsOneWidget, reason: 'one leg = half of 40');
      await tester.tap(find.byKey(const Key('cancel-leg-ret')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(find.text(l.offTitle(whenTue)), findsOneWidget);
      expect(find.text(l.lateOffBody(40)), findsOneWidget);
    });

    testWidgets('[$code] undo after the seat went to the waitlist is refused calmly', (tester) async {
      final clock = TestClock(at(mon, 20, 0));
      await _pump(tester, clock, code);
      await tester.tap(find.byKey(const Key('cant-come')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      clock.now = at(mon, 21, 0);
      await tester.tap(find.text(l.undo));
      await tester.pumpAndSettle();
      expect(find.text(l.undoRefused), findsOneWidget);
      expect(find.byKey(const Key('off-banner')), findsOneWidget);
    });

    testWidgets('[$code] only the return trip cancelled → leg-specific banner', (tester) async {
      await _pump(tester, TestClock(at(mon, 20, 0)), code);
      await tester.tap(find.byKey(const Key('cant-come')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancel-leg-going')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(find.text(l.offLegTitle(l.tripReturn, whenTue)), findsOneWidget);
    });

    testWidgets('[$code] not coming next week: one tap + confirm', (tester) async {
      final c = await _pump(tester, TestClock(at(rideTuesday, 12, 0)), code);
      await tester.tap(find.byKey(const Key('cant-come')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('not-next-week')));
      await tester.pumpAndSettle();
      expect(find.text(l.notNextWeekConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-not-next-week')));
      await tester.pumpAndSettle();
      expect(find.text(l.notNextWeekDone), findsOneWidget);
      final sun = CalendarDate(2026, 10, 11);
      expect(await c.read(dailyCommuteRepositoryProvider).absences(sun, sun.addDays(6)), hasLength(10));
    });

    testWidgets('[$code] second no-show this month → warning banner', (tester) async {
      await _pump(tester, TestClock(at(rideTuesday, 7, 0)), code, extra: _twoNoShows());
      expect(find.text(l.headsUp), findsOneWidget);
      expect(find.text(l.noShowWarning), findsOneWidget);
    });

    testWidgets('[$code] third no-show → removal notice → find a new group', (tester) async {
      final clock = TestClock(at(rideTuesday, 7, 20));
      final c = await _pump(tester, clock, code, extra: _twoNoShows());
      final repo = c.read(dailyCommuteRepositoryProvider);
      final id = Ride.idFor('sz-0725', rideTuesday, Leg.going);
      await tester.runAsync(() async {
        await repo.arrivedAt(id, 'central-st', at(rideTuesday, 7, 25));
        await repo.mark(id, 'me', Outcome.noShow, at(rideTuesday, 7, 30));
        await repo.startTrip(id, at(rideTuesday, 7, 31));
      });
      c.invalidate(todayControllerProvider);
      await tester.pumpAndSettle();
      expect(find.text(l.removedTitle), findsOneWidget);
      expect(find.text(l.removedNotice), findsOneWidget);
      await tester.tap(find.byKey(const Key('find-new-group')));
      await tester.pumpAndSettle();
      expect(find.text(l.whereGo), findsOneWidget);
    });
  }

  testWidgets('cancel after pickup time is refused with calm copy', (tester) async {
    // Sheet opened Tuesday evening for Wednesday; confirmed after Wednesday's pickup.
    final clock = TestClock(at(rideTuesday, 21, 0));
    await _pump(tester, clock, 'en');
    await tester.tap(find.byKey(const Key('cant-come')));
    await tester.pumpAndSettle();
    clock.now = at(rideTuesday.addDays(1), 7, 26);
    await tester.tap(find.byKey(const Key('cancel-leg-ret')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.text(l10nFor(en).cancelAfterPickup), findsOneWidget);
  });
}
