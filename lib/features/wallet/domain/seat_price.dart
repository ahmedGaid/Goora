import '../../commute/domain/pricing_service.dart';
import 'payment_method.dart';

/// One price quote for a seat (005 research R2, contracts/pricing.md): every
/// price line and every charge reads this, so the fee and the cash rounding
/// (FR-029) are decided in one place. Composes the twinned
/// [PricingService.serviceFee] and [PricingService.cashAmount], so it needs no
/// twin of its own.
final class SeatPrice {
  const SeatPrice({required this.contribution, required this.fee, required this.cash, required this.mode});

  /// When the mode is cash but no cash amount fits the range, the quote falls
  /// back to the wallet price (fee included) — the screen shows the wallet line.
  factory SeatPrice.of(int contribution, {required int tripCost, required int riderSeats, required PricingMode mode}) {
    final cash = PricingService.cashAmount(contribution, tripCost: tripCost, riderSeats: riderSeats);
    final fee = PricingService.serviceFee(
      contribution,
      tripCost: tripCost,
      riderSeats: riderSeats,
      isSubscriber: mode.isFeeFree && mode != PricingMode.cash,
      isCashTrial: mode == PricingMode.cash && cash != null,
    );
    return SeatPrice(contribution: contribution, fee: fee, cash: cash, mode: mode);
  }

  /// What goes to the driver.
  final int contribution;

  /// Goora's service fee; 0 for subscribed, company and cash.
  final int fee;

  /// The cash amount, or null when cash isn't offered for this seat.
  final int? cash;

  final PricingMode mode;

  int get total => contribution + fee;

  bool get cashOffered => cash != null;

  /// What actually moves: the cash amount (cash mode, when offered) or [total].
  int get payable => mode == PricingMode.cash && cash != null ? cash! : total;

  /// Stored as quoted: a request's or booking's price is fixed (FR-022), so it
  /// is never re-derived on read.
  Map<String, Object?> toJson() => {'contribution': contribution, 'fee': fee, 'cash': cash, 'mode': mode.name};

  static SeatPrice fromJson(Map<String, Object?> j) => SeatPrice(
        contribution: j['contribution']! as int,
        fee: j['fee']! as int,
        cash: j['cash'] as int?,
        mode: PricingMode.values.byName(j['mode']! as String),
      );

  @override
  bool operator ==(Object other) =>
      other is SeatPrice &&
      other.contribution == contribution &&
      other.fee == fee &&
      other.cash == cash &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(contribution, fee, cash, mode);
}
