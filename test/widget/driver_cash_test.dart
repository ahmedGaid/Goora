import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/daily/presentation/today/today_controller.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';
import 'package:goora/features/wallet/presentation/share_mark_row.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 004 v2 US5, widened by 007 US2: after drop-off the driver answers for
/// every passenger's share — each pays the driver directly, cash or InstaPay
/// — and sees what was received apart from Goora's money. I drive Thursday
/// (rotation from Sun 4 Oct); Youssef pays cash, Sara by InstaPay.
final _thu = rideTuesday.addDays(2);

Future<ProviderContainer> _driveAndEnd(WidgetTester tester, String locale, {bool onlyGoing = false}) async {
  final clock = TestClock(at(_thu, 7, 20));
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.driver, locale: locale),
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 3400);
  if (onlyGoing) {
    // A one-leg driving day: a cover takes the return (the Mon 30/11 walk shape).
    await c.read(dailyCommuteRepositoryProvider).cantDrive(_thu, {Leg.ret}, at(_thu.addDays(-2), 20, 0));
    c.invalidate(todayControllerProvider);
  }
  await tester.pumpAndSettle();
  Future<void> tap(String key) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  await tap('arrived-main-gate');
  await tap('picked-ahmed');
  await tap('picked-sara');
  await tap('arrived-central-st');
  await tap('picked-mohamed');
  await tap('picked-youssef');
  await tap('start-trip');
  clock.now = at(_thu, 8, 5);
  await tap('end-trip');
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

String get _rideId => 'sz-0725:${_thu.toIso()}:going';

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: after the trip ends, every passenger gets the receipt buttons', (tester) async {
      await _driveAndEnd(tester, code);
      expect(find.text(l.tripEndedNote), findsOneWidget, reason: 'the ended trip stays on screen');
      for (final id in ['ahmed', 'sara', 'mohamed', 'youssef']) {
        expect(find.byKey(Key('cash-received-$id')), findsOneWidget, reason: id);
        expect(find.byKey(Key('cash-unpaid-$id')), findsOneWidget, reason: id);
      }
      expect(find.text(l.cashReceived(40)), findsNWidgets(4));
    });

    testWidgets('[$code] S-6: a one-leg driving day — ending the going leg still shows the receipt card',
        (tester) async {
      await _driveAndEnd(tester, code, onlyGoing: true);
      expect(find.text(l.tripEndedNote), findsOneWidget, reason: 'the ended trip stays on screen (walk Mon 30/11)');
      for (final id in ['ahmed', 'sara', 'mohamed', 'youssef']) {
        expect(find.byKey(Key('cash-received-$id')), findsOneWidget, reason: id);
      }
    });

    testWidgets('[$code] AC2: "Received" is recorded and shown as a status, with a way to change it', (tester) async {
      final c = await _driveAndEnd(tester, code);
      await _tap(tester, 'cash-received-youssef');
      expect(find.widgetWithText(GooraStatusChip, l.cashMarkedReceived), findsOneWidget);
      expect(find.byKey(const Key('cash-received-youssef')), findsNothing);
      expect(find.byKey(const Key('cash-change-youssef')), findsOneWidget, reason: 'within 24 hours');
      final marks = await c.read(walletRepositoryProvider).shareMarks(_rideId);
      expect(marks.single.outcome, CashOutcome.received);
      expect(marks.single.amount, 40);
    });

    testWidgets('[$code] AC2: "Didn\'t get it" is recorded and can be corrected to received', (tester) async {
      final c = await _driveAndEnd(tester, code);
      await _tap(tester, 'cash-unpaid-sara');
      expect(find.widgetWithText(GooraStatusChip, l.cashMarkedUnpaid), findsOneWidget);
      await _tap(tester, 'cash-change-sara');
      expect(find.widgetWithText(GooraStatusChip, l.cashMarkedReceived), findsOneWidget);
      final marks = await c.read(walletRepositoryProvider).shareMarks(_rideId);
      expect(marks.single.outcome, CashOutcome.received);
    });

    testWidgets('[$code] AC3: Wallet shows what was received directly, apart; no balance to withdraw',
        (tester) async {
      final c = await _driveAndEnd(tester, code);
      await _tap(tester, 'cash-received-youssef');
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('cash-received'));
      expect(find.descendant(of: card, matching: find.text(l.egpAmount(80))), findsOneWidget,
          reason: 'seeded 40 + today\'s 40');
      expect(find.text(l.cashReceivedNote), findsOneWidget);
      expect(find.byKey(const Key('withdraw')), findsNothing, reason: 'Goora holds no driver money');
      expect(find.byKey(const Key('payments-list')), findsOneWidget);
    });

    testWidgets('[$code] the receipt row stores the amount it shows', (tester) async {
      final c = await pumpScreen(
        tester,
        Scaffold(
          body: ShareMarkRow(
            rideId: _rideId,
            riderId: 'youssef',
            driverId: 'me',
            riderName: 'Youssef',
            date: _thu,
            fallbackAmount: 45,
          ),
        ),
        locale: locale,
        overrides: dailyOverrides(TestClock(at(_thu, 8, 5))),
      );
      expect(find.text(l.cashReceived(45)), findsOneWidget, reason: 'the fallback before a share is known');
      await tester.tap(find.byKey(const Key('cash-received-youssef')));
      await tester.pumpAndSettle();
      final marks = await c.read(walletRepositoryProvider).shareMarks(_rideId);
      expect(marks.single.amount, 45);
    });

    testWidgets('[$code] F20: the receipt label is shown in full at 390 px (not cut with "…")', (tester) async {
      await _driveAndEnd(tester, code);
      final label = find.text(l.cashReceived(40)).first;
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'no ellipsis');
      final textWidth = paragraph.size.width;
      expect(textWidth, greaterThan(0));
      final tp = TextPainter(text: paragraph.text, textDirection: paragraph.textDirection)..layout();
      expect(textWidth, greaterThanOrEqualTo(tp.width - 0.5));
    });
  }
}
