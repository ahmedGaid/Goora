import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../../../core/time/now_provider.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/domain/phone_number.dart';
import '../../onboarding/domain/profile.dart';
import '../domain/privacy.dart';
import '../domain/trust.dart';
import '../domain/trust_repository.dart';

/// Trust on the real backend (011 research D11): statuses on the person's
/// `profiles` row, written only by the server functions; contacts and SOS in
/// the 003 tables under their owner-only rules.
final class SupabaseTrustRepository implements TrustRepository {
  SupabaseTrustRepository(this._db, {required this._person, required this._now});

  final BackendGateway _db;
  final Profile? Function() _person;
  final Now _now;

  String get _me => _db.userId ?? (throw StateError('signed out'));

  Future<Row> _row() async => (await _db.select('profiles', where: [Filter.eq('id', _me)])).single;

  @override
  Future<TrustProfile> profile() async {
    final p = _person()!;
    final r = await _row();
    final driver = p.role == Role.driver || r['driver_docs'] == 'verified';
    final idOk = driver || r['rider_id_status'] == RiderIdStatus.verified.name;
    final docs = !driver
        ? VerificationStatus.notNeeded
        : r['driver_docs'] == 'pending'
        ? VerificationStatus.notVerified
        : VerificationStatus.verified;
    final workEmail = r['work_email_verified'] == true ? r['work_email'] as String? : null;
    VerificationStatus ok(bool v) => v ? VerificationStatus.verified : VerificationStatus.notVerified;
    return TrustProfile(
      firstName: p.firstName,
      initials: [
        p.firstName,
        p.lastName,
      ].where((s) => s.isNotEmpty).map((s) => String.fromCharCode(s.runes.first).toUpperCase()).join(),
      rating: (r['rating'] as num? ?? 5).toDouble(),
      items: [
        const VerificationItem(VerificationKind.phone, VerificationStatus.verified),
        VerificationItem(VerificationKind.nationalId, ok(idOk)),
        VerificationItem(VerificationKind.workEmail, ok(workEmail != null)),
        VerificationItem(VerificationKind.license, docs),
        VerificationItem(VerificationKind.vehicle, docs),
      ],
      isWoman: p.gender == Gender.female,
      privacy: PrivacyPreference.values.asNameMap()[r['privacy_preference']] ?? PrivacyPreference.verifiedUsers,
      company: r['company'] as String?,
      workEmail: workEmail,
      compound: r['compound'] as String?,
    );
  }

  @override
  Future<RiderIdStatus> riderIdStatus() async {
    if (_person()?.role == Role.driver) return RiderIdStatus.verified;
    return RiderIdStatus.values.asNameMap()[(await _row())['rider_id_status']] ?? RiderIdStatus.notVerified;
  }

  @override
  Future<RiderIdStatus> submitRiderId() async =>
      RiderIdStatus.values.byName((await _db.rpc('submit_rider_id'))! as String);

  /// Checked here like the fake; the profiles trigger refuses it again.
  @override
  Future<void> setPrivacy(PrivacyPreference p) async {
    if (!PrivacyRules.available(p, (await profile()).facts)) throw const TrustRefused(TrustRefusal.privacyUnavailable);
    try {
      await _db.update('profiles', {'privacy_preference': p.name}, where: [Filter.eq('id', _me)]);
    } on BackendRefused catch (e) {
      if (e.reason == 'privacyUnavailable') throw const TrustRefused(TrustRefusal.privacyUnavailable);
      rethrow;
    }
  }

  @override
  Future<List<TrustedContact>> contacts() async => [
    for (final r in await _db.select('trusted_contacts', where: [Filter.eq('user_id', _me)], orderBy: 'created_at'))
      TrustedContact(
        id: r['id']! as String,
        name: r['name']! as String,
        phone: PhoneNumber.tryParse(r['phone']! as String)!,
      ),
  ];

  @override
  Future<void> addContact(String name, PhoneNumber phone) async {
    if ((await contacts()).length >= TrustedContact.max) throw const TrustRefused(TrustRefusal.contactsFull);
    try {
      await _db.insert('trusted_contacts', [
        {
          'user_id': _me,
          'name': name.trim(),
          'phone': phone.e164,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ]);
    } on BackendConflict catch (e) {
      // 003's trusted_contacts_limit trigger: another device added the third.
      if (e.detail == 'contactsFull') throw const TrustRefused(TrustRefusal.contactsFull);
      rethrow;
    }
  }

  @override
  Future<void> removeContact(String id) =>
      _db.delete('trusted_contacts', where: [Filter.eq('id', id), Filter.eq('user_id', _me)]);

  /// Recorded on the server; alerting contacts is the server's job later.
  @override
  Future<SosAlert> sendSos({String? rideId}) async {
    final ids = [for (final c in await contacts()) c.id];
    final row = (await _db.insert('sos_alerts', [
      {'user_id': _me, 'ride_id': rideId, 'contact_ids': ids},
    ])).single;
    return SosAlert(id: row['id']! as String, rideId: rideId, at: _now(), contactIds: ids);
  }

  @override
  Future<void> startDriverVerification() => _db.rpc('start_driver_verification');
}
