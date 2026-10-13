import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/geo.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../wallet/domain/payment_method.dart';
import '../../wallet/domain/seat_price.dart';
import '../domain/anonymous_rider.dart';
import '../domain/market_day.dart';
import '../domain/offered_trip.dart';
import '../domain/seat_offer.dart';
import '../domain/trip_request.dart';

/// A fake rider the demo actions book with ("A rider books your seat"). The
/// name is what a driver sees from departure on; before it only [rider] shows.
final class SeedRider {
  const SeedRider({required this.id, required this.firstName, required this.rider});

  final String id;
  final String firstName;
  final AnonymousRider rider;
}

/// Fake corridor market (005 research R14): 12 people who want Sheikh Zayed →
/// Smart Village in the morning, a few in the evening, two offers, and pools
/// of fake riders and drivers for the debug demo actions. Dates follow the
/// demo clock — seeded requests are always ahead of it and offers always in
/// the next running day, so the corridor never looks stale (R13).
abstract final class MarketSeed {
  /// The price basis every seeded request and offer shares with the corridor
  /// groups (160 EGP a leg across 3 seats).
  static const tripCost = 160;
  static const riderSeats = 3;

  static const _contribution = 40;

  static const _pickupSz = GeoPoint(30.0427, 30.98);
  static const _pickupSv = GeoPoint(30.0719, 31.017);

  // ------------------------------------------------------------ requests

  /// Morning requests, 7:00–8:00, Sheikh Zayed → Smart Village. Detour is
  /// the minutes a driver leaving each area adds; a request fits a driver at
  /// under 10 (R14). Sheikh Zayed drivers fit all 12; October ones fewer.
  static const _morning = <_RequestRow>[
    _RequestRow('m01', Clock.hm(7, 0), AnonymousRider(isWoman: true, rating: 4.9), Repeat.daily, 3, 11),
    _RequestRow('m02', Clock.hm(7, 5), AnonymousRider(isWoman: false, rating: 4.6), Repeat.once, 5, 9),
    _RequestRow('m03', Clock.hm(7, 10), AnonymousRider(isWoman: true), Repeat.once, 4, 8),
    _RequestRow('m04', Clock.hm(7, 15), AnonymousRider(isWoman: false, rating: 4.8), Repeat.daily, 6, 12),
    _RequestRow('m05', Clock.hm(7, 20), AnonymousRider(isWoman: false), Repeat.once, 2, 14),
    _RequestRow('m06', Clock.hm(7, 25), AnonymousRider(isWoman: true, rating: 4.7), Repeat.once, 7, 10),
    _RequestRow('m07', Clock.hm(7, 30), AnonymousRider(isWoman: false, rating: 4.5), Repeat.daily, 3, 7),
    _RequestRow('m08', Clock.hm(7, 35), AnonymousRider(isWoman: true, rating: 5), Repeat.once, 8, 13),
    _RequestRow('m09', Clock.hm(7, 40), AnonymousRider(isWoman: false), Repeat.once, 4, 6),
    _RequestRow('m10', Clock.hm(7, 45), AnonymousRider(isWoman: false, rating: 4.4), Repeat.daily, 9, 15),
    _RequestRow('m11', Clock.hm(7, 50), AnonymousRider(isWoman: true, rating: 4.8), Repeat.once, 5, 9),
    _RequestRow('m12', Clock.hm(8, 0), AnonymousRider(isWoman: false, rating: 4.6), Repeat.once, 6, 11),
  ];

  /// Evening requests, Smart Village → Sheikh Zayed.
  static const _evening = <_RequestRow>[
    _RequestRow('e01', Clock.hm(17, 0), AnonymousRider(isWoman: false, rating: 4.7), Repeat.once, 4, 10),
    _RequestRow('e02', Clock.hm(17, 15), AnonymousRider(isWoman: true, rating: 4.9), Repeat.daily, 6, 8),
    _RequestRow('e03', Clock.hm(17, 30), AnonymousRider(isWoman: false), Repeat.once, 3, 12),
    _RequestRow('e04', Clock.hm(18, 0), AnonymousRider(isWoman: true), Repeat.once, 7, 9),
  ];

  /// Every seeded request, all `posted`, each on its next workday.
  static List<TripRequest> requests(WallTime now) => [
    for (final row in _morning) _request(row, Leg.going, now),
    for (final row in _evening) _request(row, Leg.ret, now),
  ];

