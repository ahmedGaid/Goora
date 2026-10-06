import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/matching_service.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/backup_service.dart';
import 'package:goora/features/daily/domain/privacy.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/schedule.dart';

const pickup = GeoPoint(30.04, 30.98);
const work = GeoPoint(30.071, 31.017);
final tue = CalendarDate(2026, 10, 6);

Member person(
  String id, {
  MemberRole role = MemberRole.driver,
  bool woman = false,
  double rating = 4.8,
  PrivacyPreference privacy = PrivacyPreference.verifiedUsers,
}) =>
    Member(
      id: id,
      firstName: id,
      initials: id,
      role: role,
      isWoman: woman,
      rating: rating,
      reliability: 100,
      privacy: privacy,
    );

CommuteGroup group(List<Member> riders) => CommuteGroup(
      id: 'g',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: work,
      pickupPoints: const [pickup],
      going: const Clock.hm(7, 30),
      ret: const Clock.hm(17, 0),
      days: CommuteProfile.defaultDays,
      members: [person('planned'), person('offduty'), ...riders],
      price: 40,
      freeSeatsGoing: 1,
      freeSeatsReturn: 1,
      detourMinutes: 5,
    );

/// The going leg on Tuesday, its planned driver away.
Ride rideOf(CommuteGroup g, {List<String>? on}) => Ride(
      groupId: g.id,
      date: tue,
      leg: Leg.going,
      driverId: null,
      passengers: [
        for (final id in on ?? g.riders.map((m) => m.id)) Passenger(memberId: id, stopId: 'stop-1'),
      ],
      stops: g.goingStops,
    );

/// [metres] north of the pickup point.
GeoPoint near(double metres) => GeoPoint(pickup.lat + metres / 111195, pickup.lng);

BackupCandidate candidate(
  Member m,
  BackupStep step, {
  double metres = 100,
  Clock departure = const Clock.hm(7, 30),
  int seats = 3,
  bool available = true,
  Set<Day> days = CommuteProfile.defaultDays,
}) =>
    BackupCandidate(
      member: m,
      step: step,
      seeker: Seeker(
        role: MemberRole.driver,
        home: near(metres),
        work: work,
        departure: departure,
        ret: const Clock.hm(17, 0),
        days: days,
        legs: const {Leg.going, Leg.ret},
      ),
      freeSeats: seats,
      available: available,
    );

void main() {
  final riders = [person('sara', role: MemberRole.rider, woman: true), person('youssef', role: MemberRole.rider)];
  final g = group(riders);
  final ride = rideOf(g);

  test('each step wins only when every earlier step has no passing candidate', () {
    for (final winner in BackupStep.values) {
      final candidates = [
        for (final step in BackupStep.values)
          candidate(person('c-${step.name}'), step, available: step.index >= winner.index),
      ];
      final result = BackupService.findCover(ride, g, candidates);
      expect(result.step, winner);
      expect(result.coverId, 'c-${winner.name}');
    }
  });

  test('same group beats a better nearby candidate', () {
    final result = BackupService.findCover(ride, g, [
      candidate(person('near', rating: 5), BackupStep.nearbyGroup, metres: 10),
      candidate(person('offduty', rating: 4.1), BackupStep.sameGroup, metres: 900),
    ]);
    expect(result.coverId, 'offduty');
    expect(result.step, BackupStep.sameGroup);
  });

  test('too few seats → skipped; the cover never needs a seat for themselves', () {
    expect(
      BackupService.findCover(ride, g, [
        candidate(person('small'), BackupStep.sameGroup, seats: 1),
        candidate(person('big'), BackupStep.nearbyGroup, seats: 2),
      ]).coverId,
      'big',
    );
    final withOffDuty = rideOf(g, on: ['offduty', 'sara', 'youssef']);
    expect(
      BackupService.findCover(withOffDuty, g, [candidate(person('offduty'), BackupStep.sameGroup, seats: 2)]).coverId,
      'offduty',
    );
  });

  test('002 hard constraints at the limit pass, one over fails', () {
    const limits = MatchingLimits();
    BackupResult at({required int minutesLate, required double metres}) => BackupService.findCover(ride, g, [
          candidate(person('c'), BackupStep.nearbyGroup, departure: Clock.hm(7, 30 + minutesLate), metres: metres),
        ]);
    expect(at(minutesLate: limits.timeMinutes, metres: 100).found, isTrue);
    expect(at(minutesLate: limits.timeMinutes + 1, metres: 100).found, isFalse);
    expect(at(minutesLate: 0, metres: limits.pickupMeters - 1).found, isTrue);
    expect(at(minutesLate: 0, metres: limits.pickupMeters + 1).found, isFalse);
  });

  test('driving that leg on that day only: a cover who does not commute Tuesday fails', () {
    final result = BackupService.findCover(ride, g, [
      candidate(person('weekend'), BackupStep.sameGroup, days: const {Day.fri, Day.sat}),
    ]);
    expect(result.found, isFalse);
  });

  test("a women-only passenger rejects a male cover; a woman covers instead", () {
    final strict = group([
      person('sara', role: MemberRole.rider, woman: true, privacy: PrivacyPreference.womenOnly),
      person('youssef', role: MemberRole.rider),
    ]);
    final result = BackupService.findCover(rideOf(strict), strict, [
      candidate(person('man'), BackupStep.sameGroup),
      candidate(person('woman', woman: true), BackupStep.sameCompany),
    ]);
    expect(result.coverId, 'woman');
    expect(result.step, BackupStep.sameCompany);
  });

  test('within a step: least detour, then highest rating, then lowest id', () {
    BackupResult pick(List<BackupCandidate> c) => BackupService.findCover(ride, g, c);
    expect(
      pick([
        candidate(person('far', rating: 5), BackupStep.nearbyGroup, metres: 600),
        candidate(person('close', rating: 4), BackupStep.nearbyGroup, metres: 200),
      ]).coverId,
      'close',
    );
    expect(
      pick([
        candidate(person('b', rating: 4.5), BackupStep.nearbyGroup),
        candidate(person('a', rating: 4.9), BackupStep.nearbyGroup),
      ]).coverId,
      'a',
    );
    expect(
      pick([
        candidate(person('zed'), BackupStep.nearbyGroup),
        candidate(person('amr'), BackupStep.nearbyGroup),
      ]).coverId,
      'amr',
    );
  });

  test('no candidates, or none passing → none', () {
    expect(BackupService.findCover(ride, g, const []).found, isFalse);
    final none = BackupService.findCover(ride, g, [candidate(person('away'), BackupStep.sameGroup, available: false)]);
    expect(none.found, isFalse);
    expect(none.step, isNull);
  });
}
