import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile.dart';
import '../domain/repositories.dart';

final class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._prefs);

  static const _key = 'profile';

  final SharedPreferences _prefs;

  @override
  Future<Profile?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? Profile.fromJson(decoded) : null;
  }

  @override
  Future<void> save(Profile profile) => _prefs.setString(_key, jsonEncode(profile.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
