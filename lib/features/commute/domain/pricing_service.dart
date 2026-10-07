import 'commute_profile.dart';

/// Trip-cost inputs. Real rates are an open item (brief §8), so they stay
/// behind [ratesEnabled]; until then the launch corridor uses [demoCorridorCost].
final class TripCostConfig {
  const TripCostConfig({
    this.ratesEnabled = false,
    this.egpPerKm = 0,
    this.tollsEgp = 0,
    this.demoCorridorCost = 160,
  });

  final bool ratesEnabled;
  final double egpPerKm;
  final int tollsEgp;

  /// Founder decision 2026-10-05: 160 ÷ (3 + 1) = 40, the brief's demo.
  final int demoCorridorCost;
}

final class PriceRange {
  const PriceRange({required this.min, required this.suggested, required this.max});

  final int min;
  final int suggested;
  final int max;

  bool contains(int price) => price >= min && price <= max;
}

/// Cost-sharing rules from brief §6.2. Drivers recover costs; they never profit.
abstract final class PricingService {
  static const step = 2;
  static const rangePercent = 20;

  static int tripCost(TripCostConfig config, {double? routeKm}) {
    if (config.ratesEnabled && routeKm != null) {
      return (routeKm * config.egpPerKm).round() + config.tollsEgp;
    }
    return config.demoCorridorCost;
  }

  /// trip cost ÷ (riders + 1), rounded to the nearest 2 EGP.
  static int suggested(int tripCost, int riders) => (tripCost / ((riders + 1) * step)).round() * step;

  /// ±20 % of the suggestion in 2 EGP steps, and never more than an equal
  /// share of the whole trip cost (riders' total ≤ trip cost).
  static PriceRange range(int tripCost, int riders) {
    final s = suggested(tripCost, riders);
    const unit = 100 * step;
    final min = ((s * (100 - rangePercent) + unit - 1) ~/ unit) * step;
    final upper = (s * (100 + rangePercent) ~/ unit) * step;
    final cap = (tripCost ~/ (riders * step)) * step;
    return PriceRange(min: min, suggested: s, max: upper < cap ? upper : cap);
  }

  static int snap(int price, PriceRange r) => price < r.min ? r.min : (price > r.max ? r.max : price);

  static int recoveryPerDay(int seats, int price, DrivenTrips trips) => seats * price * trips.tripsPerDay;

  /// Positive = above suggested, negative = below, 0 = the suggested price.
  static int deltaFromSuggested(int price, PriceRange r) => price - r.suggested;

  /// Goora's per-trip service fee (brief §6.7 A). The contribution still goes
  /// to the driver in full; the fee is on top, never part of the trip cost the
  /// cap above protects (004 spec "Constitution II reading").
  static const feeRatePercent = 10;

  /// 10% of the contribution, nearest whole EGP, halves up (004 research R6);
  /// 0 for subscribers, company-plan riders and cash trips.
  static int serviceFee(int contribution, {required bool isSubscriber, required bool isCashTrial}) {
    if (isSubscriber || isCashTrial) return 0;
    return (contribution * feeRatePercent + 50) ~/ 100;
  }

  /// What the rider pays for one trip: 40 → 44, or 40 when fee-free.
  static int riderTotal(int contribution, {required bool isSubscriber, required bool isCashTrial}) =>
      contribution + serviceFee(contribution, isSubscriber: isSubscriber, isCashTrial: isCashTrial);
}
