import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:goora/features/wallet/domain/wallet_rules.dart';

void main() {
  test('trialEndDate = chosenAt.addMonths(1)', () {
    final chosenAt = CalendarDate(2026, 10, 8);
    expect(WalletRules.trialEndDate(chosenAt), chosenAt.addMonths(1));
    expect(WalletRules.trialEndDate(chosenAt), CalendarDate(2026, 11, 8));
  });

  group('tripsCovered — 40 EGP/leg ⇒ 80 EGP/round-trip', () {
    test('balance below one leg-share → 0', () {
      expect(WalletRules.tripsCovered(30, 40), 0);
    });

    test('79 EGP → 0 trips, 80 EGP → 1 trip (exact round-trip boundary)', () {
      expect(WalletRules.tripsCovered(79, 40), 0);
      expect(WalletRules.tripsCovered(80, 40), 1);
    });

    test("the brief's numbers: 320 EGP / 80 ⇒ 4 trips", () {
      expect(WalletRules.tripsCovered(320, 40), 4);
    });
  });

  group('isPlanDue', () {
    final today = CalendarDate(2026, 10, 8);

    test('true only when untilDate is set and in the past', () {
      final due = Plan(
          personId: 'me', type: PlanType.monthly, status: PlanStatus.due, price: 129, untilDate: today.addDays(-1));
      expect(WalletRules.isPlanDue(due, today), isTrue);
    });

    test('false when untilDate is today or in the future', () {
      final current = Plan(
          personId: 'me', type: PlanType.monthly, status: PlanStatus.trialing, price: 129, untilDate: today);
      expect(WalletRules.isPlanDue(current, today), isFalse);
      final future = Plan(
          personId: 'me',
          type: PlanType.monthly,
          status: PlanStatus.trialing,
          price: 129,
          untilDate: today.addDays(1));
      expect(WalletRules.isPlanDue(future, today), isFalse);
    });

    test('false for Company (no untilDate)', () {
      const company = Plan(personId: 'me', type: PlanType.company, status: PlanStatus.active, price: 0);
      expect(WalletRules.isPlanDue(company, today), isFalse);
    });
  });
}
