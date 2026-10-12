import 'activity_entry.dart';

/// "You paid X EGP in fees this month. With a subscription you'd pay 129."
/// (brief §6.7 B).
abstract final class FeeSavingsCalculator {
  static const subscriptionPrice = 129;

  /// Service fees paid on trips dated in [monthKey] (`yyyy-mm`).
  static int feesInMonth(Iterable<ActivityEntry> activity, String monthKey) => activity
      .where((e) => e.kind == ActivityKind.trip && e.date.monthKey == monthKey)
      .fold(0, (sum, e) => sum + e.fee);

  static bool shouldUpsell(int feesThisMonth, {required bool isFeeFree}) =>
      !isFeeFree && feesThisMonth > subscriptionPrice;
}
