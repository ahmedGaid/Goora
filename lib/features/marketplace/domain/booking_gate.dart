import '../../wallet/domain/share.dart';

enum BookingCheckKind { ok, needsMethod, owesDriver, feeOverdue }

final class BookingCheck {
  const BookingCheck._(this.kind, [this.amount = 0, this.driverFirstName = '']);

  static const ok = BookingCheck._(BookingCheckKind.ok);
  static const needsMethod = BookingCheck._(BookingCheckKind.needsMethod);
  const BookingCheck.owesDriver(int amount, String driverFirstName)
      : this._(BookingCheckKind.owesDriver, amount, driverFirstName);

  /// 008 FR-005: Goora's own fees, past the 3-day grace.
  const BookingCheck.feeOverdue(int amount) : this._(BookingCheckKind.feeOverdue, amount);

  final BookingCheckKind kind;

  /// owesDriver / feeOverdue: EGP still owed; owesDriver also names to whom
  /// (first name, FR-018).
  final int amount;
  final String driverFirstName;

  @override
  bool operator ==(Object other) =>
      other is BookingCheck && other.kind == kind && other.amount == amount && other.driverFirstName == driverFirstName;

  @override
  int get hashCode => Object.hash(kind, amount, driverFirstName);

  @override
  String toString() => 'BookingCheck(${kind.name}, $amount, $driverFirstName)';
}

/// May this person take a seat right now (005 FR-008, 007 FR-005)? Checked
/// at Book, at Post, at accept and at group join. A share a driver marked as
/// not received blocks first; then Goora's own fees, but only once overdue
/// (008 FR-005) — a fee owed within its grace never blocks. Dart-only: the
/// server writes its own check against its own records.
abstract final class BookingGate {
  static BookingCheck check({required bool hasArrangement, required List<Share> openShares, int feeOverdue = 0}) {
    final debts = [for (final s in openShares) if (s.status.isOpenDebt) s];
    if (debts.isNotEmpty) {
      // The oldest debt names the driver; the amount is everything owed.
      debts.sort((a, b) => a.tripEnd.compareTo(b.tripEnd));
      return BookingCheck.owesDriver(debts.fold(0, (sum, s) => sum + s.amount), debts.first.otherFirstName);
    }
    if (feeOverdue > 0) return BookingCheck.feeOverdue(feeOverdue);
    if (!hasArrangement) return BookingCheck.needsMethod;
    return BookingCheck.ok;
  }
}
