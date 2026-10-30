import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/onboarding/data/fake_otp_provider.dart';
import 'package:goora/features/onboarding/data/supabase_auth_repository.dart';
import 'package:goora/features/onboarding/domain/otp_provider.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';

import '../../contract/support/in_memory_gateway.dart';

final class _RealOtp implements OtpProvider {
  @override
  OtpProviderKind get kind => OtpProviderKind.sms;
  @override
  Future<void> send(PhoneNumber phone) async {}
  @override
  Future<bool> verify(PhoneNumber phone, String code) async => true;
}

void main() {
  test('the sign-in bridge refuses a hosted backend or a real code provider (011 research D5)', () {
    final db = InMemoryGateway();
    expect(() => SupabaseAuthRepository(db, otp: const FakeOtpProvider(), backendUrl: 'https://abc.supabase.co'),
        throwsStateError);
    expect(() => SupabaseAuthRepository(db, otp: _RealOtp(), backendUrl: 'http://127.0.0.1:54321'), throwsStateError);
    for (final url in ['http://127.0.0.1:54321', 'http://localhost:54321', 'http://10.0.2.2:54321']) {
      expect(SupabaseAuthRepository(db, otp: const FakeOtpProvider(), backendUrl: url).isFake, isTrue);
    }
  });

  test('the account email round-trips the number', () {
    final phone = PhoneNumber.tryParse('01001234567')!;
    expect(SupabaseAuthRepository.emailFor(phone), 'p201001234567@phone.goora.test');
  });
}
