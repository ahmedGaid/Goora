import '../../onboarding/domain/phone_number.dart';
import 'privacy.dart';
import 'trust.dart';

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
}
