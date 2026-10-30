# Research: Real Backend Behind the Repository Seams (011)

Long autonomous lane (2026-10-30): no founder questions were asked. Every open point was answered
by the implementing session, picking the defensible option; each answer is a numbered decision
below with the rejected alternative. A founder answer that differs changes only that decision.

## Clarify — questions answered by the session (2026-10-30)

| # | Question | Answer | Decision |
|---|---|---|---|
| Q1 | The brief for this lane says "money stays integer piasters", but the domain, the TS twins and the three existing migrations all use whole EGP. Which unit does the server store? | Whole EGP integers, as today. | D8 |
| Q2 | With the OTP provider still fake (012), how does the app get a real server session? | A local-only bridge: the fake code is checked on the device, then a password session per phone number. | D5 |
| Q3 | What does "offline" mean with the backend on? | Unreachable at start → this run uses the fakes; mid-session failures map to the seam's existing failure types. | D6, D7 |
| Q4 | What do demo-only calls (demo buttons, reset demo data, seeded people) do on the real backend? | Nothing harmful: they answer "nothing to do" and change no server row. | D4, D16, D13 |
| Q5 | Which gaps in the three existing migrations does this lane fix? | API grants (new tables aren't auto-exposed any more), the six areas added in 006, write rules the clients need, and the cost-cap CHECK. | D17 |

## Decisions

### D1 — One flag, read from the build: `Env.backendLive`
`static const backendLiveRequested = bool.fromEnvironment('BACKEND_LIVE')`, and
`backendLive => backendLiveRequested && hasSupabase`. Default off; no committed file turns it on
(`.env.example` gains an empty `BACKEND_LIVE=`).
Rejected: a plain `false` constant like `CompanyFlags` — those gate legal/financial switches and
must change only by reviewed code; this one only picks storage, hosted deploy is blocked anyway,
and a developer must be able to try the local backend without editing code. Rejected: a Settings
toggle — new copy and a way to split one person's data across two stores mid-demo.

### D2 — Where the choice is made: each seam's provider, through `backendModeProvider`
`lib/core/backend/backend_providers.dart` exposes `backendModeProvider` (fake | live, overridable
in tests) and `backendGatewayProvider`. Each existing `xRepository` provider reads the mode and
builds the fake exactly as today or the Supabase implementation. Cross-seam callbacks (wallet ↔
marketplace ↔ company) keep their `ref.read`-inside-a-callback pattern (005 lesson).
Rejected: swapping providers with `ProviderScope.overrides` in `main.dart` — a second provider
graph to keep in sync, and widget tests that build `ProviderScope` themselves would bypass it.

### D3 — A thin port, `BackendGateway`, between repositories and `SupabaseClient`
Operations: `select` (eq / gte / lte / in filters, order, limit), `insert`, `upsert`, `update`,
`delete`, `rpc`, `invoke` (Edge Function), `userId`, and an `auth` part (password sign-in/up,
sign-out, current email). Rows are `Map<String, Object?>`. `SupabaseGateway` adapts it;
`InMemoryGateway` (test only) keeps tables in maps, emulates primary/unique keys and lets a test
register RPC and Edge Function handlers.
Rejected: mocking `SupabaseClient`'s fluent builders (brittle, needs a mocking package —
constitution IX); an HTTP-level PostgREST fake (bigger than the port).

