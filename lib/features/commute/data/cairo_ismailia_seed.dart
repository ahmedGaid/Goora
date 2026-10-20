import '../domain/clock.dart';
import '../domain/commute_profile.dart';
import '../domain/geo.dart';
import '../domain/group.dart';
import '../domain/place.dart';
import 'corridor_seed.dart';

/// Cairo ↔ Ismailia launch corridor (006): one place and one named meeting
/// point per area, plus the demo groups. Points are approximate area centres,
/// recalled (not map-checked, research R7), used only for matching distances
/// and never shown.
abstract final class CairoIsmailiaSeed {
  static const _newCairo = GeoPoint(30.03, 31.47); // recalled
  static const _nasrCity = GeoPoint(30.06, 31.34); // recalled
  static const _heliopolis = GeoPoint(30.09, 31.32); // recalled
  static const _obour = GeoPoint(30.23, 31.48); // recalled
  static const _tenthOfRamadan = GeoPoint(30.29, 31.75); // recalled
  static const _ismailia = GeoPoint(30.60, 32.27); // recalled

  static const homeNewCairo = Place(id: 'home-nc', area: Area.newCairo, point: _newCairo);
  static const homeNasrCity = Place(id: 'home-nasr', area: Area.nasrCity, point: _nasrCity);
  static const homeHeliopolis = Place(id: 'home-heli', area: Area.heliopolis, point: _heliopolis);
  static const homeObour = Place(id: 'home-obour', area: Area.obour, point: _obour);
  static const homeTenthOfRamadan = Place(id: 'home-10r', area: Area.tenthOfRamadan, point: _tenthOfRamadan);
  static const homeIsmailia = Place(id: 'home-ism', area: Area.ismailia, point: _ismailia);

  static const workNewCairo = Place(id: 'work-nc', area: Area.newCairo, point: _newCairo);
  static const workNasrCity = Place(id: 'work-nasr', area: Area.nasrCity, point: _nasrCity);
  static const workHeliopolis = Place(id: 'work-heli', area: Area.heliopolis, point: _heliopolis);
  static const workIsmailia = Place(id: 'work-ism', area: Area.ismailia, point: _ismailia);

  static const homePlaces = [homeNewCairo, homeNasrCity, homeHeliopolis, homeObour, homeTenthOfRamadan, homeIsmailia];

  /// Obour and 10th of Ramadan are road towns: homes, not workplaces.
  static const workPlaces = [workNewCairo, workNasrCity, workHeliopolis, workIsmailia];

  /// The public meeting point of each area (never a home): a named spot a few
  /// hundred metres from the area centre (the home point), so the walk is real,
  /// never 0 m. Its name is [StopName.meetingPointOf].
  static const meetingPoints = <Area, GeoPoint>{
    Area.newCairo: GeoPoint(30.0335, 31.4730),
    Area.nasrCity: GeoPoint(30.0640, 31.3460),
    Area.heliopolis: GeoPoint(30.0925, 31.3235),
    Area.obour: GeoPoint(30.2270, 31.4850),
    Area.tenthOfRamadan: GeoPoint(30.2940, 31.7540),
    Area.ismailia: GeoPoint(30.6030, 32.2740),
  };

