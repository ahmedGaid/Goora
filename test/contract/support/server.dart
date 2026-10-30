import 'package:goora/core/backend/backend_gateway.dart';
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
