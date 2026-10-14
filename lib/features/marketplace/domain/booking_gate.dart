import '../../wallet/domain/payment_method.dart';
import '../../wallet/domain/seat_price.dart';

enum BookingCheckKind { ok, needsMethod, topUp }

final class BookingCheck {
  const BookingCheck._(this.kind, [this.gap = 0]);

  static const ok = BookingCheck._(BookingCheckKind.ok);
  static const needsMethod = BookingCheck._(BookingCheckKind.needsMethod);
  const BookingCheck.topUp(int gap) : this._(BookingCheckKind.topUp, gap);

  final BookingCheckKind kind;

  /// EGP still missing (topUp only).
  final int gap;

  @override
  bool operator ==(Object other) => other is BookingCheck && other.kind == kind && other.gap == gap;

  @override
  int get hashCode => Object.hash(kind, gap);

  @override
  String toString() => 'BookingCheck(${kind.name}, gap: $gap)';
}

/// Can this person pay for this seat right now (005 research R8, FR-008,
/// FR-009)? Checked at Book, at Post and again at accept. Dart-only for now:
/// the server writes its own check against its own ledger.
abstract final class BookingGate {
  static BookingCheck check({
    required bool hasArrangement,
    required PricingMode mode,
    required bool cashOffered,
    required int balance,
    required SeatPrice price,
  }) {
    if (!hasArrangement) return BookingCheck.needsMethod;
    // Company riders are never blocked and may go below zero (as in 004).
    if (mode == PricingMode.company) return BookingCheck.ok;
    if (mode == PricingMode.cash && cashOffered) return BookingCheck.ok;
    if (balance >= price.total) return BookingCheck.ok;
    return BookingCheck.topUp(price.total - balance);
  }
}
