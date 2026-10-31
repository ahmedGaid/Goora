import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/backend/backend_failure.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/supabase_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';
import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';

/// 013 D10 cases that only the Supabase implementation has: the ride is stored once
/// on first read, a failed call falls back to the plan, the day off is sent to the server.
final _now = WallTime(CalendarDate(2026, 11, 1), const Clock.hm(8, 0));
final _person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
final _sunday = CalendarDate(2026, 11, 1);

Future<({InMemoryGateway db, SupabaseDailyCommuteRepository repo, String me})> _world() async {
  SharedPreferences.setMockInitialValues(memberPrefs(role: Role.rider, member: true));
  final prefs = await SharedPreferences.getInstance();
  final catalog = GroupCatalog(prefs);
  final fake = FakeDailyCommuteRepository(
    prefs,
    commute: FakeCommuteRepository(prefs, catalog: catalog),
    person: () => _person,
    now: () => _now,
    catalog: catalog,
  );
  final group = (await fake.myGroup())!;
  final db = InMemoryGateway(keys: tableKeys);
  final me = await signUpPerson(db, _person, id: fake.meId);
  installCommuteServer(db);
  installDailyServer(db);
  seedGroup(db, group);
  db.table('group_members').add({'group_id': group.id, 'user_id': me, 'role': 'rider'});
  return (db: db, repo: SupabaseDailyCommuteRepository(db), me: me);
}

int _calls(InMemoryGateway db, String action) =>
    db.calls.where((c) => c.$1 == 'commute-day' && c.$2['action'] == action).length;

void main() {
  test('ST1 an unstored ride is stored once, then carries a token and each rider\'s own stop', () async {
    final w = await _world();
    final ride = await w.repo.ride(_sunday, Leg.going);
    expect(ride?.shareToken, isNotEmpty);
    expect(ride!.passengers.map((p) => p.stopId).toSet().length, greaterThan(1));
    for (final p in ride.passengers) {
      expect(ride.stops.map((s) => s.id), contains(p.stopId));
    }
    await w.repo.ride(_sunday, Leg.going);
    expect(_calls(w.db, 'ride'), 1);
  });

  test('ST2 a failed call falls back to the plan and the next read asks again', () async {
    final w = await _world();
    final working = w.db.functions['commute-day']!;
    w.db.functions['commute-day'] = (_, _) => throw const BackendOffline();
    final planned = await w.repo.ride(_sunday, Leg.going);
    expect(planned, isNotNull);
    expect(planned!.shareToken, isNull);

    w.db.functions['commute-day'] = working;
    expect((await w.repo.ride(_sunday, Leg.going))?.shareToken, isNotEmpty);
  });

  test('ST3 the day off is sent when nobody drives, and ignored when someone does', () async {
    final w = await _world();
    await w.repo.ride(_sunday, Leg.going); // stores the ride, with a driver
    await w.repo.chooseNoCoverOption(_sunday, Leg.going, NoCoverOption.dayOff);
    expect(_calls(w.db, 'noCover'), 1);
    expect(await w.repo.absences(_sunday, _sunday), isEmpty);

    for (final r in w.db.table('rides')) {
      r['driver_id'] = null;
    }
    await w.repo.chooseNoCoverOption(_sunday, Leg.going, NoCoverOption.dayOff);
    final stored = await w.repo.absences(_sunday, _sunday);
    expect([for (final a in stored) (a.personId, a.leg, a.kind)], [(w.me, Leg.going, AbsenceKind.noCover)]);
  });
}
