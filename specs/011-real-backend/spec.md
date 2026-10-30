# Feature Specification: Real Backend Behind the Repository Seams

**Feature Branch**: `011-real-backend`

**Created**: 2026-10-30

**Status**: Draft — clarified 2026-10-30 (answers logged in research.md "Decisions"; long autonomous
lane, no founder questions asked)

**Input**: User description: "011 real backend: a Supabase implementation behind every existing
repository seam (commute, daily commute, trust, marketplace, wallet, company, onboarding
auth/profile), chosen by one flag backendLive (default OFF, also off without
SUPABASE_URL/ANON_KEY) so the app with no env runs exactly as today on the fakes. New migrations
with RLS on every table for wallet, company, onboarding/profile, trust; company privacy in RLS (no
individual employee rows to HR without consent, aggregates k>=5); no driver-profit column or path
(Law 87/2018). Local Supabase only; no hosted deploy; OTP and payment providers stay fake (012).
Shared contract tests per seam that the fake passes and the Supabase implementation passes too."

**Sources of truth**: constitution II (drivers never profit), IV (privacy by design; companies
never see an employee's data without consent), V (trust), VIII (repositories behind interfaces),
"Backend" and "Secrets" in Technology constraints · brief §4 tech stack · the three existing
migrations (002 commute, 003 daily, 005 marketplace) · 003 `contracts/edge-functions.md` · 010
research R8 (wallet seams) and R9 (company server shape).

## User Scenarios & Testing *(mandatory)*

The people served here are the founder and the developers who run Goora, and through them every
future rider, driver and HR contact whose data will live on the server.

### User Story 1 - Nothing changes until the backend is switched on (Priority: P1)

A developer or tester installs the app with no backend settings, or with them but without turning
the backend on. The app behaves exactly as today: demo data, the test code `123456`, every screen
and every flow the same.

**Why this priority**: the app is in daily walk-throughs on the fakes. A backend that breaks the
demo is a regression for everyone, so "off means off" comes first.

**Independent Test**: run the full existing test suite with no backend settings; every existing
test passes unchanged and the number of tests only grows.

**Acceptance Scenarios**:

1. **Given** no backend settings, **When** the app starts, **Then** every repository is the
   existing on-device one and the code screen shows the test code as today.
2. **Given** backend settings present but the backend switch off, **When** the app starts,
   **Then** the result is the same as scenario 1.
3. **Given** the backend switch on but no backend address or key, **When** the app starts,
   **Then** the switch counts as off.

---

### User Story 2 - The database itself protects people's data (Priority: P1)

Whatever a client sends, the database answers only what the privacy rules allow: a person reads and
changes their own rows; a driver never sees a rider's name, photo or home before the trip; an HR
contact sees their company's account, invoices and log, a roster limited to name, work email and
since-when, and numbers only as totals of at least five people; an employee's trips reach HR only
after that employee said yes. No table, column or call records money earned by a driver.

**Why this priority**: the constitution's privacy and Law 87/2018 boundaries are legal; on a shared
server they must hold even if the app is wrong.

**Independent Test**: database tests sign in as different people (rider, driver, other rider, HR
contact, employee with and without consent, no one) and check every rule; they run against a local
database.

**Acceptance Scenarios**:

1. **Given** two signed-in people A and B, **When** A reads or writes B's private rows (profile,
   trusted contacts, wallet, plan, payment method, ID status), **Then** A gets nothing and changes
   nothing.
2. **Given** an HR contact of company C, **When** they read C's employees, **Then** they get only the
   four roster columns and never a trip, pickup point, time, group, share or role.
3. **Given** an employee who has not said yes to sharing trips, **When** HR asks for the statement,
   **Then** that employee is not in it; after they say yes, **Then** they are.
4. **Given** a dashboard total built from fewer than five people, **When** HR reads it, **Then** the
   value is withheld ("fewer than 5"), never the number.
5. **Given** a signed-out caller, **When** they read any table, **Then** they get nothing.
6. **Given** the full schema, **When** it is inspected, **Then** every table has its access rules
   switched on and no column or ledger kind holds driver income.

