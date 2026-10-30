import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../domain/otp_provider.dart';
import '../domain/phone_number.dart';
import '../domain/repositories.dart';

/// Sign-in on the real backend while the phone code is still fake (011
/// research D5). The code is checked by [OtpProvider] as before; a correct
/// code then opens a password session for that number, so a number keeps one
/// account on any device and `existingAccount` means what the fake means.
///
/// Anyone who knows a number can sign in as it — exactly what the fake code
/// already allows, and no more — so this refuses to run unless the backend is
/// local and the code provider is fake. 012 replaces it with phone OTP.
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._db, {required OtpProvider otp, required String backendUrl}) : _otp = otp {
    if (otp.kind != OtpProviderKind.fake || !isLocal(backendUrl)) {
      throw StateError('The sign-in bridge runs only with the fake code on a local backend (011 research D5)');
    }
  }

  static const _domain = '@phone.goora.test';

  final BackendGateway _db;
  final OtpProvider _otp;

  static bool isLocal(String url) {
    final host = Uri.tryParse(url)?.host;
    return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
  }

  static String emailFor(PhoneNumber phone) => 'p${phone.e164.substring(1)}$_domain';

  static String _passwordFor(PhoneNumber phone) => 'goora-local-${phone.e164}';

  @override
  bool get isFake => _otp.kind == OtpProviderKind.fake;

  @override
  PhoneNumber? get currentPhone {
    final email = _db.auth.email;
    if (email == null || !email.startsWith('p') || !email.endsWith(_domain)) return null;
    return PhoneNumber.tryParse(email.substring(1, email.length - _domain.length));
  }

  @override
  Future<void> sendCode(PhoneNumber phone) => _otp.send(phone);

  @override
  Future<VerifyResult> verifyCode(PhoneNumber phone, String code) async {
    if (!await _otp.verify(phone, code)) throw const InvalidCodeException();
    final email = emailFor(phone);
    try {
      await _db.auth.signInWithPassword(email, _passwordFor(phone));
      return const VerifyResult(existingAccount: true);
    } on BackendUnauthorized {
      await _guard(() => _db.auth.signUp(email, _passwordFor(phone)));
      return const VerifyResult(existingAccount: false);
    } on BackendOffline {
      throw const AuthNetworkException();
    }
  }

  @override
  Future<void> signOut() => _guard(_db.auth.signOut);

  static Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on BackendOffline {
      throw const AuthNetworkException();
    }
  }
}
