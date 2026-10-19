import 'package:shared_preferences/shared_preferences.dart';

import '../domain/otp_provider.dart';
import '../domain/phone_number.dart';
import '../domain/repositories.dart';
import 'fake_otp_provider.dart';

/// Development stand-in for phone OTP until Supabase keys are provided.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._prefs, {this.simulateOffline = false, OtpProvider? otp})
      : _otp = otp ?? FakeOtpProvider(simulateOffline: simulateOffline);

  static const testCode = FakeOtpProvider.testCode;
  static const _accountsKey = 'fake_auth.accounts';
  static const _sessionKey = 'fake_auth.session';

  final SharedPreferences _prefs;
  final bool simulateOffline;
  final OtpProvider _otp;

  @override
  bool get isFake => true;

  @override
  PhoneNumber? get currentPhone => PhoneNumber.tryParse(_prefs.getString(_sessionKey) ?? '');

  @override
  Future<void> sendCode(PhoneNumber phone) => _otp.send(phone);

  @override
  Future<VerifyResult> verifyCode(PhoneNumber phone, String code) async {
    if (!await _otp.verify(phone, code)) throw const InvalidCodeException();
    final accounts = _prefs.getStringList(_accountsKey) ?? const <String>[];
    final existing = accounts.contains(phone.e164);
    if (!existing) await _prefs.setStringList(_accountsKey, [...accounts, phone.e164]);
    await _prefs.setString(_sessionKey, phone.e164);
    return VerifyResult(existingAccount: existing);
  }

  @override
  Future<void> signOut() => _prefs.remove(_sessionKey);
}
