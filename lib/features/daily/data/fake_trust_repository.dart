import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/now_provider.dart';
import '../../onboarding/domain/choices.dart';
import '../../onboarding/domain/phone_number.dart';
import '../../onboarding/domain/profile.dart';
import '../domain/privacy.dart';
import '../domain/trust.dart';
import '../domain/trust_repository.dart';
import 'daily_seed.dart';
import 'fake_daily_commute_repository.dart';

/// Trust data on fake statuses over shared_preferences (FR-023 – FR-027).
/// The privacy key is shared with the daily repository, which puts the
/// preference on the person's group member.
final class FakeTrustRepository implements TrustRepository {
  FakeTrustRepository(this._prefs, {required this._person, required this._now});

  static const privacyKey = FakeDailyCommuteRepository.privacyKey;
  static const contactsKey = 'trust.contacts';
  static const sosKey = 'trust.sos';
  static const docsPendingKey = 'trust.driverDocsPending';

  static const allKeys = [privacyKey, contactsKey, sosKey, docsPendingKey];

  final SharedPreferences _prefs;
  final Profile? Function() _person;
  final Now _now;

  @override
  Future<TrustProfile> profile() async {
    final p = _person()!;
    final items = DailySeed.verification(
      driver: p.role == Role.driver,
      docsPending: _prefs.getBool(docsPendingKey) ?? false,
    );
    final workEmail = items.any((i) => i.kind == VerificationKind.workEmail && i.status == VerificationStatus.verified);
    return TrustProfile(
      firstName: p.firstName,
      initials: [p.firstName, p.lastName]
          .where((s) => s.isNotEmpty)
          .map((s) => String.fromCharCode(s.runes.first).toUpperCase())
          .join(),
      rating: DailySeed.myRating,
      items: items,
      isWoman: p.gender == Gender.female,
      privacy: PrivacyPreference.values.asNameMap()[_prefs.getString(privacyKey)] ?? PrivacyPreference.verifiedUsers,
      company: workEmail ? DailySeed.company : null,
    );
  }

  @override
  Future<void> setPrivacy(PrivacyPreference p) async {
    if (!PrivacyRules.available(p, (await profile()).facts)) throw const TrustRefused(TrustRefusal.privacyUnavailable);
    await _prefs.setString(privacyKey, p.name);
  }

  @override
  Future<List<TrustedContact>> contacts() async => _read(contactsKey, TrustedContact.fromJson);

  @override
  Future<void> addContact(String name, PhoneNumber phone) async {
    final list = await contacts();
    if (list.length >= TrustedContact.max) throw const TrustRefused(TrustRefusal.contactsFull);
    final id = 'c${DateTime.now().microsecondsSinceEpoch}';
    await _write(contactsKey, [...list, TrustedContact(id: id, name: name.trim(), phone: phone)], (c) => c.toJson());
  }

  @override
  Future<void> removeContact(String id) async =>
      _write(contactsKey, [for (final c in await contacts()) if (c.id != id) c], (c) => c.toJson());

  @override
  Future<SosAlert> sendSos({String? rideId}) async {
    final alerts = _read(sosKey, SosAlert.fromJson);
    final alert = SosAlert(
      id: 'sos${alerts.length + 1}',
      rideId: rideId,
      at: _now(),
      contactIds: [for (final c in await contacts()) c.id],
    );
    await _write(sosKey, [...alerts, alert], (a) => a.toJson());
    return alert;
  }

  @override
  Future<void> startDriverVerification() => _prefs.setBool(docsPendingKey, true);

  List<T> _read<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) fromJson((e as Map).cast<String, Object?>())];
  }

  Future<void> _write<T>(String key, List<T> items, Map<String, Object?> Function(T) toJson) =>
      _prefs.setString(key, jsonEncode([for (final i in items) toJson(i)]));
}
