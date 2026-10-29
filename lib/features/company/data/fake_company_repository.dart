import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/place.dart';
import '../../wallet/domain/direct_pay.dart';
import '../domain/company.dart';
import '../domain/company_dashboard.dart';
import '../domain/company_log.dart';
import '../domain/company_repository.dart';
import '../domain/company_rules.dart';
import '../domain/company_terms.dart';
import '../domain/employee_month_facts.dart';
import '../domain/enrollment.dart';
import '../domain/hr_views.dart';
import '../domain/invoice.dart';
import 'company_seed.dart';

/// What the company network needs to know about a person who is not in the
/// seed: the roster name and their verified work email (null = none yet).
typedef PersonLookup = Future<({String name, String? workEmail})?> Function(String personId);

/// The company network on fake data over shared_preferences (010
/// data-model.md). Seeded from [CompanySeed] on the first read, anchored at
/// that moment of [_now]; Settings → Reset ([clearAll]) starts over.
///
/// Every read first brings a company up to date at the given moment
/// ([_catchUp]): a passed contract end ends it, every closed month gets its
/// one invoice (research R4, idempotent by key), and suspensions/resumptions
/// are logged. So a demo-clock jump over several months issues each month
/// once (SC-004).
///
/// P3 builds US1–US4's data side. [dashboard] (P7) and the HR statement
/// (P8) throw [UnimplementedError] until their phase. HR-only methods take
/// no caller id in the contract, so the "is HR contact" check stays with the
/// screen until a later phase adds one (research "Lane B notes").
final class FakeCompanyRepository implements CompanyRepository {
  FakeCompanyRepository(this._prefs, {required this._person, required this._now});

  final SharedPreferences _prefs;
  final PersonLookup _person;

  /// Only anchors the seed; every method takes its own moment.
  final Now _now;

  /// Every key the company network owns.
  static const keyPrefix = 'company.';
  static const seededKey = 'company.seeded';
  static const companiesKey = 'company.companies';
  static const nextIndexKey = 'company.nextIndex';
  static String domainKey(String domain) => 'company.domain.$domain';
  static String enrollmentsKey(String companyId) => 'company.enrollments.$companyId';
  static String invoiceKey(String companyId, String monthKey) => 'company.invoice.$companyId.$monthKey';
  static String logKey(String companyId) => 'company.log.$companyId';

