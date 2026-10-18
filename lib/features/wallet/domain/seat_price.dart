import 'direct_pay.dart';
import 'payment_method.dart';

/// One price quote for a seat or a trip (005 research R2, 007 research R4):
/// every price line and every fee reads this, so the share the rider hands
/// the driver and Goora's fee are decided in one place. Composes the twinned
/// [DirectPay] rules, so it needs no twin of its own.
final class SeatPrice {
  const SeatPrice({
    required this.contribution,
    required this.share,
    required this.fee,
    required this.mode,
    this.method = PaymentMethod.cash,
  });

  factory SeatPrice.of(int contribution,
      {required int tripCost,
      required int riderSeats,
      required PricingMode mode,
      PaymentMethod method = PaymentMethod.cash}) {
    final share = DirectPay.share(contribution, method: method, tripCost: tripCost, riderSeats: riderSeats);
    final fee = DirectPay.fee(contribution,
        share: share, tripCost: tripCost, riderSeats: riderSeats, feeFree: mode.isFeeFree);
    return SeatPrice(contribution: contribution, share: share, fee: fee, mode: mode, method: method);
  }

  /// The published contribution (what the price range is about).
  final int contribution;

  /// What the rider hands the driver directly: the 5-EGP cash amount when
  /// paying cash and one fits, otherwise [contribution]. Never Goora's money.
  final int share;

  /// Goora's service fee; 0 for trial, subscribed and company.
  final int fee;

  final PricingMode mode;
  final PaymentMethod method;

  /// Everything the rider pays for this trip: the share to the driver plus
  /// Goora's fee.
  int get total => share + fee;

  /// Stored as quoted: a request's or booking's price is fixed (FR-022), so it
  /// is never re-derived on read.
  Map<String, Object?> toJson() =>
      {'contribution': contribution, 'share': share, 'fee': fee, 'mode': mode.name, 'method': method.name};

  /// 004/005 rows carry `cash` and modes `cash`/`wallet`; they read as the
  /// trial and per-trip modes with the cash amount as the share.
  static SeatPrice fromJson(Map<String, Object?> j) {
    final contribution = j['contribution']! as int;
    final mode = switch (j['mode']! as String) {
      'cash' => PricingMode.trial,
      'wallet' => PricingMode.perTrip,
      final name => PricingMode.values.byName(name),
    };
    return SeatPrice(
      contribution: contribution,
      share: (j['share'] as int?) ?? (j['cash'] as int?) ?? contribution,
      fee: j['fee']! as int,
      mode: mode,
      method: PaymentMethod.parse((j['method'] as String?) ?? PaymentMethod.cash.name),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SeatPrice &&
      other.contribution == contribution &&
      other.share == share &&
      other.fee == fee &&
      other.mode == mode &&
      other.method == method;

  @override
  int get hashCode => Object.hash(contribution, share, fee, mode, method);
}
