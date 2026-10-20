import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// 004 US3 → 007 US4: the driver Wallet tab. Goora holds none of the
/// driver's money: the tab shows what passengers paid directly this month
/// (the seeded 40 from Youssef), each passenger's share and its status, the
/// driver's InstaPay handle, and the trip-cost breakdown.
Future<ProviderContainer> _openWallet(
  WidgetTester tester,
  String locale, {
  List<Override> overrides = const [],
  Map<String, Object> extra = const {},
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.driver, locale: locale), ...extra},
    overrides: [...dailyOverrides(TestClock(at(rideTuesday, 7, 0))), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 3000);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: received directly this month, apart from Goora — no balance to withdraw',
        (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.cashReceivedTitle), findsOneWidget);
      final card = find.byKey(const Key('cash-received'));
      expect(find.descendant(of: card, matching: find.text(l.egpAmount(40))), findsOneWidget,
          reason: 'seeded: Youssef paid 40 cash yesterday');
      expect(find.text(l.cashReceivedNote), findsOneWidget);
      expect(find.byKey(const Key('withdraw')), findsNothing);
      expect(find.text(l.actTripIncome), findsNothing, reason: 'Goora writes no driver income (007 R8)');
    });

    testWidgets('[$code] AC2: each passenger share is listed with its status in words', (tester) async {
      await _openWallet(tester, code);
      expect(find.byKey(const Key('payments-list')), findsOneWidget);
      expect(find.text('Youssef'), findsOneWidget);
      expect(find.text(l.cashMarkedReceived), findsOneWidget);
    });

    testWidgets('[$code] AC3: trip-cost breakdown shows the gap for an empty seat', (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.driverBreakdownTitle), findsOneWidget);
      // sz-0725: 4-seat capacity (2 riders + 1 free), 40 EGP/leg, round trip.
      expect(find.text(l.egpAmount(320)), findsOneWidget, reason: 'trip cost at full capacity, round trip');
      expect(find.text(l.egpAmount(160)), findsWidgets, reason: 'received from 2 riders round trip, and the gap');
      expect(find.text(l.driverBreakdownFree), findsOneWidget);
    });

    testWidgets('[$code] AC4: the InstaPay handle is saved trimmed (007 R7)', (tester) async {
      final c = await _openWallet(tester, code);
      final field = find.descendant(of: find.byKey(const Key('instapay-field')), matching: find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.enterText(field, '  omar.k@instapay  ');
      await tester.tap(find.byKey(const Key('instapay-save')));
      await tester.pumpAndSettle();
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      expect(await c.read(walletRepositoryProvider).instapayHandleOf(meId), 'omar.k@instapay');
      expect(find.text(l.instapayHandleHint), findsOneWidget);
    });

    testWidgets('[$code] S-1: a 004 balance left from before gives NO withdraw action (Goora holds no driver money)',
        (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          'wallet.balance.me': 180,
          'wallet.activity.me': jsonEncode([
            ActivityEntry(id: 'w-income-1', kind: ActivityKind.tripIncome, amount: 180, date: rideTuesday.addDays(-1))
                .toJson(),
          ]),
        },
      );
      expect(find.byKey(const Key('withdraw')), findsNothing);
      expect(find.textContaining('InstaPay'), findsWidgets, reason: 'only the handle card mentions it');
      expect(find.text(code == 'ar' ? 'اسحب على InstaPay' : 'Withdraw to InstaPay'), findsNothing);
    });

    testWidgets('[$code] N-9: saving the InstaPay handle says it was saved', (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.instapaySaved), findsNothing);
      final field = find.descendant(of: find.byKey(const Key('instapay-field')), matching: find.byType(TextField));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'omar.k@instapay');
      await tester.tap(find.byKey(const Key('instapay-save')));
      await tester.pumpAndSettle();
      expect(find.text(l.instapaySaved), findsOneWidget);
    });
  }
}
