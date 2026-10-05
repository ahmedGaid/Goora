import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/place.dart';

void main() {
  const valid = CommuteProfile(
    home: CorridorSeed.sheikhZayed,
    work: CorridorSeed.smartVillage,
    departure: CommuteProfile.defaultDeparture,
    ret: CommuteProfile.defaultReturn,
    days: CommuteProfile.defaultDays,
  );

  test('a complete corridor profile has no problem', () => expect(valid.problem, isNull));

  test('missing home or work', () {
    const noHome = CommuteProfile(
      home: null,
      work: CorridorSeed.smartVillage,
      departure: CommuteProfile.defaultDeparture,
      ret: CommuteProfile.defaultReturn,
      days: CommuteProfile.defaultDays,
    );
    expect(noHome.problem, CommuteProblem.missingPlace);
  });

  test('home and work within 1.5 km', () {
    const nearWork = Place(id: 'near', area: Area.sheikhZayed, point: GeoPoint(30.05, 30.98)); // ≈ 1.1 km
    expect(valid.copyWith(work: nearWork).problem, CommuteProblem.sameArea);
  });

  test('no working day', () => expect(valid.copyWith(days: {}).problem, CommuteProblem.noDays));

  test('return must be after departure', () {
    expect(valid.copyWith(ret: CommuteProfile.defaultDeparture).problem, CommuteProblem.returnBeforeDeparture);
    expect(valid.copyWith(ret: const Clock.hm(7, 0)).problem, CommuteProblem.returnBeforeDeparture);
  });

  test('JSON round-trip keeps every field, including the driver offer', () {
    final p = valid.copyWith(
      driver: const DriverOffer(seats: 2, trips: DrivenTrips.going, contribution: 46),
    );
    final back = CommuteProfile.fromJson(p.toJson());
    expect(back.home!.id, 'home-sz');
    expect(back.work!.area, Area.smartVillage);
    expect(back.departure, CommuteProfile.defaultDeparture);
    expect(back.days, CommuteProfile.defaultDays);
    expect(back.driver!.trips, DrivenTrips.going);
    expect(back.driver!.contribution, 46);
  });

  test('clock formats with Western digits and clamps within the day', () {
    expect(const Clock.hm(7, 5).h12, '7:05');
    expect(const Clock.hm(17, 0).h12, '5:00');
    expect(const Clock.hm(0, 0).h12, '12:00');
    expect(const Clock.hm(23, 58).shift(5).minutes, Clock.minutesPerDay - 1);
    expect(const Clock.hm(0, 2).shift(-5).minutes, 0);
  });
}
