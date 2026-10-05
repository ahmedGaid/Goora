import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/commute_profile.dart';
import '../domain/commute_repository.dart';
import '../domain/group.dart';
import '../domain/place.dart';
import 'corridor_seed.dart';

final class FakeCommuteRepository implements CommuteRepository {
  FakeCommuteRepository(this._prefs, {List<CommuteGroup>? groups}) : _groups = groups ?? CorridorSeed.groups;

  static const _profileKey = 'commute.profile';
  static const _membershipKey = 'commute.membership';
  static const _waitlistKey = 'commute.waitlist';

  final SharedPreferences _prefs;
  final List<CommuteGroup> _groups;

  @override
  List<Place> homePlaces() => CorridorSeed.homePlaces;

  @override
  List<Place> workPlaces() => CorridorSeed.workPlaces;

  @override
  Future<CommuteProfile?> loadProfile() async {
    final raw = _prefs.getString(_profileKey);
    return raw == null ? null : CommuteProfile.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
  }

  @override
  Future<void> saveProfile(CommuteProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  @override
  Future<List<CommuteGroup>> groupsFor(Area origin, Area destination) async =>
      _groups.where((g) => g.origin == origin && g.destination == destination).toList();

  @override
  Future<int> joinWaitlist(Area origin, Area destination) async {
    await _prefs.setString(_waitlistKey, '${origin.name}>${destination.name}');
    return CorridorSeed.waitlistAhead + 1;
  }

  @override
  Future<void> join(String groupId) => _prefs.setString(_membershipKey, groupId);

  @override
  Future<String?> joinedGroupId() async => _prefs.getString(_membershipKey);
}
