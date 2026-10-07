import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_rules.dart';

void main() {
  group('tripsCovered — a round-trip day at the rider\'s leg total', () {
    test('wallet rider: 44 EGP/leg ⇒ 88/day; 87 → 0, 88 → 1, 200 → 2', () {
      expect(WalletRules.tripsCovered(87, 44), 0);
      expect(WalletRules.tripsCovered(88, 44), 1);
      expect(WalletRules.tripsCovered(200, 44), 2);
    });

    test('fee-free rider: 40 EGP/leg ⇒ 80/day; 320 → 4', () {
      expect(WalletRules.tripsCovered(320, 40), 4);
    });

    test('a negative balance covers 0, never a negative count', () {
      expect(WalletRules.tripsCovered(-44, 44), 0);
    });
  });

  group('plans', () {
    final today = CalendarDate(2026, 10, 8);
    Plan monthly(CalendarDate start) => Plan(
          personId: 'me',
          type: PlanType.monthly,
          status: PlanStatus.active,
          price: 129,
          startDate: start,
          untilDate: start.addMonths(1),
        );

    test('a subscription covers its own period only', () {
      final p = monthly(today);
      expect(p.coversDate(today.addDays(-1)), isFalse);
      expect(p.coversDate(today), isTrue);
      expect(p.coversDate(today.addMonths(1)), isTrue);
      expect(p.coversDate(today.addMonths(1).addDays(1)), isFalse);
      expect(WalletRules.isPlanDue(p, today.addMonths(1).addDays(1)), isTrue);
    });

    test('company covers from its start and never lapses', () {
      final p = Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0, startDate: today);
      expect(p.coversDate(today.addDays(400)), isTrue);
      expect(WalletRules.isPlanDue(p, today.addDays(400)), isFalse);
    });

    test('a v1 "trialing" plan reads back as lapsed, not a crash', () {
      final p = Plan.fromJson({'personId': 'me', 'type': 'monthly', 'status': 'trialing', 'price': 129, 'untilDate': '2026-11-08'});
      expect(p.status, PlanStatus.due);
      expect(p.coversDate(today), isFalse);
    });
  });

  group('PricingMode.of — which price a rider sees (FR-004)', () {
    final today = CalendarDate(2026, 10, 8);

    test('cash while the trial allows it, then wallet', () {
      expect(PricingMode.of(method: PaymentMethod.cash, plan: null, today: today, cashAvailable: true), PricingMode.cash);
      expect(PricingMode.of(method: PaymentMethod.cash, plan: null, today: today, cashAvailable: false), PricingMode.wallet);
      expect(PricingMode.of(method: null, plan: null, today: today, cashAvailable: false), PricingMode.wallet);
    });

    test('a paid-up plan beats the method', () {
      final sub = Plan(
        personId: 'me',
        type: PlanType.yearly,
        status: PlanStatus.active,
        price: 1290,
        startDate: today,
        untilDate: today.addMonths(12),
      );
      expect(PricingMode.of(method: PaymentMethod.cash, plan: sub, today: today, cashAvailable: true), PricingMode.subscribed);
      const company = Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0);
      expect(PricingMode.of(method: PaymentMethod.wallet, plan: company, today: today, cashAvailable: false), PricingMode.company);
    });

    test('only the wallet mode pays a fee', () {
      expect(PricingMode.wallet.isFeeFree, isFalse);
      expect([PricingMode.cash, PricingMode.subscribed, PricingMode.company].every((m) => m.isFeeFree), isTrue);
    });
  });
}
