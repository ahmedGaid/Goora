import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US3: the withdraw sheet on its own — success and forced-failure paths
/// (T040).
Future<ProviderContainer> _openSheet(
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
  await tester.tap(find.byKey(const Key('withdraw')));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] success: the balance resets and the sheet closes', (tester) async {
      final c = await _openSheet(tester, code);
      expect(find.text(l.egpAmount(180)), findsWidgets, reason: 'the seeded 180 EGP balance shown for confirmation');
      await tester.tap(find.byKey(const Key('withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('withdraw-confirm')), findsNothing, reason: 'sheet closed on success');
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 0);
    });

    testWidgets('[$code] forced failure: inline error with retry, balance/activity unchanged', (tester) async {
      final c = await _openSheet(
        tester,
        code,
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.byKey(const Key('withdraw-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l.withdrawFailTitle), findsOneWidget);
      expect(find.text(l.retry), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 180);
      expect(wallet.activity, hasLength(2));
      expect(find.byKey(const Key('withdraw-confirm')), findsOneWidget, reason: 'sheet stays open after a failure');
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
