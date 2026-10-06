import '../../../core/time/calendar_date.dart';
import 'plan.dart';

/// Pure functions (data-model.md); no state.
abstract final class WalletRules {
  /// One calendar month from [chosenAt] (research R1).
  static CalendarDate trialEndDate(CalendarDate chosenAt) => chosenAt.addMonths(1);

  /// A "trip" is a round-trip day (going + return), so the divisor is
  /// `2 × legShare` (clarification: 40 EGP/leg ⇒ 80 EGP per round-trip day).
  static int tripsCovered(int balance, int legShare) {
    final roundTrip = 2 * legShare;
    final covered = balance ~/ roundTrip;
    return covered < 0 ? 0 : covered;
  }

  /// A plan is due once its free or paid period has ended with no
  /// arrangement (FR-014) — Company never goes due (no `untilDate`).
  static bool isPlanDue(Plan plan, CalendarDate today) =>
      plan.untilDate != null && today.isAfter(plan.untilDate!);
}
