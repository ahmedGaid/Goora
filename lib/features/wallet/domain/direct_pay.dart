import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/pricing_service.dart';
import 'cash_mark.dart';
import 'payment_method.dart';

/// Where one rider's share for one ride stands (007 research R2). The share
/// is paid to the driver outside Goora; this is only its trust status.
enum ShareStatus {
  pending,
  received,
  autoReceived,
  notReceived,
  disputed;

  /// The rider still owes the driver: booking is blocked (FR-005).
  bool get isOpenDebt => this == notReceived || this == disputed;
}

/// The driver-confirms-receipt rules (007 research R2, R3). Twin of
/// supabase/functions/_shared/direct_pay.ts — both run
/// test/fixtures/direct_pay_vectors.json. Times are whole minutes on one
/// shared scale so both sides compare the same numbers.
abstract final class SharePolicy {
  /// No answer from the driver for this long after the trip → received.
  static const autoReceiveMinutes = 24 * 60;

  /// An auto-received share may be turned into "didn't pay" once, until then.
  static const reverseAutoMinutes = 7 * 24 * 60;

  static const disputeWindowDays = 30;
  static const disputeLimit = 2;

  static final _epoch = CalendarDate(2000, 1, 1);

  /// The shared day scale (days since 2000-01-01) for [disputeFlagged].
  static int dayOf(CalendarDate d) => _epoch.daysUntil(d);

  /// The shared minute scale for [status] and [canMark].
  static int minuteOf(WallTime t) => dayOf(t.date) * 24 * 60 + t.time.minutes;

  /// [claimAt] counts only when made after the latest "didn't pay" mark.
  static ShareStatus status({
    required CashOutcome? mark,
    required int? markedAt,
    required int? claimAt,
    required int tripEnd,
    required int now,
  }) {
    if (mark == CashOutcome.received) return ShareStatus.received;
    if (mark == CashOutcome.didNotPay) {
      final claimed = claimAt != null && (markedAt == null || claimAt > markedAt);
      return claimed ? ShareStatus.disputed : ShareStatus.notReceived;
    }
    return now - tripEnd >= autoReceiveMinutes ? ShareStatus.autoReceived : ShareStatus.pending;
  }

  /// May the driver set [outcome] now? Any answer within 24 hours of the
  /// trip; "received" always (it only clears a debt); an auto-received share
  /// may become "didn't pay" once within 7 days. Otherwise answers are frozen.
  static bool canMark({
    required ShareStatus current,
    required CashOutcome outcome,
    required int tripEnd,
    required int now,
    required bool reversedOnce,
  }) {
    if (now < tripEnd) return false;
    if (outcome == CashOutcome.received && current != ShareStatus.received) return true;
    if (now - tripEnd < autoReceiveMinutes) return true;
    return current == ShareStatus.autoReceived &&
        outcome == CashOutcome.didNotPay &&
        !reversedOnce &&
        now - tripEnd < reverseAutoMinutes;
  }

  /// Two "didn't pay" marks on trips in the last 30 days (today included)
  /// flag the rider for review — never an automatic ban (FR-007).
  static bool disputeFlagged(List<int> didNotPayDays, int today) =>
      didNotPayDays.where((d) => d <= today && today - d < disputeWindowDays).length >= disputeLimit;
}

/// The share a rider hands the driver and Goora's own fee on it (007
/// research R4). Composes the twinned [PricingService] rules and has its own
/// twin in direct_pay.ts.
abstract final class DirectPay {
  /// Cash is rounded to 5 EGP when a multiple fits the range (005 FR-029);
  /// InstaPay, or cash with no fitting multiple, is the exact contribution.
  static int share(int contribution,
      {required PaymentMethod method, required int tripCost, required int riderSeats}) {
    if (method == PaymentMethod.cash) {
      return PricingService.cashAmount(contribution, tripCost: tripCost, riderSeats: riderSeats) ?? contribution;
    }
    return contribution;
  }

  /// 10% of the contribution (half up), trimmed so share + fee never passes
  /// the rider's equal share of the trip cost — so cash rounding up can't
  /// break Constitution II. 0 when fee-free (trial, subscribed, company).
  static int fee(int contribution,
      {required int share, required int tripCost, required int riderSeats, required bool feeFree}) {
    if (feeFree) return 0;
    // Untrimmed 10%, half up — PricingService.serviceFee trims against the
    // contribution, but the cap here is on what is actually paid.
    final base = (contribution * PricingService.feeRatePercent + 50) ~/ 100;
    final room = PricingService.equalShare(tripCost, riderSeats) - share;
    final fee = base < room ? base : room;
    return fee < 0 ? 0 : fee;
  }
}
