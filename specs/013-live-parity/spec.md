# Feature Specification: Live-Mode Parity for the Real Backend

**Feature Branch**: `013-live-parity`

**Created**: 2026-10-31

**Status**: Draft — clarified 2026-10-31 (answers logged in research.md "Decisions"; long
autonomous lane, no founder questions asked)

**Input**: User description: "013 live-mode parity: 011 put every repository seam on Supabase behind
`backendLive` (OFF by default), but live mode still has known gaps, no seed data, and the database
tests have never run. Close those so the app in live mode behaves like the fakes: run the database
tests for real and fix what fails; write the seed (Cairo↔Ismailia + Sheikh Zayed demo corridor,
groups, a company with at least five enrolled employees); wallet (cash trial, fee due/overdue,
trip rows from daily records, rider first name and real method on shares); marketplace (driver
first name on offers through a narrow door, group legs in the driver's day, requests for me,
reclaim, finished one-offs); daily (a ride the server has not stored yet carries a real share token
and each rider's own stop; the "no cover" choice is sent); company (suspensions subtracted from
coverage, dashboard money/CO2/parking/route gaps with the k ≥ 5 rule, Goora-staff actions, clear
all); and two small debts (repeating fake contact ids, 5 ms pacing in the trust contract)."

**Sources of truth**: 011 `research.md` (Decisions D1–D25, "Known gaps", Finding F1) and its
`contracts/*.md` · constitution II (drivers never profit), IV (privacy by design; companies never
see an employee's data without consent), VIII (repositories behind interfaces), "Backend" and
"Secrets" · 008 (fee balance: 5-trip trial, 150 EGP / month-end ≥ 30, 3-day grace) · 010 research
R9 (company server shape, k ≥ 5) · 003 `contracts/edge-functions.md`.

## User Scenarios & Testing *(mandatory)*

The people served here are the founder and the developers who run Goora against a local backend,
and through them every future rider, driver and HR contact: what they see on the real backend must
equal what they saw in the demo.

### User Story 1 - Nothing changes until the backend is switched on (Priority: P1)

A developer or tester installs the app with no backend settings, or with them but with the backend
switch off. The app behaves exactly as today: demo data, the test code `123456`, every screen and
flow the same, every existing test unchanged.

**Why this priority**: the fakes carry the daily walk-throughs. Closing live-mode gaps must not
move a pixel or a number on them.

**Independent Test**: run the full existing suite with no backend settings; every existing test
passes unchanged and the total only grows.

**Acceptance Scenarios**:

1. **Given** no backend settings, **When** the app starts, **Then** every repository is the
   on-device one, as in 011.
2. **Given** a change to a fake repository made by this feature (the small debts), **When** the
   existing fake tests run, **Then** they pass unedited.
3. **Given** the backend switch, **When** its default is read, **Then** it is off.

---

### User Story 2 - The database has been run, and starts with the demo corridor (Priority: P1)

A developer starts the local database, resets it, and gets the schema plus demo data: the
Cairo↔Ismailia and Sheikh Zayed corridors with groups and pickup points, and a company with at
least five enrolled employees — all fictional. The database tests (written in 011, never run) run
and pass; whatever failed was fixed in a new migration.

**Why this priority**: every other live-mode claim rests on a database nobody has run yet. A
rule that was never executed is a guess.

**Independent Test**: reset the local database from scratch, run the database test suite, and read
the pass/fail numbers from the run.

**Acceptance Scenarios**:

1. **Given** a clean local database, **When** it is reset, **Then** every migration and the seed
   apply with no error.
2. **Given** the reset database, **When** the database tests run, **Then** every test passes and
   the counts are recorded.
3. **Given** the seeded corridor, **When** a signed-in test person asks for groups between two
   corridor areas, **Then** at least one group with pickup points comes back.
4. **Given** the seeded company, **When** its HR contact asks for the dashboard, **Then** headcount
   based totals show (five or more people) and totals built from fewer people stay withheld.
5. **Given** the seed, **When** it is read, **Then** it holds no real name, phone, e-mail or
   address, and no secret.
6. **Given** a database test that fails, **When** the cause is a migration, **Then** it is fixed in
   a new migration, never by editing one that already applied.

---

### User Story 3 - A rider's wallet reads the same live as on the fakes (Priority: P1)

A rider on the real backend takes five fee-free trips, then pays the Goora fee per trip. The
wallet shows what is owed, when it falls due, and when it is overdue (150 EGP owed, or 30 EGP or
more at month end; blocked after a 3-day grace). Group trips show as rows in the activity list as
the daily records say they happened. On "who paid" shares, the driver sees the rider's first name
and the method the rider actually chose, not always cash.

**Why this priority**: money is the most trusted screen; a live wallet that never counts the trial
or never blocks an overdue balance is wrong in a way that costs real pounds later.

**Independent Test**: one shared behaviour list for wallet runs against the on-device version and
the real-backend version and gives the same answers for trial count, owed, due date, overdue
state and activity rows.

**Acceptance Scenarios**:

1. **Given** a rider with fewer than five completed trips, **When** a fee would be charged,
   **Then** it is 0 and the trip counts toward the trial.
2. **Given** a rider past the trial who owes 150 EGP, **When** the balance is read, **Then** it is
   due; three days later it is overdue and new bookings are refused naming the amount.
3. **Given** 30 or more EGP owed at month end, **When** the month turns, **Then** it falls due from
   the 1st; below 30 it carries over.
4. **Given** trips finished in the daily records, **When** the rider opens the activity list,
   **Then** each finished trip appears once, with the same wording inputs the fake gives.
5. **Given** a rider who marked "I paid" by InstaPay, **When** the driver reads shares, **Then** the
   row shows the rider's first name and InstaPay — and never a phone, home address or surname.
6. **Given** any wallet action, **When** it runs, **Then** no ledger row records money earned by a
   driver (Law 87/2018).

---

### User Story 4 - A seat marketplace that shows who is driving (Priority: P2)

On the real backend, a rider browsing seat offers sees the driver's first name; a driver sees
their own day including the group legs they drive, the requests addressed to them, can reclaim
a seat offer they cancelled, and sees their finished one-off trips.

**Why this priority**: offers without a driver name look broken next to the demo, and the missing
driver-day items hide trips the driver has committed to.

**Independent Test**: the shared marketplace behaviour list gains cases for each item and passes
on both versions.

**Acceptance Scenarios**:

1. **Given** a published offer, **When** a rider lists offers, **Then** the driver's first name
   shows, and no phone, surname, home or other private fact does.
2. **Given** a driver in a group and a one-off offer on the same day, **When** the driver opens
   their day, **Then** both appear in time order.
3. **Given** a rider posted a request addressed to a driver, **When** that driver lists requests
   for them, **Then** it appears; for any other driver it does not.
4. **Given** a booked seat that a subscriber takes (005 US6), **When** it is reclaimed, **Then** the
   booker is refunded what they paid and a full offer opens again; a subscriber's own seat and a
   seat booked after the cut-off are final, and a reclaim after the cut-off is refused, with the
   same results as the fake.
5. **Given** a finished one-off trip, **When** the driver lists done one-offs, **Then** it appears.

---

### User Story 5 - A group ride the server has not stored yet is still correct (Priority: P2)

On the real backend, a ride that is planned but not stored on the server yet still carries its own
share token and shows each rider's own pickup stop, and a rider's "no cover" choice reaches the
server.

**Why this priority**: today every rider in a planned ride appears at the first stop with no token,
so the share link and pickup sheet are wrong until the server stores the ride.

**Independent Test**: the shared daily behaviour list gains cases for token, per-rider stop and
the "no cover" choice, and passes on both versions.

**Acceptance Scenarios**:

1. **Given** a planned ride not yet stored, **When** its share data is read, **Then** it has a
   real token that is the same on the next read.
2. **Given** a ride with three riders at three stops, **When** it is read, **Then** each rider
   shows their own stop.
3. **Given** a rider who chooses "no cover", **When** the choice is sent, **Then** the server
   stores it and the next read shows it.

---

### User Story 6 - HR sees correct, private numbers on the real backend (Priority: P2)

An HR contact on the real backend sees coverage net of suspensions, and dashboard totals for money,
CO2, parking and route gaps — each shown only when at least five people stand behind it, otherwise
withheld. "Reset demo data" removes the signed-in person's own company rows from the server.
Goora-staff demo actions either work through a documented staff-only path or are explicitly "demo
only on the fakes".

**Why this priority**: the company dashboard is sold on trust; wrong coverage or a leaked small-group
number breaks it. It stays behind flags that are OFF.

**Independent Test**: the shared company behaviour list gains cases for suspensions, k ≥ 5
withholding of each total and clear-all, and passes on both versions; database tests cover the
staff path.

**Acceptance Scenarios**:

1. **Given** a company with six employees of whom two are suspended, **When** coverage is read,
   **Then** it counts four.
2. **Given** a month with fewer than five people behind a total, **When** HR reads the dashboard,
   **Then** that total is withheld, not shown as zero.
3. **Given** five or more people behind a total, **When** HR reads it, **Then** the number shows.
4. **Given** the signed-in person created a company, **When** they choose "reset demo data",
   **Then** the rows they own are gone from the server and rows they do not own are untouched.
5. **Given** a staff action (approve, mark paid, set HR contact, end contract), **When** a
   non-staff caller tries it, **Then** it is refused; **When** the staff path runs, **Then** it
   works and is logged — or the action is documented as fake-only with the reason.

---

### User Story 7 - Two small debts are paid (Priority: P3)

Two things from 011 that nobody should trip over again: the fake trust repository hands out
contact ids that can repeat inside one clock tick, and the trust behaviour list waits 5 ms between
steps to dodge it.

**Why this priority**: low risk, small, but it removes a flaky-test hazard.

**Independent Test**: add two trusted contacts back to back with no pause; they get different ids.

**Acceptance Scenarios**:

1. **Given** two contacts added in the same instant, **When** the fake stores them, **Then** their
   ids differ.
2. **Given** the trust behaviour list, **When** it is read, **Then** it has no sleep.

### Edge Cases

- The Docker engine is not answering → database phases are recorded "DB not run" with the reason;
  the Dart side and written SQL are still delivered and a re-run is one command.
- A rider completes exactly the fifth trial trip while a booking for the sixth is open → the sixth
  is charged; the fifth was fee-free.
- A refund brings owed under 150 before the grace ends → still overdue (008 edge case).
- Month ends with exactly 30 owed → due from the 1st; 29 → carries over.
- A rider is both a driver and a rider in the same corridor → the shares list never shows the person
  to themselves.
- A driver has no first name on file → the offer shows a neutral label, never a blank or an id.
- Two reclaims of the same offer at once → one wins, the other is refused.
- A company has exactly five enrolled employees and one is suspended → money totals withhold
  (four people), coverage shows four.
- A staff action is attempted with an ordinary user session → refused, nothing written.
- "Reset demo data" is run by an employee who owns no company → nothing happens, no error.
- The seed is applied twice → the second run fails loudly or is a no-op; it never duplicates rows.

## Requirements *(mandatory)*

### Functional Requirements

**Switch and floor**

- **FR-001**: `backendLive` MUST stay off by default, and the app with no backend settings MUST
  behave exactly as before; no existing test may be edited to make this feature pass.
- **FR-002**: Every seam's shared behaviour list (contract) MUST be extended for each item below,
  and the on-device and real-backend versions MUST both pass the same list. A contract MUST NOT be
  weakened or have a case removed.
- **FR-003**: The company flags `companyInvoicesLive` and `hrStatementExport` MUST stay off.
- **FR-004**: No secret MAY be committed; no hosted project MAY be touched; local backend only.

**Database truth and seed**

- **FR-005**: The database test suite MUST be run against a freshly reset local database, every
  failure fixed (migrations first, in new migration files), and the real pass/fail counts recorded.
  If the container engine is unavailable, "DB not run" MUST be recorded with the reason.
- **FR-006**: A seed MUST load on every reset: the Cairo↔Ismailia and Sheikh Zayed corridors with
  groups and pickup points, and one company with at least five enrolled employees. All people,
  phones, e-mails and places MUST be fictional; the seed MUST NOT hold a secret.
- **FR-007**: A reset of the local database MUST complete with no error with migrations and seed.

**Wallet**

- **FR-008**: The first five completed trips of a rider MUST be fee-free; the fee from the sixth
  follows the existing pricing rule. Where money is decided, the server MUST decide it; the Dart
  side MUST mirror it and pass the same vectors.
- **FR-009**: A rider's fee balance MUST fall due when owed reaches 150 EGP or when 30 EGP or more
  is owed at month end, MUST turn overdue after a 3-day grace, and MUST block new bookings while
  overdue (008). The due date clears only when owed reaches 0.
- **FR-010**: The wallet's activity list MUST include one row per trip finished in the daily
  records, derived server-side from those records, never from client input.
- **FR-011**: A "who paid" share MUST carry the rider's first name and the method the rider
  actually recorded; it MUST NOT carry a surname, phone, home or any other private fact.
- **FR-012**: No new column, ledger kind or call MAY record a driver's income (Law 87/2018).

**Marketplace**

- **FR-013**: A seat offer MUST carry the driver's first name, delivered through a narrow door;
  profile rows MUST stay readable by their owner only, and no phone or home may leave.
- **FR-014**: A driver's day MUST include the group legs the driver drives, in time order with
  one-off trips.
- **FR-015**: Requests addressed to a driver MUST be listed for that driver and no other.
- **FR-016**: A booked seat MUST be reclaimable by the booker or the offer's driver with the fake's
  rules (refund, final for subscriber seats and post-cut-off bookings, refused after the cut-off);
  the two-trips-a-day cap and the cost cap (Law 87/2018) MUST hold.
- **FR-017**: A driver's finished one-off trips MUST be listed.

**Daily**

- **FR-018**: A planned-but-unstored ride MUST carry a stable, real share token and each rider's own
  stop.
- **FR-019**: The rider's "no cover" choice MUST be sent to the server and read back.

**Company**

- **FR-020**: Coverage MUST subtract suspended employees.
- **FR-021**: Dashboard money, CO2, parking and route-gap totals MUST be computed on the server and
  withheld when fewer than five people stand behind them (010 R9).
- **FR-022**: Goora-staff actions on the real backend MUST either go through a documented
  service-role path that ordinary callers cannot use, or be explicitly recorded as "demo only on the
  fakes"; either way the choice is logged with the rejected alternative.
- **FR-023**: "Reset demo data" on the real backend MUST remove the server rows the signed-in
  person owns and no others.

**Small debts**

- **FR-024**: The fake trust repository MUST NOT issue the same contact id twice; the trust
  behaviour list MUST have no timed pause.

**Hand-off**

- **FR-025**: The README "Running against local Supabase" MUST cover seed, reset and database tests;
  research.md MUST log every decision with its rejected option; the goora-status skill MUST get a
  dated block at its top.

### Key Entities

- **Trial counter**: a rider's number of completed trips, deciding fee-free (first five) or fee.
- **Fee balance**: owed amount, due date, overdue state, derived from the ledger (008).
- **Share row**: a driver-facing line "first name · amount · method · status" for one trip, no
  other personal fact.
- **Driver day item**: a dated, timed entry for a group leg or a one-off offer.
- **Share token**: a stable random value naming one ride for a share link.
- **Coverage / dashboard total**: company numbers, each tagged shown or withheld by the k ≥ 5 rule.
- **Seed corridor**: fictional demo groups, pickup points and one company with five or more
  employees loaded on reset.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With no backend settings, 100% of existing tests pass unchanged, with at least 1944
  app tests and 276 server-rule tests.
- **SC-002**: The database test suite runs against a reset local database with 0 failures and its
  counts are recorded; or "DB not run" with a named reason when the engine is unavailable.
- **SC-003**: A reset of the local database with the seed ends with 0 errors and at least 1 group
  per seeded corridor and 5 enrolled employees in the seeded company.
- **SC-004**: Each of the 7 seams' shared behaviour lists passes on both versions, with at least one
  new case for every item in FR-008 to FR-023.
- **SC-005**: Every "Known gap" in 011 research is either closed or re-filed with a stated reason:
  0 left unmentioned.
- **SC-006**: 0 ledger kinds, columns or calls record driver income; a database test scans for it.
- **SC-007**: A scan of the diff finds 0 secrets and 0 real personal data.
- **SC-008**: Two trusted contacts added in one clock tick get different ids in 100% of runs, with
  no pause in the test.

## Assumptions

- Local only: no hosted project; deploying is the founder's call. Phone codes and payments stay
  fake (012); OTP, payment partner and tile provider are the founder's (Q4).
- Amounts stay whole Egyptian pounds as integers, as in 011 D8 (the lane brief says "piasters";
  the domain, the rule twins and the existing tables are whole pounds — logged as a decision).
- Screens are not changed in this lane. A gap that needs a screen change is filed as a follow-up.
- The fee-free trial count and the fee/overdue maths already exist as pure Dart with TypeScript
  twins and vectors; this lane moves where they are *applied* (the server), not the rules.
- The shared Docker engine may be unresponsive; database phases then wait or are recorded as not
  run, per FR-005. Another project's database stack on the same engine must not be touched.
