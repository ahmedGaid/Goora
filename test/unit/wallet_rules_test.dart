import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_rules.dart';

WallTime _midnight(CalendarDate date) => WallTime(date, const Clock.hm(0, 0));

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
          startDate: _midnight(start),
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
      final p =
          Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0, startDate: _midnight(today));
      expect(p.coversDate(today.addDays(400)), isTrue);
      expect(WalletRules.isPlanDue(p, today.addDays(400)), isFalse);
    });

    test('a v1 "trialing" plan reads back as lapsed, not a crash', () {
      final p = Plan.fromJson({'personId': 'me', 'type': 'monthly', 'status': 'trialing', 'price': 129, 'untilDate': '2026-11-08'});
      expect(p.status, PlanStatus.due);
      expect(p.coversDate(today), isFalse);
    });

    test('a v1 plan with a bare-date startDate still parses (research R14)', () {
      final p = Plan.fromJson({
        'personId': 'me',
        'type': 'monthly',
        'status': 'active',
        'price': 129,
        'startDate': today.toIso(),
        'untilDate': today.addMonths(1).toIso(),
      });
      expect(p.startDate, WallTime(today, const Clock.hm(0, 0)));
      expect(p.coversDate(today), isTrue);
    });

    test('coversTrip keeps the fee a trip already settled before subscribing, same day (research R14)', () {
      final subscribedAt = WallTime(today, const Clock.hm(21, 5)); // 9:05 PM
      final p = Plan(
        personId: 'me',
        type: PlanType.monthly,
        status: PlanStatus.active,
        price: 129,
        startDate: subscribedAt,
        untilDate: today.addMonths(1),
      );
      final tripBeforeSubscribing = WallTime(today, const Clock.hm(17, 0)); // 5 PM return leg
      final tripAfterSubscribing = WallTime(today, const Clock.hm(21, 30));
      expect(p.coversTrip(tripBeforeSubscribing), isFalse, reason: 'already charged its fee before the rider subscribed');
      expect(p.coversTrip(tripAfterSubscribing), isTrue);
      // The forward-looking, day-granularity check still treats the whole day as covered —
      // that's right for "what will I pay on my next trip today", just not for history.
      expect(p.coversDate(today), isTrue);
    });
  });

  group('PricingMode.of — which price a rider sees (FR-004)', () {
    final today = CalendarDate(2026, 10, 8);

    test('fee-free while the trial allows it, then per trip (007 R6)', () {
      expect(PricingMode.of(plan: null, today: today, trialAvailable: true), PricingMode.trial);
      expect(PricingMode.of(plan: null, today: today, trialAvailable: false), PricingMode.perTrip);
    });

    test('a paid-up plan beats the trial', () {
      final sub = Plan(
        personId: 'me',
        type: PlanType.yearly,
        status: PlanStatus.active,
        price: 1290,
        startDate: _midnight(today),
        untilDate: today.addMonths(12),
      );
      expect(PricingMode.of(plan: sub, today: today, trialAvailable: true), PricingMode.subscribed);
      const company = Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0);
      expect(PricingMode.of(plan: company, today: today, trialAvailable: false), PricingMode.company);
    });

    test('only per trip pays a fee', () {
      expect(PricingMode.perTrip.isFeeFree, isFalse);
      expect([PricingMode.trial, PricingMode.subscribed, PricingMode.company].every((m) => m.isFeeFree), isTrue);
    });
  });
}
