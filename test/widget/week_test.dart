import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/presentation/labels.dart';
import 'package:goora/features/daily/presentation/week/week_controller.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US5, ar + en. Sunday 4 Oct 2026 (rotation start), noon.
final sun = CalendarDate(2026, 10, 4);

Future<ProviderContainer> _openWeek(WidgetTester tester, Role role, String locale, {bool seedChanges = false}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: role, locale: locale),
    overrides: dailyOverrides(TestClock(at(sun, 12, 0))),
  );
  tester.view.physicalSize = const Size(390, 2400);
  if (seedChanges) {
    final repo = c.read(dailyCommuteRepositoryProvider) as FakeDailyCommuteRepository;
    await tester.runAsync(() async {
      await repo.cancel(sun.addDays(3), {Leg.going, Leg.ret}, at(sun, 12, 0)); // Wed, free
      await repo.demoDriverOut(cover: true); // Tue: Ahmed out
    });
    c.invalidate(weekControllerProvider);
  }
  await tester.tap(find.text(l10nFor(Locale(locale)).tabWeek));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    Finder row(int day, String text) =>
        find.descendant(of: find.byKey(Key('week-2026-10-0$day')), matching: find.text(text));

    testWidgets('[$code] rider: rotation, a backup and a day off', (tester) async {
      await _openWeek(tester, Role.rider, code, seedChanges: true);
      expect(find.text(l.scheduleTitle), findsOneWidget);
      expect(find.text(l.rotateNote), findsOneWidget);
      // Rotation spreads the days between Ahmed and Mohamed.
      expect(row(4, l.drivesName('Ahmed')), findsOneWidget);
      expect(row(4, l.weekRiderLine('Ahmed', 'Ahmed')), findsOneWidget);
      expect(row(5, l.drivesName('Mohamed')), findsOneWidget);
      expect(row(8, l.drivesName('Ahmed')), findsOneWidget);
      // Tuesday: Ahmed can't drive; Mohamed covers both trips.
      expect(row(6, l.drivesName('Mohamed')), findsOneWidget);
      expect(row(6, l.weekRiderLine(l.backupName('Mohamed'), l.backupName('Mohamed'))), findsOneWidget);
      // Wednesday: off before 9 PM.
      expect(row(7, l.youOff), findsOneWidget);
      expect(row(7, l.offNote), findsOneWidget);
      expect(find.byKey(const Key('week-2026-10-09')), findsNothing, reason: 'Friday is not a working day');
    });

    testWidgets('[$code] driver: my days with riders, "You ride" on the others', (tester) async {
      await _openWeek(tester, Role.driver, code);
      expect(row(5, l.youDrive), findsOneWidget);
      expect(row(5, l.weekDriveLine(l.dirBoth, 4)), findsOneWidget);
      expect(row(6, l.drivesName('Mohamed')), findsOneWidget);
      expect(row(6, l.youRide), findsOneWidget);
      expect(row(4, l.heroWhen(sun, sun)), findsOneWidget);
    });

    testWidgets('[$code] Not coming next week is on the Week tab', (tester) async {
      await _openWeek(tester, Role.rider, code);
      await tester.tap(find.byKey(const Key('week-not-next-week')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-not-next-week')));
      await tester.pumpAndSettle();
      expect(find.text(l.notNextWeekDone), findsOneWidget);
    });
  }
}
