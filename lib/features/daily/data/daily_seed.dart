import '../../../core/time/calendar_date.dart';
import '../../commute/data/corridor_seed.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/geo.dart';
import '../../commute/domain/group.dart';
import '../domain/ride.dart';
import '../domain/trust.dart';

/// Fake daily-commute data on top of [CorridorSeed] (research R11).
abstract final class DailySeed {
  /// Member id of the person using the app.
  static const meId = 'me';

  /// Where seeded members board on the going leg (homes stay private; only
  /// the stop is known).
  static const memberStops = {
    'ahmed': 'main-gate',
    'sara': 'main-gate',
    'mohamed': 'central-st',
    'youssef': 'central-st',
  };

  /// Rating shown for the person until real ratings exist.
  static const myRating = 4.9;

  /// The person's past rides: the 7 ride days before [today], both legs,
  /// with one late cancel (the most recent going trip) → 13.5 kept of 14
  /// booked = 96 % (research R4, R11).
  static List<ReliabilityEvent> history(CommuteGroup g, CalendarDate today) {
    final events = <ReliabilityEvent>[];
    var date = today.addDays(-1);
    while (events.length < 14) {
      if (g.days.contains(date.weekday)) {
        for (final leg in Leg.values) {
          final late = events.isEmpty && leg == Leg.going;
          events.add(ReliabilityEvent(
            personId: meId,
            rideId: Ride.idFor(g.id, date, leg),
            date: date,
            kind: late ? ReliabilityEventKind.lateCancel : ReliabilityEventKind.kept,
          ));
        }
      }
      date = date.addDays(-1);
    }
    return events;
  }

  /// The person's company, known from their verified work email.
  static const company = 'Valeo';

  /// Fake verification statuses (FR-023a): phone, ID and work email are
  /// verified; license and vehicle are not needed for riders, verified for
  /// drivers, and not verified yet for a rider who just switched to driving.
  static List<VerificationItem> verification({required bool driver, bool docsPending = false}) {
    final docs = !driver
        ? VerificationStatus.notNeeded
        : docsPending
            ? VerificationStatus.notVerified
            : VerificationStatus.verified;
    return [
      const VerificationItem(VerificationKind.phone, VerificationStatus.verified),
      const VerificationItem(VerificationKind.nationalId, VerificationStatus.verified),
      const VerificationItem(VerificationKind.workEmail, VerificationStatus.verified),
      VerificationItem(VerificationKind.license, docs),
      VerificationItem(VerificationKind.vehicle, docs),
    ];
  }

  /// Drivers outside the corridor groups, for backup steps 3–4 (same
  /// company, same compound), with their own commute to Smart Village.
  /// Homes are approximate and never shown.
  static const networkDrivers = <({Member member, GeoPoint home, Clock going, Clock ret})>[
    (
      member: Member(
        id: 'tarek',
        firstName: 'Tarek',
        initials: 'TR',
        role: MemberRole.driver,
        isWoman: false,
        rating: 4.8,
        reliability: 97,
        company: company,
        seats: 3,
        vehicle: Vehicle(make: 'Kia Cerato', colour: VehicleColour.grey),
        phone: '+201000000011',
      ),
      home: GeoPoint(30.0432, 30.981),
      going: Clock.hm(7, 30),
      ret: Clock.hm(17, 0),
    ),
    (
      member: Member(
        id: 'heba',
        firstName: 'Heba',
        initials: 'HB',
        role: MemberRole.driver,
        isWoman: true,
        rating: 4.9,
        reliability: 98,
        compound: 'Beverly Hills',
        seats: 3,
        vehicle: Vehicle(make: 'Nissan Sunny', colour: VehicleColour.white),
        phone: '+201000000012',
      ),
      home: GeoPoint(30.0418, 30.9795),
      going: Clock.hm(7, 20),
      ret: Clock.hm(17, 10),
    ),
  ];

  /// sz-0725: the group the corridor defaults match (Ahmed, Mohamed, Sara, Youssef).
  static CommuteGroup get mainGroup => CorridorSeed.groups.firstWhere((g) => g.id == 'sz-0725');
}
