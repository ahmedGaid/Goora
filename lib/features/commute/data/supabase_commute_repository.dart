import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../domain/clock.dart';
import '../domain/commute_profile.dart';
import '../domain/commute_repository.dart';
import '../domain/corridor.dart';
import '../domain/group.dart';
import '../domain/place.dart';

/// Commute on the real backend (011 research D18). The person's commute
/// profile is their own `commute_profiles` row; groups come from
/// `groups_for`, which never returns a home point or a rider's name to an
/// outsider; joining and the waitlist are server functions.
final class SupabaseCommuteRepository implements CommuteRepository {
  SupabaseCommuteRepository(this._db, {required this.corridor});

  static const table = 'commute_profiles';

  final BackendGateway _db;

  /// The active corridor: the places setup offers (006 R4), as in the fake.
  final Corridor corridor;

  String get _me => _db.userId ?? (throw StateError('signed out'));

  @override
  List<Place> homePlaces() => corridor.homePlaces;

  @override
  List<Place> workPlaces() => corridor.workPlaces;

  Place? _place(List<Place> places, Object? id) => places.where((p) => p.id == id).firstOrNull;

  @override
  Future<CommuteProfile?> loadProfile() async {
    final rows = await _db.select(table, where: [Filter.eq('user_id', _me)]);
    if (rows.isEmpty) return null;
    final r = rows.single;
    final seats = r['seats'] as int?;
    return CommuteProfile(
      home: _place(corridor.homePlaces, r['home_place']),
      work: _place(corridor.workPlaces, r['work_place']),
      departure: _clock(r['departure']! as String),
      ret: _clock(r['return_time']! as String),
      days: {for (final d in (r['days']! as List).cast<String>()) Day.values.byName(d)},
      driver: seats == null
          ? null
          : DriverOffer(
              seats: seats,
              trips: DrivenTrips.values.byName(r['driven_trips']! as String),
              contribution: r['contribution']! as int,
            ),
    );
  }

  @override
  Future<void> saveProfile(CommuteProfile profile) async {
    final home = profile.home, work = profile.work;
    if (home == null || work == null) throw ArgumentError('a commute profile needs both places');
    await _db.upsert(table, [
      {
        'user_id': _me,
        'home_place': home.id,
        'home_area': home.area.name,
        'home': _ewkt(home),
        'work_place': work.id,
        'work_area': work.area.name,
        'work': _ewkt(work),
        'departure': _hhmm(profile.departure),
        'return_time': _hhmm(profile.ret),
        'days': [
          for (final d in Day.values)
            if (profile.days.contains(d)) d.name,
        ],
        'seats': profile.driver?.seats,
        'driven_trips': profile.driver?.trips.name,
        'contribution': profile.driver?.contribution,
      },
    ], onConflict: 'user_id');
  }

  @override
  Future<List<CommuteGroup>> groupsFor(Area origin, Area destination) async {
    final cards = await _db.rpc('groups_for', {'p_origin': origin.name, 'p_destination': destination.name});
    return [for (final c in (cards as List? ?? const [])) CommuteGroup.fromJson((c as Map).cast<String, Object?>())];
  }

  @override
  Future<int> joinWaitlist(Area origin, Area destination) async =>
      (await _db.rpc('join_waitlist', {'p_origin': origin.name, 'p_destination': destination.name}))! as int;

  /// The person joins as what their commute profile says: a driver with their
  /// seats and legs, else a rider on both legs.
  @override
  Future<void> join(String groupId) async {
    final driver = (await loadProfile())?.driver;
    try {
      await _db.rpc('join_group', {
        'p_group': groupId,
        'p_role': driver == null ? 'rider' : 'driver',
        'p_legs': [
          for (final l in driver?.trips.legs ?? const {Leg.going, Leg.ret}) l.name,
        ],
        'p_seats': driver?.seats,
      });
    } on BackendRefused catch (e) {
      if (e.reason == 'noSuchGroup') throw ArgumentError.value(groupId, 'groupId', 'no such group');
      rethrow;
    }
  }

  @override
  Future<String?> joinedGroupId() async {
    final rows = await _db.select('group_members', where: [Filter.eq('user_id', _me)], limit: 1);
    return rows.isEmpty ? null : rows.single['group_id'] as String?;
  }

  static String _ewkt(Place p) => 'SRID=4326;POINT(${p.point.lng} ${p.point.lat})';

  static String _hhmm(Clock c) =>
      '${(c.minutes ~/ 60).toString().padLeft(2, '0')}:${(c.minutes % 60).toString().padLeft(2, '0')}';

  /// Postgres `time` reads back as 'HH:MM:SS'.
  static Clock _clock(String s) {
    final [h, m, ...] = s.split(':').map(int.parse).toList();
    return Clock.hm(h, m);
  }
}
