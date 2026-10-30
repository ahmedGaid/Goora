import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/commute_profile.dart' show Leg;
import '../domain/company.dart';
import '../domain/company_dashboard.dart';
import '../domain/company_log.dart';
import '../domain/company_repository.dart';
import '../domain/company_rules.dart';
import '../domain/company_terms.dart';
import '../domain/enrollment.dart';
import '../domain/hr_views.dart';
import '../domain/invoice.dart';

/// The company network on the server (010 research R9; 011 research D12,
/// D13). The HR contact reads their own company, domains, invoices and log;
/// employees read their own enrollments and consent; individual facts reach
/// HR only through the `company_roster` view and, after a yes, the
/// `company_statement` function. The dashboard is aggregates with k = 5.
///
/// Goora staff actions (approve, mark paid, name an HR contact, end a
/// contract) run with the service role, never from the app: the `demo*`
/// methods do nothing here. Invoices are read, never issued by the app
/// (companyInvoicesLive stays off).
final class SupabaseCompanyRepository implements CompanyRepository {
  SupabaseCompanyRepository(this._db);

  final BackendGateway _db;

  // US1 — company account ----------------------------------------------------------

  @override
  Future<RegisterResult> register({
    required String personId,
    required String name,
    required List<String> domains,
    required String hrWorkEmail,
    required WallTime now,
  }) async {
    if (!Company.nameOk(name)) throw ArgumentError.value(name, 'name', '2–60 characters');
    final normalized = {for (final d in domains) CompanyDomains.normalize(d)}.toList();
    if (normalized.isEmpty) throw ArgumentError.value(domains, 'domains', 'at least one');
    // Public mail is refused on the device (research D13), before the server.
    for (final d in normalized) {
      if (CompanyDomains.isPublic(d)) return PublicDomain(d);
    }
    try {
      final id = await _db.rpc('company_register',
          {'p_name': name.trim(), 'p_domains': normalized, 'p_hr_work_email': hrWorkEmail.trim()}) as String;
      return Registered((await _company(id))!);
    } on BackendRefused catch (e) {
      if (e.reason == 'domainTaken') return DomainTaken(e.detail ?? normalized.first);
      if (e.reason == 'emailNotOnDomain') return const EmailNotOnDomain();
      rethrow;
    }
  }

  /// The HR contact's own company (RLS lets nobody else read the row).
  Future<Company?> _company(String id) async {
    final rows = await _db.select('companies', where: [Filter.eq('id', id)]);
    if (rows.isEmpty) return null;
    final domains = await _db.select('company_domains', where: [Filter.eq('company_id', id)], orderBy: 'domain');
    return _fromRow(rows.single, [for (final d in domains) d['domain']! as String]);
  }

  static Company _fromRow(Row r, List<String> domains) => Company(
        id: r['id']! as String,
        name: r['name']! as String,
        domains: domains,
        status: CompanyStatus.values.byName(r['status']! as String),
        hrContactId: r['hr_contact_id'] as String?,
        minimumSeats: (r['minimum_seats'] as int?) ?? CompanyTerms.minimumSeats,
        pricePerSeat: (r['price_per_seat'] as int?) ?? CompanyTerms.pricePerSeat,
        contractStart: _date(r['contract_start']),
        contractEnd: _date(r['contract_end']),
        approvedAt: _time(r['approved_at']),
        endedAt: _time(r['ended_at']),
      );

  static CalendarDate? _date(Object? s) => s == null ? null : CalendarDate.parse(s as String);
  static WallTime? _time(Object? s) => s == null ? null : WallTime.fromJson(s as String);

  /// Anyone may learn which company holds a domain: its id, name and status
  /// only (`company_for_domain`); the HR contact also gets the full row.
  @override
  Future<Company?> companyForDomain(String domain) async {
    final d = CompanyDomains.normalize(domain);
    final found = await _db.rpc('company_for_domain', {'p_domain': d}) as Map?;
    if (found == null) return null;
    final id = found['id']! as String;
    return await _company(id) ??
        Company(
          id: id,
          name: found['name']! as String,
          domains: [d],
          status: CompanyStatus.values.byName(found['status']! as String),
          hrContactId: null,
          minimumSeats: CompanyTerms.minimumSeats,
          pricePerSeat: CompanyTerms.pricePerSeat,
        );
  }

  @override
  Future<CompanyHome?> myCompanyAccount(String personId, WallTime now) async {
    final rows = await _db.select('companies', where: [Filter.eq('hr_contact_id', personId)], limit: 1);
    if (rows.isEmpty) return null;
    final company = (await _company(rows.single['id']! as String))!;
    final invoices = await this.invoices(company.id, now);
    return CompanyHome(
      company: company,
      status: company.status,
      latestInvoice: invoices.isEmpty ? null : invoices.first,
    );
  }

  // US2 — enrollment ---------------------------------------------------------------

