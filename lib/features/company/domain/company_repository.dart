import '../../../core/time/wall_time.dart';
import 'company.dart';
import 'company_log.dart';
import 'company_rules.dart';
import 'enrollment.dart';
import 'hr_views.dart';
import 'invoice.dart';

/// The result of registering a company (US1, FR-001, FR-002).
sealed class RegisterResult {
  const RegisterResult();
}

/// Saved as pending; the person is its HR contact.
final class Registered extends RegisterResult {
  const Registered(this.company);
  final Company company;
}

final class PublicDomain extends RegisterResult {
  const PublicDomain(this.domain);
  final String domain;
}

final class DomainTaken extends RegisterResult {
  const DomainTaken(this.domain);
  final String domain;
}

/// The HR contact's verified work email is on none of the domains.
final class EmailNotOnDomain extends RegisterResult {
  const EmailNotOnDomain();
}

/// What "Through my company" can offer one person (US2, FR-005).
sealed class EnrollOffer {
  const EnrollOffer();
}

/// No verified work email yet.
final class NoWorkEmail extends EnrollOffer {
  const NoWorkEmail();
}

/// No paying company holds this domain (none, or its contract ended).
final class NotOnGoora extends EnrollOffer {
  const NotOnGoora(this.domain);
  final String domain;
}

/// The company registered but Goora has not approved it yet; the screen
/// shows the same "not on Goora yet" as [NotOnGoora] (US1 AC5).
final class PendingCompany extends EnrollOffer {
  const PendingCompany(this.companyName);
  final String companyName;
}

/// Active or suspended: the person may enroll. While suspended, coverage
/// starts only once the overdue invoice is paid.
final class CanEnroll extends EnrollOffer {
  const CanEnroll(this.companyName);
  final String companyName;
}

final class Enrolled extends EnrollOffer {
  const Enrolled(this.companyName, this.since);
  final String companyName;
  final WallTime since;
}

/// How a person's latest enrollment ended, when none is open (US4): the
/// employee's own side reads it to end their company plan in the wallet at
/// that moment, whoever made them leave.
typedef LastLeave = ({String companyName, WallTime at, LeftWhy why});

/// The company-account home for its HR contact (research R5).
final class CompanyHome {
  const CompanyHome({required this.company, required this.status, this.latestInvoice});

  final Company company;

  /// Includes the derived `suspended`.
  final CompanyStatus status;
  final Invoice? latestInvoice;
}

/// An HR-only call made by someone who is not the HR contact.
final class NotHrContact implements Exception {
  const NotHrContact(this.companyId);
  final String companyId;

  @override
  String toString() => 'NotHrContact($companyId)';
}

/// The company network (contracts/repositories-and-navigation.md). HR-facing
/// methods return only the read models in `hr_views.dart` (research R6).
abstract interface class CompanyRepository {
  // US1 — company account

  /// [personId] becomes the HR contact; their verified work email is
  /// [hrWorkEmail].
  Future<RegisterResult> register({
    required String personId,
    required String name,
    required List<String> domains,
    required String hrWorkEmail,
    required WallTime now,
  });
  Future<Company?> companyForDomain(String domain);

  /// null = not the HR contact of any company.
  Future<CompanyHome?> myCompanyAccount(String personId, WallTime now);

  // US2 — enrollment (employee side)
  Future<EnrollOffer> offerFor(String personId, WallTime now);

  /// Consent given at [now]. Throws [StateError] unless [offerFor] is
  /// [CanEnroll].
  Future<void> enroll(String personId, {required WallTime now});
  Future<void> leave(String personId, {required WallTime now});

  /// null while [personId] is enrolled somewhere, or never enrolled.
  Future<LastLeave?> lastLeave(String personId, WallTime now);

  /// Fee-free windows: enrollments ∩ the company's active windows.
  Future<List<Window>> coverageFor(String personId, WallTime now);

  /// Whether [personId] ever enrolled anywhere (open or left). The wallet
  /// attaches [coverageFor] only then, so a company plan made before 010
  /// (no enrollment behind it) keeps its old meaning.
  Future<bool> hasEnrolled(String personId);

  // US3 — invoices (issues missing months lazily, idempotent), newest first
  Future<List<Invoice>> invoices(String companyId, WallTime now);

  // US4 — roster and log (HR)
  Future<List<RosterRow>> roster(String companyId, WallTime now);
  Future<void> removeEmployee(String companyId, String workEmail, WallTime now);
  Future<void> addDomain(String companyId, String domain, WallTime now);
  Future<void> removeDomain(String companyId, String domain, WallTime now);

  /// Newest first.
  Future<List<LogEntry>> log(String companyId);

  // US5 — dashboard (aggregates only)
  /// The months HR can pick: the running one ("so far") first, then each closed month since the contract start.
  Future<List<({String month, bool soFar})>> dashboardMonths(String companyId, WallTime now);
  Future<DashboardMonth> dashboard(String companyId, String month, WallTime now);

  // US6 — HR statement
  Future<bool> hrConsent(String personId);
  Future<void> setHrConsent(String personId, bool on, WallTime now);
  Future<List<StatementLine>> statement(String companyId, String month, WallTime now);

  // Goora staff (demo actions)
  Future<void> demoApprove(String companyId, WallTime now);
  Future<void> demoMarkPaid(String invoiceId, {required String bankRef, required WallTime now});
  /// null = the HR contact left; the company stays active with none
  /// until Goora names another (spec edge case).
  Future<void> demoSetHrContact(String companyId, String? personId, WallTime now);
  Future<void> demoEndContract(String companyId, WallTime now);

  /// Settings → Reset.
  Future<void> clearAll();
}
