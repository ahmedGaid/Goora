import '../../commute/domain/group.dart';
import 'activity_entry.dart';

/// A rider's prepaid balance, or a driver's recoverable-this-week total
/// awaiting Thursday payout.
final class Wallet {
  const Wallet({required this.ownerId, required this.role, required this.balance, required this.activity});

  final String ownerId;
  final MemberRole role;

  /// Whole EGP.
  final int balance;

  /// Newest first.
  final List<ActivityEntry> activity;
}
