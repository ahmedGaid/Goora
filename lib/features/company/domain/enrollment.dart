import '../../../core/time/wall_time.dart';
import '../../wallet/domain/direct_pay.dart';
import 'company_rules.dart';

/// Why an enrollment ended. HR sees "left" with no reason for [self]
/// (spec clarification on the log).
enum LeftWhy { self, removedByHr, domainRemoved, contractEnded }

/// One employee in one company (data-model.md "Enrollment"). Re-joining adds
/// a new row; a person has at most one open row.
final class Enrollment {
  const Enrollment({
    required this.personId,
    required this.companyId,
    required this.name,
    required this.workEmail,
    required this.enrolledAt,
    this.leftAt,
    this.leftWhy,
  }) : assert((leftAt == null) == (leftWhy == null), 'a leave has a moment and a reason');

  final String personId;
  final String companyId;

  /// The roster name, kept from the moment of consent (the employee agreed
  /// the company sees it).
  final String name;
  final String workEmail;

  /// The consent moment (FR-006).
  final WallTime enrolledAt;
  final WallTime? leftAt;
  final LeftWhy? leftWhy;

  bool get isOpen => leftAt == null;

  /// On the shared minute scale of `CompanyRules`.
  Window get window =>
      (from: SharePolicy.minuteOf(enrolledAt), to: leftAt == null ? null : SharePolicy.minuteOf(leftAt!));

  Enrollment leave(WallTime at, LeftWhy why) => Enrollment(
        personId: personId,
        companyId: companyId,
        name: name,
        workEmail: workEmail,
        enrolledAt: enrolledAt,
        leftAt: at,
        leftWhy: why,
      );

  Map<String, Object?> toJson() => {
        'personId': personId,
        'companyId': companyId,
        'name': name,
        'workEmail': workEmail,
        'enrolledAt': enrolledAt.toJson(),
        'leftAt': leftAt?.toJson(),
        'leftWhy': leftWhy?.name,
      };

  static Enrollment fromJson(Map<String, Object?> j) => Enrollment(
        personId: j['personId']! as String,
        companyId: j['companyId']! as String,
        name: j['name']! as String,
        workEmail: j['workEmail']! as String,
        enrolledAt: WallTime.fromJson(j['enrolledAt']! as String),
        leftAt: j['leftAt'] == null ? null : WallTime.fromJson(j['leftAt']! as String),
        leftWhy: j['leftWhy'] == null ? null : LeftWhy.values.byName(j['leftWhy']! as String),
      );

  @override
  bool operator ==(Object other) =>
      other is Enrollment &&
      other.personId == personId &&
      other.companyId == companyId &&
      other.name == name &&
      other.workEmail == workEmail &&
      other.enrolledAt == enrolledAt &&
      other.leftAt == leftAt &&
      other.leftWhy == leftWhy;

  @override
  int get hashCode => Object.hash(personId, companyId, name, workEmail, enrolledAt, leftAt, leftWhy);

  @override
  String toString() => 'Enrollment($personId @ $companyId, $enrolledAt → ${leftAt ?? 'open'})';
}