  Future<List<Enrollment>> _mine(String personId) async => [
        for (final r in await _db.select('enrollments',
            where: [Filter.eq('person_id', personId)], orderBy: 'enrolled_at', descending: true))
          Enrollment(
            personId: r['person_id']! as String,
            companyId: r['company_id']! as String,
            name: r['name']! as String,
            workEmail: r['work_email']! as String,
            enrolledAt: WallTime.fromJson(r['enrolled_at']! as String),
            leftAt: _time(r['left_at']),
            leftWhy: r['left_why'] == null ? null : LeftWhy.values.byName(r['left_why']! as String),
          ),
      ];

  Future<String> _companyNameFor(String workEmail) async {
    final domain = CompanyDomains.of(workEmail);
    final found = domain == null ? null : await _db.rpc('company_for_domain', {'p_domain': domain}) as Map?;
    return (found?['name'] as String?) ?? '';
  }

  @override
  Future<EnrollOffer> offerFor(String personId, WallTime now) async {
    final open = (await _mine(personId)).where((e) => e.isOpen).firstOrNull;
    if (open != null) return Enrolled(await _companyNameFor(open.workEmail), open.enrolledAt);
    final me = await _db.select('profiles', where: [Filter.eq('id', personId)]);
    final verified = me.isNotEmpty && me.single['work_email_verified'] == true;
    final email = verified ? me.single['work_email'] as String? : null;
    final domain = email == null ? null : CompanyDomains.of(email);
    if (domain == null) return const NoWorkEmail();
    final found = await _db.rpc('company_for_domain', {'p_domain': domain}) as Map?;
    if (found == null) return NotOnGoora(domain);
    final name = found['name']! as String;
    return switch (CompanyStatus.values.byName(found['status']! as String)) {
      CompanyStatus.pending => PendingCompany(name),
      CompanyStatus.ended => NotOnGoora(domain),
      CompanyStatus.active || CompanyStatus.suspended => CanEnroll(name),
    };
  }

  @override
  Future<void> enroll(String personId, {required WallTime now}) async {
    try {
      await _db.rpc('company_enroll');
    } on BackendRefused catch (e) {
      throw StateError('No company to enroll in: ${e.reason}');
    }
  }

  @override
  Future<void> leave(String personId, {required WallTime now}) => _db.rpc('company_leave');

  @override
  Future<LastLeave?> lastLeave(String personId, WallTime now) async {
    final mine = await _mine(personId);
    if (mine.isEmpty || mine.any((e) => e.isOpen)) return null;
    final last = mine.reduce((a, b) => a.leftAt!.isAfter(b.leftAt!) ? a : b);
    return (companyName: await _companyNameFor(last.workEmail), at: last.leftAt!, why: last.leftWhy!);
  }

  /// The enrollment windows. Suspensions are not subtracted on the client
  /// yet (research "Company gaps"): the server's invoices decide them.
  @override
  Future<List<Window>> coverageFor(String personId, WallTime now) async =>
      [for (final e in await _mine(personId)) e.window]..sort((a, b) => a.from.compareTo(b.from));

  @override
  Future<bool> hasEnrolled(String personId) async => (await _mine(personId)).isNotEmpty;

  // US3 — invoices -----------------------------------------------------------------

  @override
  Future<List<Invoice>> invoices(String companyId, WallTime now) async => [
        for (final r in await _db.select('invoices',
            where: [Filter.eq('company_id', companyId)], orderBy: 'month', descending: true))
          Invoice(
            id: r['id']! as String,
            companyId: r['company_id']! as String,
            month: r['month']! as String,
            peakEnrolled: r['peak_enrolled']! as int,
            billedSeats: r['billed_seats']! as int,
            pricePerSeat: r['price_per_seat']! as int,
            total: r['total']! as int,
            issuedOn: CalendarDate.parse(r['issued_on']! as String),
            dueOn: CalendarDate.parse(r['due_on']! as String),
            reference: r['reference']! as String,
            paidAt: _time(r['paid_at']),
            bankRef: r['bank_ref'] as String?,
          ),
      ];

  // US4 — roster and log (HR) ----------------------------------------------------------

  /// Open enrollments and this month's leaves, oldest first — four columns.
  @override
  Future<List<RosterRow>> roster(String companyId, WallTime now) async {
    final month = now.date.monthKey;
    final rows = [
      for (final r in await _db.select('company_roster', where: [Filter.eq('company_id', companyId)]))
        RosterRow(
          name: r['name']! as String,
          workEmail: r['work_email']! as String,
          enrolledAt: WallTime.fromJson(r['enrolled_at']! as String),
          leftAt: _time(r['left_at']),
        ),
    ]..removeWhere((r) => r.leftAt != null && r.leftAt!.date.monthKey != month);
    return rows
      ..sort((a, b) {
        final byDate = a.enrolledAt.compareTo(b.enrolledAt);
        return byDate != 0 ? byDate : a.name.compareTo(b.name);
      });
  }

