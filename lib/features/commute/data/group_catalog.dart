import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/group.dart';
import 'corridor_seed.dart';

/// Every commute group the fakes know (005 research R10): the seeded corridor
/// groups, groups the marketplace created, and members the marketplace added
/// to an existing group. Groups become data so "becomes a commute group" is a
/// real 003 group that Today and Week read like any other.
final class GroupCatalog {
  GroupCatalog(this._prefs, {this._seed = CorridorSeed.groups});

  static const groupsKey = 'market.groups';
  static const membersPrefix = 'market.members.';
  static String membersKey(String groupId) => '$membersPrefix$groupId';

  /// Ids of groups the marketplace created: `mk-<offerOrRequestId>`.
  static const createdPrefix = 'mk-';

  final SharedPreferences _prefs;
  final List<CommuteGroup> _seed;

  /// Seed then created groups, each with its added members after its own.
  List<CommuteGroup> all() => [
        for (final g in [..._seed, ..._created()])
          if (_extra(g.id) case final extra when extra.isNotEmpty) g.withMembers([...g.members, ...extra]) else g,
      ];

  CommuteGroup? byId(String id) => all().where((g) => g.id == id).firstOrNull;

  /// Stores [g]. Only marketplace ids (`mk-`) are accepted, so a created
  /// group can never shadow a seeded one.
  Future<CommuteGroup> create(CommuteGroup g) async {
    if (!g.id.startsWith(createdPrefix)) throw ArgumentError.value(g.id, 'id', 'must start with $createdPrefix');
    if (byId(g.id) != null) throw StateError('group ${g.id} already exists');
    await _write(groupsKey, [..._created(), g].map((g) => g.toJson()));
    return g;
  }

  /// Adds [m] to group [groupId]; a person already in it is left as is.
  Future<void> addMember(String groupId, Member m) async {
    final g = byId(groupId);
    if (g == null) throw ArgumentError.value(groupId, 'groupId', 'no such group');
    if (g.member(m.id) != null) return;
    await _write(membersKey(groupId), [..._extra(groupId), m].map((m) => m.toJson()));
  }

  /// Debug "Reset demo data": back to the seed.
  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((k) => k == groupsKey || k.startsWith(membersPrefix)).toList()) {
      await _prefs.remove(key);
    }
  }

  List<CommuteGroup> _created() => _read(groupsKey, CommuteGroup.fromJson);
  List<Member> _extra(String groupId) => _read(membersKey(groupId), Member.fromJson);

  List<T> _read<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) fromJson((e as Map).cast<String, Object?>())];
  }

  Future<void> _write(String key, Iterable<Map<String, Object?>> items) => _prefs.setString(key, jsonEncode([...items]));
}
