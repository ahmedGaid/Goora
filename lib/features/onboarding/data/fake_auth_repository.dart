import 'package:shared_preferences/shared_preferences.dart';

import '../domain/phone_number.dart';
import '../domain/repositories.dart';

/// Development stand-in for phone OTP until Supabase keys are provided.
final class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._prefs, {this.simulateOffline = false});

  static const testCode = '123456';
  static const _accountsKey = 'fake_auth.accounts';
  static const _sessionKey = 'fake_auth.session';

  final SharedPreferences _prefs;
  final bool simulateOffline;

  @override
  bool get isFake => true;

  @override
  PhoneNumber? get currentPhone => PhoneNumber.tryParse(_prefs.getString(_sessionKey) ?? '');

  @override
  Future<void> sendCode(PhoneNumber phone) async {
    if (simulateOffline) throw const AuthNetworkException();
  }

  @override
  Future<VerifyResult> verifyCode(PhoneNumber phone, String code) async {
    if (code != testCode) throw const InvalidCodeException();
    final accounts = _prefs.getStringList(_accountsKey) ?? const <String>[];
    final existing = accounts.contains(phone.e164);
    if (!existing) await _prefs.setStringList(_accountsKey, [...accounts, phone.e164]);
    await _prefs.setString(_sessionKey, phone.e164);
    return VerifyResult(existingAccount: existing);
  }

  @override
  Future<void> signOut() => _prefs.remove(_sessionKey);
}
