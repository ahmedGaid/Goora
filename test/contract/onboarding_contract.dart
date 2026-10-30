import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/onboarding/domain/repositories.dart';

/// One fresh AuthRepository + ProfileRepository pair over shared storage.
abstract interface class OnboardingHarness {
  AuthRepository get auth;
  ProfileRepository get profiles;
}

/// 011 contracts/seam-contracts.md — Onboarding (A1–A4, P1–P3).
void onboardingContract(String label, Future<OnboardingHarness> Function() make) {
  final phone = PhoneNumber.tryParse('01001234567')!;
  const code = '123456';
  Profile profile(String first, {Role? role}) => Profile(
    phone: phone,
    firstName: first,
    lastName: 'Khaled',
    gender: Gender.male,
    role: role,
    frequency: Frequency.everyDay,
  );

  group('onboarding contract [$label]', () {
    test('A1 a wrong code is refused and opens no session', () async {
      final h = await make();
      await h.auth.sendCode(phone);
      await expectLater(h.auth.verifyCode(phone, '000000'), throwsA(isA<InvalidCodeException>()));
      expect(h.auth.currentPhone, isNull);
    });

    test('A2 first correct code: a new account, signed in', () async {
      final h = await make();
      final r = await h.auth.verifyCode(phone, code);
      expect(r.existingAccount, isFalse);
      expect(h.auth.currentPhone, phone);
    });

    test('A3 sign out, then the same number again is an existing account', () async {
      final h = await make();
      await h.auth.verifyCode(phone, code);
      await h.auth.signOut();
      expect(h.auth.currentPhone, isNull);
      expect((await h.auth.verifyCode(phone, code)).existingAccount, isTrue);
    });

    test('A4 isFake while the code provider is fake', () async {
      expect((await make()).auth.isFake, isTrue);
    });

    test('P1 no profile before the first save', () async {
      final h = await make();
      await h.auth.verifyCode(phone, code);
      expect(await h.profiles.load(), isNull);
    });

    test('P2 save then load returns the same profile', () async {
      final h = await make();
      await h.auth.verifyCode(phone, code);
      await h.profiles.save(profile('Omar', role: Role.rider));
      expect((await h.profiles.load())?.toJson(), profile('Omar', role: Role.rider).toJson());
    });

    test('P3 a second save replaces the first; clear empties it', () async {
      final h = await make();
      await h.auth.verifyCode(phone, code);
      await h.profiles.save(profile('Omar'));
      await h.profiles.save(profile('Amr', role: Role.driver));
      expect((await h.profiles.load())?.toJson(), profile('Amr', role: Role.driver).toJson());
      await h.profiles.clear();
      expect(await h.profiles.load(), isNull);
    });
  });
}
