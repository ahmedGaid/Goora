import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/onboarding/domain/choices.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US3: driver Today and pickup check-in, ar + en (FR-013 – FR-016).
/// Rotation with three drivers (ahmed, me, mohamed) from Sun 4 Oct gives me
/// Monday and Thursday.
final _wed = rideTuesday.addDays(1);
final _thu = rideTuesday.addDays(2);

/// Ahmed and Mohamed (off duty) are away on Thursday, leaving Sara and Youssef.
Map<String, Object> _twoPassengers() => {
      FakeDailyCommuteRepository.absencesKey: jsonEncode([
        for (final id in ['ahmed', 'mohamed'])
          for (final leg in Leg.values)
            Absence(personId: id, date: _thu, leg: leg, madeAt: at(_wed, 12, 0), kind: AbsenceKind.freeCancel).toJson(),
      ]),
    };

Future<ProviderContainer> _pump(WidgetTester tester, TestClock clock, String locale, {Map<String, Object> extra = const {}}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.driver, locale: locale), ...extra},
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 2400);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] hero: tomorrow, both ways, stops, contribution 2 × 40 × 2 = 160', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code, extra: _twoPassengers());
      expect(find.text(l.drivingWhen(l.relTomorrowDay(l.dayThu))), findsOneWidget);
      expect(find.text(l.offerBtn), findsOneWidget);
      expect(find.text(l.browseBtn), findsOneWidget);
      expect(find.text(l.heroDriver(l.heroTomorrow, l.dirBoth, 2)), findsOneWidget);
      expect(find.text(l.pickupN(1, l.stopMainGate)), findsOneWidget);
      expect(find.text(l.pickupN(2, l.stopCentralSt)), findsOneWidget);
      expect(find.text(l.timeAm('7:20')), findsOneWidget);
      expect(find.text(l.timeAm('8:05')), findsOneWidget);
      expect(find.text(l.returnFrom(l.stopSmartVillageGate2)), findsOneWidget);
      expect(find.text(l.estContrib), findsOneWidget);
      expect(find.text(l.egpAmount(160)), findsOneWidget);
      expect(find.text(l.reqsOnRoute), findsOneWidget);
      expect(find.text(l.reqPrivacy), findsOneWidget);
      expect(find.text(l.sos), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('[$code] confirm ⇄ undo confirmation', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('confirm-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.confirmedNote), findsOneWidget);
      expect(find.text(l.undoConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('undo-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l.confirmDrive), findsOneWidget);
    });

    testWidgets('[$code] report delay: 10 min shifts the stops and tells riders', (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('report-delay')));
      await tester.pumpAndSettle();
      expect(find.text(l.delayTitle), findsOneWidget);
      await tester.tap(find.byKey(const Key('delay-10')));
      await tester.pumpAndSettle();
      expect(find.text(l.delaySent(l.timeAm('7:30'))), findsOneWidget);
      expect(find.text(l.timeAm('7:35')), findsOneWidget, reason: 'Central St. 7:25 → 7:35');
    });

    testWidgets("[$code] can't drive: confirm, then the group is told", (tester) async {
      await _pump(tester, TestClock(at(_wed, 20, 0)), code);
      await tester.tap(find.byKey(const Key('cant-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.cantDriveConfirm), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-cant-drive')));
      await tester.pumpAndSettle();
      expect(find.text(l.cantDriveDone(l.relTomorrowDay(l.dayThu))), findsOneWidget);
      expect(find.text(l.heroDriver(l.heroTomorrow, l.dirBoth, 4)), findsNothing);
    });

    testWidgets('[$code] check-in: anonymous until picked up; no-show only at 5:00', (tester) async {
      final clock = TestClock(at(_thu, 7, 18));
      await _pump(tester, clock, code);
      expect(find.text(l.arrivedAt(l.stopMainGate)), findsOneWidget);
      clock.now = at(_thu, 7, 20);
      await tester.tap(find.byKey(const Key('arrived-main-gate')));
      await tester.pumpAndSettle();
      expect(find.text(l.arrivedNote), findsOneWidget);
      // Main Gate: Ahmed (off duty) and Sara, both anonymous.
      expect(find.text(l.verifiedRider), findsOneWidget);
      expect(find.text(l.verifiedRiderWoman), findsOneWidget);
      expect(find.text('Sara'), findsNothing);
      expect(find.text(l.stWaiting('5:00')), findsNWidgets(2));

      clock.now = at(_thu, 7, 24, 59);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l.stWaiting('0:01')), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('noshow-sara')));
      await tester.pumpAndSettle();
      expect(find.text(l.stNoShow), findsNothing, reason: 'disabled at 4:59');

      await tester.tap(find.byKey(const Key('picked-ahmed')));
      await tester.pumpAndSettle();
      expect(find.text('Ahmed'), findsOneWidget, reason: 'name shows once picked up');

      clock.now = at(_thu, 7, 25);
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('picked-sara')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('noshow-sara')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GooraStatusChip, l.stNoShow), findsOneWidget, reason: 'switch until start');
      expect(find.text(l.noShowNote), findsOneWidget);

      await tester.tap(find.byKey(const Key('arrived-central-st')));
      await tester.pumpAndSettle();
      clock.now = at(_thu, 7, 31);
      await tester.tap(find.byKey(const Key('picked-mohamed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picked-youssef')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-trip')));
      await tester.pumpAndSettle();
      expect(find.text(l.tripOnWay), findsOneWidget);
      expect(find.byKey(const Key('picked-sara')), findsNothing, reason: 'marks are final');

      // Inbox: what riders were told, including Sara's no-show charge.
      await tester.tap(find.byKey(const Key('inbox')));
      await tester.pumpAndSettle();
      expect(find.text(l.nNoShow(l.dayThu, 40)), findsOneWidget);
      expect(find.text(l.nDriverArrived(l.stopMainGate)), findsOneWidget);
      expect(find.text(l.sentToRiders), findsWidgets);
    });
  }

  testWidgets('inbox empty state is designed', (tester) async {
    await _pump(tester, TestClock(at(_wed, 12, 0)), 'en');
    await tester.tap(find.byKey(const Key('inbox')));
    await tester.pumpAndSettle();
    final l = l10nFor(en);
    expect(find.byKey(const Key('inbox-empty')), findsOneWidget);
    expect(find.text(l.inboxEmpty), findsOneWidget);
    expect(find.text(l.inboxEmptyBody), findsOneWidget);
  });

  testWidgets('off-duty day: "Riding today with …" card (FR-022a)', (tester) async {
    await _pump(tester, TestClock(at(rideTuesday, 7, 0)), 'en');
    final l = l10nFor(en);
    expect(find.text(l.rideWith(l.relToday, 'Mohamed')), findsOneWidget);
  });

  testWidgets('driver screen fits at 1.3× text size with labelled targets', (tester) async {
    await _pump(tester, TestClock(at(_wed, 20, 0)), 'en');
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
