import '../../../core/time/calendar_date.dart';
import 'plan.dart';

/// Pure functions (data-model.md); no state.
abstract final class WalletRules {
  /// A "trip" is a round-trip day (going + return), so the divisor is
  /// `2 × legTotal` — what one leg costs this rider (44, or 40 fee-free).
  static int tripsCovered(int balance, int legTotal) {
    final roundTrip = 2 * legTotal;
    final covered = balance ~/ roundTrip;
    return covered < 0 ? 0 : covered;
  }

  /// The paid period is over — back to pay per trip. Company never lapses.
  static bool isPlanDue(Plan plan, CalendarDate today) =>
      plan.untilDate != null && today.isAfter(plan.untilDate!);
}
