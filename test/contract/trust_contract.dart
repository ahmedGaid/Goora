import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/daily/domain/privacy.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/daily/domain/trust_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

/// Builds a TrustRepository for [person], signed in. [newRider] = signed up
/// after 009, so the rider's ID is not checked yet.
typedef TrustHarness = Future<TrustRepository> Function(Profile person, {bool newRider});

/// 011 contracts/seam-contracts.md — Trust (T1–T9).
void trustContract(String label, TrustHarness make) {
  final phone = PhoneNumber.tryParse('01001234567')!;
  Profile person(String first, Gender g, Role role) =>
      Profile(phone: phone, firstName: first, lastName: 'Khaled', gender: g, role: role);
  final omar = person('Omar', Gender.male, Role.rider);
  final mona = person('Mona', Gender.female, Role.rider);
  final dina = person('Dina', Gender.female, Role.driver);
  PhoneNumber num(String n) => PhoneNumber.tryParse(n)!;
  VerificationStatus status(TrustProfile p, VerificationKind k) => p.items.firstWhere((i) => i.kind == k).status;

  group('trust contract [$label]', () {
    test('T1 the profile follows the person; privacy starts at verified users', () async {
      final p = await (await make(mona)).profile();
      expect(p.firstName, 'Mona');
      expect(p.isWoman, isTrue);
      expect(p.privacy, PrivacyPreference.verifiedUsers);
    });

    test('T2 women-only is refused for a man and nothing changes', () async {
      final repo = await make(omar);
      await expectLater(repo.setPrivacy(PrivacyPreference.womenOnly),
          throwsA(isA<TrustRefused>().having((r) => r.reason, 'reason', TrustRefusal.privacyUnavailable)));
      expect((await repo.profile()).privacy, PrivacyPreference.verifiedUsers);
    });

    test('T3 women-only for a woman', () async {
      final repo = await make(mona);
      await repo.setPrivacy(PrivacyPreference.womenOnly);
      expect((await repo.profile()).privacy, PrivacyPreference.womenOnly);
    });

    test('T4 three contacts in order, trimmed; a fourth is refused', () async {
      final repo = await make(omar);
      expect(await repo.contacts(), isEmpty);
      await repo.addContact(' Mama ', num('01011111111'));
      await repo.addContact('Baba', num('01022222222'));
      await repo.addContact('Sara', num('01033333333'));
      expect((await repo.contacts()).map((c) => c.name), ['Mama', 'Baba', 'Sara']);
      await expectLater(repo.addContact('Four', num('01044444444')),
          throwsA(isA<TrustRefused>().having((r) => r.reason, 'reason', TrustRefusal.contactsFull)));
      expect(await repo.contacts(), hasLength(3));
    });

    test('T5 removing one contact keeps the others', () async {
      final repo = await make(omar);
      await repo.addContact('Mama', num('01011111111'));
      // The fake's contact id is the microsecond clock, which Windows can
      // repeat inside one tick; people add contacts seconds apart.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.addContact('Baba', num('01022222222'));
      final first = (await repo.contacts()).first;
      await repo.removeContact(first.id);
      expect((await repo.contacts()).map((c) => c.name), ['Baba']);
    });

    test('T6 SOS names the ride and every contact', () async {
      final repo = await make(omar);
      await repo.addContact('Mama', num('01011111111'));
      await repo.addContact('Baba', num('01022222222'));
      final alert = await repo.sendSos(rideId: 'ride-1');
      expect(alert.rideId, 'ride-1');
      expect(alert.contactIds.toSet(), (await repo.contacts()).map((c) => c.id).toSet());
    });

    test('T7 a new rider is not verified until they send their ID', () async {
      final repo = await make(omar, newRider: true);
      expect(await repo.riderIdStatus(), RiderIdStatus.notVerified);
      expect(await repo.submitRiderId(), RiderIdStatus.verified);
      expect(await repo.riderIdStatus(), RiderIdStatus.verified);
    });

    test('T8 a driver always reads verified', () async {
      expect(await (await make(dina, newRider: true)).riderIdStatus(), RiderIdStatus.verified);
    });

    test('T9 a driver who starts verification waits on licence and vehicle', () async {
      final repo = await make(dina);
      await repo.startDriverVerification();
      final p = await repo.profile();
      expect(status(p, VerificationKind.license), VerificationStatus.notVerified);
      expect(status(p, VerificationKind.vehicle), VerificationStatus.notVerified);
    });
  });
}
