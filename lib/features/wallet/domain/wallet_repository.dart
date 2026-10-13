import '../../../core/time/calendar_date.dart';
import 'cash_mark.dart';
import 'payment_method.dart';
import 'payment_provider.dart';
import 'plan.dart';
import 'wallet.dart';

enum SubscribeResult { subscribed, needsTopUp }

/// App-internal interface (contracts/repositories.md) — no network API,
/// this feature has no server component.
abstract interface class WalletRepository {
  Future<Plan?> getPlan(String personId);

  /// Monthly/yearly are paid from the wallet now (research R10); not enough
  /// balance charges nothing. Company verifies first and costs nothing.
  Future<SubscribeResult> subscribe(String personId, PlanType type, {required CalendarDate today});

  /// Takes effect next billing date (no pro-rating).
  Future<Plan> changePlan(String personId, PlanType newType);

  Future<PaymentMethod?> getMethod(String personId);

  Future<void> setMethod(String personId, PaymentMethod method);

  /// Another rider's method (seeded in the fakes, research R11).
  Future<PaymentMethod?> methodOf(String riderId);

  Future<List<CashMark>> cashMarks(String rideId);

  /// The first mark for a (ride, rider) stands; later ones are ignored.
  Future<void> markCash(CashMark mark);

  Future<Wallet> getWallet(String ownerId);

  /// Failure leaves balance/activity untouched.
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount});

  /// Failure leaves balance/activity untouched; never includes cash received.
  Future<PaymentResult> withdraw(String ownerId, {required int amount});
}

/// How the marketplace moves money for a one-off seat (005 contracts/repositories.md
/// "Seams", research R7, R9). Wallet and plan seats are paid at booking; cash
/// seats never come here.
abstract interface class SeatLedger {
  /// Debits [total] ([fee] recorded); a simulated failure leaves balance and
  /// activity untouched (SC-006). One debit per [bookingId].
  Future<PaymentResult> debitSeat(String personId,
      {required String bookingId,
      required String rideId,
      required int total,
      required int fee,
      required CalendarDate date});

  /// One credit row per [bookingId]; an [amount] of 0 writes no row.
  Future<void> refundSeat(String personId,
      {required String bookingId, required String rideId, required int amount, required CalendarDate date});
}
