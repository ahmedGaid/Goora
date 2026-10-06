import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../onboarding/domain/phone_number.dart';
import 'privacy.dart';

enum VerificationKind { phone, nationalId, workEmail, license, vehicle }

enum VerificationStatus { verified, notVerified, notNeeded }

final class VerificationItem {
  const VerificationItem(this.kind, this.status);

  final VerificationKind kind;
  final VerificationStatus status;
}

/// Statuses come from fake data only in this feature (FR-023a).
final class TrustProfile {
  const TrustProfile({
    required this.firstName,
    required this.initials,
    required this.rating,
    required this.items,
    required this.isWoman,
    required this.privacy,
    this.company,
    this.compound,
  });

  final String firstName;
  final String initials;
  final double rating;
  final List<VerificationItem> items;
  final bool isWoman;
  final PrivacyPreference privacy;

  /// Set only when the work email is verified.
  final String? company;
  final String? compound;

  PersonFacts get facts => PersonFacts(isWoman: isWoman, company: company, compound: compound);
}

final class TrustedContact {
  const TrustedContact({required this.id, required this.name, required this.phone});

  static const max = 3;

  final String id;
  final String name;
  final PhoneNumber phone;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'phone': phone.e164};

  static TrustedContact fromJson(Map<String, Object?> j) => TrustedContact(
        id: j['id']! as String,
        name: j['name']! as String,
        phone: PhoneNumber.tryParse(j['phone']! as String)!,
      );
}

/// Fake send = recorded only, until an SMS provider is chosen.
final class SosAlert {
  const SosAlert({required this.id, required this.at, required this.contactIds, this.rideId});

  final String id;
  final String? rideId;
  final WallTime at;
  final List<String> contactIds;

  Map<String, Object?> toJson() => {'id': id, 'rideId': rideId, 'at': at.toJson(), 'contactIds': contactIds};

  static SosAlert fromJson(Map<String, Object?> j) => SosAlert(
        id: j['id']! as String,
        rideId: j['rideId'] as String?,
        at: WallTime.fromJson(j['at']! as String),
        contactIds: (j['contactIds']! as List).cast<String>(),
      );
}

/// Free cancels produce no event (FR-036).
enum ReliabilityEventKind { kept, noShow, lateCancel, lateCantDrive }

final class ReliabilityEvent {
  const ReliabilityEvent({required this.personId, required this.rideId, required this.date, required this.kind});

  final String personId;
  final String rideId;
  final CalendarDate date;
  final ReliabilityEventKind kind;

  Map<String, Object?> toJson() => {'personId': personId, 'rideId': rideId, 'date': date.toIso(), 'kind': kind.name};

  static ReliabilityEvent fromJson(Map<String, Object?> j) => ReliabilityEvent(
        personId: j['personId']! as String,
        rideId: j['rideId']! as String,
        date: CalendarDate.parse(j['date']! as String),
        kind: ReliabilityEventKind.values.byName(j['kind']! as String),
      );
}

final class Reliability {
  const Reliability({required this.percent, required this.monthLateCancels, required this.monthNoShows});

  /// 0–100.
  final int percent;
  final int monthLateCancels;
  final int monthNoShows;
}
