import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../wallet/data/providers.dart';
import '../../data/providers.dart';
import '../../domain/booking.dart';
import '../../domain/seat_offer.dart';

part 'empty_seats_controller.g.dart';

/// The free seats on [leg] for the viewing rider (A). Re-read after every
/// booking so a taken seat leaves the list, and when the rider's way of paying
/// changes, since it sets every price line (T104 F6).
@riverpod
Future<List<SeatOffer>> seatOffers(Ref ref, Leg leg) async {
  await ref.watch(riderPricingProvider.future);
  return ref.watch(marketplaceRepositoryProvider).seatOffers(leg, now: ref.read(nowProvider)());
}

/// Stable key for one seat: carried in the `seat=` query across PayMethod.
String seatKey(SeatOffer o) => '${o.source.kind.name}:${o.source.id}:${o.date.toIso()}:${o.leg.name}';

/// The rider's live bookings, oldest first.
@riverpod
Future<List<Booking>> myBookings(Ref ref) =>
    ref.watch(marketplaceRepositoryProvider).myBookings(now: ref.watch(nowProvider)());
