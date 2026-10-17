import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/fee_savings_calculator.dart';

ActivityEntry _trip(String id, CalendarDate date, {int fee = 4}) =>
    ActivityEntry(id: id, kind: ActivityKind.trip, amount: 40 + fee, fee: fee, date: date);

/// Brief §6.7 B: upsell once this month's fees exceed the 149 EGP subscription.
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

  test('37 trips at 4 EGP = 148: no upsell; 38 = 152: upsell', () {
    List<ActivityEntry> trips(int n) => [for (var i = 0; i < n; i++) _trip('t$i', oct)];
    expect(FeeSavingsCalculator.feesInMonth(trips(37), oct.monthKey), 148);
    expect(FeeSavingsCalculator.shouldUpsell(148, isFeeFree: false), isFalse);
    expect(FeeSavingsCalculator.shouldUpsell(149, isFeeFree: false), isFalse, reason: '"exceed" — equal is not more');
    expect(FeeSavingsCalculator.feesInMonth(trips(38), oct.monthKey), 152);
    expect(FeeSavingsCalculator.shouldUpsell(152, isFeeFree: false), isTrue);
  });

  test('a fee-free rider (subscribed, company) is never upsold', () {
    expect(FeeSavingsCalculator.shouldUpsell(500, isFeeFree: true), isFalse);
  });

  test('the comparison price is the brief\'s 149', () => expect(FeeSavingsCalculator.subscriptionPrice, 149));
}