---

### User Story 3 - Same behaviour on the real backend (Priority: P2)

For every seam the app talks through (commute, daily commute, trust, marketplace, wallet, company,
sign-in and profile), the real-backend version answers the same questions the same way as the
on-device version: the same results for the same steps, the same refusals, whole-pound amounts.

**Why this priority**: screens were built and tested against the on-device versions; if the real
one behaves differently, every screen needs re-testing.

**Independent Test**: one shared list of behaviours per seam runs against both versions; both pass.

**Acceptance Scenarios**:

1. **Given** a seam's shared behaviour list, **When** it runs against the on-device version,
   **Then** it passes today, before any real-backend code exists.
2. **Given** the same list, **When** it runs against the real-backend version, **Then** it passes.
3. **Given** a refusal the on-device version raises (wrong code, contacts full, not the HR contact,
   attendance refused), **When** the real backend refuses the same step, **Then** the app sees the
   same refusal, never a raw server message.

---

### User Story 4 - A developer runs the app against a local backend (Priority: P2)

A developer starts the local backend, applies the schema, and runs the app with the backend switch
on. They sign in with the test code, finish onboarding, and their profile, commute profile, trusted
contacts, payment method and wallet live in the database, surviving a reinstall of the app.

**Why this priority**: it proves the wiring end to end before a hosted project exists.

**Independent Test**: follow the README section "Running against local Supabase" from a clean
machine with Docker; the app signs in and a saved profile reads back from the database.

**Acceptance Scenarios**:

1. **Given** the local backend running, **When** the developer follows the README, **Then** the app
   starts on the real backend with no code change.
2. **Given** a signed-in developer, **When** they save their profile and reopen the app, **Then** the
   profile comes back from the database.

---

### User Story 5 - Losing the connection never breaks the app (Priority: P3)

If the backend can't be reached when the app starts, the app runs on the on-device versions for
that session, as today. If the connection drops mid-session, a step fails the way the on-device
version already fails (network refusal, nothing written), with the existing copy.

**Why this priority**: Egyptian mobile data drops often; a dead screen is worse than demo data.

**Independent Test**: start with the backend switch on and an unreachable address; the app comes up
on the on-device versions. Unit tests check that a network failure maps to the existing failure
types.

**Acceptance Scenarios**:

1. **Given** the switch on and the backend unreachable at start, **When** the app starts, **Then** it
   runs on the on-device versions.
2. **Given** a running session, **When** a write fails for lack of network, **Then** nothing is
   half-written and the app shows existing copy only.

### Edge Cases

- The backend switch is on but only one of address or key is set → off (US1/AC3).
- A person signs out and another signs in on the same phone → the second sees none of the first's
  rows (RLS, not the app, enforces it).
- An HR contact leaves the company → they lose HR reads at once; the company row stays.
- A company's employees count drops to four in a month → that month's totals are withheld.
- An employee withdraws HR consent → their lines leave the statement from then on.
- A driver tries to record income or a payout → no table or call accepts it.
- Two people book the last seat at once → one booking wins, the other gets "seat taken"; nothing
  half-written.
- Amounts arrive as fractions or negative values → the database refuses them.
- The local database isn't running when tests run → database tests are skipped with a clear
  "database not running" note; app tests still pass.

## Requirements *(mandatory)*

### Functional Requirements

**Switch and selection**

- **FR-001**: The app MUST choose the real backend only when one switch is on AND both the backend
  address and key are present; otherwise it MUST use the existing on-device repositories.
- **FR-002**: With the switch off, the app's behaviour, copy and tests MUST be unchanged; no existing
  test may be edited to make this feature pass.
- **FR-003**: The switch MUST default to off and MUST NOT be turned on by any committed file.
- **FR-004**: If the backend can't be reached while starting, the app MUST start on the on-device
  repositories for that session.

**Database**

- **FR-005**: The schema MUST add storage for the wallet (plans, paused plans, payment methods,
  InstaPay handles, ledger entries, share marks and claims, bundles), the company network
  (companies, domains, enrollments, invoices, company log, HR consents), the profile/onboarding
  extras and trust (privacy choice, rider ID status, driver verification, work email), plus
  anything the three existing migrations miss (API grants, missing write rules).
