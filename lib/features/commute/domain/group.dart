import 'clock.dart';
import 'commute_profile.dart';
import 'geo.dart';
import 'place.dart';

enum MemberRole { driver, rider }

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

  Iterable<Member> get drivers => members.where((m) => m.role == MemberRole.driver);
  Iterable<Member> get riders => members.where((m) => m.role == MemberRole.rider);

  Clock timeFor(Leg leg) => leg == Leg.going ? going : ret;
  int freeSeats(Leg leg) => leg == Leg.going ? freeSeatsGoing : freeSeatsReturn;
  bool hasRidersOn(Leg leg) => riders.any((r) => r.legs.contains(leg));

  Member? driverFor(Leg leg) {
    for (final d in drivers) {
      if (d.legs.contains(leg)) return d;
    }
    return null;
  }
}
