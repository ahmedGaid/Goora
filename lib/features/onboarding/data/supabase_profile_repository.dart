import '../../../core/backend/backend_gateway.dart';
import '../domain/profile.dart';
import '../domain/repositories.dart';

/// The signed-in person's `profiles` row (002 table + 011 columns). A new row
/// reads `rider_id_status = notVerified`, the 009 sign-up state, from the
/// table's default — what `LocalProfileRepository.save` writes for the fake.
final class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._db);

  static const table = 'profiles';

  final BackendGateway _db;

  @override
  Future<Profile?> load() async {
    final me = _db.userId;
    if (me == null) return null;
    final rows = await _db.select(table, where: [Filter.eq('id', me)]);
    return rows.isEmpty ? null : fromRow(rows.single);
  }

  @override
  Future<void> save(Profile profile) async {
    final me = _db.userId ?? (throw StateError('signed out'));
    final values = toRow(profile);
    final existing = await _db.select(table, where: [Filter.eq('id', me)]);
    if (existing.isEmpty) {
      await _db.insert(table, [
        {'id': me, ...values},
      ]);
    } else {
      // Column grants allow these fields only; the id never changes.
      await _db.update(table, values, where: [Filter.eq('id', me)]);
    }
  }

  /// Deletes the person's own row (and, by cascade, what hangs off it).
  @override
  Future<void> clear() async {
    final me = _db.userId;
    if (me != null) await _db.delete(table, where: [Filter.eq('id', me)]);
  }

  static Row toRow(Profile p) => {
    'phone': p.phone.e164,
    'first_name': p.firstName,
    'last_name': p.lastName,
    'gender': p.gender.name,
    'role': p.role?.name,
    'frequency': p.frequency?.name,
  };

  static Profile? fromRow(Row r) => Profile.fromJson({
    'phone': r['phone'],
    'firstName': r['first_name'],
    'lastName': r['last_name'],
    'gender': r['gender'],
    'role': r['role'],
    'frequency': r['frequency'],
  });
}
