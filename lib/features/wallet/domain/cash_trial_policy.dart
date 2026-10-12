/// A new rider may pay the driver in cash for their first [tripLimit]
/// completed trips; [strikeLimit] "Didn't pay" marks end it at once (brief
/// §6.7 C). A "Didn't pay" trip still counts as a cash trip.
abstract final class CashTrialPolicy {
  static const tripLimit = 10;
  static const strikeLimit = 2;

  /// The banner shows "from cash trip 8": once 7 are done, the next is the 8th.
  static const bannerAfter = 7;

  static bool available(int tripsDone, int strikes) => tripsDone < tripLimit && strikes < strikeLimit;

  static int tripsLeft(int tripsDone) => tripsDone >= tripLimit ? 0 : tripLimit - tripsDone;

  static bool showTopUpBanner(int tripsDone, int strikes) => available(tripsDone, strikes) && tripsDone >= bannerAfter;

  /// Why cash is over, or null while it is still available. Strikes win when
  /// both apply, so the rider reads one reason, not two.
  static CashTrialEnd? endedBy(int tripsDone, int strikes) {
    if (strikes >= strikeLimit) return CashTrialEnd.strikes;
    if (tripsDone >= tripLimit) return CashTrialEnd.tripsUsed;
    return null;
  }
}

enum CashTrialEnd { tripsUsed, strikes }
