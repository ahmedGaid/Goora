import '../../wallet/domain/share.dart';

enum BookingCheckKind { ok, needsMethod, owesDriver }

final class BookingCheck {
  const BookingCheck._(this.kind, [this.amount = 0, this.driverFirstName = '']);

  static const ok = BookingCheck._(BookingCheckKind.ok);
  static const needsMethod = BookingCheck._(BookingCheckKind.needsMethod);
  const BookingCheck.owesDriver(int amount, String driverFirstName)
      : this._(BookingCheckKind.owesDriver, amount, driverFirstName);

  final BookingCheckKind kind;

  /// owesDriver only: EGP still owed and to whom (first name, FR-018).
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
/// not received blocks first; Goora's own fee never blocks here (it goes on
/// the balance — 007 research R5; the overdue rule is 008's). Dart-only: the
/// server writes its own check against its own records.
abstract final class BookingGate {
  static BookingCheck check({required bool hasArrangement, required List<Share> openShares}) {
    final debts = [for (final s in openShares) if (s.status.isOpenDebt) s];
    if (debts.isNotEmpty) {
      // The oldest debt names the driver; the amount is everything owed.
      debts.sort((a, b) => a.tripEnd.compareTo(b.tripEnd));
      return BookingCheck.owesDriver(debts.fold(0, (sum, s) => sum + s.amount), debts.first.otherFirstName);
    }
    if (!hasArrangement) return BookingCheck.needsMethod;
    return BookingCheck.ok;
  }
}
