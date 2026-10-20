import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';

/// pending →(Goora approves) active →(invoice overdue) suspended →(paid)
/// active; active/suspended →(contract end or Goora ends it) ended, final.
/// `suspended` is never stored: it is derived from invoices (data-model.md).
enum CompanyStatus { pending, active, suspended, ended }

/// Email-domain rules (FR-002, spec clarification "how is a company proven
/// to own its domain").
abstract final class CompanyDomains {
  /// Public mail providers: anyone can have an address there, so they prove
  /// nothing about an employer.
  static const public = {
    'gmail.com',
    'googlemail.com',
    'yahoo.com',
    'yahoo.co.uk',
    'ymail.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'msn.com',
    'icloud.com',
    'me.com',
    'mac.com',
    'aol.com',
    'proton.me',
    'protonmail.com',
    'gmx.com',
    'mail.com',
    'yandex.com',
    'zoho.com',
  };

  /// Lower-case, trimmed, without a leading `@`.
  static String normalize(String domain) {
    final d = domain.trim().toLowerCase();
    return d.startsWith('@') ? d.substring(1) : d;
  }

  static bool isPublic(String domain) => public.contains(normalize(domain));

  /// The domain of [email], or null when it is not an address.
  static String? of(String email) {
    final at = email.lastIndexOf('@');
    if (at <= 0 || at == email.length - 1) return null;
    return normalize(email.substring(at + 1));
  }
}

const Object _keep = Object();

/// A company that pays Goora for its employees (data-model.md "Company").
final class Company {
  const Company({
    required this.id,
    required this.name,
    required this.domains,
    required this.status,
    required this.hrContactId,
    required this.minimumSeats,
    required this.pricePerSeat,
    this.contractStart,
    this.contractEnd,
    this.approvedAt,
    this.endedAt,
  });

  /// `co-<n>`.
  final String id;

  /// 2–60 characters ([nameOk]).
  final String name;

  /// Normalized, at least one, each held by this company only.
  final List<String> domains;

  /// Stored: pending, active or ended. Read through the repository for the
  /// derived `suspended`.
  final CompanyStatus status;

  /// One HR contact; null after they leave until Goora names another.
  final String? hrContactId;

  final CalendarDate? contractStart;
  final CalendarDate? contractEnd;
  final int minimumSeats;

  /// EGP per seat per month; a change applies from the next invoice.
  final int pricePerSeat;
  final WallTime? approvedAt;
  final WallTime? endedAt;

  /// The short id in a payment reference (`co-12` → `12`).
  String get shortId => id.startsWith('co-') ? id.substring(3) : id;

  static bool nameOk(String name) {
    final n = name.trim().length;
    return n >= 2 && n <= 60;
  }

  Company copyWith({
    List<String>? domains,
    CompanyStatus? status,
    Object? hrContactId = _keep,
    CalendarDate? contractStart,
    CalendarDate? contractEnd,
    WallTime? approvedAt,
    WallTime? endedAt,
  }) =>
      Company(
        id: id,
        name: name,
        domains: domains ?? this.domains,
        status: status ?? this.status,
        hrContactId: identical(hrContactId, _keep) ? this.hrContactId : hrContactId as String?,
        minimumSeats: minimumSeats,
        pricePerSeat: pricePerSeat,
        contractStart: contractStart ?? this.contractStart,
        contractEnd: contractEnd ?? this.contractEnd,
        approvedAt: approvedAt ?? this.approvedAt,
        endedAt: endedAt ?? this.endedAt,
      );

  Map<String, Object?> toJson() {
    assert(status != CompanyStatus.suspended, 'suspended is derived from invoices, never stored');
    return {
      'id': id,
      'name': name,
      'domains': domains,
      'status': status.name,
      'hrContactId': hrContactId,
      'minimumSeats': minimumSeats,
      'pricePerSeat': pricePerSeat,
      'contractStart': contractStart?.toIso(),
      'contractEnd': contractEnd?.toIso(),
      'approvedAt': approvedAt?.toJson(),
      'endedAt': endedAt?.toJson(),
    };
  }

  static Company fromJson(Map<String, Object?> j) => Company(
        id: j['id']! as String,
        name: j['name']! as String,
        domains: (j['domains']! as List).cast<String>(),
        status: CompanyStatus.values.byName(j['status']! as String),
        hrContactId: j['hrContactId'] as String?,
        minimumSeats: j['minimumSeats']! as int,
        pricePerSeat: j['pricePerSeat']! as int,
        contractStart: _date(j['contractStart']),
        contractEnd: _date(j['contractEnd']),
        approvedAt: _time(j['approvedAt']),
        endedAt: _time(j['endedAt']),
      );

  static CalendarDate? _date(Object? s) => s == null ? null : CalendarDate.parse(s as String);
  static WallTime? _time(Object? s) => s == null ? null : WallTime.fromJson(s as String);

  @override
  bool operator ==(Object other) =>
      other is Company &&
      other.id == id &&
      other.name == name &&
      _sameList(other.domains, domains) &&
      other.status == status &&
      other.hrContactId == hrContactId &&
      other.minimumSeats == minimumSeats &&
      other.pricePerSeat == pricePerSeat &&
      other.contractStart == contractStart &&
      other.contractEnd == contractEnd &&
      other.approvedAt == approvedAt &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(domains), status, hrContactId, minimumSeats, pricePerSeat,
      contractStart, contractEnd, approvedAt, endedAt);

  @override
  String toString() => 'Company($id, $name, ${status.name})';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
