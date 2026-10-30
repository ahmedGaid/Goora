import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/data/supabase_trust_repository.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';
import 'trust_contract.dart';

final _now = WallTime.fromJson('2026-11-02T08:00:00');

void main() {
  trustContract('fake', (Profile person, {bool newRider = false}) async {
    SharedPreferences.setMockInitialValues({if (newRider) FakeTrustRepository.riderIdKey: 'notVerified'});
    final prefs = await SharedPreferences.getInstance();
    return FakeTrustRepository(prefs, person: () => person, now: () => _now);
  });

  trustContract('supabase', (Profile person, {bool newRider = false}) async {
    final db = InMemoryGateway(keys: tableKeys);
    await signUpPerson(db, person, riderIdStatus: newRider ? 'notVerified' : 'verified');
    installTrustServer(db);
    return SupabaseTrustRepository(db, person: () => person, now: () => _now);
  });
}
