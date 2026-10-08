import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/privacy.dart';

const home = GeoPoint(30.04, 30.98);
const work = GeoPoint(30.071, 31.017);

Member member(String id, MemberRole role, {bool woman = false, double rating = 5, double reliability = 100}) =>
    Member(id: id, firstName: id, initials: id, role: role, isWoman: woman, rating: rating, reliability: reliability);

CommuteGroup group({
  Clock going = const Clock.hm(7, 30),
  Clock ret = const Clock.hm(17, 0),
  GeoPoint? pickup,
  GeoPoint? destination,
  int detour = 0,
  Set<Day> days = CommuteProfile.defaultDays,
  int free = 2,
  List<Member>? members,
}) =>
    CommuteGroup(
      id: 'g',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: destination ?? work,
      pickupPoints: [pickup ?? home],
      going: going,
      ret: ret,
      days: days,
      members: members ?? [member('a', MemberRole.driver), member('b', MemberRole.rider)],
      price: 40,
      freeSeatsGoing: free,
      freeSeatsReturn: free,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: detour,
    );

Seeker seeker({Clock departure = const Clock.hm(7, 30), Set<Day> days = CommuteProfile.defaultDays}) => Seeker(
      role: MemberRole.rider,
      home: home,
      work: work,
      departure: departure,
      ret: const Clock.hm(17, 0),
      days: days,
      legs: const {Leg.going, Leg.ret},
    );

void main() {
  test('perfect fit without a shared company scores 90', () {
    final m = MatchingService.evaluate(seeker(), group())!;
    expect(m.factors.destination, 25);
    expect(m.factors.departure, 20);
    expect(m.factors.pickup, 15);
    expect(m.factors.ret, 10);
    expect(m.factors.days, 10);
    expect(m.factors.community, 0, reason: 'no shared company/compound');
    expect(m.factors.rating, 10);
    expect(m.score, 90);
  });

  test('departure points are linear: 0 → 20, 10 min → 10, 20 min → 0', () {
    double dep(int min) => MatchingService.evaluate(seeker(), group(going: const Clock.hm(7, 30).shift(min)))!.factors.departure;
    expect(dep(0), 20);
    expect(dep(10), 10);
    expect(dep(20), 0);
  });

  test('hard limits: 20 min passes, 21 min fails', () {
    expect(MatchingService.evaluate(seeker(), group(going: const Clock.hm(7, 50))), isNotNull);
    expect(MatchingService.evaluate(seeker(), group(going: const Clock.hm(7, 51), ret: const Clock.hm(19, 0))), isNull);
  });

  test('hard limits: detour 10 passes, 11 fails', () {
    expect(MatchingService.evaluate(seeker(), group(detour: 10)), isNotNull);
    expect(MatchingService.evaluate(seeker(), group(detour: 11)), isNull);
  });

  test('hard limits: pickup and destination distance (configurable)', () {
    const near = GeoPoint(30.0445, 30.98); // ≈ 500 m north of home
    final m = MatchingService.evaluate(seeker(), group(pickup: near))!;
    expect(m.pickupMeters, closeTo(500, 2));
    expect(m.factors.pickup, closeTo(7.5, 0.05));
    expect(
      MatchingService.evaluate(seeker(), group(pickup: near), limits: const MatchingLimits(pickupMeters: 400)),
      isNull,
    );
    const farDest = GeoPoint(30.086, 31.017); // ≈ 1.67 km
    expect(MatchingService.evaluate(seeker(), group(destination: farDest)), isNull);
  });

  test('no shared working day excludes; partial days scale linearly', () {
    expect(MatchingService.evaluate(seeker(), group(days: {Day.fri, Day.sat})), isNull);
    final m = MatchingService.evaluate(seeker(), group(days: {Day.sun, Day.mon}))!;
    expect(m.factors.days, 4); // 10 × 2/5
  });

  test('rider needs a free seat on the leg', () {
    expect(MatchingService.evaluate(seeker(), group(free: 0)), isNull);
  });

  test('reasons: top four by points; ties keep listing order', () {
    final m = MatchingService.evaluate(seeker(), group())!;
    // 25, 20, 15, then return/days/rating tie at 10 → return comes first.
    expect(m.reasons.map((r) => r.kind), [
      ReasonKind.destination,
      ReasonKind.departure,
      ReasonKind.pickup,
      ReasonKind.ret,
    ]);
    expect(m.reasons.first.area, Area.smartVillage);
  });

  test('no group → no match', () {
    expect(MatchingService.match(seeker(), const []).found, isFalse);
  });

  // Privacy preference → 002 constraints (FR-024). (`group` is this file's
  // group builder, so a plain block.)
  {
    Seeker withPreference(PrivacyPreference p, {bool woman = false, String? company, String? compound}) => Seeker(
          role: MemberRole.rider,
          home: home,
          work: work,
          departure: const Clock.hm(7, 30),
          ret: const Clock.hm(17, 0),
          days: CommuteProfile.defaultDays,
          legs: const {Leg.going, Leg.ret},
          isWoman: woman,
          company: company,
          compound: compound,
          womenOnly: p.wantsWomenOnly,
          sameCompanyOnly: p.wantsSameCompany,
          sameCompoundOnly: p.wantsSameCompound,
        );
    Member at(String id, {bool woman = false, String? company, String? compound}) => Member(
          id: id,
          firstName: id,
          initials: id,
          role: id == 'd' ? MemberRole.driver : MemberRole.rider,
          isWoman: woman,
          rating: 5,
          reliability: 100,
          company: company,
          compound: compound,
        );

    final mixed = group(members: [at('d'), at('r', woman: true)]);
    final women = group(members: [at('d', woman: true), at('r', woman: true)]);
    final valeo = group(members: [at('d', company: 'Valeo'), at('r', company: 'Valeo')]);
    final dunes = group(members: [at('d', compound: 'Dunes'), at('r', compound: 'Dunes')]);

    test('verified users (default) keeps every group', () {
      for (final g in [mixed, women, valeo, dunes]) {
        expect(MatchingService.evaluate(withPreference(PrivacyPreference.verifiedUsers, woman: true), g), isNotNull);
      }
    });

    test('women only excludes a group with a man', () {
      final s = withPreference(PrivacyPreference.womenOnly, woman: true);
      expect(MatchingService.evaluate(s, mixed), isNull);
      expect(MatchingService.evaluate(s, women), isNotNull);
    });

    test('same company excludes groups with anyone from another company', () {
      final s = withPreference(PrivacyPreference.sameCompany, company: 'Valeo');
      expect(MatchingService.evaluate(s, valeo), isNotNull);
      expect(MatchingService.evaluate(s, mixed), isNull);
      expect(MatchingService.evaluate(s, dunes), isNull);
    });

    test('same compound excludes groups with anyone from another compound', () {
      final s = withPreference(PrivacyPreference.sameCompound, compound: 'Dunes');
      expect(MatchingService.evaluate(s, dunes), isNotNull);
      expect(MatchingService.evaluate(s, valeo), isNull);
    });
  }
}
