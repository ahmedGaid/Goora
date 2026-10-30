import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/supabase_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';
import 'daily_contract.dart';
import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

final _now = WallTime(CalendarDate(2026, 11, 1), const Clock.hm(8, 0));
final _person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);

Future<FakeDailyCommuteRepository> _fake({required bool member}) async {
  SharedPreferences.setMockInitialValues(memberPrefs(role: Role.rider, member: member));
  final prefs = await SharedPreferences.getInstance();
  final catalog = GroupCatalog(prefs);
  return FakeDailyCommuteRepository(prefs,
      commute: FakeCommuteRepository(prefs, catalog: catalog), person: () => _person, now: () => _now, catalog: catalog);
}

void main() {
  dailyContract('fake', ({required bool member}) async {
    final repo = await _fake(member: member);
    return (repo: repo, postNotice: (NoticeKind kind) => repo.post(kind, const {}));
  });

  dailyContract('supabase', ({required bool member}) async {
    final db = InMemoryGateway(keys: tableKeys);
    // The same group the fake seeds, with me in it, as the server would hold it.
    final group = await (await _fake(member: true)).myGroup();
    final me = await signUpPerson(db, _person, id: (await _fake(member: false)).meId);
    installCommuteServer(db);
    if (member) {
      seedGroup(db, group!);
      db.table('group_members').add({'group_id': group.id, 'user_id': me, 'role': 'rider'});
    }
    var n = 0;
    return (
      repo: SupabaseDailyCommuteRepository(db),
      postNotice: (NoticeKind kind) async => db.table('notices').add({
            'id': 'n${++n}',
            'user_id': me,
            'kind': kind.name,
            'params': <String, Object?>{},
            'created_at': '2026-11-01T06:00:00Z',
            'read_at': null,
          }),
    );
  });
}