  static Future<void> clearAllKeys(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList()) {
      await prefs.remove(key);
    }
  }

  @override
  Future<void> clearAll() => clearAllKeys(_prefs);

  // US1 — company account

  @override
  Future<RegisterResult> register({
    required String personId,
    required String name,
    required List<String> domains,
    required String hrWorkEmail,
    required WallTime now,
  }) async {
    await _ensureSeeded();
    if (!Company.nameOk(name)) throw ArgumentError.value(name, 'name', '2–60 characters');
    final normalized = {for (final d in domains) CompanyDomains.normalize(d)}.toList();
    if (normalized.isEmpty) throw ArgumentError.value(domains, 'domains', 'at least one');
    for (final d in normalized) {
      if (CompanyDomains.isPublic(d)) return PublicDomain(d);
      if (_prefs.containsKey(domainKey(d))) return DomainTaken(d);
    }
    final emailDomain = CompanyDomains.of(hrWorkEmail);
    if (emailDomain == null || !normalized.contains(emailDomain)) return const EmailNotOnDomain();
    final index = _prefs.getInt(nextIndexKey) ?? CompanySeed.nextIndex;
    final company = Company(
      id: 'co-$index',
      name: name.trim(),
      domains: normalized,
      status: CompanyStatus.pending,
      hrContactId: personId,
      minimumSeats: CompanyTerms.minimumSeats,
      pricePerSeat: CompanyTerms.pricePerSeat,
    );
    await _prefs.setInt(nextIndexKey, index + 1);
    await _saveCompany(company);
    for (final d in normalized) {
      await _prefs.setString(domainKey(d), company.id);
    }
    return Registered(company);
  }

  @override
  Future<Company?> companyForDomain(String domain) async {
    await _ensureSeeded();
    final id = _prefs.getString(domainKey(CompanyDomains.normalize(domain)));
    return id == null ? null : _company(id);
  }

  @override
  Future<CompanyHome?> myCompanyAccount(String personId, WallTime now) async {
    await _ensureSeeded();
    final mine = _companies().where((c) => c.hrContactId == personId).firstOrNull;
    if (mine == null) return null;
    final company = await _catchUp(mine, now);
    final invoices = _invoices(company.id);
    return CompanyHome(
      company: company,
      status: _statusAt(company, now),
      latestInvoice: invoices.isEmpty ? null : invoices.first,
    );
  }

  // US2 — enrollment

  @override
  Future<EnrollOffer> offerFor(String personId, WallTime now) async {
    await _ensureSeeded();
    for (final c in _companies()) {
      final company = await _catchUp(c, now);
      final open = _enrollments(company.id).where((e) => e.personId == personId && e.isOpen).firstOrNull;
      if (open != null) return Enrolled(company.name, open.enrolledAt);
    }
    final email = (await _person(personId))?.workEmail;
    final domain = email == null ? null : CompanyDomains.of(email);
    if (domain == null) return const NoWorkEmail();
    final id = _prefs.getString(domainKey(domain));
    if (id == null) return NotOnGoora(domain);
    final company = await _catchUp(_company(id)!, now);
    return switch (company.status) {
      CompanyStatus.pending => PendingCompany(company.name),
      CompanyStatus.ended => NotOnGoora(domain),
      CompanyStatus.active || CompanyStatus.suspended => CanEnroll(company.name),
    };
  }

  @override
  Future<void> enroll(String personId, {required WallTime now}) async {
    final offer = await offerFor(personId, now);
    if (offer is! CanEnroll) throw StateError('No company to enroll in: $offer');
    final person = (await _person(personId))!;
    final company = (await companyForDomain(CompanyDomains.of(person.workEmail!)!))!;
    await _saveEnrollments(company.id, [
      ..._enrollments(company.id),
      Enrollment(
        personId: personId,
        companyId: company.id,
        name: person.name,
        workEmail: person.workEmail!,
        enrolledAt: now,
      ),
    ]);
  }

  @override
  Future<void> leave(String personId, {required WallTime now}) async {
    await _ensureSeeded();
    for (final c in _companies()) {
      final rows = _enrollments(c.id);
      final i = rows.indexWhere((e) => e.personId == personId && e.isOpen);
      if (i < 0) continue;
      rows[i] = rows[i].leave(now, LeftWhy.self);
      await _saveEnrollments(c.id, rows);
      await _log(LogEntry(
        companyId: c.id,
        at: now,
        actor: LogActor.employee,
        kind: LogKind.employeeLeft,
        detail: rows[i].name,
      ));
    }
  }

  @override
  Future<LastLeave?> lastLeave(String personId, WallTime now) async {
    await _ensureSeeded();
    LastLeave? latest;
    for (final c in _companies()) {
      final company = await _catchUp(c, now);
      for (final e in _enrollments(company.id).where((e) => e.personId == personId)) {
        if (e.isOpen) return null;
        if (latest == null || e.leftAt!.isAfter(latest.at)) {
          latest = (companyName: company.name, at: e.leftAt!, why: e.leftWhy!);
        }
      }
    }
    return latest;
  }

  @override
  Future<List<Window>> coverageFor(String personId, WallTime now) async {
    await _ensureSeeded();
    final out = <Window>[];
    for (final c in _companies()) {
      final mine = _enrollments(c.id).where((e) => e.personId == personId).map((e) => e.window).toList();
      if (mine.isEmpty) continue;
      final company = await _catchUp(c, now);
      out.addAll(CompanyRules.coverage(mine, _activeWindows(company, now)));
    }
    return out..sort((a, b) => a.from.compareTo(b.from));
  }

  @override
  Future<bool> hasEnrolled(String personId) async {
    await _ensureSeeded();
    return _companies().any((c) => _enrollments(c.id).any((e) => e.personId == personId));
  }

  // US3 — invoices

  @override
  Future<List<Invoice>> invoices(String companyId, WallTime now) async {
    await _ensureSeeded();
    final company = _company(companyId);
    if (company == null) return const [];
    await _catchUp(company, now);
    return _invoices(companyId);
  }

  // US4 — roster and log

  @override
  Future<List<RosterRow>> roster(String companyId, WallTime now) async {
    await _ensureSeeded();
    final company = _company(companyId);
    if (company == null) return const [];
    await _catchUp(company, now);
    final month = now.date.monthKey;
    // One row per person: the open enrollment, else this month's last leave.
    final byPerson = <String, Enrollment>{};
    for (final e in _enrollments(companyId)) {
      if (!e.isOpen && e.leftAt!.date.monthKey != month) continue;
      final seen = byPerson[e.personId];
      if (seen == null || (seen.leftAt != null && (e.isOpen || e.leftAt!.isAfter(seen.leftAt!)))) {
        byPerson[e.personId] = e;
      }
    }
    final rows = byPerson.values.toList()
      ..sort((a, b) {
        final byDate = a.enrolledAt.compareTo(b.enrolledAt);
        return byDate != 0 ? byDate : a.name.compareTo(b.name);
      });
    return [
      for (final e in rows) RosterRow(name: e.name, workEmail: e.workEmail, enrolledAt: e.enrolledAt, leftAt: e.leftAt),
    ];
  }

  @override
  Future<void> removeEmployee(String companyId, String workEmail, WallTime now) async {
    await _ensureSeeded();
    final rows = _enrollments(companyId);
    final email = workEmail.trim().toLowerCase();
    final i = rows.indexWhere((e) => e.isOpen && e.workEmail.toLowerCase() == email);
    if (i < 0) throw StateError('$workEmail is not enrolled in $companyId');
    rows[i] = rows[i].leave(now, LeftWhy.removedByHr);
    await _saveEnrollments(companyId, rows);
    await _log(LogEntry(
      companyId: companyId,
      at: now,
      actor: LogActor.hr,
      kind: LogKind.employeeRemoved,
      detail: rows[i].name,
    ));
  }

  @override
  Future<void> addDomain(String companyId, String domain, WallTime now) async {
    await _ensureSeeded();
    final company = _company(companyId)!;
    final d = CompanyDomains.normalize(domain);
    if (CompanyDomains.isPublic(d)) throw StateError('$d is a public mail domain');
    if (_prefs.containsKey(domainKey(d))) throw StateError('$d is already held');
    await _saveCompany(company.copyWith(domains: [...company.domains, d]));
    await _prefs.setString(domainKey(d), companyId);
    await _log(LogEntry(companyId: companyId, at: now, actor: LogActor.hr, kind: LogKind.domainAdded, detail: d));
  }

  @override
  Future<void> removeDomain(String companyId, String domain, WallTime now) async {
    await _ensureSeeded();
    final company = _company(companyId)!;
    final d = CompanyDomains.normalize(domain);
    if (!company.domains.contains(d)) throw StateError('$companyId does not hold $d');
    if (company.domains.length == 1) throw StateError('A company keeps at least one domain');
    await _saveCompany(company.copyWith(domains: [...company.domains]..remove(d)));
    await _prefs.remove(domainKey(d));
    final rows = [
      for (final e in _enrollments(companyId))
        e.isOpen && CompanyDomains.of(e.workEmail) == d ? e.leave(now, LeftWhy.domainRemoved) : e,
    ];
    await _saveEnrollments(companyId, rows);
    await _log(LogEntry(companyId: companyId, at: now, actor: LogActor.hr, kind: LogKind.domainRemoved, detail: d));
  }

  @override
  Future<List<LogEntry>> log(String companyId) async {
    await _ensureSeeded();
    // Same moment → the one written later first (Dart's sort is not stable).
    final indexed = _logEntries(companyId).indexed.toList()
      ..sort((a, b) {
        final byTime = b.$2.at.compareTo(a.$2.at);
        return byTime != 0 ? byTime : b.$1.compareTo(a.$1);
      });
    return [for (final (_, e) in indexed) e];
  }

  // US5, US6 — later phases

  @override
  Future<List<({String month, bool soFar})>> dashboardMonths(String companyId, WallTime now) async {
    await _ensureSeeded();
    final start = _company(companyId)?.contractStart;
    if (start == null) return const [];
    return CompanyDashboard.months(start, now.date);
  }

  /// Demo data (research R10): Valeo's seeded facts repeat every month; anyone
  /// else enrolled counts as headcount only (no commute profile, so no
  /// route-gap effect).
  @override
  Future<DashboardMonth> dashboard(String companyId, String month, WallTime now) async {
    await _ensureSeeded();
    final seeded = companyId == CompanySeed.valeoId ? CompanySeed.valeoFacts : const <EmployeeMonthFacts>[];
    final known = {for (final f in seeded) f.personId};
    final extra = <EmployeeMonthFacts>[
      for (final e in _enrollments(companyId))
        if (e.isOpen && !known.contains(e.personId))
          EmployeeMonthFacts(
            personId: e.personId,
            riderTrips: 0,
            riderGoingTrips: 0,
            driverTrips: 0,
            savedEgp: 0,
            km: 0,
            homeArea: Area.sheikhZayed,
            hasProfile: false,
            hasGroup: false,
          ),
    ];
    final soFar = month == now.date.monthKey;
    return CompanyDashboard.build(
      month: month,
      soFar: soFar,
      facts: [...seeded, ...extra],
      workdays: CompanyDashboard.workdaysIn(month, through: soFar ? now.date : null),
    );
  }

  @override
  Future<bool> hrConsent(String personId) => throw UnimplementedError('US6 HR statement: tasks.md P8');

  @override
  Future<void> setHrConsent(String personId, bool on, WallTime now) =>
      throw UnimplementedError('US6 HR statement: tasks.md P8');

  @override
  Future<List<StatementLine>> statement(String companyId, String month, WallTime now) =>
      throw UnimplementedError('US6 HR statement: tasks.md P8');

  // Goora staff (demo actions)

  @override
  Future<void> demoApprove(String companyId, WallTime now) async {
    await _ensureSeeded();
    final company = _company(companyId)!;
    if (company.status != CompanyStatus.pending) throw StateError('$companyId is not pending');
    await _saveCompany(company.copyWith(
      status: CompanyStatus.active,
      approvedAt: now,
      contractStart: now.date,
      contractEnd: now.date.addMonths(CompanyTerms.contractMonths),
    ));
    await _log(LogEntry(companyId: companyId, at: now, actor: LogActor.goora, kind: LogKind.approved));
  }

  @override
  Future<void> demoMarkPaid(String invoiceId, {required String bankRef, required WallTime now}) async {
    await _ensureSeeded();
    // `inv-<companyId>-<yyyy-mm>`
    final monthKey = invoiceId.substring(invoiceId.length - 7);
    final companyId = invoiceId.substring(4, invoiceId.length - 8);
    final raw = _prefs.getString(invoiceKey(companyId, monthKey));
    if (raw == null) throw StateError('No invoice $invoiceId');
    final invoice = Invoice.fromJson(_decode(raw));
    if (invoice.paidAt != null) return;
    await _saveInvoice(invoice.markPaid(at: now, bankRef: bankRef));
    await _log(LogEntry(
      companyId: companyId,
      at: now,
      actor: LogActor.goora,
      kind: LogKind.invoicePaid,
      detail: monthKey,
    ));
    await _catchUp(_company(companyId)!, now);
  }

  @override
  Future<void> demoSetHrContact(String companyId, String? personId, WallTime now) async {
    await _ensureSeeded();
    await _saveCompany(_company(companyId)!.copyWith(hrContactId: personId));
    await _log(LogEntry(companyId: companyId, at: now, actor: LogActor.goora, kind: LogKind.hrContactChanged));
  }

  @override
  Future<void> demoEndContract(String companyId, WallTime now) async {
    await _ensureSeeded();
    final company = await _catchUp(_company(companyId)!, now);
    if (company.status == CompanyStatus.ended) return;
    await _end(company, now);
  }

  // Bringing a company up to date

  Future<Company> _catchUp(Company company, WallTime now) async {
    var c = company;
    if (c.status == CompanyStatus.pending) return c;
    final contractEnd = c.contractEnd == null ? null : WallTime(c.contractEnd!, const Clock.hm(0, 0));
    if (c.status != CompanyStatus.ended && contractEnd != null && !now.isBefore(contractEnd)) {
      c = await _end(c, contractEnd);
    }
    await _issueMissing(c, now);
    await _logSuspensions(c, now);
    return c;
  }

  /// Ends the contract at [at]: every open enrollment leaves then (FR-019).
  Future<Company> _end(Company company, WallTime at) async {
    final ended = company.copyWith(status: CompanyStatus.ended, endedAt: at);
    await _saveCompany(ended);
    await _saveEnrollments(company.id, [
      for (final e in _enrollments(company.id)) e.isOpen ? e.leave(at, LeftWhy.contractEnded) : e,
    ]);
    await _log(LogEntry(companyId: company.id, at: at, actor: LogActor.goora, kind: LogKind.contractEnded));
    return ended;
  }

  /// One invoice per closed month from approval to the last closed month, or
  /// to the month the contract ended (its final invoice).
  Future<void> _issueMissing(Company c, WallTime now) async {
    if (c.approvedAt == null) return;
    var month = _firstOf(c.approvedAt!.date);
    var last = _firstOf(now.date).addMonths(-1);
    if (c.endedAt != null) {
      // Ended at 00:00 on a 1st → that month had no active minute.
      final endMonth = _firstOf(c.endedAt!.plusMinutes(-1).date);
      if (endMonth.isBefore(last)) last = endMonth;
    }
    final byPerson = <String, List<Window>>{};
    for (final e in _enrollments(c.id)) {
      (byPerson[e.personId] ??= []).add(e.window);
    }
    while (!month.isAfter(last)) {
      if (!_prefs.containsKey(invoiceKey(c.id, month.monthKey))) {
        final next = month.addMonths(1);
        final peak = CompanyRules.peakEnrolled(byPerson, SharePolicy.dayOf(month), SharePolicy.dayOf(next));
        final invoice = Invoice.issue(company: c, month: month, peakEnrolled: peak);
        await _saveInvoice(invoice);
        await _log(LogEntry(
          companyId: c.id,
          at: WallTime(invoice.issuedOn, const Clock.hm(0, 0)),
          actor: LogActor.goora,
          kind: LogKind.invoiceIssued,
          detail: invoice.month,
        ));
      }
      month = month.addMonths(1);
    }
  }

  /// Each gap in the active windows that has started is one "suspended"; each
  /// window after a gap is one "resumed". Logged once each.
  Future<void> _logSuspensions(Company c, WallTime now) async {
    final windows = _activeWindows(c, now);
    final endedAt = c.endedAt == null ? null : SharePolicy.minuteOf(c.endedAt!);
    final nowMinute = SharePolicy.minuteOf(now);
    final existing = _logEntries(c.id);
    Future<void> once(LogKind kind, int minute) async {
      final at = _fromMinute(minute);
      if (existing.any((e) => e.kind == kind && e.at == at)) return;
      await _log(LogEntry(companyId: c.id, at: at, actor: LogActor.goora, kind: kind));
    }

    for (final (i, w) in windows.indexed) {
      if (i > 0 && w.from <= nowMinute) await once(LogKind.resumed, w.from);
      if (w.to != null && w.to != endedAt && w.to! <= nowMinute) await once(LogKind.suspended, w.to!);
    }
  }

  /// What is known at [now]: an unpaid invoice whose suspension day has not
  /// come yet may still be paid in time, so it cuts nothing yet.
  List<Window> _activeWindows(Company c, WallTime now) {
    if (c.approvedAt == null) return const [];
    return CompanyRules.activeWindows(
      approvedAt: SharePolicy.minuteOf(c.approvedAt!),
      endedAt: c.endedAt == null ? null : SharePolicy.minuteOf(c.endedAt!),
      overdue: [
        for (final inv in _invoices(c.id))
          if (!now.isBefore(inv.suspendFrom))
            (
              suspendFrom: SharePolicy.minuteOf(inv.suspendFrom),
              paidAt: inv.paidAt == null ? null : SharePolicy.minuteOf(inv.paidAt!),
            ),
      ],
    );
  }

  CompanyStatus _statusAt(Company c, WallTime now) {
    if (c.status != CompanyStatus.active) return c.status;
    return CompanyRules.covered(_activeWindows(c, now), SharePolicy.minuteOf(now))
        ? CompanyStatus.active
        : CompanyStatus.suspended;
  }

  // Seed

  /// Shared while it runs, so calls that overlap seed once.
  Future<void>? _seeding;

  Future<void> _ensureSeeded() {
    if (_prefs.getBool(seededKey) ?? false) return Future.value();
    return _seeding ??= _seed().whenComplete(() => _seeding = null);
  }

  Future<void> _seed() async {
    final anchor = _now();
    final valeo = CompanySeed.valeo(anchor);
    await _prefs.setString(companiesKey, jsonEncode([valeo.toJson(), CompanySeed.orange.toJson()]));
    for (final c in [valeo, CompanySeed.orange]) {
      for (final d in c.domains) {
        await _prefs.setString(domainKey(d), c.id);
      }
    }
    await _saveEnrollments(valeo.id, CompanySeed.valeoEnrollments(valeo.approvedAt!));
    await _log(LogEntry(companyId: valeo.id, at: valeo.approvedAt!, actor: LogActor.goora, kind: LogKind.approved));
    // The months already closed were paid on their issue day.
    await _issueMissing(valeo, anchor);
    for (final inv in _invoices(valeo.id)) {
      final on = WallTime(inv.issuedOn, const Clock.hm(11, 0));
      final at = on.isAfter(anchor) ? anchor : on;
      await _saveInvoice(inv.markPaid(at: at, bankRef: 'SEED-${inv.month}'));
      await _log(LogEntry(
        companyId: valeo.id,
        at: at,
        actor: LogActor.goora,
        kind: LogKind.invoicePaid,
        detail: inv.month,
      ));
    }
    await _prefs.setBool(seededKey, true);
  }

  // Storage

  List<Company> _companies() {
    final raw = _prefs.getString(companiesKey);
    if (raw == null) return [];
    return [for (final j in jsonDecode(raw) as List) Company.fromJson((j as Map).cast<String, Object?>())];
  }

  Company? _company(String id) => _companies().where((c) => c.id == id).firstOrNull;

  Future<void> _saveCompany(Company company) async {
    final all = _companies();
    final i = all.indexWhere((c) => c.id == company.id);
    if (i < 0) {
      all.add(company);
    } else {
      all[i] = company;
    }
    await _prefs.setString(companiesKey, jsonEncode([for (final c in all) c.toJson()]));
  }

  List<Enrollment> _enrollments(String companyId) {
    final raw = _prefs.getString(enrollmentsKey(companyId));
    if (raw == null) return [];
    return [for (final j in jsonDecode(raw) as List) Enrollment.fromJson((j as Map).cast<String, Object?>())];
  }

  Future<void> _saveEnrollments(String companyId, List<Enrollment> rows) =>
      _prefs.setString(enrollmentsKey(companyId), jsonEncode([for (final e in rows) e.toJson()]));

  /// Newest month first.
  List<Invoice> _invoices(String companyId) {
    final prefix = 'company.invoice.$companyId.';
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) Invoice.fromJson(_decode(_prefs.getString(k)!))];
  }

  Future<void> _saveInvoice(Invoice invoice) =>
      _prefs.setString(invoiceKey(invoice.companyId, invoice.month), jsonEncode(invoice.toJson()));

  List<LogEntry> _logEntries(String companyId) {
    final raw = _prefs.getString(logKey(companyId));
    if (raw == null) return [];
    return [for (final j in jsonDecode(raw) as List) LogEntry.fromJson((j as Map).cast<String, Object?>())];
  }

  Future<void> _log(LogEntry entry) => _prefs.setString(
        logKey(entry.companyId),
        jsonEncode([for (final e in [..._logEntries(entry.companyId), entry]) e.toJson()]),
      );

  static Map<String, Object?> _decode(String raw) => (jsonDecode(raw) as Map).cast<String, Object?>();

  static CalendarDate _firstOf(CalendarDate d) => CalendarDate(d.year, d.month, 1);

  static final _epoch = CalendarDate(2000, 1, 1);

  static WallTime _fromMinute(int minute) =>
      WallTime(_epoch.addDays(minute ~/ (24 * 60)), Clock(minute % (24 * 60)));
}
