import 'phone_number.dart';
import 'profile.dart';

final class VerifyResult {
  const VerifyResult({required this.existingAccount});

  final bool existingAccount;
}

final class InvalidCodeException implements Exception {
  const InvalidCodeException();
}

final class AuthNetworkException implements Exception {
  const AuthNetworkException();
}

abstract interface class AuthRepository {
  /// Throws [AuthNetworkException] when the code cannot be sent.
  Future<void> sendCode(PhoneNumber phone);

  /// Throws [InvalidCodeException] on a wrong code.
  Future<VerifyResult> verifyCode(PhoneNumber phone, String code);

  PhoneNumber? get currentPhone;

  Future<void> signOut();

  /// True while running on the fake: the code screen shows the test code.
  bool get isFake;
}

abstract interface class ProfileRepository {
  Future<Profile?> load();

  Future<void> save(Profile profile);

  Future<void> clear();
}
