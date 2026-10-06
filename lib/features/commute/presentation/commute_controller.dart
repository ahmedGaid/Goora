import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../daily/data/providers.dart';
import '../../daily/domain/privacy.dart';
import '../../daily/domain/trust.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/presentation/session_controller.dart';
import '../data/providers.dart';
import '../domain/commute_profile.dart';
import '../domain/group.dart';
import '../domain/matching_service.dart';
import '../domain/place.dart';
import '../domain/pricing_service.dart';

part 'commute_controller.g.dart';

const timeStepMinutes = 5;

/// The commute profile being edited on the setup screen.
@Riverpod(keepAlive: true)
class CommuteController extends _$CommuteController {
  @override
  Future<CommuteProfile> build() async {
    final saved = await ref.read(commuteRepositoryProvider).loadProfile();
    return saved ??
        const CommuteProfile(
          home: null,
          work: null,
          departure: CommuteProfile.defaultDeparture,
          ret: CommuteProfile.defaultReturn,
          days: CommuteProfile.defaultDays,
        );
  }

  bool get isDriver => ref.read(sessionControllerProvider).profile?.role == Role.driver;

  int get tripCost => PricingService.tripCost(ref.read(tripCostConfigProvider));

  PriceRange rangeFor(int seats) => PricingService.range(tripCost, seats);

  /// The driver offer shown on screen; defaults to 3 seats, both ways, suggested price.
  DriverOffer offerOf(CommuteProfile p) {
    final offer = p.driver;
    if (offer != null) return offer;
    const seats = DriverOffer.defaultSeats;
    return DriverOffer(seats: seats, trips: DrivenTrips.both, contribution: rangeFor(seats).suggested);
  }

  void _update(CommuteProfile Function(CommuteProfile) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }

  void setHome(Place place) => _update((p) => p.copyWith(home: place));

  void setWork(Place place) => _update((p) => p.copyWith(work: place));

  void shiftDeparture(int minutes) => _update((p) => p.copyWith(departure: p.departure.shift(minutes)));

  void shiftReturn(int minutes) => _update((p) => p.copyWith(ret: p.ret.shift(minutes)));

  void toggleDay(Day day) => _update((p) {
        final days = {...p.days};
        days.contains(day) ? days.remove(day) : days.add(day);
        return p.copyWith(days: days);
      });

  void setSeats(int seats) => _update((p) {
        final offer = offerOf(p);
        final range = rangeFor(seats);
        return p.copyWith(
          driver: offer.copyWith(seats: seats, contribution: PricingService.snap(offer.contribution, range)),
        );
      });

  void setTrips(DrivenTrips trips) => _update((p) => p.copyWith(driver: offerOf(p).copyWith(trips: trips)));

  void stepContribution(int direction) => _update((p) {
        final offer = offerOf(p);
        final next = PricingService.snap(offer.contribution + direction * PricingService.step, rangeFor(offer.seats));
        return p.copyWith(driver: offer.copyWith(contribution: next));
      });

  /// Saves the profile, runs matching and records the outcome.
  Future<MatchOutcome> findMatch() async {
    final repo = ref.read(commuteRepositoryProvider);
    final session = ref.read(sessionControllerProvider).profile!;
    final draft = state.requireValue;
    final profile = isDriver ? draft.copyWith(driver: offerOf(draft)) : draft.copyWith(clearDriver: true);
    await repo.saveProfile(profile);
    state = AsyncData(profile);

    // Who can ride with me (FR-024): the saved preference turns on the 002
    // constraint; company and compound come from trust data.
    final trust = await ref.read(trustRepositoryProvider).profile();
    final seeker = Seeker(
      role: isDriver ? MemberRole.driver : MemberRole.rider,
      home: profile.home!.point,
      work: profile.work!.point,
      departure: profile.departure,
      ret: profile.ret,
      days: profile.days,
      legs: isDriver ? profile.driver!.trips.legs : const {Leg.going, Leg.ret},
      isWoman: session.gender == Gender.female,
      company: trust.company,
      compound: trust.compound,
      womenOnly: trust.privacy.wantsWomenOnly,
      sameCompanyOnly: trust.privacy.wantsSameCompany,
      sameCompoundOnly: trust.privacy.wantsSameCompound,
    );
    final groups = await repo.groupsFor(profile.home!.area, profile.work!.area);
    final result = MatchingService.match(seeker, groups);
    final outcome = MatchOutcome(
      profile: profile,
      viewerIsDriver: isDriver,
      result: result,
      waitlistPosition: result.found ? null : await repo.joinWaitlist(profile.home!.area, profile.work!.area),
    );
    ref.read(lastMatchProvider.notifier).set(outcome);
    return outcome;
  }
}

/// A driver whose license or vehicle is not verified yet can't be matched
/// as a driver (US6/AC4).
@riverpod
Future<bool> driverDocsPending(Ref ref) async {
  if (ref.watch(sessionControllerProvider).profile?.role != Role.driver) return false;
  final items = (await ref.watch(trustRepositoryProvider).profile()).items;
  return items.any((i) =>
      (i.kind == VerificationKind.license || i.kind == VerificationKind.vehicle) &&
      i.status == VerificationStatus.notVerified);
}

final class MatchOutcome {
  const MatchOutcome({
    required this.profile,
    required this.viewerIsDriver,
    required this.result,
    this.waitlistPosition,
  });

  final CommuteProfile profile;
  final bool viewerIsDriver;
  final MatchResult result;
  final int? waitlistPosition;
}

@Riverpod(keepAlive: true)
class LastMatch extends _$LastMatch {
  @override
  MatchOutcome? build() => null;

  void set(MatchOutcome outcome) => state = outcome;
}
