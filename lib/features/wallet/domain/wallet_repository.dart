import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import 'cash_mark.dart';
import 'payment_method.dart';
import 'payment_provider.dart';
import 'plan.dart';
import 'share.dart';
import 'wallet.dart';

enum SubscribeResult { subscribed, needsTopUp }

/// App-internal interface (contracts/repositories.md) — no network API,
/// this feature has no server component. Holds only Goora's own money; the
/// driver's share is paid outside Goora and lives here only as a trust status
/// (007 FR-001).
abstract interface class WalletRepository {
  Future<Plan?> getPlan(String personId);

  /// Monthly/yearly are paid from the wallet now (research R10); not enough
  /// balance charges nothing. Company verifies first and costs nothing.
  Future<SubscribeResult> subscribe(String personId, PlanType type, {required CalendarDate today});

  /// Takes effect next billing date (no pro-rating).
  Future<Plan> changePlan(String personId, PlanType newType);

  /// 010 research R8 — called by the company network when [personId]
  /// enrolls at [now]: the company plan replaces a personal one, whose paid
  /// days left are paused; no fee-free trial from now on (Q11 default).
  /// Trips already taken keep the price they had.
  Future<void> startCompanyPlan(String personId, WallTime now);

  /// 010 research R8 — when [personId] leaves (any path) at [now]: the
  /// paused plan comes back with its days counted from [now]'s date, else
  /// they pay per trip. Trips taken while covered stay fee-free.
  Future<void> endCompanyPlan(String personId, WallTime now);

  /// The personal plan paused by [startCompanyPlan], if any.
  Future<PausedPlan?> pausedPlan(String personId);

  /// How the rider pays the driver (cash / InstaPay).
  Future<PaymentMethod?> getMethod(String personId);

  Future<void> setMethod(String personId, PaymentMethod method);

  /// Another rider's method (seeded in the fakes, research R11).
  Future<PaymentMethod?> methodOf(String riderId);

  /// The driver's current marks on [rideId], one per rider.
  Future<List<CashMark>> shareMarks(String rideId);

  /// Sets the driver's answer for one rider's share when
  /// `SharePolicy.canMark` allows it (007 R2); otherwise ignored.
  Future<void> markShare(CashMark mark);

  /// The rider's "دفعت" on a share marked as not received (FR-006).
  Future<void> claimPaid(String rideId, String riderId);

  /// Every share of this rider's that the driver hasn't confirmed, open debts
  /// first (FR-005 guard and the debt banner).
  Future<List<Share>> openShares(String riderId);

  /// A driver's shares from their riders, newest first (US4 payments list).
  Future<List<Share>> driverShares(String driverId);

  /// The signed-in driver's view of one rider's share on one ride (driver
  /// Today after drop-off); null when that rider has no share there.
  Future<Share?> driverShareOn(String rideId, String riderId);

  /// Two "didn't pay" marks in 30 days (FR-007).
  Future<bool> disputeFlagged(String riderId);

  Future<String?> instapayHandleOf(String driverId);

  /// "≤ 40 chars, trimmed; empty → null" (007 research R7).
  Future<void> setInstapayHandle(String driverId, String? handle);

  Future<Wallet> getWallet(String ownerId);

  /// Failure leaves balance/activity untouched.
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount});

  /// Failure leaves balance/activity untouched.
  Future<PaymentResult> withdraw(String ownerId, {required int amount});

  /// 008 FR-003: pays everything owed to Goora in one transaction by
  /// [method]; nothing owed → success with nothing written; a failure writes
  /// nothing.
  Future<PaymentResult> settle(String riderId, {required String method});

  /// 008 FR-007: 20 trips for 75 EGP in one transaction; never touches the
  /// balance; a failure writes nothing.
  Future<PaymentResult> buyBundle(String riderId, {required String method});
}

/// How the marketplace records Goora's fee for a one-off seat (005 research
/// R7, 007 research R5). The driver's share is never debited here; trial
/// seats never come here.
abstract interface class SeatLedger {
  /// Takes [fee] from the balance at booking (an internal line, so it can't
  /// fail; a balance below zero is a fee owed). [share] is shown, never
  /// debited. One row per [bookingId].
  Future<void> debitSeat(String personId,
      {required String bookingId,
      required String rideId,
      required int fee,
      required int share,
      required CalendarDate date});

  /// One credit row per [bookingId]; an [amount] of 0 writes no row.
  Future<void> refundSeat(String personId,
      {required String bookingId, required String rideId, required int amount, required CalendarDate date});
}
