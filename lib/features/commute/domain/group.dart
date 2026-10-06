import '../../../core/time/calendar_date.dart';
import '../../daily/domain/privacy.dart';
import 'clock.dart';
import 'commute_profile.dart';
import 'geo.dart';
import 'place.dart';

enum MemberRole { driver, rider }

/// Named pickup / drop points (l10n); people see these, never home points.
enum StopName { mainGate, centralSt, gasStation, smartVillageGate2 }

/// A group pickup stop on the going leg, in driving order.
final class Stop {
  const Stop({required this.id, required this.name, required this.point, required this.time});

  final String id;
  final StopName name;

  /// Public meeting point (not a home).
  final GeoPoint point;
  final Clock time;
}

enum VehicleColour { white, silver, black, grey, red, blue }

final class Vehicle {
  const Vehicle({required this.make, required this.colour});

  /// Proper noun, shown as written (not translated).
  final String make;
  final VehicleColour colour;
}

final class Member {
  const Member({
    required this.id,
    required this.firstName,
    required this.initials,
    required this.role,
    required this.isWoman,
    required this.rating,
    required this.reliability,
    this.company,
    this.compound,
    this.legs = const {Leg.going, Leg.ret},
    this.seats,
    this.vehicle,
    this.phone,
    this.privacy = PrivacyPreference.verifiedUsers,
    this.days,
  });

  final String id;
  final String firstName;
  final String initials;
  final MemberRole role;
  final bool isWoman;
  final String? company;
  final String? compound;

  /// 0–5 stars.
  final double rating;

  /// 0–100 %.
  final double reliability;

  /// Legs this member rides (rider) or drives (driver).
  final Set<Leg> legs;

  /// Drivers only: seats offered (1–4).
  final int? seats;
  final Vehicle? vehicle;

  /// E.164; fake numbers in seed data.
  final String? phone;
  final PrivacyPreference privacy;

  /// Days this member commutes; null = the group's days.
  final Set<Day>? days;

  Set<Day> daysIn(CommuteGroup g) => days ?? g.days;
}

final class CommuteGroup {
  const CommuteGroup({
    required this.id,
    required this.origin,
    required this.destination,
    required this.destinationPoint,
    required this.pickupPoints,
    required this.going,
    required this.ret,
    required this.days,
    required this.members,
    required this.price,
    required this.freeSeatsGoing,
    required this.freeSeatsReturn,
    required this.detourMinutes,
    this.womenOnly = false,
    this.sameCompanyOnly,
    this.sameCompoundOnly,
    this.stops = const [],
    this.arrival,
    this.arrivalName,
    this.rotationStart,
  });

  final String id;
  final Area origin;
  final Area destination;
  final GeoPoint destinationPoint;
  final List<GeoPoint> pickupPoints;
  final Clock going;
  final Clock ret;
  final Set<Day> days;
  final List<Member> members;

  /// EGP per rider per trip, fixed for the month.
  final int price;
  final int freeSeatsGoing;
  final int freeSeatsReturn;

  /// Extra driving minutes to serve a new member's pickup point.
  final int detourMinutes;
  final bool womenOnly;

  /// When set, only people of this company / compound may join.
  final String? sameCompanyOnly;
  final String? sameCompoundOnly;

  /// Going-leg pickup stops in driving order; the last stop's time is [going].
  /// [pickupPoints] stays the matching input (002), so stops may add points.
  final List<Stop> stops;

  /// Arrival at work on the going leg, and where (also the return pickup).
  final Clock? arrival;
  final StopName? arrivalName;

  /// First Sunday of the 4-week rotation periods (research R5).
  final CalendarDate? rotationStart;

  Iterable<Member> get drivers => members.where((m) => m.role == MemberRole.driver);
  Iterable<Member> get riders => members.where((m) => m.role == MemberRole.rider);

  Clock timeFor(Leg leg) => leg == Leg.going ? going : ret;
  int freeSeats(Leg leg) => leg == Leg.going ? freeSeatsGoing : freeSeatsReturn;
  bool hasRidersOn(Leg leg) => riders.any((r) => r.legs.contains(leg));

  CommuteGroup withMembers(List<Member> members) => CommuteGroup(
        id: id,
        origin: origin,
        destination: destination,
        destinationPoint: destinationPoint,
        pickupPoints: pickupPoints,
        going: going,
        ret: ret,
        days: days,
        members: members,
        price: price,
        freeSeatsGoing: freeSeatsGoing,
        freeSeatsReturn: freeSeatsReturn,
        detourMinutes: detourMinutes,
        womenOnly: womenOnly,
        sameCompanyOnly: sameCompanyOnly,
        sameCompoundOnly: sameCompoundOnly,
        stops: stops,
        arrival: arrival,
        arrivalName: arrivalName,
        rotationStart: rotationStart,
      );

  /// Going stops; a group without named stops gets one at its first pickup
  /// point and going time.
  List<Stop> get goingStops =>
      stops.isNotEmpty ? stops : [Stop(id: 'stop-1', name: StopName.gasStation, point: pickupPoints.first, time: going)];

  /// The stop nearest [home]; only the stop is ever shown (constitution IV).
  Stop nearestStop(GeoPoint home) {
    var best = goingStops.first;
    for (final s in goingStops.skip(1)) {
      if (home.distanceTo(s.point) < home.distanceTo(best.point)) best = s;
    }
    return best;
  }

  /// Where the return leg starts (and the going leg ends).
  Stop get workStop => Stop(
        id: 'work',
        name: arrivalName ?? StopName.smartVillageGate2,
        point: destinationPoint,
        time: ret,
      );

  Clock get arrivalTime => arrival ?? going.shift(defaultTripMinutes);

  static const defaultTripMinutes = 40;

  Member? member(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Member? driverFor(Leg leg) {
    for (final d in drivers) {
      if (d.legs.contains(leg)) return d;
    }
    return null;
  }
}
