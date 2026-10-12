import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/fee_savings_calculator.dart';

ActivityEntry _trip(String id, CalendarDate date, {int fee = 4}) =>
    ActivityEntry(id: id, kind: ActivityKind.trip, amount: 40 + fee, fee: fee, date: date);

/// Brief §6.7 B: upsell once this month's fees exceed the 129 EGP subscription.
void main() {
  final oct = CalendarDate(2026, 10, 1);

  test('sums only this month\'s trip fees', () {
    final activity = [
      _trip('a', oct),
      _trip('b', oct.addDays(5)),
      _trip('sep', CalendarDate(2026, 9, 30)),
      ActivityEntry(id: 'top', kind: ActivityKind.topUp, amount: 200, date: oct),
    ];
    expect(FeeSavingsCalculator.feesInMonth(activity, oct.monthKey), 8);
  });

  test('32 trips at 4 EGP = 128: no upsell; 33 = 132: upsell', () {
    List<ActivityEntry> trips(int n) => [for (var i = 0; i < n; i++) _trip('t$i', oct)];
    expect(FeeSavingsCalculator.feesInMonth(trips(32), oct.monthKey), 128);
    expect(FeeSavingsCalculator.shouldUpsell(128, isFeeFree: false), isFalse);
    expect(FeeSavingsCalculator.shouldUpsell(129, isFeeFree: false), isFalse, reason: '"exceed" — equal is not more');
    expect(FeeSavingsCalculator.feesInMonth(trips(33), oct.monthKey), 132);
    expect(FeeSavingsCalculator.shouldUpsell(132, isFeeFree: false), isTrue);
  });

  test('a fee-free rider (subscribed, company) is never upsold', () {
    expect(FeeSavingsCalculator.shouldUpsell(500, isFeeFree: true), isFalse);
  });

  test('the comparison price is the brief\'s 129', () => expect(FeeSavingsCalculator.subscriptionPrice, 129));
}