  /// Demo groups (T027): 4 each way, 300 EGP a leg across 3 seats, 76 a rider
  /// (inside the 62–90 range, research R2). Going 06:30–07:30, return
  /// 16:30–17:30, Sun–Thu. Per direction: one women-only group and one full
  /// car (the waitlist demo). Seats: riders on a leg + free seats ≤ 3.
  static final groups = <CommuteGroup>[
    // Cairo side → Ismailia.
    _group(
      id: 'ci-nc-0630',
      origin: Area.newCairo,
      destination: Area.ismailia,
      going: const Clock.hm(6, 30),
      ret: const Clock.hm(16, 30),
      free: 1,
      detour: 5,
      members: [_driver('hany', 'Hany', 'HN', 'Toyota Corolla', VehicleColour.white), _rider('mazen', 'Mazen', 'MZ'), _rider('dina', 'Dina', 'DN', woman: true)],
    ),
    _group(
      id: 'ci-heli-0700',
      origin: Area.heliopolis,
      destination: Area.ismailia,
      going: const Clock.hm(7, 0),
      ret: const Clock.hm(17, 0),
      free: 2,
      detour: 4,
      womenOnly: true,
      members: [_driver('rania', 'Rania', 'RN', 'Hyundai Elantra', VehicleColour.silver, woman: true), _rider('yara', 'Yara', 'YR', woman: true)],
    ),
    _group(
      id: 'ci-obour-0715',
      origin: Area.obour,
      destination: Area.ismailia,
      going: const Clock.hm(7, 15),
      ret: const Clock.hm(17, 15),
      free: 0,
      detour: 6,
      members: [
        _driver('adel', 'Adel', 'AD', 'Kia Cerato', VehicleColour.black),
        _rider('tamer', 'Tamer', 'TM'),
        _rider('lamia', 'Lamia', 'LM', woman: true),
        _rider('walid', 'Walid', 'WL'),
      ],
    ),
    _group(
      id: 'ci-10r-0730',
      origin: Area.tenthOfRamadan,
      destination: Area.ismailia,
      going: const Clock.hm(7, 30),
      ret: const Clock.hm(17, 30),
      free: 2,
      detour: 7,
      members: [_driver('sherif', 'Sherif', 'SH', 'Nissan Sunny', VehicleColour.grey), _rider('hoda', 'Hoda', 'HD', woman: true)],
    ),
    // Ismailia → Cairo side.
    _group(
      id: 'ci-nasr-0630',
      origin: Area.ismailia,
      destination: Area.nasrCity,
      going: const Clock.hm(6, 30),
      ret: const Clock.hm(16, 30),
      free: 1,
      detour: 5,
      members: [_driver('essam', 'Essam', 'ES', 'Chevrolet Optra', VehicleColour.white), _rider('nabil', 'Nabil', 'NB'), _rider('salwa', 'Salwa', 'SW', woman: true)],
    ),
    _group(
      id: 'ci-heli-0700-r',
      origin: Area.ismailia,
      destination: Area.heliopolis,
      going: const Clock.hm(7, 0),
      ret: const Clock.hm(17, 0),
      free: 2,
      detour: 4,
      womenOnly: true,
      members: [_driver('mervat', 'Mervat', 'MV', 'Toyota Yaris', VehicleColour.red, woman: true), _rider('nesma', 'Nesma', 'NS', woman: true)],
    ),
    _group(
      id: 'ci-nc-0715',
      origin: Area.ismailia,
      destination: Area.newCairo,
      going: const Clock.hm(7, 15),
      ret: const Clock.hm(17, 15),
      free: 0,
      detour: 6,
      members: [
        _driver('magdy', 'Magdy', 'MG', 'Hyundai Accent', VehicleColour.silver),
        _rider('ramy', 'Ramy', 'RM'),
        _rider('shaimaa', 'Shaimaa', 'SM', woman: true),
        _rider('fady', 'Fady', 'FD'),
      ],
    ),
    _group(
      id: 'ci-nasr-0730',
      origin: Area.ismailia,
      destination: Area.nasrCity,
      going: const Clock.hm(7, 30),
      ret: const Clock.hm(17, 30),
      free: 2,
      detour: 8,
      members: [_driver('ashraf', 'Ashraf', 'AS', 'Kia Picanto', VehicleColour.blue), _rider('manar', 'Manar', 'MN', woman: true)],
    ),
  ];

  static CommuteGroup _group({
    required String id,
    required Area origin,
    required Area destination,
    required Clock going,
    required Clock ret,
    required int free,
    required int detour,
    required List<Member> members,
    bool womenOnly = false,
  }) {
    final minutes = tripMinutes(origin, destination);
    return CommuteGroup(
      id: id,
      origin: origin,
      destination: destination,
      destinationPoint: meetingPoints[destination]!,
      pickupPoints: [meetingPoints[origin]!],
      going: going,
      ret: ret,
      days: CommuteProfile.defaultDays,
      members: members,
      price: 76,
      freeSeatsGoing: free,
      freeSeatsReturn: free,
      tripCost: 300,
      riderSeats: 3,
      detourMinutes: detour,
      womenOnly: womenOnly,
      stops: [stopIn(origin, 'stop-1', going)],
      arrival: going.shift(minutes),
      rotationStart: CorridorSeed.rotationStart,
    );
  }

  static Member _driver(String id, String name, String initials, String make, VehicleColour colour, {bool woman = false}) => Member(
        id: id,
        firstName: name,
        initials: initials,
        role: MemberRole.driver,
        isWoman: woman,
        rating: 4.8,
        reliability: 96,
        seats: 4,
        vehicle: Vehicle(make: make, colour: colour),
      );

  static Member _rider(String id, String name, String initials, {bool woman = false}) => Member(
        id: id,
        firstName: name,
        initials: initials,
        role: MemberRole.rider,
        isWoman: woman,
        rating: 4.7,
        reliability: 95,
      );

  /// The meeting point in [area] as a stop at [time].
  static Stop stopIn(Area area, String id, Clock time) =>
      Stop(id: id, name: StopName.meetingPointOf(area), point: meetingPoints[area]!, time: time);

  /// Cairo district ↔ Ismailia 105 min (middle of the verified 1h30–2h band,
  /// R1); road town ↔ Ismailia 90; anywhere on the Cairo side 30.
  static int tripMinutes(Area from, Area to) {
    if (from == to) return 0;
    if (from != Area.ismailia && to != Area.ismailia) return 30;
    final other = from == Area.ismailia ? to : from;
    return other == Area.obour || other == Area.tenthOfRamadan ? 90 : 105;
  }
}
