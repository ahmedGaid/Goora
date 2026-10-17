import '../domain/otp_provider.dart';
import '../domain/phone_number.dart';
import '../domain/repositories.dart';

/// Development stand-in: every phone accepts [testCode].
final class FakeOtpProvider implements OtpProvider {
  const FakeOtpProvider({this.simulateOffline = false});

  static const testCode = '123456';

  final bool simulateOffline;

  @override
  OtpProviderKind get kind => OtpProviderKind.fake;

  @override
  Future<void> send(PhoneNumber phone) async {
    if (simulateOffline) throw const AuthNetworkException();
  }

  @override
  Future<bool> verify(PhoneNumber phone, String code) async => code == testCode;
}
