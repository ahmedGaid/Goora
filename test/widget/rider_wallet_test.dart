import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/router.dart';
import 'package:goora/app/routes.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart' show Leg;
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/providers.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_provider.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/presentation/labels.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/pump_app.dart';

/// US2: rider Wallet tab (T031).
Map<String, Object> _withMonthlyTrial({required CalendarDate until}) => {
      FakeWalletRepository.planKey: jsonEncode(
        Plan(personId: 'me', type: PlanType.monthly, status: PlanStatus.trialing, price: 129, untilDate: until)
            .toJson(),
      ),
    };

/// A free cancellation recorded yesterday — inside the activity window
/// `getWallet` reads (today-60..today), unlike the live "I can't come
/// tomorrow" flow which only ever cancels a future day.
Map<String, Object> _withYesterdayFreeCancel() => {
      FakeDailyCommuteRepository.absencesKey: jsonEncode([
        Absence(
          personId: 'me',
          date: rideTuesday.addDays(-1),
          leg: Leg.going,
          madeAt: WallTime(rideTuesday.addDays(-1), const Clock.hm(18, 0)),
          kind: AbsenceKind.freeCancel,
        ).toJson(),
      ]),
    };

/// A late-cancel half-charge tied to a trip, so it shows distinct from the
/// free-cancel zero-row above (AC4).
Map<String, Object> _withLateCancelCharge() => {
      FakeDailyCommuteRepository.chargesKey: jsonEncode([
        Charge(
          id: 'c1',
          personId: 'me',
          rideId: Ride.idFor('sz-0725', rideTuesday.addDays(-2), Leg.going),
          reason: ChargeReason.lateCancel,
          amount: 20,
          owedTo: 'ahmed',
        ).toJson(),
      ]),
    };

/// Opens the Wallet tab directly (deep link), same as a redirected or
/// due-plan rider would reach it — research R2: Wallet stays reachable
/// even with a due plan.
Future<ProviderContainer> _openWallet(
  WidgetTester tester,
  String locale, {
  Map<String, Object> extra = const {},
  List<Override> overrides = const [],
}) async {
  final c = await pumpGooraApp(
    tester,
    prefs: {...memberPrefs(role: Role.rider, locale: locale, withPlan: false), ...extra},
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

    testWidgets('[$code] AC1: plan card shows "Free until {date} · then {price} EGP/month"', (tester) async {
      final until = rideTuesday.addDays(10);
      await _openWallet(tester, code, extra: _withMonthlyTrial(until: until));
      expect(find.text(l.planFreeUntil(l.shortDate(until), 129)), findsOneWidget);
      expect(find.byKey(const Key('plan-change')), findsOneWidget);
    });

    testWidgets('[$code] AC1: a due plan shows the due banner and prompt', (tester) async {
      await _openWallet(tester, code, extra: _withMonthlyTrial(until: rideTuesday.addDays(-5)));
      expect(find.text(l.planDueTitle), findsWidgets);
      expect(find.text(l.planDueBody), findsOneWidget);
    });

    testWidgets('[$code] AC2: balance card, trips caption, method and amount pills', (tester) async {
      await _openWallet(tester, code, extra: _withMonthlyTrial(until: rideTuesday.addDays(10)));
      expect(find.text(l.balanceLabel), findsOneWidget);
      expect(find.text(l.coversTrips(0)), findsOneWidget, reason: 'zero balance covers no trips yet');
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      expect(find.text(l.topUpMethodInstaPay), findsOneWidget);
      expect(find.text(l.topUpMethodVodafone), findsOneWidget);
      expect(find.text(l.topUpMethodCard), findsOneWidget);
      for (final amount in [200, 400, 800]) {
        expect(find.text(l.egpAmount(amount)), findsOneWidget);
      }
    });

    testWidgets('[$code] AC3: a successful top-up increases the balance and adds a row at the top', (tester) async {
      final c = await _openWallet(tester, code, extra: _withMonthlyTrial(until: rideTuesday.addDays(10)));
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-amount-400')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();

      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 400);
      expect(wallet.activity.first.kind, ActivityKind.topUp);
      expect(wallet.activity.first.amount, 400);
      expect(find.text(l.egpAmount(400)), findsOneWidget, reason: 'balance card now shows the new total');
    });

    testWidgets('[$code] AC4: a late-cancel charge and a free cancellation both show, distinctly', (tester) async {
      await _openWallet(
        tester,
        code,
        extra: {
          ..._withMonthlyTrial(until: rideTuesday.addDays(10)),
          ..._withYesterdayFreeCancel(),
          ..._withLateCancelCharge(),
        },
      );
      expect(find.text(l.actFreeCancelZero), findsOneWidget);
      expect(find.text(l.actLateCancelCharge), findsOneWidget);
      expect(find.text(l.egpAmount(0)), findsWidgets, reason: 'balance card and the zero-amount row both show 0 EGP');
      expect(find.text('-${l.egpAmount(20)}'), findsOneWidget, reason: 'the late-cancel row is a charge, not a credit');
    });

    testWidgets('[$code] AC5: the per-trip breakdown ends "Goora fees: in your plan", never a number', (tester) async {
      await _openWallet(tester, code, extra: _withMonthlyTrial(until: rideTuesday.addDays(10)));
      expect(find.text(l.breakdownFees), findsOneWidget);
      expect(find.text(l.breakdownTitle), findsOneWidget);
    });

    testWidgets('[$code] AC5/SC-005: a top-up failure leaves the balance unchanged with an inline retry',
        (tester) async {
      final c = await _openWallet(
        tester,
        code,
        extra: _withMonthlyTrial(until: rideTuesday.addDays(10)),
        overrides: [paymentProviderProvider.overrideWithValue(const _AlwaysFail())],
      );
      await tester.tap(find.byKey(const Key('top-up')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('top-up-confirm')));
      await tester.pumpAndSettle();

      expect(find.text(l.topUpFailTitle), findsOneWidget);
      final meId = c.read(dailyCommuteRepositoryProvider).meId;
      final wallet = await c.read(walletRepositoryProvider).getWallet(meId);
      expect(wallet.balance, 0);
      expect(wallet.activity, isEmpty);
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
