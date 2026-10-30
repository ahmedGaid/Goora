import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/backend/backend_gateway.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/onboarding/data/supabase_profile_repository.dart';
import 'package:goora/features/onboarding/domain/profile.dart';

import 'in_memory_gateway.dart';

/// Stand-ins for the SQL functions in supabase/migrations/2026103000*, as
/// `InMemoryGateway` handlers. They do what the SQL does for the contract's
/// cases; the SQL itself is checked by supabase/tests/*.test.sql.

/// A signed-in person with their `profiles` row, as after onboarding.
Future<String> signUpPerson(InMemoryGateway db, Profile person,
    {String riderIdStatus = 'verified', String? id, String? workEmail}) async {
  final uid = id ?? db.newId('user');
  db.table('profiles').removeWhere((r) => r['id'] == uid);
  await db.insert('profiles', [
    {
      'id': uid,
      ...SupabaseProfileRepository.toRow(person),
      'rating': 4.8,
      'reliability': 100,
      'privacy_preference': 'verifiedUsers',
      'rider_id_status': riderIdStatus,
      'driver_docs': 'notNeeded',
      'company': null,
      'compound': null,
      'work_email': workEmail,
      'work_email_verified': workEmail != null,
    }
  ]);
  db.userId = uid;
  return uid;
}

Row _myProfile(InMemoryGateway db) => db.table('profiles').firstWhere((r) => r['id'] == db.me());

/// 20261030000100: submit_rider_id, start_driver_verification, and the
/// privacy trigger (refused:privacyUnavailable).
void installTrustServer(InMemoryGateway db) {
  db.rpcs['submit_rider_id'] = (_, db) {
    _myProfile(db)['rider_id_status'] = 'verified';
    return 'verified';
  };
  db.rpcs['start_driver_verification'] = (_, db) {
    final p = _myProfile(db);
    if (p['driver_docs'] != 'verified') p['driver_docs'] = 'pending';
    return null;
  };
}

/// A group row as the seed would load it: matching columns + its `card`.
void seedGroup(InMemoryGateway db, CommuteGroup g) {
  db.table('groups').add({
    'id': g.id,
    'origin_area': g.origin.name,
    'destination_area': g.destination.name,
    'card': g.toJson(),
  });
}

/// 20261030000100: groups_for, join_group, join_waitlist.
void installCommuteServer(InMemoryGateway db) {
  db.rpcs['groups_for'] = (p, db) => [
        for (final g in db.table('groups'))
          if (g['origin_area'] == p['p_origin'] && g['destination_area'] == p['p_destination']) g['card'],
      ];
  db.rpcs['join_group'] = (p, db) {
    final me = db.me();
    if (!db.table('groups').any((g) => g['id'] == p['p_group'])) throw const BackendRefused('noSuchGroup');
    db.table('group_members').removeWhere((m) => m['user_id'] == me && m['group_id'] != p['p_group']);
    if (!db.table('group_members').any((m) => m['user_id'] == me)) {
      db.table('group_members').add({'group_id': p['p_group'], 'user_id': me, 'role': p['p_role'], 'legs': p['p_legs']});
    }
    return null;
  };
  db.rpcs['join_waitlist'] = (p, db) {
    final me = db.me();
    final list = db.table('waitlist');
    bool route(Row r) => r['origin_area'] == p['p_origin'] && r['destination_area'] == p['p_destination'];
    if (!list.any((r) => r['user_id'] == me && route(r))) {
      list.add({'user_id': me, 'origin_area': p['p_origin'], 'destination_area': p['p_destination']});
    }
    final onRoute = list.where(route).toList();
    return onRoute.indexWhere((r) => r['user_id'] == me) + 1;
  };
}
