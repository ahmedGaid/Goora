import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/data/fake_otp_provider.dart';
import 'package:goora/features/onboarding/domain/otp_provider.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/repositories.dart';

/// Profit change 6: the code service is chosen by config, fake by default.
void main() {
  final phone = PhoneNumber.tryParse('01012345678')!;

  test(
    'config names map to providers; empty or unknown falls back to fake',
    () {
      expect(OtpProviderKind.parse(''), OtpProviderKind.fake);
      expect(OtpProviderKind.parse('nonsense'), OtpProviderKind.fake);
      expect(OtpProviderKind.parse('WhatsApp'), OtpProviderKind.whatsapp);
      expect(OtpProviderKind.parse(' firebase '), OtpProviderKind.firebase);
      expect(OtpProviderKind.parse('sms'), OtpProviderKind.sms);
    },
  );

  test('fake provider accepts only the test code', () async {
    const p = FakeOtpProvider();
    expect(p.kind, OtpProviderKind.fake);
    expect(await p.verify(phone, FakeOtpProvider.testCode), isTrue);
    expect(await p.verify(phone, '000000'), isFalse);
  });

  test('fake provider offline: send throws a network error', () {
    expect(
      const FakeOtpProvider(simulateOffline: true).send(phone),
      throwsA(isA<AuthNetworkException>()),
    );
  });
}
