import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/presentation/labels.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US4 on the rider's Today (FR-019, FR-020), ar + en. Monday evening; the
/// driver planned for tomorrow (Tue 6 Oct, Ahmed) can't drive.
Future<ProviderContainer> _pumpWithDriverOut(WidgetTester tester, String locale, {required bool cover}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.rider, locale: locale),
    overrides: dailyOverrides(TestClock(at(rideTuesday.addDays(-1), 18, 0))),
  );
  tester.view.physicalSize = const Size(390, 2600);
  final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
  await tester.runAsync(() => repo.demoDriverOut(cover: cover));
  c.invalidate(todayControllerProvider);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] cover banner: who is out, who covers, Got it dismisses', (tester) async {
      await _pumpWithDriverOut(tester, code, cover: true);
      expect(find.text(l.backupTitleFor('Ahmed', l.dayTue)), findsOneWidget);
      expect(find.text(l.backupBodyFor('Mohamed')), findsOneWidget);
      expect(find.byKey(const Key('leg-going')), findsOneWidget);
      expect(find.text(l.legRow(l.legGoing, 'Mohamed', l.time(const Clock.hm(7, 25)))), findsOneWidget);
      await tester.tap(find.text(l.gotIt));
      await tester.pumpAndSettle();
      expect(find.text(l.backupTitleFor('Ahmed', l.dayTue)), findsNothing);
    });

    testWidgets('[$code] no cover: three options; a day off is free', (tester) async {
      final c = await _pumpWithDriverOut(tester, code, cover: false);
      expect(find.text(l.noCoverTitle(l.relTomorrowDay(l.dayTue))), findsOneWidget);
      expect(find.text(l.noCoverBody('Ahmed')), findsOneWidget);
      expect(find.byKey(const Key('no-cover-seat')), findsOneWidget);
      expect(find.byKey(const Key('no-cover-post')), findsOneWidget);

      await tester.tap(find.byKey(const Key('no-cover-day-off')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-cover-2026-10-06')), findsNothing);
      expect(find.text(l.offTitle(l.relTomorrowDay(l.dayTue))), findsOneWidget);
      expect(find.text(l.offNoCoverBody), findsOneWidget);
      expect(find.text(l.undo), findsNothing, reason: 'nothing to undo: there is no driver');
      final repo = c.read(dailyCommuteRepositoryProvider);
      final mine = (await tester.runAsync(() => repo.absences(rideTuesday, rideTuesday)))!
          .where((a) => a.personId == 'me');
      expect(mine.map((a) => a.kind), everyElement(AbsenceKind.noCover));
      expect(await tester.runAsync(repo.chargesOwed), isEmpty);
    });

    for (final (key, title) in [('no-cover-seat', l.emptySeatsTitle), ('no-cover-post', l.postReq)]) {
      testWidgets('[$code] no cover: $key routes to its screen', (tester) async {
        await _pumpWithDriverOut(tester, code, cover: false);
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets);
        expect(find.byKey(Key(key)), findsNothing, reason: 'left Today');
      });
    }
  }
}