  Future<void> _hr(String companyId, String function, Row params) async {
    try {
      await _db.rpc(function, {'p_company': companyId, ...params});
    } on BackendRefused catch (e) {
      if (e.reason == 'notHrContact') throw NotHrContact(companyId);
      throw StateError('${e.reason}${e.detail == null ? '' : ': ${e.detail}'}');
    }
  }

  @override
  Future<void> removeEmployee(String companyId, String workEmail, WallTime now) =>
      _hr(companyId, 'company_remove_employee', {'p_work_email': workEmail.trim().toLowerCase()});

  @override
  Future<void> addDomain(String companyId, String domain, WallTime now) {
    final d = CompanyDomains.normalize(domain);
    if (CompanyDomains.isPublic(d)) throw StateError('$d is a public mail domain');
    return _hr(companyId, 'company_add_domain', {'p_domain': d});
  }

  @override
  Future<void> removeDomain(String companyId, String domain, WallTime now) =>
      _hr(companyId, 'company_remove_domain', {'p_domain': CompanyDomains.normalize(domain)});

  /// Newest first; server-only kinds the app has no word for are left out.
  @override
  Future<List<LogEntry>> log(String companyId) async {
    final known = {for (final k in LogKind.values) k.name};
    return [
      for (final r in await _db.select('company_log',
          where: [Filter.eq('company_id', companyId)], orderBy: 'created_at', descending: true))
        if (known.contains(r['kind']))
          LogEntry(
            companyId: companyId,
            at: WallTime.fromJson(r['at']! as String),
            actor: LogActor.values.byName(r['actor']! as String),
            kind: LogKind.values.byName(r['kind']! as String),
            detail: r['detail'] as String?,
          ),
    ];
  }

  // US5 — dashboard -------------------------------------------------------------------

  @override
  Future<List<({String month, bool soFar})>> dashboardMonths(String companyId, WallTime now) async {
    final start = (await _company(companyId))?.contractStart;
    return start == null ? const [] : CompanyDashboard.months(start, now.date);
  }

  /// The server's aggregates; money, CO₂, parking and route gaps are not
  /// computed there yet, so they read as withheld (null / none).
  @override
  Future<DashboardMonth> dashboard(String companyId, String month, WallTime now) async {
    final Map<Object?, Object?> d;
    try {
      d = (await _db.rpc('company_dashboard', {'p_company': companyId, 'p_month': month}))! as Map;
    } on BackendRefused {
      throw NotHrContact(companyId);
    }
    return DashboardMonth(
      month: month,
      soFar: month == now.date.monthKey,
      enrolled: d['enrolled'] as int?,
      active: d['active'] as int?,
      carpoolRatePct: d['carpoolRatePct'] as int?,
      groups: d['groups'] as int?,
      tripsShared: d['tripsShared'] as int?,
      moneySaved: null,
      co2Kg: null,
      parkingPerDay: null,
      routeGaps: const [],
    );
  }

  // US6 — HR statement ------------------------------------------------------------------

  @override
  Future<bool> hrConsent(String personId) async {
    if ((await _mine(personId)).every((e) => !e.isOpen)) return false;
    final rows = await _db.select('hr_consents', where: [Filter.eq('person_id', personId)]);
    return rows.isNotEmpty && rows.single['on'] == true;
  }

  @override
  Future<void> setHrConsent(String personId, bool on, WallTime now) async {
    if ((await _mine(personId)).every((e) => !e.isOpen)) throw StateError('$personId is not enrolled in any company');
    await _db.rpc('company_set_consent', {'p_on': on});
  }

  @override
  Future<List<StatementLine>> statement(String companyId, String month, WallTime now) async {
    final List<Object?> lines;
    try {
      lines = (await _db.rpc('company_statement', {'p_company': companyId, 'p_month': month}))! as List;
    } on BackendRefused {
      throw NotHrContact(companyId);
    }
    return [
      for (final l in lines.cast<Map<Object?, Object?>>())
        StatementLine(
          name: l['name']! as String,
          date: CalendarDate.parse(l['date']! as String),
          leg: Leg.values.byName(l['leg']! as String),
          sharePaid: l['sharePaid']! as int,
        ),
    ];
  }

  // Goora staff: service role only, never from the app ------------------------------------

  @override
  Future<void> demoApprove(String companyId, WallTime now) async {}

  @override
  Future<void> demoMarkPaid(String invoiceId, {required String bankRef, required WallTime now}) async {}

  @override
  Future<void> demoSetHrContact(String companyId, String? personId, WallTime now) async {}

  @override
  Future<void> demoEndContract(String companyId, WallTime now) async {}

  /// Settings → Reset clears the device; the server's rows stay.
  @override
  Future<void> clearAll() async {}
}
