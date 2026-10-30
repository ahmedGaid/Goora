import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/commute_repository.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';

/// A fresh CommuteRepository on the Cairo ↔ Ismailia corridor whose group
/// list holds [group].
typedef CommuteHarness = Future<CommuteRepository> Function(CommuteGroup group);

/// 011 contracts/seam-contracts.md — Commute (C1–C5).
void commuteContract(String label, CommuteHarness make) {
  const corridor = Corridors.cairoIsmailia;
  final seeded = Corridors.groupsOf(corridor).first;

  group('commute contract [$label]', () {
    test('C1 places are the corridor\'s', () async {
      final repo = await make(seeded);
      expect(repo.homePlaces().map((p) => p.id), corridor.homePlaces.map((p) => p.id));
      expect(repo.workPlaces().map((p) => p.id), corridor.workPlaces.map((p) => p.id));
    });

    test('C2 no profile, then the saved one comes back', () async {
      final repo = await make(seeded);
      expect(await repo.loadProfile(), isNull);
      final profile = CommuteProfile(
        home: corridor.homePlaces.first,
        work: corridor.workPlaces.first,
        departure: CommuteProfile.defaultDeparture,
        ret: CommuteProfile.defaultReturn,
        days: CommuteProfile.defaultDays,
        driver: const DriverOffer(seats: 3, trips: DrivenTrips.both, contribution: 60),
      );
      await repo.saveProfile(profile);
      expect((await repo.loadProfile())?.toJson(), profile.toJson());
    });

    test('C3 the route lists its group and no other route does', () async {
      final repo = await make(seeded);
      expect((await repo.groupsFor(seeded.origin, seeded.destination)).map((g) => g.id), contains(seeded.id));
      final other = Area.values.firstWhere((a) => a != seeded.origin && a != seeded.destination);
      expect((await repo.groupsFor(other, seeded.destination)).map((g) => g.id), isNot(contains(seeded.id)));
    });

    test('C4 an unknown group is refused; a known one is joined', () async {
      final repo = await make(seeded);
      expect(() => repo.join('no-such-group'), throwsArgumentError);
      expect(await repo.joinedGroupId(), isNull);
      await repo.join(seeded.id);
      expect(await repo.joinedGroupId(), seeded.id);
    });

    test('C5 a waitlist place, the same when asked twice', () async {
      final repo = await make(seeded);
      final first = await repo.joinWaitlist(seeded.origin, seeded.destination);
      expect(first, greaterThanOrEqualTo(1));
      expect(await repo.joinWaitlist(seeded.origin, seeded.destination), first);
    });
  });
}
