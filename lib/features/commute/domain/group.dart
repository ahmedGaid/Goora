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

  Map<String, Object?> toJson() => {'id': id, 'name': name.name, 'point': point.toJson(), 'time': time.minutes};

  static Stop fromJson(Map<String, Object?> j) => Stop(
        id: j['id']! as String,
        name: StopName.values.byName(j['name']! as String),
        point: GeoPoint.fromJson(_map(j['point'])),
        time: Clock(j['time']! as int),
      );
}

enum VehicleColour { white, silver, black, grey, red, blue }

final class Vehicle {
  const Vehicle({required this.make, required this.colour});

  /// Proper noun, shown as written (not translated).
  final String make;
  final VehicleColour colour;

  Map<String, Object?> toJson() => {'make': make, 'colour': colour.name};

  static Vehicle fromJson(Map<String, Object?> j) =>
      Vehicle(make: j['make']! as String, colour: VehicleColour.values.byName(j['colour']! as String));
}

Map<String, Object?> _map(Object? o) => (o! as Map).cast<String, Object?>();

/// Sets are written in enum order, so the JSON is stable.
List<String> _names<T extends Enum>(List<T> all, Set<T> set) => [for (final v in all) if (set.contains(v)) v.name];

Set<T> _set<T extends Enum>(List<T> all, Object? names) => {for (final n in (names! as List).cast<String>()) all.byName(n)};

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

  PersonFacts get facts => PersonFacts(isWoman: isWoman, company: company, compound: compound);

  Map<String, Object?> toJson() => {
        'id': id,
        'firstName': firstName,
        'initials': initials,
        'role': role.name,
        'isWoman': isWoman,
        'company': company,
        'compound': compound,
        'rating': rating,
        'reliability': reliability,
        'legs': _names(Leg.values, legs),
        'seats': seats,
        'vehicle': vehicle?.toJson(),
        'phone': phone,
        'privacy': privacy.name,
        'days': days == null ? null : _names(Day.values, days!),
      };

  static Member fromJson(Map<String, Object?> j) => Member(
        id: j['id']! as String,
        firstName: j['firstName']! as String,
        initials: j['initials']! as String,
        role: MemberRole.values.byName(j['role']! as String),
        isWoman: j['isWoman']! as bool,
        company: j['company'] as String?,
        compound: j['compound'] as String?,
        rating: (j['rating']! as num).toDouble(),
        reliability: (j['reliability']! as num).toDouble(),
        legs: _set(Leg.values, j['legs']),
        seats: j['seats'] as int?,
        vehicle: j['vehicle'] == null ? null : Vehicle.fromJson(_map(j['vehicle'])),
        phone: j['phone'] as String?,
        privacy: PrivacyPreference.values.byName(j['privacy']! as String),
        days: j['days'] == null ? null : _set(Day.values, j['days']),
      );
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
    required this.tripCost,
    required this.riderSeats,
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

  /// EGP per leg for the whole car (004 v2.1 research R15).
  final int tripCost;

  /// Seats the car's fare is split across, 1–4 (004 v2.1 research R15).
  final int riderSeats;

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
        tripCost: tripCost,
        riderSeats: riderSeats,
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

  int get tripMinutes => arrivalTime.minutes - going.minutes;

  /// When the [leg] trip arrives, before any reported delay.
  Clock endFor(Leg leg) => leg == Leg.going ? arrivalTime : ret.shift(tripMinutes);

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

  /// Legs this group runs: those any member rides or drives. A group the
  /// marketplace created runs one leg only (005 research R10).
  Set<Leg> get legs => {for (final m in members) ...m.legs};

  Map<String, Object?> toJson() => {
        'id': id,
        'origin': origin.name,
        'destination': destination.name,
        'destinationPoint': destinationPoint.toJson(),
        'pickupPoints': [for (final p in pickupPoints) p.toJson()],
        'going': going.minutes,
        'ret': ret.minutes,
        'days': _names(Day.values, days),
        'members': [for (final m in members) m.toJson()],
        'price': price,
        'freeSeatsGoing': freeSeatsGoing,
        'freeSeatsReturn': freeSeatsReturn,
        'tripCost': tripCost,
        'riderSeats': riderSeats,
        'detourMinutes': detourMinutes,
        'womenOnly': womenOnly,
        'sameCompanyOnly': sameCompanyOnly,
        'sameCompoundOnly': sameCompoundOnly,
        'stops': [for (final s in stops) s.toJson()],
        'arrival': arrival?.minutes,
        'arrivalName': arrivalName?.name,
        'rotationStart': rotationStart?.toIso(),
      };

  static CommuteGroup fromJson(Map<String, Object?> j) => CommuteGroup(
        id: j['id']! as String,
        origin: Area.values.byName(j['origin']! as String),
        destination: Area.values.byName(j['destination']! as String),
        destinationPoint: GeoPoint.fromJson(_map(j['destinationPoint'])),
        pickupPoints: [for (final p in j['pickupPoints']! as List) GeoPoint.fromJson(_map(p))],
        going: Clock(j['going']! as int),
        ret: Clock(j['ret']! as int),
        days: _set(Day.values, j['days']),
        members: [for (final m in j['members']! as List) Member.fromJson(_map(m))],
        price: j['price']! as int,
        freeSeatsGoing: j['freeSeatsGoing']! as int,
        freeSeatsReturn: j['freeSeatsReturn']! as int,
        tripCost: j['tripCost']! as int,
        riderSeats: j['riderSeats']! as int,
        detourMinutes: j['detourMinutes']! as int,
        womenOnly: j['womenOnly']! as bool,
        sameCompanyOnly: j['sameCompanyOnly'] as String?,
        sameCompoundOnly: j['sameCompoundOnly'] as String?,
        stops: [for (final s in j['stops']! as List) Stop.fromJson(_map(s))],
        arrival: j['arrival'] == null ? null : Clock(j['arrival']! as int),
        arrivalName: j['arrivalName'] == null ? null : StopName.values.byName(j['arrivalName']! as String),
        rotationStart: j['rotationStart'] == null ? null : CalendarDate.parse(j['rotationStart']! as String),
      );
}
