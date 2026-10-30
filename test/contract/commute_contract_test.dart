import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/data/supabase_commute_repository.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'commute_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

void main() {
  commuteContract('fake', (CommuteGroup group) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return FakeCommuteRepository(prefs,
        catalog: GroupCatalog(prefs, seed: [group]), corridor: Corridors.cairoIsmailia);
  });

  commuteContract('supabase', (CommuteGroup group) async {
    final db = InMemoryGateway(keys: tableKeys);
    await signUpPerson(db, Profile(
        phone: PhoneNumber.tryParse('01001234567')!, firstName: 'Omar', lastName: 'K', gender: Gender.male));
    seedGroup(db, group);
    installCommuteServer(db);
    return SupabaseCommuteRepository(db, corridor: Corridors.cairoIsmailia);
  });
}
