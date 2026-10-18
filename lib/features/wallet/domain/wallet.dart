import '../../../core/time/calendar_date.dart';
import '../../commute/domain/group.dart';
import 'activity_entry.dart';
import 'cash_trial_policy.dart';
import 'payment_method.dart';
import 'share.dart';

/// Goora's own money for one person (007 FR-001): a rider's balance (top-ups
/// minus Goora's fees and subscriptions; below zero = fees owed) and, for
/// drivers, only legacy 004 rows. The driver's share never enters it.
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
    this.shares = const [],
    this.bundleTripsLeft = 0,
    this.feeDue,
    this.feeOverdue = false,
  });

  final String ownerId;
  final MemberRole role;

  /// Whole EGP; a rider's can go below zero once trips outrun top-ups.
  final int balance;

  /// Newest first.
  final List<ActivityEntry> activity;

  /// Riders: how they pay the driver (cash / InstaPay).
  final PaymentMethod? method;

  /// Riders: where the fee-free trial stands (007 research R6).
  final CashTrialStatus? cashTrial;

  /// Service fees paid on this calendar month's trips.
  final int feesThisMonth;

  /// Drivers: shares confirmed received this month — never part of [balance].
  final int cashReceived;

  /// Riders: shares not yet confirmed (open debts first). Drivers: their
  /// riders' shares, newest first.
  final List<Share> shares;

  /// Riders: bundle trips not used yet (008; they never expire).
  final int bundleTripsLeft;

  /// Riders: the day the owed fees fell due (008 FR-004), or null.
  final CalendarDate? feeDue;

  /// Riders: owed fees past the 3-day grace — booking is blocked (FR-005).
  final bool feeOverdue;

  /// Riders: what is owed to Goora now.
  int get owed => balance < 0 ? -balance : 0;

  /// Riders: everything a driver marked as not received.
  List<Share> get openDebts => [for (final s in shares) if (s.status.isOpenDebt) s];
}

/// Where a rider's fee-free trial stands, from their history (004 R8, 007 R6).
final class CashTrialStatus {
  const CashTrialStatus({required this.tripsDone, required this.strikes});

  final int tripsDone;
  final int strikes;

  bool get available => CashTrialPolicy.available(tripsDone, strikes);
  int get tripsLeft => CashTrialPolicy.tripsLeft(tripsDone);
  bool get showTopUpBanner => CashTrialPolicy.showTopUpBanner(tripsDone, strikes);
  CashTrialEnd? get endedBy => CashTrialPolicy.endedBy(tripsDone, strikes);
}
