import '../../onboarding/domain/phone_number.dart';
import 'privacy.dart';
import 'trust.dart';

/// Why a trust action was refused; the UI maps each to calm copy.
enum TrustRefusal { privacyUnavailable, contactsFull }

final class TrustRefused implements Exception {
  const TrustRefused(this.reason);

  final TrustRefusal reason;

  @override
  String toString() => 'TrustRefused(${reason.name})';
}

abstract interface class TrustRepository {
  Future<TrustProfile> profile();

  /// Refused when [p] is not available to the person (research R7).
  Future<void> setPrivacy(PrivacyPreference p);
  Future<List<TrustedContact>> contacts();

  /// At most [TrustedContact.max].
  Future<void> addContact(String name, PhoneNumber phone);
  Future<void> removeContact(String id);

  /// Fake: recorded only.
  Future<SosAlert> sendSos({String? rideId});

  /// A rider switching to driver mode: license and vehicle wait for
  /// verification, and driver matching waits with them (US6/AC4).
  Future<void> startDriverVerification();
}