- **FR-006**: Every table MUST have row-level access rules switched on, with at least one rule or an
  explicit "server only" note.
- **FR-007**: A person MUST read and write only their own private rows; rows about others reach them
  only through server functions that apply the existing privacy rules.
- **FR-008**: HR MUST read individual employee data only as the four roster columns (name, work
  email, since, status) and the consented statement; dashboards MUST withhold any total built from
  fewer than five people.
- **FR-009**: No column, ledger kind or server call MAY record a driver's income, earnings or payout
  (Law 87/2018). The driver's share stays a trust status only (007).
- **FR-010**: Money MUST be stored as whole-pound integers with checks against negative or
  fractional values where a negative makes no sense.
- **FR-011**: Writes that move money or touch another person MUST go through server functions that
  re-check the rule inside the same transaction; a failed write MUST change nothing.
- **FR-012**: Every access rule MUST have a database test; the tests MUST run against a local
  database when one is available, and the run (or "database not run") MUST be recorded.

**App side**

- **FR-013**: Each seam MUST have a real-backend implementation of the same interface, in the
  seam's data folder.
- **FR-014**: Each seam MUST have one shared behaviour list (contract test) that the on-device
  version passes before the real-backend version exists, and the real-backend version passes after.
- **FR-015**: Server failures MUST map to the seam's existing failure types (network, wrong code,
  refusals); no raw server text MAY reach a screen.
- **FR-016**: The rule twins (Dart and server-side TypeScript) MUST stay unchanged unless a rule
  truly moves; any move MUST be logged.
- **FR-017**: Sign-in MUST keep the on-device test code check until feature 012 brings a real code
  provider; payments MUST stay on the existing fake provider.
- **FR-018**: No key or secret MAY be committed; keys reach the app only as build settings.
- **FR-019**: The company flags `companyInvoicesLive` and `hrStatementExport` MUST stay off.
- **FR-020**: The README MUST explain how to run the app against a local backend.

### Key Entities

- **Backend switch**: one on/off setting plus the address/key pair; decides which repositories the
  app uses.
- **Wallet records**: a person's plan, paused plan, payment method, InstaPay handle, ledger entries
  (Goora's own money only), share marks (driver's answer) and claims (rider's "I paid"), bundle.
- **Company records**: company, its domains, enrollments (person, since, until, why left), invoices,
  log entries, HR consent per employee.
- **Trust records**: privacy choice, rider ID status, driver verification status, work email,
  trusted contacts, SOS alerts (contacts and SOS exist since 003).
- **Seam contract**: a named list of behaviours a seam must show, run against each implementation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With no backend settings, 100% of the existing tests pass unchanged and the total
  number of passing tests does not fall below 1769 app tests and 276 server-rule tests.
- **SC-002**: 100% of database tables have access rules on; 0 tables are reachable by a signed-out
  caller.
- **SC-003**: Every access rule listed in the data model has at least one passing database test.
- **SC-004**: 7 of 7 seams have a shared behaviour list passing on both the on-device and the
  real-backend version.
- **SC-005**: 0 columns, ledger kinds or server calls record driver income.
- **SC-006**: A developer with Docker reaches a signed-in app on the local backend by following the
  README alone.
- **SC-007**: 0 secrets in the repository (a scan of the diff finds no keys).

## Assumptions

- Local only: no hosted project exists and none is created here; deploying is the founder's call.
- Phone codes and payments stay fake until 012; the real-backend session is opened after the
  on-device code check (research.md, Decisions).
- Amounts are whole Egyptian pounds as integers, matching the app's domain, the server rule twins
  and the existing tables.
- Behaviour that only the demo needs (seeded people, demo buttons, "reset demo data") stays on the
  on-device versions; the real-backend versions answer them safely (nothing to do) and the contract
  lists leave them out.
- Group-trip fees derived from finished rides are posted by the server's daily functions; until those
  post ledger rows, the real-backend wallet shows only what its own ledger holds (logged follow-up).
