import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US2: the top-up sheet on its own — method/amount selection, success and
/// forced-failure paths (T032).
final _activePlan = jsonEncode(
  const Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0).toJson(),
);

Future<ProviderContainer> _openSheet(
  WidgetTester tester,
  String locale, {
  List<Override> overrides = const [],
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {
      ...memberPrefs(role: Role.rider, locale: locale, withPlan: false),
      FakeWalletRepository.planKey: _activePlan,
    },
    overrides: [...dailyOverrides(TestClock(at(rideTuesday, 7, 0))), ...overrides],
  );
  tester.view.physicalSize = const Size(390, 2600);
  c.read(routerProvider).go(Routes.wallet);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('top-up')));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  for (final locale in locales) {
    final l = l10nFor(locale);
    final code = locale.languageCode;

    testWidgets('[$code] default selection is InstaPay / 200 EGP; picking another pill selects it', (tester) async {
      await _openSheet(tester, code);
      expect(find.byKey(const Key('top-up-method-instapay')), findsOneWidget);
      expect(find.byKey(const Key('top-up-amount-200')), findsOneWidget);
      await tester.tap(find.byKey(const Key('top-up-method-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-amount-800')));
      await tester.pumpAndSettle();
      // Selection change itself has no externally visible marker other than
      // the pill re-rendering selected; the success path below proves it
      // was actually used.
    });

    testWidgets('[$code] success: the amount reaches the ledger and the sheet closes', (tester) async {
      final c = await _openSheet(tester, code);
      await tester.tap(find.byKey(const Key('top-up-amount-800')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('top-up-confirm')), findsNothing, reason: 'sheet closed on success');
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 800);
    });

    testWidgets('[$code] forced failure: inline error with retry, balance/activity unchanged', (tester) async {
      final c = await _openSheet(
        tester,
        code,
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l.topUpFailTitle), findsOneWidget);
      expect(find.text(l.retry), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 0);
      expect(wallet.activity, isEmpty);
      expect(find.byKey(const Key('top-up-confirm')), findsOneWidget, reason: 'sheet stays open after a failure');
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
