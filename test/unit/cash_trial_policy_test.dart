import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/wallet/domain/cash_trial_policy.dart';

/// Brief §6.7 C: 10 cash trips, 2 "Didn't pay" strikes, banner from trip 8.
void main() {
  test('limits are the brief\'s numbers', () {
    expect(CashTrialPolicy.tripLimit, 10);
    expect(CashTrialPolicy.strikeLimit, 2);
    expect(CashTrialPolicy.bannerAfter, 7);
  });

  test('trips left counts down from 10 and never goes negative', () {
    expect(CashTrialPolicy.tripsLeft(0), 10);
    expect(CashTrialPolicy.tripsLeft(3), 7);
    expect(CashTrialPolicy.tripsLeft(9), 1);
    expect(CashTrialPolicy.tripsLeft(10), 0);
    expect(CashTrialPolicy.tripsLeft(12), 0);
  });

  test('cash is available for trips 1–10 and gone after the 10th', () {
    expect(CashTrialPolicy.available(0, 0), isTrue);
    expect(CashTrialPolicy.available(9, 0), isTrue);
    expect(CashTrialPolicy.available(10, 0), isFalse);
  });

  test('one strike keeps cash, the second turns it off at once', () {
    expect(CashTrialPolicy.available(3, 1), isTrue);
    expect(CashTrialPolicy.available(3, 2), isFalse);
    expect(CashTrialPolicy.endedBy(3, 2), CashTrialEnd.strikes);
  });

  test('the top-up banner shows from cash trip 8 (7 done) until cash ends', () {
    expect(CashTrialPolicy.showTopUpBanner(6, 0), isFalse);
    expect(CashTrialPolicy.showTopUpBanner(7, 0), isTrue);
    expect(CashTrialPolicy.showTopUpBanner(9, 0), isTrue);
    expect(CashTrialPolicy.showTopUpBanner(10, 0), isFalse, reason: 'cash over — the ended state replaces the banner');
    expect(CashTrialPolicy.showTopUpBanner(8, 2), isFalse);
  });

  test('why cash ended: one reason, strikes win over trips used', () {
    expect(CashTrialPolicy.endedBy(5, 1), isNull);
    expect(CashTrialPolicy.endedBy(10, 0), CashTrialEnd.tripsUsed);
    expect(CashTrialPolicy.endedBy(10, 2), CashTrialEnd.strikes, reason: 'struck on the 10th trip: one state, not two');
  });
}