  static TripRequest _request(_RequestRow row, Leg leg, WallTime now) {
    final going = leg == Leg.going;
    return TripRequest(
      id: 'rq-seed-${row.id}',
      riderId: 'seed-${row.id}',
      rider: row.rider,
      leg: leg,
      from: going ? Area.sheikhZayed : Area.smartVillage,
      to: going ? Area.smartVillage : Area.sheikhZayed,
      date: MarketDay.nextWorkday(row.departure, now),
      departure: row.departure,
      repeat: row.repeat,
      pickup: Stop(
        id: 'rq-stop-${row.id}',
        name: going ? StopName.mainGate : StopName.smartVillageGate2,
        point: going ? _pickupSz : _pickupSv,
        time: row.departure,
      ),
      detourFrom: {
        Area.sheikhZayed: row.detourSheikhZayed,
        Area.october: row.detourOctober,
        Area.smartVillage: going ? 0 : row.detourSheikhZayed,
      },
      price: quote(_contribution),
    );
  }

  /// The wallet quote a seeded request's rider was given.
  static SeatPrice quote(int contribution) =>
      SeatPrice.of(contribution, tripCost: tripCost, riderSeats: riderSeats, mode: PricingMode.wallet);

  // -------------------------------------------------------------- offers

  /// Tarek, "Just once" Sheikh Zayed → Smart Village 7:30, 3 seats at 44: a
  /// wallet rider sees 44 + 4 = 48, a cash rider 45 (FR-029).
  static const tarekId = 'of-seed-tarek';

  /// Heba, "Every workday" return 17:10, 3 seats at 40.
  static const hebaId = 'of-seed-heba';

  static List<OfferedTrip> offers(WallTime now) => [
    OfferedTrip(
      id: tarekId,
      driverId: 'tarek',
      leg: Leg.going,
      from: Area.sheikhZayed,
      to: Area.smartVillage,
      date: MarketDay.nextWorkday(const Clock.hm(7, 30), now),
      departure: const Clock.hm(7, 30),
      seats: 3,
      riderSeats: riderSeats,
      tripCost: tripCost,
      contribution: 44,
      repeat: Repeat.once,
      pickup: const Stop(id: 'of-stop-tarek', name: StopName.mainGate, point: _pickupSz, time: Clock.hm(7, 30)),
    ),
    OfferedTrip(
      id: hebaId,
      driverId: 'heba',
      leg: Leg.ret,
      from: Area.smartVillage,
      to: Area.sheikhZayed,
      date: MarketDay.nextWorkday(const Clock.hm(17, 10), now),
      departure: const Clock.hm(17, 10),
      seats: 3,
      riderSeats: riderSeats,
      tripCost: tripCost,
      contribution: 40,
      repeat: Repeat.daily,
      pickup: const Stop(id: 'of-stop-heba', name: StopName.smartVillageGate2, point: _pickupSv, time: Clock.hm(17, 10)),
    ),
  ];

  // --------------------------------------------------------------- pools

  /// Fake drivers; the first two own the seeded offers. "A driver accepts
  /// your request" takes the next one in turn.
  static const drivers = <SeatDriver>[
    SeatDriver(id: 'tarek', firstName: 'Tarek', initials: 'TR', rating: 4.8),
    SeatDriver(id: 'heba', firstName: 'Heba', initials: 'HB', rating: 4.9, isWoman: true),
    SeatDriver(id: 'khaled', firstName: 'Khaled', initials: 'KH', rating: 4.7),
    SeatDriver(id: 'mariam', firstName: 'Mariam', initials: 'MR', rating: 4.8, isWoman: true),
  ];

  /// Fake riders; "A rider books your seat" takes the next one in turn.
  static const riders = <SeedRider>[
    SeedRider(id: 'seed-rider-nadia', firstName: 'Nadia', rider: AnonymousRider(isWoman: true, rating: 4.6)),
    SeedRider(id: 'seed-rider-omar', firstName: 'Omar', rider: AnonymousRider(isWoman: false, rating: 4.8)),
    SeedRider(id: 'seed-rider-salma', firstName: 'Salma', rider: AnonymousRider(isWoman: true)),
    SeedRider(id: 'seed-rider-hassan', firstName: 'Hassan', rider: AnonymousRider(isWoman: false, rating: 4.4)),
  ];

  static SeatDriver? driverById(String id) => drivers.where((d) => d.id == id).firstOrNull;

  static SeedRider? riderById(String id) => riders.where((r) => r.id == id).firstOrNull;

  /// A seeded request/offer id, which the stores overlay rather than own.
  static bool isSeedId(String id) => id.startsWith('rq-seed-') || id.startsWith('of-seed-');
}

final class _RequestRow {
  const _RequestRow(this.id, this.departure, this.rider, this.repeat, this.detourSheikhZayed, this.detourOctober);

  final String id;
  final Clock departure;
  final AnonymousRider rider;
  final Repeat repeat;
  final int detourSheikhZayed;
  final int detourOctober;
}
