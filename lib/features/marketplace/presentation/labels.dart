import '../../../core/l10n/app_localizations.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/presentation/labels.dart';
import '../../daily/presentation/labels.dart';
import '../domain/seat_offer.dart';

/// Marketplace text. The price line is `WalletLabels.priceLine(SeatPrice)` —
/// one line for every trip, by the rider's arrangement (FR-004).
extension MarketplaceLabels on AppLocalizations {
  /// "Today · 7:25 AM" · "Tomorrow · 7:25 AM" · "Sun · 7:25 AM".
  String seatWhen(SeatOffer offer, WallTime now) => '${heroWhen(offer.date, now.date)} · ${time(offer.departure)}';

  /// The pickup stop and its time, "Pickup · 7:20 AM — Sheikh Zayed".
  String seatPickup(SeatOffer offer) => '${tlPickup(time(offer.pickup.time))} — ${stopName(offer.pickup.name)}';
}
