import '../../../core/time/calendar_date.dart';
import 'payment_provider.dart';
import 'plan.dart';
import 'wallet.dart';

/// App-internal interface (contracts/repositories.md) — no network API,
/// this feature has no server component.
abstract interface class WalletRepository {
  Future<Plan?> getPlan(String personId);

  Future<Plan> choosePlan(String personId, PlanType type, {required CalendarDate today});

  /// Takes effect next billing date (FR-004, no pro-rating).
  Future<Plan> changePlan(String personId, PlanType newType);

  Future<Wallet> getWallet(String ownerId);

  /// Failure leaves balance/activity untouched (FR-006).
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount});

  /// Failure leaves balance/activity untouched (FR-010).
  Future<PaymentResult> withdraw(String ownerId, {required int amount});
}
