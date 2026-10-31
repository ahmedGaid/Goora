# Research: Live-Mode Parity for the Real Backend (013)

Long autonomous lane (2026-10-31): no founder questions were asked. Every open point was answered
by the implementing session, picking the defensible option; each answer is a numbered decision
below with the rejected alternative. A founder answer that differs changes only that decision.

## Clarify — questions answered by the session (2026-10-31)

| # | Question | Answer | Decision |
|---|---|---|---|
| Q1 | The lane brief says "money stays integer piasters"; the domain, the rule twins and every table are whole EGP (011 D8). Which unit? | Whole EGP integers, unchanged. | D1 |
| Q2 | Where is the wallet's fee state decided (trial, owed, due, overdue, trip rows)? | In the database, by one read function; the device maps its answer. | D2, D3, D4 |
| Q3 | Does the server also refuse a booking while the balance is overdue? | Yes for book / post / accept; the device gate stays as the friendly first line. | D5 |
| Q4 | How does a first name reach another person without opening `profiles`? | Narrow `security definer` functions that return first name (+ rating) only. | D6, D7 |
| Q5 | Goora-staff actions on the real backend: edge function or fake-only? | Staff SQL functions callable by `service_role` only; the app's `demo*` buttons stay no-ops on live ("demo only on fakes"). | D12 |
| Q6 | Docker may stay hung. What is the fallback for the database phases? | Write SQL anyway, validate on a scratch native PostgreSQL 16 with a documented shim if Docker is still down at the gates, and record exactly what ran. | D15 |
| Q7 | Do any "Known gaps" need a screen change? | None found; any that appears is filed as a follow-up (presentation is not ours). | D16 |

## Decisions

