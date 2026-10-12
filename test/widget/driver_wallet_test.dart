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
import 'package:goora/features/wallet/domain/payment_provider.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US3: driver Wallet tab (T039). The seeded driver already has trip income
/// (160 EGP) + a rider's fee (20 EGP, from 'sara') via `WalletSeed`,
/// confirmed through the repository rather than replayed from 003's flows.
Future<ProviderContainer> _openWallet(
  WidgetTester tester,
  String locale, {
  List<Override> overrides = const [],
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.driver, locale: locale)},
    overrides: [...dailyOverrides(TestClock(at(rideTuesday, 7, 0))), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2600);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] AC1: recovered total and payout line', (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.recoveredTitle), findsOneWidget);
      expect(find.text(l.egpAmount(180)), findsWidgets, reason: 'seeded 160 + 20 EGP');
      expect(find.text(l.payoutNote), findsOneWidget);
    });

    testWidgets('[$code] AC2: withdraw resets the balance and adds a Withdrawal row', (tester) async {
      final c = await _openWallet(tester, code);
      await tester.tap(find.byKey(const Key('withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('withdraw-confirm')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 0);
      expect(wallet.activity.first.kind, ActivityKind.withdrawal);
      expect(find.text(l.actWithdrawal), findsOneWidget);
    });

    testWidgets('[$code] AC3: trip-cost breakdown shows the gap for an empty seat', (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.driverBreakdownTitle), findsOneWidget);
      // sz-0725: 4-seat capacity (2 riders + 1 free), 40 EGP/leg, round trip.
      expect(find.text(l.egpAmount(320)), findsOneWidget, reason: 'trip cost at full capacity, round trip');
      expect(find.text(l.egpAmount(160)), findsWidgets, reason: 'received from 2 riders round trip, and the gap');
      expect(find.text(l.driverBreakdownFree), findsOneWidget);
    });

    testWidgets('[$code] AC4: a rider fee shows labelled by rider', (tester) async {
      await _openWallet(tester, code);
      expect(find.text(l.actFeeReceivedFrom('sara')), findsOneWidget);
      expect(find.text(l.actTripIncome), findsOneWidget);
    });

    testWidgets('[$code] SC-005: a forced withdrawal failure leaves balance/activity unchanged', (tester) async {
      final c = await _openWallet(
        tester,
        code,
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.byKey(const Key('withdraw')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l.withdrawFailTitle), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 180);
      expect(wallet.activity, hasLength(2));
    });
  }
}

final class _AlwaysFail implements PaymentProvider {
  const _AlwaysFail();

  @override
  Future<PaymentResult> topUp({required String method, required int amount}) async => PaymentResult.failure;

  @override
  Future<PaymentResult> withdraw({required int amount}) async => PaymentResult.failure;
}
