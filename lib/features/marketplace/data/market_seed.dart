import '../../../core/time/wall_time.dart';
import '../../commute/data/cairo_ismailia_seed.dart';
import '../../commute/data/corridors.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/corridor.dart';
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
  /// The old corridor: the price basis (160 EGP a leg across 3 seats) its
  /// seeded rows share with its groups. Each corridor carries its own (006 T024).
  static const _old = Corridors.sheikhZayedSmartVillage;

  static const _contribution = 40;

  static const _pickupSz = GeoPoint(30.0427, 30.98);
  static const _pickupSv = GeoPoint(30.0719, 31.017);
  static const _pickupOct = GeoPoint(30.0131, 30.9512);

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

  /// Every seeded request of [corridor], all `posted`, each on its next
  /// workday. Both corridors have 12 morning + 4 evening rows (same ids), so
  /// counts and banners behave alike; the default is the old corridor.
  static List<TripRequest> requests(WallTime now, {Corridor corridor = Corridors.sheikhZayedSmartVillage}) =>
      _isCairoIsmailia(corridor)
      ? [
          for (final row in _morning) _cairoRequest(row, Leg.going, now),
          for (final row in _evening) _cairoRequest(row, Leg.ret, now),
        ]
      : [
          for (final row in _morning) _request(row, Leg.going, now),
          for (final row in _evening) _request(row, Leg.ret, now),
        ];

  static bool _isCairoIsmailia(Corridor c) => c.id == Corridors.cairoIsmailia.id;

  // Cairo ↔ Ismailia (006): the same 12 + 4 rows move 30 minutes earlier
  // (06:30–07:30 and 16:30–17:00 → 17:30) and run New Cairo → Ismailia in the
  // morning, Ismailia → New Cairo in the evening. A row's two detour numbers
  // spread over the five Cairo-side areas, so some drivers fit it (< 10) and
  // some do not. Contribution 76 = the suggested price at 300 EGP / 3 seats.

  static const _cairoShift = -30;
  static const _cairoContribution = 76;

  static TripRequest _cairoRequest(_RequestRow row, Leg leg, WallTime now) {
    final going = leg == Leg.going;
    const cairo = Corridors.cairoIsmailia;
    final departure = row.departure.shift(_cairoShift);
    final from = going ? Area.newCairo : Area.ismailia;
    return TripRequest(
      id: 'rq-seed-${row.id}',
      riderId: 'seed-${row.id}',
      rider: row.rider,
      leg: leg,
      from: from,
      to: going ? Area.ismailia : Area.newCairo,
      date: MarketDay.nextWorkday(departure, now),
      departure: departure,
      repeat: row.repeat,
      pickup: CairoIsmailiaSeed.stopIn(from, 'rq-stop-${row.id}', departure),
      detourFrom: {
        Area.newCairo: row.detourSheikhZayed,
        Area.nasrCity: row.detourSheikhZayed + 1,
        Area.heliopolis: row.detourOctober,
        Area.obour: row.detourSheikhZayed + 2,
        Area.tenthOfRamadan: row.detourOctober + 1,
        // Evening: the Ismailia driver's own detour; morning: they start there.
        Area.ismailia: going ? 0 : row.detourSheikhZayed,
      },
      price: quote(_cairoContribution, corridor: cairo),
    );
  }

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

  /// The per-trip quote a seeded request's rider was given.
  static SeatPrice quote(int contribution, {Corridor? corridor}) => SeatPrice.of(
    contribution,
    tripCost: (corridor ?? _old).tripCost,
    riderSeats: (corridor ?? _old).riderSeats,
    mode: PricingMode.perTrip,
  );

  // -------------------------------------------------------------- offers

  /// Tarek, "Just once" Sheikh Zayed → Smart Village 7:30, 3 seats at 44: a
  /// wallet rider sees 44 + 4 = 48, a cash rider 45 (FR-029).
  static const tarekId = 'of-seed-tarek';

  /// Heba, "Every workday" return 17:10, 3 seats at 40.
  static const hebaId = 'of-seed-heba';

  static List<OfferedTrip> offers(WallTime now, {Corridor corridor = Corridors.sheikhZayedSmartVillage}) =>
      _isCairoIsmailia(corridor) ? _cairoOffers(now) : _oldOffers(now);

  /// Tarek "Just once" New Cairo → Ismailia 06:45, 3 seats at 84; Heba "Every
  /// workday" Ismailia → New Cairo 17:00, 3 seats at 76 (both inside 62–90).
  static List<OfferedTrip> _cairoOffers(WallTime now) {
    const going = Clock.hm(6, 45);
    const back = Clock.hm(17, 0);
    const cairo = Corridors.cairoIsmailia;
    return [
      OfferedTrip(
        id: tarekId,
        driverId: 'tarek',
        leg: Leg.going,
        from: Area.newCairo,
        to: Area.ismailia,
        date: MarketDay.nextWorkday(going, now),
        departure: going,
        durationMinutes: cairo.tripMinutes(Area.newCairo, Area.ismailia),
        seats: cairo.riderSeats,
        riderSeats: cairo.riderSeats,
        tripCost: cairo.tripCost,
        contribution: 84,
        repeat: Repeat.once,
        pickup: CairoIsmailiaSeed.stopIn(Area.newCairo, 'of-stop-tarek', going),
      ),
      OfferedTrip(
        id: hebaId,
        driverId: 'heba',
        leg: Leg.ret,
        from: Area.ismailia,
        to: Area.newCairo,
        date: MarketDay.nextWorkday(back, now),
        departure: back,
        durationMinutes: cairo.tripMinutes(Area.ismailia, Area.newCairo),
        seats: cairo.riderSeats,
        riderSeats: cairo.riderSeats,
        tripCost: cairo.tripCost,
        contribution: 76,
        repeat: Repeat.daily,
        pickup: CairoIsmailiaSeed.stopIn(Area.ismailia, 'of-stop-heba', back),
      ),
    ];
  }

  static List<OfferedTrip> _oldOffers(WallTime now) => [
    OfferedTrip(
      id: tarekId,
      driverId: 'tarek',
      leg: Leg.going,
      from: Area.sheikhZayed,
      to: Area.smartVillage,
      date: MarketDay.nextWorkday(const Clock.hm(7, 30), now),
      departure: const Clock.hm(7, 30),
      seats: 3,
      riderSeats: _old.riderSeats,
      tripCost: _old.tripCost,
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
      riderSeats: _old.riderSeats,
      tripCost: _old.tripCost,
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

  /// The public meeting point a driver leaving [area] uses when they publish
  /// (never a home, FR-023): one fixed gate per area.
  static Stop pickupIn(Area area, String id, Clock time) => switch (area) {
    Area.sheikhZayed => Stop(id: id, name: StopName.mainGate, point: _pickupSz, time: time),
    Area.october => Stop(id: id, name: StopName.centralSt, point: _pickupOct, time: time),
    Area.smartVillage => Stop(id: id, name: StopName.smartVillageGate2, point: _pickupSv, time: time),
    _ => CairoIsmailiaSeed.stopIn(area, id, time),
  };

  /// A public point in [area], where a trip into it ends.
  static GeoPoint pointIn(Area area) => switch (area) {
    Area.sheikhZayed => _pickupSz,
    Area.october => _pickupOct,
    Area.smartVillage => _pickupSv,
    _ => CairoIsmailiaSeed.meetingPoints[area]!,
  };

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
