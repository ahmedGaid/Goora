import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/commute_profile.dart';
import '../domain/commute_repository.dart';
import '../domain/corridor.dart';
import '../domain/group.dart';
import '../domain/place.dart';
import 'corridor_seed.dart';
import 'corridors.dart';
import 'group_catalog.dart';

final class FakeCommuteRepository implements CommuteRepository {
  FakeCommuteRepository(this._prefs, {GroupCatalog? catalog, this.corridor = Corridors.cairoIsmailia})
      : _catalog = catalog ?? GroupCatalog(_prefs, seed: Corridors.groupsOf(corridor));

  static const _profileKey = 'commute.profile';
  /// Read synchronously at start-up to resume members at Today (research R1).
  static const membershipKey = 'commute.membership';

  /// Synchronous check for the router's first location.
  static bool hasMembership(SharedPreferences prefs) => prefs.containsKey(membershipKey);
  static const _waitlistKey = 'commute.waitlist';

  static const allKeys = [_profileKey, membershipKey, _waitlistKey];

  final SharedPreferences _prefs;

  /// Seeded corridor groups plus groups the marketplace created (005 R10).
  final GroupCatalog _catalog;

  /// The active corridor: the places setup offers (006 R4).
  final Corridor corridor;

  @override
  List<Place> homePlaces() => corridor.homePlaces;

  @override
  List<Place> workPlaces() => corridor.workPlaces;

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
      _catalog.all().where((g) => g.origin == origin && g.destination == destination).toList();

  @override
  Future<int> joinWaitlist(Area origin, Area destination) async {
    await _prefs.setString(_waitlistKey, '${origin.name}>${destination.name}');
    return CorridorSeed.waitlistAhead + 1;
  }

  @override
  Future<void> join(String groupId) {
    if (_catalog.byId(groupId) == null) throw ArgumentError.value(groupId, 'groupId', 'no such group');
    return _prefs.setString(membershipKey, groupId);
  }

  @override
  Future<String?> joinedGroupId() async => _prefs.getString(membershipKey);
}
