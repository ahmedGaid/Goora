import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/marketplace/domain/booking_gate.dart';
import 'package:goora/features/onboarding/data/local_profile_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

/// 009: a rider's national ID is checked before the first trip, not at
/// signup; drivers are unchanged.
void main() {
  Future<FakeTrustRepository> trust(Role role, [Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role);
    return FakeTrustRepository(p, person: () => person, now: () => at(rideTuesday, 9, 0));
  }

  VerificationStatus idItem(TrustProfile t) => t.items.firstWhere((i) => i.kind == VerificationKind.nationalId).status;

  test('a new rider starts not verified, and the Trust item says so', () async {
    final repo = await trust(Role.rider, {FakeTrustRepository.riderIdKey: 'notVerified'});
    expect(await repo.riderIdStatus(), RiderIdStatus.notVerified);
    expect(idItem(await repo.profile()), VerificationStatus.notVerified);
  });

  test('submitting both sides verifies (fakes verify at once)', () async {
    final repo = await trust(Role.rider, {FakeTrustRepository.riderIdKey: 'notVerified'});
    expect(await repo.submitRiderId(), RiderIdStatus.verified);
    expect(idItem(await repo.profile()), VerificationStatus.verified);
  });

  test('a person who signed up before 009 (no status written) stays verified (FR-006)', () async {
    final repo = await trust(Role.rider);
    expect(await repo.riderIdStatus(), RiderIdStatus.verified);
  });

  test('signing up now writes "not verified"; saving the profile again keeps the status', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final profiles = LocalProfileRepository(prefs);
    final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
    await profiles.save(person);
    expect(prefs.getString(FakeTrustRepository.riderIdKey), 'notVerified');
    await prefs.setString(FakeTrustRepository.riderIdKey, 'verified');
    await profiles.save(person);
    expect(prefs.getString(FakeTrustRepository.riderIdKey), 'verified');
  });

  test('drivers are always verified (FR-005)', () async {
    final repo = await trust(Role.driver);
    expect(await repo.riderIdStatus(), RiderIdStatus.verified);
    expect(idItem(await repo.profile()), VerificationStatus.verified);
  });

  test('gate order: owes driver / fee overdue come before the ID, the ID before the method (FR-008)', () {
    expect(BookingGate.check(hasArrangement: false, openShares: const [], idOk: false), BookingCheck.needsId);
    expect(BookingGate.check(hasArrangement: true, openShares: const [], feeOverdue: 152, idOk: false).kind,
        BookingCheckKind.feeOverdue);
    expect(BookingGate.check(hasArrangement: true, openShares: const [], idOk: true), BookingCheck.ok);
  });

  test('pending still holds the action', () {
    expect(RiderIdStatus.pending.ok, isFalse);
  });
}
