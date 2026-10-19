import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile.dart';
import '../domain/repositories.dart';

final class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._prefs);

  static const _key = 'profile';

  /// `FakeTrustRepository.riderIdKey` (009): a person signing up now has had
  /// no ID check yet; a profile saved before 009 never gets this key, so they
  /// stay verified (their ID was checked at signup then).
  static const _riderIdKey = 'trust.riderId';

  final SharedPreferences _prefs;

  @override
  Future<Profile?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? Profile.fromJson(decoded) : null;
  }

  @override
  Future<void> save(Profile profile) async {
    if (!_prefs.containsKey(_key) && !_prefs.containsKey(_riderIdKey)) {
      await _prefs.setString(_riderIdKey, 'notVerified');
    }
    await _prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clear() => _prefs.remove(_key);
}