### D4 — What a contract covers
Per seam, a behaviour list run from a neutral starting state (a signed-in person, an optional
group/company the harness seeds through each implementation's own storage). It covers round trips,
ownership, refusals, idempotence and amounts. It leaves out what only the demo has — seeded people
and history, demo buttons, "reset demo data" — which stays pinned by the existing
`fake_*_repository_test.dart` files.
Rejected: running every existing fake test against both — those tests pin the seeded simulation
(rotation history, Valeo, demo corridor), which a real server does not have.

### D5 — Sign-in bridge until 012: device code check + password session, local URLs only
`SupabaseAuthRepository` keeps the existing `OtpProvider` (fake: `123456`) for `sendCode`/
`verifyCode`. After a correct code it signs in with email `p<e164 digits>@phone.goora.test` and a
password derived from the number; on "invalid credentials" it signs up. `existingAccount` = the
sign-in succeeded — exactly `FakeAuthRepository`'s meaning (this number had an account), and the
same account on any device. It refuses to run (throws `StateError`) unless the backend URL is
local (`localhost`, `127.0.0.1`, `10.0.2.2`) **and** the OTP provider is fake: anyone who knows a
number can sign in as it, which is what the fake code already allows and no more. `isFake` stays
true (the code screen keeps its test-code hint). 012 swaps this for Supabase phone OTP.
Rejected: anonymous sign-in — a new account on every install (existing accounts always read as new)
and a `config.toml` change; Supabase phone auth with `test_otp` — only listed numbers work; a real
SMS provider — that is 012.

### D6 — Unreachable at start → this run uses the fakes
`Backend.init()` (called once in `main.dart`) does nothing when `backendLive` is off. When on, it
initialises Supabase and probes `<url>/auth/v1/health` with a 3 s timeout; on failure the mode is
`fake` for this run and a debug log says why. No copy, no screen.
Rejected: a read-through cache in every seam (a second store per seam and stale/split data);
a blocking "can't reach server" screen (new copy, and the demo works offline today).

### D7 — Failures map to the seam's existing types
`BackendFailure` (sealed): `BackendOffline`, `BackendUnauthorized`, `BackendConflict(code)`,
`BackendRefused(reason)`, `BackendError`. `mapBackendError` turns `PostgrestException`,
`AuthException`, `FunctionException`, `SocketException`/`ClientException`/`TimeoutException` into
them. Each repository translates where its interface names a type: `AuthNetworkException`,
`InvalidCodeException`, `TrustRefused`, `AttendanceRefused`, `NotHrContact`, `StateError`, the
sealed result classes (e.g. `SeatTaken`). Anything else is rethrown as `BackendFailure`, matching
the contracts' "storage failures throw". Server functions refuse with
`raise exception 'refused:<reason>' using errcode = 'P0001'`; Edge Functions with HTTP 409
`{ refused }` (003 contract).
Rejected: new error copy per failure (spec says none if avoidable).

### D8 — Money: whole EGP integers (Q1)
Every new money column is `integer` whole EGP with `CHECK`s (≥ 0 where a negative is meaningless;
ledger amounts are signed). Same unit as the domain (`Wallet.balance` "Whole EGP"), the TS twins
and the existing `charges.amount`, `groups.price`, `offered_trips.contribution`.
Rejected: piasters on new tables only (two units in one schema — the bug walk N-5 was about units
on screen, this would be units in data); piasters everywhere (rewrites the rule twins and their
vectors, which FR-016 forbids without a moved rule).

### D9 — Law 87/2018: no driver-income path
The ledger (`wallet_entries.kind`) allows `topUp`, `withdrawal`, `subscription`, `seatBooked`,
`seatRefund`, `settlement`, `bundle`, `bundleTrip`, `trip`, `cashTrip`, `tripDeduction`,
`lateCancelCharge`, `freeCancelZero` (the rider's own Goora money only; corrected at P6 from the
planned `tripFee`/`charge` to match `ActivityKind`) — never `tripIncome`,
`feeReceived`, `cashReceived` or any payout/earning kind. No column anywhere is named or used for
driver income. The driver's share stays a status: `share_marks` (driver's answer) and
`share_claims` (rider's "I paid"), no amount credited to anyone. `wallet_withdraw` refuses more
than the person's own positive balance (their own top-ups). A pgTAP test asserts the kind list and
scans `information_schema.columns` for income/earning/payout/profit names.
Legacy 004 driver rows (`tripIncome` etc.) exist only in the fakes' seeded demo.

### D10 — Who writes what
Own-row, single-person writes go straight to the table under RLS: profile, commute profile,
trusted contacts, payment method, InstaPay handle, privacy choice (a trigger keeps the choice
available — women-only needs a woman, same-company needs a company, same-compound a compound,
mirroring `PrivacyRules.available`'s facts, not its code). Money moves, cross-person writes and
status changes go through `security definer` functions that check the caller and re-check the rule
in the same transaction (contracts/server-functions.md). Columns the owner must not set
(`rider_id_status`, `driver_docs`, `work_email_verified`, `rating`, `reliability`) are revoked from
`authenticated` with column-level grants.

### D11 — Trust statuses on the profile row
`profiles` gains `phone`, `rider_id_status` (`notVerified` | `pending` | `verified`, default
`notVerified` = 009 sign-up), `driver_docs` (`notNeeded` | `pending` | `verified`), `work_email`,
`work_email_verified`. `submit_rider_id()` sets `verified` at once, like the fakes (a real check
may set `pending` first — 012/later). `start_driver_verification()` sets `pending`. Verification
items in `TrustProfile` are built from these columns with the same statuses the fake shows.

### D12 — Company privacy in the database (010 R9)
Tables `companies`, `company_domains` (unique `domain`), `enrollments`, `invoices`, `company_log`,
`hr_consents`, `paused_plans`. RLS: an employee reads their own enrollments and consent; the HR
contact reads their company row, domains, invoices and log. The roster is only the view
`company_roster` (name, work email, since, status — four columns, the HR contact's company only).
Dashboard and statement are only `company_dashboard(company, month)` and
`company_statement(company, month)`: `security definer`, caller must be the HR contact; the
dashboard returns `null` for any count built from fewer than 5 people (k = 5); the statement lists
only employees whose consent is on. No HR call returns a person id, group, pickup, time, share or
role. Staff writes (approve, mark paid, set HR contact, end contract) are service-role only; the
app's demo buttons do nothing on the real backend.

### D13 — Company registration and enrollment
`company_register(name, domains, hr_work_email)` inserts a pending company, its domains and the log
line in one transaction; a taken domain refuses with `refused:domainTaken:<domain>`; the HR work
email must be on one of the domains. Public-mail domains are refused on the device by the same
`CompanyRules` check the fake uses; the company stays `pending` until Goora staff approve, which
is the server-side gate. `company_enroll()` reads the caller's verified work email, finds the
active/suspended company holding its domain and opens an enrollment (consent = now) — refusing
`notEligible` otherwise. `company_leave()` closes it (`why = left`). `clearAll` on the real backend
changes nothing on the server.
Rejected: a server copy of the public-domain list (a third copy of a twin rule; approval already
gates it — revisit with the R9 invoice Edge Function).

### D14 — Clock
The fakes take the demo clock (`now`); the server stamps with `now()` in Africa/Cairo where a rule
needs wall time (003 R2). Supabase repositories do not send times for writes the server stamps.
Contract cases whose result depends on the demo clock are marked `clockBound` and run only over
`InMemoryGateway`, where the harness passes the case's time to the handler.

### D15 — Daily commute: tables for reads, `commute-day` for actions
Reads use the 003 tables under their RLS (rides, absences, check-ins, outcomes, charges, events,
notices). The schedule is built on the device with `RotationPlanner` from the group, absences and
backups, as the fake does. Actions call the existing `commute-day` Edge Function with the 003
contract's action names and map `{ refused }` to `AttendanceRefused`/`UndoResult`. Notices: read on
subscribe and after `markRead` (no realtime). The fake's `NoticeSink` role (posting marketplace
notices) has no client path on the real backend: the server writes notices.
Rejected: a realtime channel for notices (realtime is not part of the local stack used here; more
moving parts than this lane needs).

### D16 — Marketplace: existing tables + `market_*` functions
Writes go through `market_publish`, `market_post`, `market_cancel_request`, `market_book`,
`market_cancel_booking`, `market_cancel_offer`, `market_accept`, `market_reclaim`. Prices come from
the Dart twin on the device and are re-checked by the cost-cap CHECK (`contribution × rider_seats ≤
trip_cost`, equivalent to `contribution ≤ ⌊trip_cost / rider_seats⌋`) — Law 87's "riders' total ≤
trip cost" as an invariant, not a copy of the maths. The two-trips-a-day cap is re-checked inside
`market_publish`/`market_accept` (a count, the limit 2 from the constitution). Booking re-checks free
seats under a row lock; the `unique (rider_id, trip_date, leg)` constraint makes a double booking
`alreadyRiding`. Demo calls answer `DemoNothing`.

### D17 — What the three existing migrations miss (Q5)
1. **API grants**: `config.toml` documents that new tables are no longer exposed to the API roles
   without explicit grants; none of the three migrations grant anything. `20261030000000` grants
   `select/insert/update/delete` per table to `authenticated` only where a policy exists, and
   nothing to `anon`.
2. **Areas**: `commute_profiles.home_area/work_area`, `offered_trips.origin_area/destination_area`,
   `trip_requests.*_area` allow only the three 002 areas; 006 added six (`newCairo`, `nasrCity`,
   `heliopolis`, `obour`, `tenthOfRamadan`, `ismailia`). The checks are replaced with the nine.
3. **Cost cap**: `offered_trips` gains `check (contribution * rider_seats <= trip_cost)`.
4. **Missing client rules**: `profiles` is readable only by its owner, so group screens need
   members' public facts — served by `group_cards(...)` (definer, first name only for drivers,
   no rider names to drivers — constitution IV).

### D18 — Commute: groups through a function, membership through a function
`groups_for(origin, destination)` returns the corridor's groups with pickup points and members'
public facts. `join_group(group)` inserts the membership after checking the group exists (the fake
throws `ArgumentError` for an unknown id; the real one refuses `noSuchGroup`, mapped to the same
`ArgumentError`). `join_waitlist(origin, destination)` upserts the row and returns its position
(rows ahead + 1). `homePlaces`/`workPlaces` stay the corridor's static lists, as in the fake.

### D19 — Local stack on shifted ports
Another project's stack (project id `backend`) holds the default ports 54321–54327 on this machine,
and must not be stopped. The session runs Goora's stack from a scratch copy of `supabase/` whose
`config.toml` shifts every port by +1000 (55321 API, 55322 DB) with `project_id = "goora011"`;
the repo's `config.toml` is unchanged. The README documents the default ports for a clean machine.

### D20 — Live contract runs are opt-in
The contract runners read `GOORA_CONTRACT_DB_URL`, `GOORA_CONTRACT_ANON_KEY` and
`GOORA_CONTRACT_SERVICE_KEY` from `--dart-define`. When absent, the live group is skipped and the
test prints "DB not run". The keys are the local demo keys `supabase status` prints; they are never
committed.

### D21 — `lib/main.dart` gets one line
`Supabase.initialize` must run before the first provider reads the client, so `main.dart` awaits
`Backend.init()` before `runApp`. `main.dart` is outside this lane's OWNS list but in no other
lane's either; the line does nothing when `backendLive` is off.
Rejected: initialising lazily inside a provider — Riverpod providers can't await, so the first
screen would race the client.

### D22 — Groups carry a display document (`groups.card`)
The 002 columns stay the PostGIS matching inputs; `groups.card` / `group_members.card` (jsonb)
hold the rest of the app's `CommuteGroup` / `Member` JSON (stops, vehicle, seats, days).
`groups_for()` merges them with names and ratings from `profiles` at read time, with the privacy
cuts of constitution IV. Rejected: one column per display field — a dozen columns that only mirror
a Dart class and drift from it.

### D23 — Contract cases changed while writing them
- K5 was "setHrConsent(true) → true": the fake refuses consent without an enrollment, and
  enrolling needs a company Goora approved (a staff action, service role only). K5 is now "never
  enrolled → no consent". K6 was "roster by a non-HR → NotHrContact": the fake has no caller to
  check, so K6 is now "HR adds a domain; a held domain is refused". Both originals are covered by
  `supabase/tests/30_company.test.sql`.
- Daily D3/D4 (cut-off charges) belong to the `commute-day` Edge Function; their rules run as the
  TS twins under `node --test`. The Dart contract keeps the read side (no absences, no charges).
- Rejected: changing the fakes so the original cases pass — the goal forbids changing their
  behaviour.

### D24 — Server function signatures as built (supersede contracts/server-functions.md)
`wallet_subscribe(p_type)` (price from `plan_prices`, never from the client); added
`wallet_start_company_plan()` / `wallet_end_company_plan()`; `market_book(p_offer,
p_contribution, p_fee, p_paid_by)`; `market_accept(p_request, p_trip_cost, p_seats)`;
`company_register(p_name, p_domains, p_hr_work_email)`. The migrations are the source of truth.
Rejected: a client-sent plan price — a client could underpay.

### D25 — Profile `clear()` deletes the person's own row
Settings → Reset on the live backend deletes the `profiles` row (the cascade removes what hangs
off it). Rejected: blanking columns — leaves a half-person that RLS still treats as a member.

### Known gaps (live mode, for 012 or later)
- **Wallet**: cash trial, `feeDue`/`feeOverdue` and trip rows derived from 003 records are not
  computed; shares come from the driver's marks only (no first name; method shown as cash).
- **Company**: suspensions are not subtracted from coverage on the device; dashboard money, CO2,
  parking and route gaps read as withheld; Goora staff `demo*` actions do nothing (service role);
  `clearAll` leaves server rows.
- **Marketplace**: seat offers carry no driver name (profiles are owner-only); group legs are not
  in `driverDay`; `requestsForMe` is empty; `reclaim` is refused; `doneOneOffs` is empty; demos do
  nothing.
- **Daily**: a ride the server has not stored yet reads from the plan (no share token, the first
  stop for every rider); the "no cover" choice is not sent.
- **Seed**: no `supabase/seed.sql` yet (T015), so a fresh local stack has no groups.

### Finding F1 — fake trust contact ids repeat inside one clock tick
`FakeTrustRepository` uses the microsecond clock as a contact id, so two adds inside one Windows
clock tick get the same id. The trust contract paces T5 by 5 ms; the fake is unchanged (existing
fakes keep their behaviour). Worth fixing in a later lane.

## Analyze pass (2026-10-30, after tasks.md)

| ID | Severity | Finding | Fix |
|---|---|---|---|
| A1 | HIGH | FR-019 (company flags stay off) had no task | T037 checks `company_flags.dart` is unchanged |
| A2 | HIGH | FR-002 (no existing test edited) had no check | T037 checks no existing test file is in the diff |
| A3 | MEDIUM | `lib/main.dart` edit (T026) is outside OWNS | D21 records why and that no other lane owns it |
| A4 | LOW | data-model says share marks are written "via `wallet_mark_share`" while the RLS column says "driver all" | Both kept: RLS lets the driver read own marks; writes are function-only (contracts/server-functions.md) |
| A5 | LOW | Spec edge case "database tests skipped when not running" vs FR-012 "run when available" | Consistent: skipped = "DB not run" recorded (T016) |

No CRITICAL findings. Every FR maps to at least one task: FR-001–004 → T017–T026, T034;
FR-005–012 → T005–T016; FR-013–016 → T027–T033; FR-017 → T027; FR-018 → T037; FR-019 → T037;
FR-020 → T035.

## Results log

- **SQL tests: DB not run.** The 3 pre-011 migrations applied cleanly on Postgres 17 earlier in
  the session; then the Docker engine hung (`docker info` timed out, exit 124). It was not
  restarted, because another project's stack runs on it. `supabase/tests/*.test.sql` (5 files)
  are written but not executed. Next run: copy `supabase/` to the shifted-port scratch dir,
  `supabase db reset`, `supabase test db`.
- **Live contract run (D20): not run**, same reason.
- **Contracts** (in-memory gateway, each half fake and half Supabase, all green): onboarding 14,
  trust 18, commute 10, wallet 16, company 14, marketplace 10, daily 10.
- **Gates (2026-10-30)**: `flutter analyze` 0 issues; `node --test` 276/276; `flutter test
  --concurrency=1`: see the goora-status block.
