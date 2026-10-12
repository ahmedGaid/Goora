import '../../../core/time/calendar_date.dart';
import '../domain/clock.dart';
import '../domain/commute_profile.dart';
import '../domain/geo.dart';
import '../domain/group.dart';
import '../domain/place.dart';

/// Fake launch-corridor data (Sheikh Zayed / 6th of October → Smart Village)
/// used until the Supabase backend is connected. Points are approximate area
/// centres, good enough for demo matching only.
abstract final class CorridorSeed {
  static const sheikhZayed = Place(id: 'home-sz', area: Area.sheikhZayed, point: GeoPoint(30.04, 30.98));
  static const october = Place(id: 'home-oct', area: Area.october, point: GeoPoint(29.97, 30.94));
  static const smartVillage = Place(id: 'work-sv', area: Area.smartVillage, point: GeoPoint(30.071, 31.017));

  static const homePlaces = [sheikhZayed, october];
  static const workPlaces = [smartVillage];

  /// People already on the corridor waitlist before the current user.
  static const waitlistAhead = 6;

  static const _weekdays = CommuteProfile.defaultDays;
  static const _destination = GeoPoint(30.0719, 31.017);

  /// Rotation periods start on this Sunday (research R5).
  static const rotationStart = CalendarDate.ymd(2026, 10, 4);

  /// sz-0725 pickup stops (prototype): Main Gate is the matching point (002);
  /// Central St. is the second stop, nearest to the Sheikh Zayed home.
  static const mainGate = Stop(id: 'main-gate', name: StopName.mainGate, point: GeoPoint(30.0427, 30.98), time: Clock.hm(7, 20));
  static const centralSt = Stop(id: 'central-st', name: StopName.centralSt, point: GeoPoint(30.0405, 30.9805), time: Clock.hm(7, 25));

  static const _ahmed = Member(
    id: 'ahmed',
    firstName: 'Ahmed',
    initials: 'AM',
    role: MemberRole.driver,
    isWoman: false,
    rating: 4.9,
    reliability: 97,
    seats: 4,
    vehicle: Vehicle(make: 'Toyota Corolla', colour: VehicleColour.white),
    phone: '+201000000001',
  );
  static const _mohamed = Member(
    id: 'mohamed',
    firstName: 'Mohamed',
    initials: 'MH',
    role: MemberRole.driver,
    isWoman: false,
    rating: 4.8,
    reliability: 96,
    seats: 4,
    vehicle: Vehicle(make: 'Hyundai Elantra', colour: VehicleColour.silver),
    phone: '+201000000002',
  );
  static const _sara = Member(
    id: 'sara',
    firstName: 'Sara',
    initials: 'SR',
    role: MemberRole.rider,
    isWoman: true,
    rating: 5,
    reliability: 98,
    phone: '+201000000003',
  );
  static const _youssef = Member(
    id: 'youssef',
    firstName: 'Youssef',
    initials: 'YS',
    role: MemberRole.rider,
    isWoman: false,
    rating: 4.7,
    reliability: 94,
    phone: '+201000000004',
  );

  static const groups = <CommuteGroup>[
    CommuteGroup(
      id: 'sz-0725',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: _destination,
      pickupPoints: [GeoPoint(30.0427, 30.98)],
      going: Clock.hm(7, 25),
      ret: Clock.hm(17, 0),
      days: _weekdays,
      members: [_ahmed, _mohamed, _sara, _youssef],
      price: 40,
      freeSeatsGoing: 1,
      freeSeatsReturn: 1,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 6,
      stops: [mainGate, centralSt],
      arrival: Clock.hm(8, 5),
      arrivalName: StopName.smartVillageGate2,
      rotationStart: rotationStart,
    ),
    CommuteGroup(
      id: 'sz-0740',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: GeoPoint(30.075, 31.017),
      pickupPoints: [GeoPoint(30.0472, 30.98)],
      going: Clock.hm(7, 40),
      ret: Clock.hm(17, 5),
      days: _weekdays,
      members: [
        Member(id: 'sara-d', firstName: 'Sara', initials: 'SR', role: MemberRole.driver, isWoman: true, rating: 4.9, reliability: 99),
        Member(id: 'nour', firstName: 'Nour', initials: 'NR', role: MemberRole.rider, isWoman: true, rating: 4.8, reliability: 95),
      ],
      price: 40,
      freeSeatsGoing: 2,
      freeSeatsReturn: 2,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 4,
      stops: [Stop(id: 'stop-1', name: StopName.gasStation, point: GeoPoint(30.0472, 30.98), time: Clock.hm(7, 40))],
      arrival: Clock.hm(8, 20),
      arrivalName: StopName.smartVillageGate2,
      rotationStart: rotationStart,
    ),
    CommuteGroup(
      id: 'sz-0715',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: _destination,
      pickupPoints: [GeoPoint(30.0463, 30.98)],
      going: Clock.hm(7, 15),
      ret: Clock.hm(17, 20),
      days: _weekdays,
      members: [
        Member(id: 'youssef-d', firstName: 'Youssef', initials: 'YS', role: MemberRole.driver, isWoman: false, rating: 4.7, reliability: 93),
        Member(id: 'karim', firstName: 'Karim', initials: 'KR', role: MemberRole.rider, isWoman: false, rating: 4.6, reliability: 92),
      ],
      price: 40,
      freeSeatsGoing: 1,
      freeSeatsReturn: 1,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 8,
      stops: [Stop(id: 'stop-1', name: StopName.gasStation, point: GeoPoint(30.0463, 30.98), time: Clock.hm(7, 15))],
      arrival: Clock.hm(7, 55),
      arrivalName: StopName.smartVillageGate2,
      rotationStart: rotationStart,
    ),
    CommuteGroup(
      id: 'sz-0720',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: _destination,
      pickupPoints: [GeoPoint(30.0436, 30.98)],
      going: Clock.hm(7, 20),
      ret: Clock.hm(17, 10),
      days: _weekdays,
      members: [
        Member(id: 'hassan', firstName: 'Hassan', initials: 'HS', role: MemberRole.driver, isWoman: false, rating: 4.8, reliability: 96),
        Member(id: 'mona', firstName: 'Mona', initials: 'MN', role: MemberRole.rider, isWoman: true, rating: 4.9, reliability: 97),
      ],
      price: 40,
      freeSeatsGoing: 2,
      freeSeatsReturn: 2,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 5,
      stops: [Stop(id: 'stop-1', name: StopName.gasStation, point: GeoPoint(30.0436, 30.98), time: Clock.hm(7, 20))],
      arrival: Clock.hm(8, 0),
      arrivalName: StopName.smartVillageGate2,
      rotationStart: rotationStart,
    ),
    CommuteGroup(
      id: 'oct-0700',
      origin: Area.october,
      destination: Area.smartVillage,
      destinationPoint: _destination,
      pickupPoints: [GeoPoint(29.9727, 30.94)],
      going: Clock.hm(7, 0),
      ret: Clock.hm(16, 45),
      days: _weekdays,
      members: [_mohamed, _youssef],
      price: 40,
      freeSeatsGoing: 2,
      freeSeatsReturn: 2,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 7,
      stops: [Stop(id: 'stop-1', name: StopName.gasStation, point: GeoPoint(29.9727, 30.94), time: Clock.hm(7, 0))],
      arrival: Clock.hm(7, 50),
      arrivalName: StopName.smartVillageGate2,
      rotationStart: rotationStart,
    ),
  ];
}
