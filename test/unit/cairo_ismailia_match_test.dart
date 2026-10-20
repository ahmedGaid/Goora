import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';

/// 006 T030: the seeded Cairo ↔ Ismailia groups through the real matching
/// service, one test per direction (limits unchanged).
void main() {
  Seeker rider(
    Place home,
    Place work,
    Clock departure, {
    Clock ret = const Clock.hm(17, 0),
    Set<Leg> legs = const {Leg.going, Leg.ret},
    bool woman = false,
  }) =>
      Seeker(
        role: MemberRole.rider,
        home: home.point,
        work: work.point,
        departure: departure,
        ret: ret,
        days: CommuteProfile.defaultDays,
        legs: legs,
        isWoman: woman,
      );

  // The old corridor's groups ride along, so a match cannot come from them.
  final all = [...CorridorSeed.groups, ...CairoIsmailiaSeed.groups];

  test('New Cairo → Ismailia: matches the 06:30 group, both legs', () {
    final r = MatchingService.match(
      rider(CairoIsmailiaSeed.homeNewCairo, CairoIsmailiaSeed.workIsmailia, const Clock.hm(6, 30), ret: const Clock.hm(16, 30)),
      all,
    );
    expect(r.found, isTrue);
    expect(r.main!.group.id, 'ci-nc-0630');
    expect(r.main!.legs, {Leg.going, Leg.ret});
    expect(r.returnMatch, isNull);
  });

  test('Ismailia → Nasr City: matches a group per departure time', () {
    final early = MatchingService.match(
      rider(CairoIsmailiaSeed.homeIsmailia, CairoIsmailiaSeed.workNasrCity, const Clock.hm(6, 30), ret: const Clock.hm(16, 30)),
      all,
    );
    expect(early.found, isTrue);
    expect(early.main!.group.id, 'ci-nasr-0630');

    final late = MatchingService.match(
      rider(CairoIsmailiaSeed.homeIsmailia, CairoIsmailiaSeed.workNasrCity, const Clock.hm(7, 30), ret: const Clock.hm(17, 30)),
      all,
    );
    expect(late.found, isTrue);
    expect(late.main!.group.id, 'ci-nasr-0730');
  });

  test('every seeded group with a free seat is found by a rider on its own route and time', () {
    for (final g in CairoIsmailiaSeed.groups.where((g) => g.freeSeatsGoing > 0)) {
      final home = [...CairoIsmailiaSeed.homePlaces].firstWhere((p) => p.area == g.origin);
      final work = [...CairoIsmailiaSeed.workPlaces].firstWhere((p) => p.area == g.destination, orElse: () => home);
      // Road towns are homes only; a rider to one skips the work-place lookup.
      if (work.area != g.destination) continue;
      final r = MatchingService.match(
        rider(home, work, g.going, ret: g.ret, woman: g.womenOnly),
        all,
      );
      expect(r.found, isTrue, reason: g.id);
      expect(r.main!.group.id, g.id);
    }
  });

  test('Heliopolis home, time with no group: no match', () {
    final r = MatchingService.match(
      rider(CairoIsmailiaSeed.homeHeliopolis, CairoIsmailiaSeed.workIsmailia, const Clock.hm(10, 0), ret: const Clock.hm(20, 0), woman: true),
      all,
    );
    expect(r.found, isFalse);
  });

  test('Heliopolis → Ismailia at the women-only time: a man gets no match, a woman does', () {
    final man = MatchingService.match(
      rider(CairoIsmailiaSeed.homeHeliopolis, CairoIsmailiaSeed.workIsmailia, const Clock.hm(7, 0)),
      all,
    );
    expect(man.found, isFalse);

    final woman = MatchingService.match(
      rider(CairoIsmailiaSeed.homeHeliopolis, CairoIsmailiaSeed.workIsmailia, const Clock.hm(7, 0), woman: true),
      all,
    );
    expect(woman.found, isTrue);
    expect(woman.main!.group.id, 'ci-heli-0700');
  });

  test('a full car is not offered to a rider (waitlist demo)', () {
    for (final id in ['ci-obour-0715', 'ci-nc-0715']) {
      final g = CairoIsmailiaSeed.groups.firstWhere((g) => g.id == id);
      final home = CairoIsmailiaSeed.homePlaces.firstWhere((p) => p.area == g.origin);
      final work = CairoIsmailiaSeed.workPlaces.firstWhere((p) => p.area == g.destination);
      final r = MatchingService.match(rider(home, work, g.going, ret: g.ret), CairoIsmailiaSeed.groups);
      expect(r.found, isFalse, reason: id);
    }
  });

  test('a rider on the old corridor never matches a Cairo ↔ Ismailia group', () {
    final r = MatchingService.match(
      Seeker(
        role: MemberRole.rider,
        home: CorridorSeed.sheikhZayed.point,
        work: CorridorSeed.smartVillage.point,
        departure: const Clock.hm(7, 25),
        ret: const Clock.hm(17, 0),
        days: CommuteProfile.defaultDays,
        legs: const {Leg.going, Leg.ret},
      ),
      CairoIsmailiaSeed.groups,
    );
    expect(r.found, isFalse);
  });
}
