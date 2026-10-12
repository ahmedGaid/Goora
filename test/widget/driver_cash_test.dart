import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/widgets/goora_status_chip.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/cash_mark.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// v2 US5: after drop-off a driver records cash from cash-trial riders, and
/// sees it apart from withdrawable earnings. I drive Thursday (rotation from
/// Sun 4 Oct); Youssef is the seeded cash rider, the others pay by wallet.
final _thu = rideTuesday.addDays(2);

Future<ProviderContainer> _driveAndEnd(WidgetTester tester, String locale) async {
  final clock = TestClock(at(_thu, 7, 20));
  final c = await pumpGooraApp(
    tester,
    prefs: memberPrefs(role: Role.driver, locale: locale),
    overrides: dailyOverrides(clock),
  );
  tester.view.physicalSize = const Size(390, 3000);
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

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: after the trip ends, only the cash rider gets the cash buttons', (tester) async {
      await _driveAndEnd(tester, code);
      expect(find.text(l.tripEndedNote), findsOneWidget, reason: 'the ended trip stays on screen');
      expect(find.byKey(const Key('cash-received-youssef')), findsOneWidget);
      expect(find.text(l.cashReceived(40)), findsOneWidget);
      expect(find.text(l.didNotPay), findsOneWidget);
      expect(find.byKey(const Key('cash-received-sara')), findsNothing, reason: 'Sara pays by wallet');
    });

    testWidgets('[$code] AC2: "Received" is recorded once and shown as a status', (tester) async {
      final c = await _driveAndEnd(tester, code);
      await tester.tap(find.byKey(const Key('cash-received-youssef')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GooraStatusChip, l.cashMarkedReceived), findsOneWidget);
      expect(find.byKey(const Key('cash-received-youssef')), findsNothing);
      final rideId = 'sz-0725:${_thu.toIso()}:going';
      final marks = await c.read(walletRepositoryProvider).cashMarks(rideId);
      expect(marks.single.outcome, CashOutcome.received);
      expect(marks.single.amount, 40);
    });

    testWidgets('[$code] AC2: "Didn\'t pay" is recorded too', (tester) async {
      await _driveAndEnd(tester, code);
      await tester.tap(find.byKey(const Key('cash-unpaid-youssef')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GooraStatusChip, l.cashMarkedUnpaid), findsOneWidget);
    });

    testWidgets('[$code] AC3: Wallet shows cash received apart; withdrawing never takes it', (tester) async {
      final c = await _driveAndEnd(tester, code);
      await tester.tap(find.byKey(const Key('cash-received-youssef')));
      await tester.pumpAndSettle();
      c.read(routerProvider).go(Routes.wallet);
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('cash-received'));
      expect(find.descendant(of: card, matching: find.text(l.egpAmount(80))), findsOneWidget,
          reason: 'seeded 40 + today\'s 40');
      expect(find.text(l.cashReceivedNote), findsOneWidget);

      await tester.tap(find.byKey(const Key('withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('withdraw-confirm')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: card, matching: find.text(l.egpAmount(80))), findsOneWidget);
    });
  }
}
