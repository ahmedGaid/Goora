import 'dart:convert';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:goora/app/locale_controller.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/now_provider.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/daily/domain/phone_dialer.dart';
import 'package:goora/features/daily/domain/trip_sharer.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';

final testPhone = PhoneNumber.tryParse('01012345678')!;

/// Tue 6 Oct 2026, a ride day of the seeded group (rotation start Sun 4 Oct).
final rideTuesday = CalendarDate(2026, 10, 6);

WallTime at(CalendarDate d, int h, int m, [int s = 0]) => WallTime(d, Clock.hm(h, m), s);

final class RecordingDialer implements PhoneDialer {
  final dialled = <String>[];

  @override
  Future<bool> dial(String number) async {
    dialled.add(number);
    return true;
  }
}

final class RecordingSharer implements TripSharer {
  final shared = <String>[];

  @override
  Future<void> share(String text) async => shared.add(text);
}

/// A clock tests can move.
final class TestClock {
  TestClock(this.now);

  WallTime now;

  WallTime call() => now;
}

/// Commute profile on the corridor; [ret] / [driver] vary per test.
CommuteProfile corridorProfile({Clock ret = CommuteProfile.defaultReturn, DriverOffer? driver}) => CommuteProfile(
      home: CorridorSeed.sheikhZayed,
      work: CorridorSeed.smartVillage,
      departure: CommuteProfile.defaultDeparture,
      ret: ret,
      days: CommuteProfile.defaultDays,
      driver: driver,
    );

/// Groups the marketplace created, as `GroupCatalog` stores them (005 R10).
/// Spread into [memberPrefs] and pass the group's id as `groupId` to join one.
Map<String, Object> createdGroupsPrefs(List<CommuteGroup> groups) =>
    {GroupCatalog.groupsKey: jsonEncode([for (final g in groups) g.toJson()])};

/// Signed in, onboarded for every-day commuting, joined to [groupId]
/// (sz-0725 by default).
Map<String, Object> memberPrefs({
  required Role role,
  String locale = 'ar',
  Gender gender = Gender.male,
  CommuteProfile? commute,
  bool member = true,
  String groupId = 'sz-0725',
  bool withPlan = true,
  PaymentMethod? method,
}) =>
    {
      LocaleController.storageKey: locale,
      'fake_auth.session': testPhone.e164,
      'fake_auth.accounts': [testPhone.e164],
      'profile': jsonEncode(
        Profile(
          phone: testPhone,
          firstName: 'Omar',
          lastName: 'Khaled',
          gender: gender,
          role: role,
          frequency: Frequency.everyDay,
        ).toJson(),
      ),
      'commute.profile': jsonEncode(
        (commute ??
                corridorProfile(
                  driver: role == Role.driver
                      ? const DriverOffer(seats: 4, trips: DrivenTrips.both, contribution: 40)
                      : null,
                ))
            .toJson(),
      ),
      if (member) FakeCommuteRepository.membershipKey: groupId,
      // 004: a rider needs a payment arrangement to reach Today/Week; a
      // Company plan (fee-free, never lapses) is seeded so pre-004 tests keep
      // their 40 EGP numbers. Tests of the payment flow pass withPlan: false
      // and/or a [method].
      if (member && role == Role.rider && withPlan)
        FakeWalletRepository.planKey: jsonEncode(
          const Plan(personId: DailySeed.meId, type: PlanType.company, status: PlanStatus.active, price: 0)
              .toJson(),
        ),
      if (method != null) FakeWalletRepository.methodKey(DailySeed.meId): method.name,
      if (method != null) FakeWalletRepository.sinceKey(DailySeed.meId): '2026-10-01',
    };

List<Override> dailyOverrides(TestClock clock, {RecordingDialer? dialer, RecordingSharer? sharer}) => [
      nowProvider.overrideWithValue(clock.call),
      if (dialer != null) phoneDialerProvider.overrideWithValue(dialer),
      if (sharer != null) tripSharerProvider.overrideWithValue(sharer),
    ];

/// Pins the old Sheikh Zayed → Smart Village corridor for a test written
/// before 006 (research "P1 spike result": the app default is Cairo ↔
/// Ismailia; only tests that need the old areas add this override).
Override oldCorridor() => activeCorridorProvider.overrideWithBuild((ref, notifier) => Corridors.sheikhZayedSmartVillage);
