import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/storage/preferences.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/data/providers.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/providers.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';
import '../helpers/group_expect.dart';

const _tarek = Member(
  id: 'tarek',
  firstName: 'Tarek',
  initials: 'TR',
  role: MemberRole.driver,
  isWoman: false,
  rating: 4.8,
  reliability: 97,
  legs: {Leg.going},
  seats: 3,
  vehicle: Vehicle(make: 'Kia Cerato', colour: VehicleColour.grey),
);

const _nadia = Member(
  id: 'nadia',
  firstName: 'Nadia',
  initials: 'ND',
  role: MemberRole.rider,
  isWoman: true,
  rating: 4.6,
  reliability: 95,
  legs: {Leg.going},
);

/// A daily offer that became a group (R10): one leg, one stop, Sun–Thu.
CommuteGroup _created(String id) => CommuteGroup(
      id: id,
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: const GeoPoint(30.0719, 31.017),
      pickupPoints: const [GeoPoint(30.0432, 30.981)],
      going: const Clock.hm(7, 30),
      ret: const Clock.hm(17, 0),
      days: CommuteProfile.defaultDays,
      members: const [_tarek],
      price: 44,
      freeSeatsGoing: 2,
      freeSeatsReturn: 0,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 0,
      stops: const [Stop(id: 'stop-1', name: StopName.gasStation, point: GeoPoint(30.0432, 30.981), time: Clock.hm(7, 30))],
      rotationStart: CalendarDate(2026, 10, 11),
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('GroupCatalog (005 T028)', () {
    test('a fresh catalog is the corridor seed', () {
      final c = GroupCatalog(prefs);
      expect(c.all().map((g) => g.id), CorridorSeed.groups.map((g) => g.id));
      expect(c.byId('sz-0725'), same(CorridorSeed.groups.first));
      expect(c.byId('nope'), isNull);
    });

    test('create stores an mk- group after the seed', () async {
      final c = GroupCatalog(prefs);
      await c.create(_created('mk-of-1'));
      expect(c.all().map((g) => g.id), [...CorridorSeed.groups.map((g) => g.id), 'mk-of-1']);
      expectSameGroup(c.byId('mk-of-1')!, _created('mk-of-1'));
    });

    test('create refuses an id without mk-, and a duplicate', () async {
      final c = GroupCatalog(prefs);
      expect(() => c.create(_created('sz-0725')), throwsArgumentError);
      expect(() => c.create(_created('of-1')), throwsArgumentError);
      await c.create(_created('mk-of-1'));
      expect(() => c.create(_created('mk-of-1')), throwsStateError);
      expect(c.all().where((g) => g.id == 'mk-of-1'), hasLength(1));
    });

    test('addMember merges into a seeded group, after its own members', () async {
      final c = GroupCatalog(prefs);
      await c.addMember('sz-0740', _nadia.withId('rana'));
      final g = c.byId('sz-0740')!;
      expect(g.members.map((m) => m.id), ['sara-d', 'nour', 'rana']);
      expect(g.member('rana')!.legs, {Leg.going});
    });

    test('addMember merges into a created group', () async {
      final c = GroupCatalog(prefs);
      await c.create(_created('mk-of-1'));
      await c.addMember('mk-of-1', _nadia);
      expect(c.byId('mk-of-1')!.members.map((m) => m.id), ['tarek', 'nadia']);
    });

    test('addMember: a person already in the group is not added twice', () async {
      final c = GroupCatalog(prefs);
      await c.addMember('sz-0725', CorridorSeed.groups.first.members.first);
      await c.create(_created('mk-of-1'));
      await c.addMember('mk-of-1', _nadia);
      await c.addMember('mk-of-1', _nadia);
      expect(c.byId('sz-0725')!.members, hasLength(CorridorSeed.groups.first.members.length));
      expect(c.byId('mk-of-1')!.members.map((m) => m.id), ['tarek', 'nadia']);
    });

    test('addMember to an unknown group throws', () {
      expect(() => GroupCatalog(prefs).addMember('mk-none', _nadia), throwsArgumentError);
    });

    test('survives a new instance on the same prefs', () async {
      final first = GroupCatalog(prefs);
      await first.create(_created('mk-of-1'));
      await first.addMember('mk-of-1', _nadia);
      await first.addMember('sz-0715', _nadia);
      final second = GroupCatalog(prefs);
      expectSameGroup(second.byId('mk-of-1')!, _created('mk-of-1').withMembers([_tarek, _nadia]));
      expect(second.byId('sz-0715')!.members.map((m) => m.id), ['youssef-d', 'karim', 'nadia']);
    });

    test('clear removes created groups and added members, keeps other keys', () async {
      await prefs.setString('daily.notices', '[]');
      final c = GroupCatalog(prefs);
      await c.create(_created('mk-of-1'));
      await c.addMember('sz-0740', _nadia);
      await c.clear();
      expect(prefs.getKeys().where((k) => k.startsWith('market.')), isEmpty);
      expect(prefs.getString('daily.notices'), '[]');
      expect(c.all().map((g) => g.id), CorridorSeed.groups.map((g) => g.id));
      expect(c.byId('sz-0740')!.members, hasLength(2));
    });

    test('a custom seed replaces the corridor seed', () {
      final c = GroupCatalog(prefs, seed: [CorridorSeed.groups.last]);
      expect(c.all().map((g) => g.id), ['oct-0700']);
    });
  });

  group('catalog wiring (005 T030)', () {
    test('commute repository: groupsFor lists a created group, join accepts it, refuses an unknown id', () async {
      final catalog = GroupCatalog(prefs);
      final repo = FakeCommuteRepository(prefs, catalog: catalog);
      await catalog.create(_created('mk-of-1'));
      final ids = (await repo.groupsFor(Area.sheikhZayed, Area.smartVillage)).map((g) => g.id);
      expect(ids, containsAllInOrder(['sz-0725', 'mk-of-1']));
      expect((await repo.groupsFor(Area.october, Area.smartVillage)).map((g) => g.id), ['oct-0700']);
      await repo.join('mk-of-1');
      expect(await repo.joinedGroupId(), 'mk-of-1');
      expect(() => repo.join('mk-none'), throwsArgumentError);
      expect(await repo.joinedGroupId(), 'mk-of-1');
    });

    test('daily repository: a member added to the seeded group rides in it', () async {
      SharedPreferences.setMockInitialValues(memberPrefs(role: Role.rider, groupId: 'sz-0740'));
      final prefs = await SharedPreferences.getInstance();
      await GroupCatalog(prefs).addMember('sz-0740', _nadia);
      final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: Role.rider);
      final repo = FakeDailyCommuteRepository(
        prefs,
        commute: FakeCommuteRepository(prefs),
        person: () => person,
        now: TestClock(at(rideTuesday, 6, 0)).call,
      );
      expect((await repo.myGroup())!.members.map((m) => m.id), ['sara-d', 'nour', 'nadia', repo.meId]);
      expect((await repo.ride(rideTuesday, Leg.going))!.carries('nadia'), isTrue);
      expect((await repo.ride(rideTuesday, Leg.ret))!.carries('nadia'), isFalse);
    });

    test('invalidating groupCatalogProvider rebuilds the commute and daily repositories', () {
      final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      addTearDown(c.dispose);
      final catalog = c.read(groupCatalogProvider);
      final commute = c.read(commuteRepositoryProvider);
      final daily = c.read(dailyCommuteRepositoryProvider);
      expect(c.read(commuteRepositoryProvider), same(commute));

      c.invalidate(groupCatalogProvider);
      expect(c.read(groupCatalogProvider), isNot(same(catalog)));
      expect(c.read(commuteRepositoryProvider), isNot(same(commute)));
      expect(c.read(dailyCommuteRepositoryProvider), isNot(same(daily)));
    });
  });
}

extension on Member {
  Member withId(String id) => Member.fromJson({...toJson(), 'id': id});
}
