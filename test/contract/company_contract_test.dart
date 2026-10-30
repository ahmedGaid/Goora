import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/company/data/fake_company_repository.dart';
import 'package:goora/features/company/data/supabase_company_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'company_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

final _now = WallTime(CalendarDate(2026, 11, 2), const Clock.hm(9, 0));

void main() {
  companyContract('fake', () async {
    SharedPreferences.setMockInitialValues({});
    final people = <String, ({String name, String? workEmail})>{};
    final repo = FakeCompanyRepository(
      await SharedPreferences.getInstance(),
      person: (id) async => people[id],
      now: () => _now,
    );
    return (
      repo: repo,
      person: (String first, {String? workEmail}) async {
        final id = 'p${people.length + 1}';
        people[id] = (name: '$first K', workEmail: workEmail);
        return id;
      },
      actAs: (String _) {},
    );
  });

  companyContract('supabase', () async {
    final db = InMemoryGateway(keys: tableKeys);
    installCompanyServer(db, wall: _now.toJson());
    var n = 0;
    return (
      repo: SupabaseCompanyRepository(db),
      person: (String first, {String? workEmail}) {
        n++;
        return signUpPerson(
          db,
          Profile(phone: PhoneNumber.tryParse('0100123456$n')!, firstName: first, lastName: 'K', gender: Gender.female),
          workEmail: workEmail,
        );
      },
      actAs: (String id) => db.userId = id,
    );
  });
}
