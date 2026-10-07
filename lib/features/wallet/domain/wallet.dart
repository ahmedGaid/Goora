import '../../commute/domain/group.dart';
import 'activity_entry.dart';
import 'cash_trial_policy.dart';
import 'payment_method.dart';

/// A rider's prepaid balance, or a driver's recoverable-this-week total
/// awaiting Thursday payout.
final class Wallet {
  const Wallet({
    required this.ownerId,
    required this.role,
    required this.balance,
    required this.activity,
    this.method,
    this.cashTrial,
    this.feesThisMonth = 0,
    this.cashReceived = 0,
  });

  final String ownerId;
  final MemberRole role;

  /// Whole EGP; a rider's can go below zero once trips outrun top-ups.
  final int balance;

  /// Newest first.
  final List<ActivityEntry> activity;

  /// Riders: the method chosen after joining.
  final PaymentMethod? method;

  /// Riders who chose cash: where the trial stands (null for wallet riders).
  final CashTrialStatus? cashTrial;

  /// Service fees paid on this calendar month's trips.
  final int feesThisMonth;

  /// Drivers: cash recorded as received — never part of [balance].
  final int cashReceived;
}

/// Where a cash rider's trial stands, from their history (research R8).
final class CashTrialStatus {
  const CashTrialStatus({required this.tripsDone, required this.strikes});

  final int tripsDone;
  final int strikes;

  bool get available => CashTrialPolicy.available(tripsDone, strikes);
  int get tripsLeft => CashTrialPolicy.tripsLeft(tripsDone);
  bool get showTopUpBanner => CashTrialPolicy.showTopUpBanner(tripsDone, strikes);
  CashTrialEnd? get endedBy => CashTrialPolicy.endedBy(tripsDone, strikes);
}
