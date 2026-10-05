import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/app/locale_controller.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/features/onboarding/data/fake_auth_repository.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final phone = PhoneNumber.tryParse('01212345678')!;

  group('FakeAuthRepository', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('wrong code throws and does not sign in', () async {
      final auth = FakeAuthRepository(prefs);
      await expectLater(auth.verifyCode(phone, '000000'), throwsA(isA<InvalidCodeException>()));
      expect(auth.currentPhone, isNull);
    });

    test('first verify creates the account; second finds it', () async {
      final auth = FakeAuthRepository(prefs);
      expect((await auth.verifyCode(phone, FakeAuthRepository.testCode)).existingAccount, isFalse);
      expect(auth.currentPhone, phone);
      await auth.signOut();
      expect(auth.currentPhone, isNull);
      expect((await auth.verifyCode(phone, FakeAuthRepository.testCode)).existingAccount, isTrue);
    });

    test('offline sendCode throws a network error', () async {
      final auth = FakeAuthRepository(prefs, simulateOffline: true);
      await expectLater(auth.sendCode(phone), throwsA(isA<AuthNetworkException>()));
    });
  });

  group('LocaleController', () {
    Future<ProviderContainer> container(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      return c;
    }

    test('defaults to Arabic when nothing is stored', () async {
      final c = await container({});
      expect(c.read(localeControllerProvider), LocaleController.arabic);
    });

    test('toggle switches to English and persists it', () async {
      final c = await container({});
      await c.read(localeControllerProvider.notifier).toggle();
      expect(c.read(localeControllerProvider), LocaleController.english);
      expect(c.read(sharedPreferencesProvider).getString(LocaleController.storageKey), 'en');
    });

    test('restores a stored English choice', () async {
      final c = await container({LocaleController.storageKey: 'en'});
      expect(c.read(localeControllerProvider), LocaleController.english);
    });
  });
}