### D1 — Money: whole EGP integers (Q1)
Same as 011 D8. Rejected: piasters (the lane brief's wording) — two units in one schema, and it
rewrites the Dart/TS rule twins and their vectors, which FR-001 forbids without a moved rule.

### D2 — The wallet's fee state is one read function: `wallet_state()` (Q2)
`security definer`, caller-only (reads `auth.uid()`; no person parameter). It walks the caller's
finished group trips (`reliability_events` kind `kept` where the caller did not drive), finished
one-off seats (`bookings`), charges and free cancellations in date order and returns JSON:
`{trialDone, strikes, trialOn, debits, bundleLeft, feeDue, feeOverdue, entries[]}`. `entries` carry
the same ids and kinds as `FakeWalletRepository._riderTrips` (`cash:<ride>`, `trip:<ride>`,
`bundle-trip:<ride>`, `charge:<id>`, `absence:...`). The device's `getWallet` adds
`sum(wallet_entries.delta) − debits` for the balance, exactly as the fake does.
Rejected: (a) deriving on the device from raw rows, as the fake does — the server could then never
enforce the overdue block (D5) and every client would re-implement 008; (b) a TS Edge Function using
the existing twins — an extra hop, no transaction with the ledger, and the wallet's other money
moves are all SQL; (c) posting derived rows into `wallet_entries` by a cron — a writer that must
never double-post against the `seat:` rows, and no scheduler exists locally.

### D3 — Third copy of the rule, kept honest by generated vectors
`pay_equal_share`, `pay_cash_amount`, `direct_pay_share`, `direct_pay_fee` and `fee_due_date` are SQL
twins of `PricingService`, `DirectPay` and `FeeBalancePolicy`. A small Node script
(`supabase/tests/gen_vector_tests.mjs`) turns the existing `test/fixtures/*_vectors.json` into
`supabase/tests/60_vectors.test.sql`; a `node --test` file regenerates in memory and fails when the
committed SQL differs, so the three copies cannot drift unnoticed even without a database.
Rejected: hand-copied expectations (drift), a PL/Deno function (not in the local stack).

### D4 — Trip rows are derived on read, never stored
Same as the fake (007 R5/R6). Rejected: storing them at trip end — needs a trigger/cron, risks a
double count against `seat:`/`refund:` rows, and rows would freeze a price the fake recomputes.

### D5 — The server refuses book / post / accept while overdue
`wallet_assert_open()` raises `refused:feeOverdue:<owed>`; `market_book`, `market_post` and
`market_accept` call it first (new migration, `create or replace`). The Dart repositories already
return `BookFeeOverdue` from the device gate, so the new refusal maps to the same result.
Rejected: server enforcement only — the screens need the amount before the tap.

### D6 — Driver first name on seat offers: `market_offer_cards()`
`security definer` function returning the open offers (same filter as the table read) joined with
the driver's `first_name`, `rating`, `driver_is_woman` and `initials` (first + last initial, exactly
what the existing `groups_for()` already gives a group's drivers) and the taken-seat count (other
riders' bookings are private, so the count is made in the function) — no surname, phone, home or id
beyond the driver's own id. With `p_ids` it returns those offers, including the caller's booked ones
after the offer filled or was cancelled (a booked seat's card). `profiles` stays owner-only.
Rejected: a public view of `profiles` (exposes columns by default), widening the profiles policy.

### D7 — Share rows: `wallet_share_rows(p_role)`
Returns, for the caller as rider or as driver, one row per share: ride, other party's **first name**,
the rider's recorded method, amount, mark outcome, claim flag, trip end. Never a surname/phone/home.
The share amount uses `direct_pay_share` with the ride's group price/trip cost/seats or the
one-off's own numbers. Rejected: joining client-side (needs profile reads we deny).

### D8 — Group legs in `driverDay`, `requestsForMe`, `doneOneOffs`
`driverDay` group legs: pure Dart over `DailyCommuteRepository.schedule/ride` and
`SeatMath.ownGroupLeg`, like the fake (no group-seat bookings exist on live, so `holds` is empty).
`requestsForMe`: `market_requests_for(p_leg)` returns posted requests not the caller's, with only
`is_woman` of the rider; privacy filter and fit are applied on the device with the same domain rules.
`doneOneOffs`: `market_done_one_offs()` returns finished seats the caller rode or drove with first
names. Rejected: opening `trip_requests` / `bookings` to all drivers.

### D9 — `market_reclaim(p_booking)`
Rules copied from `FakeMarketplaceRepository.reclaim` (005 US6: a subscriber takes the seat). The
caller must be the booking's rider or the offer's driver (the fake has no caller; a stranger is
refused). Status booked, not a subscriber's
seat, not booked after the cut-off, refuse after the cut-off (`reclaimTooLate`), refund the paid fee
as a `seatRefund` row, reopen a `full` offer. The cut-off is `is_late(date, at)`, SQL twin of
`AttendanceRules.isLate` (21:00 the evening before), vectors in D3. 011 listed this function but the
migration never defined it; this lane adds it.

### D9a — Found while closing the marketplace gaps
- **`accept` could never work live**: it pre-read the request from `trip_requests`, which a driver
  cannot read (RLS: own rows only), so it always answered "doesn't fit". It now finds the request
  among the cards `market_requests_for` returns, then calls `market_accept`.
- **Re-filed (not closed): accepting a request that *joins* a trip the driver already has** (the fake's
  `AcceptJoined`) needs a server function that books the rider on the driver's existing offer; the
  live repository refuses such a request instead of adding a third trip. Follow-up: `market_accept_join`.
- The seat-reclaimed notice needed `notices_kind_check` to allow `seatReclaimed`; done in
  `20261031000200` (a new constraint, the 003 one dropped inside the same migration).

### D10 — Daily: a `ride` and a `noCover` action on the existing `commute-day` function
`ride {date, leg}` calls the existing `ensureRides` for the caller's group and date, then returns the
ride id; the device reads the stored row (real token, own stops). `noCover {date, leg}` inserts the
rider's `absences` row of kind `noCover` (always free) and is refused unless the ride has no driver.
Rejected: minting a token on the device (a guessable/unstored value), a SQL port of the rotation
planner (a fourth copy).

### D11 — Company coverage and dashboard
`company_suspensions(p_company)` (definer; the company's HR contact or one of its enrolled
employees — an employee cannot read the company row) returns `{approvedAt, endedAt, invoices:
[{dueOn, paidAt}]}`, the invoices being those past their suspension day; the device feeds them to
`CompanyRules.activeWindows` and intersects with the enrollment window — no SQL port of the window
maths. `company_dashboard` is replaced (new migration) to add `moneySaved`, `co2Kg`, `parkingPerDay`
and `routeGaps`, each `null`/empty below five people (010 R9, R7): money = Σ (leg trip cost − share)
over rider trips; CO₂ = km × 0.1645 kg; parking = going rider trips ÷ workdays; km from a small
`corridor_legs` table (Cairo↔Ismailia 123, Sheikh Zayed↔Smart Village 13; other pairs 0 and said so).
Rejected: returning invoice rows to employees (more than needed).

### D12 — Goora-staff actions (Q5)
`staff_company_approve`, `staff_invoice_mark_paid`, `staff_company_set_hr`, `staff_company_end`:
SQL functions with `execute` granted to `service_role` only, each writing the company log line.
The app's `demo*` methods stay no-ops on live: the app is not a staff tool, and an Edge Function the
app could call would make every signed-in user "staff". pgTAP proves `authenticated` is refused.
`company_reset_mine()` (definer) deletes the caller's own enrollments, consent and paused plan and
any company where they are the only HR contact and nothing is paid; it backs `clearAll`.

### D13 — Seed
`supabase/seed.sql`, idempotent (`on conflict do nothing`), fictional only: auth users with
`@seed.goora.test` addresses, two corridors (Cairo↔Ismailia, Sheikh Zayed↔Smart Village) with 3
groups and pickup points, one active company "Demo Motors" with 6 enrolled employees, 5 consenting.
A pgTAP file checks counts.

### D14 — Fixes found by the first database run
Recorded in the "Results log" below as they happen. Rule: a failing test is fixed in a **new**
migration; an applied migration is never edited.

### D15 — Docker fallback (Q6)
`docker info` timed out at the start of this lane (2026-10-31, 60 s, exit 124); the conductor was told
once. Non-DB phases go on. If Docker is still down when the database gates come, a scratch cluster
from the machine's native PostgreSQL 16 on port 55499 (own data dir under the scratchpad; the
service on 5432 is not touched) runs the migrations through a shim for what Supabase provides
(roles, `auth.users`, `auth.uid()`, `extensions` schema, a stand-in for PostGIS types) and a small
pgTAP-compatible assertion shim. That run is reported as **"scratch PG16 + shim"**, never as the real
`supabase test db`. When Docker answers, the real run replaces it.

### D16 — Follow-ups, re-filed with a reason (not done in this lane)
1. **Accepting a request that joins a trip the driver already has** (the fake's `AcceptJoined`) —
   needs a server function that books the rider on the driver's existing offer
   (`market_accept_join`). Live refuses such a request (D9a). Reason: a new money-adjacent write
   path, outside the listed gaps.
2. **A live contract run against a real database.** 011 D20 describes `GOORA_CONTRACT_*` defines;
   no such runner was ever written. The SQL is proven by pgTAP, the Dart mapping by the in-memory
   contracts; the two meet only in a real app run (README steps). Reason: needs a running stack.
3. **Fee-free history of a *personal* plan that was replaced** is not kept on the server (only
   ended company windows are, in `plan_cover_windows`); the fake keeps both. Reason: no live flow
   replaces a plan yet.
4. **Group trip end time** in shares is the recorded `rides.ended_at`, else the planned arrival +
   1 h as an estimate (the SQL has no corridor-minutes table). It affects only the 24-hour
   auto-receive clock of a share whose driver never ended the trip.
5. **The Edge Function glue** (`commute-day` actions `ride` and `noCover`) is not type-checked or
   run here (no Deno on this machine); its rule is a tested pure function (`_shared/no_cover.ts`).
6. **Presentation:** no screen change was needed; none is filed.

## Known gaps (011) → where each closes

| 011 gap | Closed by |
|---|---|
| Wallet: cash trial, feeDue/feeOverdue, trip rows, shares first name + method | **closed** — D2–D5, D7 (WT1–WT8, pgTAP 50/55/60) |
| Company: suspensions, dashboard money/CO2/parking/route gaps, staff `demo*`, `clearAll` | **closed** — D11, D12 (CS1–CS7, pgTAP 70); staff `demo*` = documented "demo only on the fakes" + service-role `staff_*` |
| Marketplace: driver name, group legs, requestsForMe, reclaim, doneOneOffs | **closed** — D6, D8, D9 (ML1–ML6, pgTAP 65); accept-join re-filed |
| Daily: unstored ride token + stops, "no cover" | **closed** — D10 (D7/D8 contract, ST1–ST3, node no_cover) |
| Seed (T015) | **closed** — D13 (`seed.sql`, pgTAP 80) |
| F1 fake trust ids / 5 ms pacing | **closed** (P6, `fake_trust_ids_test.dart`, pacing removed) |
| *New:* `accept` could never find its request under RLS | **closed** (D9a); join-an-existing-trip re-filed (D16 #1) |

## Analyze pass (2026-10-31, after tasks.md)

| ID | Severity | Finding | Fix |
|---|---|---|---|
| A1 | MEDIUM | Spec US4/FR-016 described `reclaim` as "driver takes back a cancelled offer"; the interface and fake say a subscriber takes a booked seat (005 US6) | Spec and D9 corrected; caller rule added |
| A2 | MEDIUM | T005 would have meant editing an existing fake test | New file `test/unit/fake_trust_ids_test.dart` |
| A3 | MEDIUM | 008 FR-005 blocks Join too; the guard covered Book/Post/accept only | T020 adds `join_group` |
| A4 | LOW | SQL "tests first": a pgTAP file cannot fail without a database | Write T017 before T016; its first run (harness or real) must fail before the function exists |
| A5 | MEDIUM | P1 and the SQL of P2–P5 depend on a database; Docker was hung | D15 fallback, labelled honestly; tasks keep working without it |

No CRITICAL findings. Every FR maps to a task: FR-001/002 → every contract task + T041 · FR-003 →
T037, T041 · FR-004 → T041 · FR-005 → T009, T010 · FR-006/007 → T011–T013 · FR-008/009 → T015–T020 ·
FR-010/011 → T016, T019 · FR-012 → T017 · FR-013–015 → T022–T026 · FR-016 → T023, T026 · FR-017 →
T022, T026 · FR-018/019 → T028–T031 · FR-020–023 → T033–T037 · FR-024 → T005–T007 · FR-025 →
T039, T040, T042.

## Results log

### 2026-10-31 — P1 database truth (scratch PG16 + shim, NOT the real `supabase test db`)

- **Docker**: `docker info` timed out at 60 s (exit 124) at the start and again before P1 (25 s).
  The conductor was told once (accepted: "told the founder"). Not restarted by this lane.
- **Harness** (D15, `supabase/scratch/`): native PostgreSQL 16.15 on a throwaway cluster, port 55499,
  own data dir in the session scratchpad (the machine's 5432 service untouched); real **pgTAP v1.3.3**
  built from the official release (source scanned: no `COPY PROGRAM` / file functions); a shim for
  roles, `auth.users`/`auth.uid()`, the `extensions` schema, PostGIS types (`point`), `pg_cron`.
- **Migrations**: all 9 apply with no error. **Seed**: applies clean, twice (idempotent).
- **First run of the 011 pgTAP files**: 3 + 16 + 17 + 9 = 45 assertions passed at once; the profile
  file (14) failed to *load* — a **test bug**, not a migration bug: `UPDATE … RETURNING` inside a
  `FROM` subquery is invalid SQL. Fixed in the test (row-count helper). No migration needed a fix,
  so `20261031000000_pgtap_fixes.sql` was not created.
- **After the fix + `80_seed.test.sql` (new, 9)**: `00` 3 · `10` 14 · `20` 16 · `30` 17 · `40` 9 ·
  `80` 9 = **68 / 68 ok, 0 not ok, 0 SQL errors**.
- **What this does not prove**: R2 ("anon holds no grant on any table") depends on the platform's
  default privileges, which the shim does not copy; PostGIS behaviour is stubbed. The real
  `supabase db reset` + `supabase test db` must still be run once Docker answers — **DB real run:
  pending**.
- **D6 note**: the existing `groups_for()` already gives drivers `initials` = first + last initial;
  `market_offer_cards` follows that precedent (no new exposure).

### 2026-10-31 — P2–P5 database and app results

- **Bugs the tests caught in the lane's own SQL** (fixed before commit, no applied migration edited):
  `wallet_state()` returned early when the rider had no "since" and skipped due/overdue — the fake
  computes them from the ledger regardless (found by `55_overdue_guard`); `accept` read its request
  through RLS (D9a); a company employee cannot read the company row, so `company_suspensions` also
  returns `approvedAt` / `endedAt` (found while writing the Dart side).
- **New pgTAP files**: `50_wallet_state` 24 · `55_overdue_guard` 7 · `60_vectors` 114 (generated from
  the shared JSON; stale-guard in `node --test`) · `65_marketplace_live` 22 · `70_company_live` 21.
- **Full pgTAP run on the scratch cluster (clean reset, all 9 + 4 migrations + seed)**:
  `00` 3 · `10` 14 · `20` 16 · `30` 17 · `40` 9 · `50` 24 · `55` 7 · `60` 114 · `65` 22 · `70` 21 ·
  `80` 9 = **256 / 256 ok, 0 not ok, 0 SQL errors** — "scratch PG16 + shim", **not** `supabase test db`.
- **Contracts** (in-memory gateway, fake and Supabase over the same cases): wallet trips WT1–WT8
  (16 runs), marketplace live ML1–ML2 (4 runs), daily D7–D8 added to the existing daily contract;
  Supabase-only: marketplace ML3–ML6, daily ST1–ST3, company CS1–CS7. All of `test/contract`: 123 green.
- **Existing tests**: none edited outside `test/contract/**`; in the contracts only additions (daily
  D7/D8), the requested removal of the 5 ms pacing (trust), and test-server support code. No golden
  changed.

### 2026-10-31 — final gates (worktree Goora-live, branch 013-live-parity)

| Gate | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test --concurrency=1` | **1984 passed** (baseline 1944; floor ≥ 1944) |
| `node --test "supabase/functions/_shared/*.test.ts"` | **281 passed** (baseline 276; +2 vector guard, +3 no-cover) |
| pgTAP, scratch PG16 + shim | **256 / 256** ok (not the real `supabase test db`) |
| Real `supabase db reset` / `supabase test db` | **not run** — `docker info` timed out (exit 124) at the start, before P1, and at the close; never restarted by this lane |
| Goldens changed | none |
| Files outside `specs/013*`, `supabase/**`, `test/contract/**`: | the 5 `lib/features/*/data/*` repos + `fake_trust_repository.dart`, `test/unit/fake_trust_ids_test.dart` (new), README |
| gitleaks `main..HEAD` | no leaks |
