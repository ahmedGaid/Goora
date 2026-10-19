# Contract: repositories, seams and navigation (010)

## CompanyRepository (`lib/features/company/domain/company_repository.dart`)

Abstract; `FakeCompanyRepository` in `data/`. Results are sealed classes, as in 005.

```dart
abstract interface class CompanyRepository {
  // US1 — company account
  Future<RegisterResult> register({required String name, required List<String> domains,
      required String hrWorkEmail, required WallTime now});
      // Registered(company) | PublicDomain(domain) | DomainTaken(domain) | EmailNotOnDomain
  Future<Company?> companyForDomain(String domain);
  Future<CompanyHome?> myCompanyAccount(String personId, WallTime now); // null = not HR anywhere

  // US2 — enrollment (employee side)
  Future<EnrollOffer> offerFor(String personId, WallTime now);
      // NoWorkEmail | NotOnGoora(domain) | Pending | CanEnroll(companyName) | Enrolled(companyName, since)
  Future<void> enroll(String personId, {required WallTime now}); // consent given = now
  Future<void> leave(String personId, {required WallTime now});
  Future<List<Window>> coverageFor(String personId, WallTime now);

  // US3 — invoices (issues missing months lazily, idempotent)
  Future<List<Invoice>> invoices(String companyId, WallTime now);

  // US4 — roster and log (HR only; throws NotHrContact otherwise)
  Future<List<RosterRow>> roster(String companyId, WallTime now);
  Future<void> removeEmployee(String companyId, String workEmail, WallTime now);
  Future<void> addDomain(String companyId, String domain, WallTime now);
  Future<void> removeDomain(String companyId, String domain, WallTime now);
  Future<List<LogEntry>> log(String companyId);

  // US5 — dashboard (aggregates only)
  Future<DashboardMonth> dashboard(String companyId, String month, WallTime now);

  // US6 — HR statement
  Future<bool> hrConsent(String personId);
  Future<void> setHrConsent(String personId, bool on, WallTime now);
  Future<List<StatementLine>> statement(String companyId, String month, WallTime now);

  // Goora staff (demo actions)
  Future<void> demoApprove(String companyId, WallTime now);
  Future<void> demoMarkPaid(String invoiceId, {required String bankRef, required WallTime now});
  Future<void> demoSetHrContact(String companyId, String personId, WallTime now);
  Future<void> demoEndContract(String companyId, WallTime now);

  Future<void> clearAll(); // Settings → Reset
}
```

HR-facing methods return only the read models in data-model.md. No method gives HR a person id,
group, pickup, time, share status or role (test: `company_privacy_test.dart` checks the returned
types' fields).

## Seams into existing features (functions, not provider reads — 005 lesson on provider cycles)

- **Wallet** (`FakeWalletRepository`): new constructor function
  `Future<List<Window>?> Function(String personId) companyCoverage`. When the stored plan is
  `PlanType.company`, the plan returned by reads carries these windows; `Plan.coversTrip` /
  `coversDate` use them (research R2). `subscribe(PlanType.company)` is no longer called by the UI;
  enrollment goes through `CompanyRepository.enroll`, which calls a wallet seam
  `startCompanyPlan(personId, now)` / `endCompanyPlan(personId, now)` (pause/restore personal
  plan, set `noTrial`).
- **Plan** (`plan.dart`): optional, non-persisted `coverage` field; the assert stays.
  `coversTrip(at)` for company = `CompanyRules.covered(coverage, minuteOf(at))`; with no
  coverage attached (old data, tests) = today's behaviour from `startDate`.
- **Marketplace** booking: `plan.coversDate(now.date)` → `plan.coversTrip(now)` (fee taken at the
  booking moment).
- **Trust**: work-email verification keeps setting `TrustProfile.company`; the employee's work email
  string is needed for the domain → add `TrustProfile.workEmail` (fake: `<first>@valeo.com`).
- **Notices** (`NoticeSink`): new kinds `companyPlanStarted`, `companyPlanEnded`,
  `companyPlanPaused`, `companyPlanResumed`.

## Navigation (`go_router`, `Routes`)

| Route | Screen | Who |
|---|---|---|
| `/company` | Company account home (register / pending / HR home / my enrollment) | any signed-in user |
| `/company/register` | Register a company | any |
| `/company/roster` | Roster (+ remove) | HR |
| `/company/invoices` | Invoice list | HR |
| `/company/invoice?id=` | One invoice with bank details + reference | HR |
| `/company/dashboard?month=` | Dashboard | HR |
| `/company/log` | Company log | HR |
| `/company/statement?month=` | HR statement (US6) | HR |

Employee side, no new route: the Plan screen's "Through my company" opens the reworked
`company_verify_sheet.dart` → consent sheet; the rider Wallet's company plan card gains "Leave"
and (US6) "Share my trips with HR". Entry to `/company`: Settings row "Company account".
