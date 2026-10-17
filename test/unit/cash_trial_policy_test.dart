import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/wallet/domain/cash_trial_policy.dart';

/// Brief §6.7 C: 5 cash trips (profit change 3, was 10), 2 "Didn't pay" strikes, banner from trip 4.
void main() {
  test('limits are the brief\'s numbers', () {
    expect(CashTrialPolicy.tripLimit, 5);
    expect(CashTrialPolicy.strikeLimit, 2);
    expect(CashTrialPolicy.bannerAfter, 3);
  });

  test('trips left counts down from 5 and never goes negative', () {
    expect(CashTrialPolicy.tripsLeft(0), 5);
    expect(CashTrialPolicy.tripsLeft(3), 2);
    expect(CashTrialPolicy.tripsLeft(4), 1);
    expect(CashTrialPolicy.tripsLeft(5), 0);
    expect(CashTrialPolicy.tripsLeft(12), 0);
  });

  test('cash is available for trips 1–5 and gone after the 5th', () {
    expect(CashTrialPolicy.available(0, 0), isTrue);
    expect(CashTrialPolicy.available(4, 0), isTrue);
    expect(CashTrialPolicy.available(5, 0), isFalse);
  });

  test('one strike keeps cash, the second turns it off at once', () {
    expect(CashTrialPolicy.available(3, 1), isTrue);
    expect(CashTrialPolicy.available(3, 2), isFalse);
    expect(CashTrialPolicy.endedBy(3, 2), CashTrialEnd.strikes);
  });

  test('the top-up banner shows from cash trip 4 (3 done) until cash ends', () {
    expect(CashTrialPolicy.showTopUpBanner(2, 0), isFalse);
    expect(CashTrialPolicy.showTopUpBanner(3, 0), isTrue);
    expect(CashTrialPolicy.showTopUpBanner(4, 0), isTrue);
    expect(CashTrialPolicy.showTopUpBanner(5, 0), isFalse, reason: 'cash over — the ended state replaces the banner');
    expect(CashTrialPolicy.showTopUpBanner(4, 2), isFalse);
  });

  test('why cash ended: one reason, strikes win over trips used', () {
    expect(CashTrialPolicy.endedBy(3, 1), isNull);
    expect(CashTrialPolicy.endedBy(5, 0), CashTrialEnd.tripsUsed);
    expect(CashTrialPolicy.endedBy(5, 2), CashTrialEnd.strikes, reason: 'struck on the 5th trip: one state, not two');
  });
}
