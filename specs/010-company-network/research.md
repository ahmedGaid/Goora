# Research: Company Network (010)

Written 2026-10-19 on `spec/company-network` from `main` @ `eda1844`. Every code fact below was read
in this worktree this session; anything not verified is marked **unverified**.

## R0 — Legal and accounting answers (pending, by design)

Founder Q8. Nothing here is answered. Record the answers here before the matching task runs:

| # | Question | Blocks |
|---|---|---|
| a | Is a fixed per-employee monthly fee from a company to Goora fine under Law 87/2018? (Same family as change 1's per-trip-fee question.) | real invoices (flag `companyInvoicesLive`) |
| b | Personal Data Protection Law 151/2020: is the enrollment consent (name, work email, since) and the HR-statement opt-in enough as written? Any data-processing agreement needed with the company? | US6 export, real roster |
| c | Must the invoice be an ETA e-invoice? Is the price before or after 14% VAT? | real invoices |
| d | Change-1 questions (CBE licence, per-trip fee, pay-later balance) — still pending. | nothing new here |

Decision: build against fakes. Real invoice issuing and any HR-statement export (file/share) stay
behind feature flags (`companyInvoicesLive`, `hrStatementExport`) that are off, as the constitution
requires for open legal items.

## R1 — What exists today (verified in code)

- `PlanType.company` (`lib/features/wallet/domain/plan.dart`): price 0, no `untilDate`;
  `coversDate` and `coversTrip` return `true` for company after `startDate`. **Never ends.**
- `company_verify_sheet.dart`: reads `TrustProfile.company`; if set, "confirm" calls
  `planController.subscribe(PlanType.company)`. **No check that the company pays Goora.**
- `TrustProfile.company` is a plain string; the fake sets it to `DailySeed.company` (`'Valeo'`)
  when the work email is verified (`fake_trust_repository.dart`). **No company entity, no domain.**
- `PricingMode.company` (`payment_method.dart`) is fee-free; `direct_pay` and `SeatPrice` treat it as
  fee 0.
- Marketplace (`fake_marketplace_repository.dart` ~l.314–330): `subscriber: mode == subscribed ||
  mode == company` — a company rider already gets fee 0 on one-off seats **and** the subscriber
  reclaim right (US6 of 005). Spec Q5 default keeps this.
- Same-company matching and the privacy filter use `PersonFacts.company` (002/003) — unchanged.
- Cash trial: `wallet.noTrial.<personId>` (`FakeWalletRepository.noTrialKey`) already keeps a
  person out of the trial. Reuse it for leavers (Q11 default).

## R2 — Coverage at an exact moment (riskiest; do first)

Problem: today a company plan covers every date forever. The spec needs coverage to start at
enrollment and stop at leaving, suspension or contract end, judged per trip at its settle moment
(as 004 R14 did for subscriptions).

Call sites of the plan check (verified by grep, this session):
`router.dart` (pay-method guard, `coversDate`), `payment_method.dart` (`PricingMode.of`,
`coversDate`), `wallet/data/providers.dart` (`PricingMode.of`), `wallet_controller.dart`
(`PricingMode.of`, `lapsed`), `fake_wallet_repository.dart` (past trips, `coversTrip`),
`fake_marketplace_repository.dart` (`coversDate` + `PricingMode.of` at booking).

Options:
- A. Change every caller to ask a new company service. 6 call sites, easy to miss one.
- B. **Chosen.** Keep `Plan` as the one question callers ask. A company `Plan` read from the wallet
  repository carries its `CoverageWindows` (not stored; attached on read from the company
  repository). `coversTrip(at)` = windows contain `at`. `coversDate(d)` = any window overlaps day
  `d` (the router's pay-method guard only). Everything that decides or shows today's price uses the
  exact moment: `fake_wallet_repository` past trips (already `coversTrip`), marketplace booking
  (switch to `coversTrip(now)`), and `PricingMode.of`, which gains a `now: WallTime` and asks
  `coversTrip(now)` so Wallet/Today stop saying "Company" the minute someone leaves or the company
  is suspended (analyze F4).
- Why B: callers don't change except the marketplace booking line; the rule stays pure and
  twinnable; 004 R14's moment precision carries over.

Spike (task T003): list the tests that assume "company covers forever" (grep `PlanType.company`
under `test/`) and run them against windows = `[enrolledAt, ∞)` — must stay green before any
leaving/suspension logic lands.

### P1 spike result — Lane A, 2026-10-20 (T003–T007)
Grep `PlanType.company` / `PricingMode.company` under `test/` (after the 006 merge). Every hit stores
or builds a company `Plan` **without coverage windows**, so each keeps today's meaning ("covered from
`startDate`, forever") through the null-coverage path and needed no change:
- `test/helpers/daily_fakes.dart` (`memberPrefs(withPlan: true)` seeds a company plan for every
  pre-004 rider test) → all widget/golden tests that use it.
- `test/widget/empty_seats_test.dart`, `test/widget/top_up_sheet_test.dart`,
  `test/widget/plan_screen_test.dart` (subscribes Company through the old verify sheet).
- `test/unit/fake_marketplace_repository_test.dart` (two `company: true` riders),
  `test/unit/fake_wallet_repository_test.dart` (`subscribe(PlanType.company)`),
  `test/unit/seat_price_test.dart` (mode only), `test/unit/wallet_rules_test.dart`.

The one change to an existing test: `wallet_rules_test.dart` "PricingMode.of" group, 4 calls
`today: today` → `now: _midnight(today)` (the signature now takes the exact moment). Same
expectations.

What changed in code:
- `Plan.coverage` (`List<Window>?`, never in JSON) + `withCoverage`. Company with coverage:
  `coversTrip(at)` = `CompanyRules.covered(coverage, minuteOf(at))`; `coversDate(d)` = a non-empty
  window overlaps day `d`. Without coverage, or any other plan type: unchanged.
- `PricingMode.of(plan, now, trialAvailable)` — `today` replaced by `now`, asks `coversTrip(now)`
  for every plan type. For Monthly/Yearly this equals the old `coversDate(today)` whenever `now` is
  at or after the subscribe moment, which is always true outside a rewound demo clock. Callers:
  `riderPricing` (wallet providers), `WalletController.build`, marketplace `_rider`.
- Marketplace booking: `coversDate(now.date)` → `coversTrip(now)` (`hasArrangement` uses it too).
- `coversDate` is left only in the router's pay-method guard and `WalletView.lapsed` (Monthly only).
- `FakeWalletRepository(companyCoverage:)` function seam: a stored company plan comes back from
  `getPlan` with the windows attached; the seam returns null by default (tests, old data) so the
  plan keeps its pre-010 meaning. Wiring it to the company network is T019.

Rejected: keeping `today` and adding an optional `now` (two ways to ask one question; a caller
that forgets `now` silently keeps "company covers all day").

## R3 — Money rules and the twin

Rules that decide money (spec FR-029) live in pure Dart `lib/features/company/domain/company_rules.dart`
with TS twin `supabase/functions/_shared/company.ts`, both run `test/fixtures/company_vectors.json`,
generated by `test/fixtures/gen_company_vectors.py` (same folder and pattern as 005's `gen_marketplace_vectors.py`). Minutes use `SharePolicy.minuteOf` (days since
2000-01-01 × 1440 + minute of day) so both sides compare the same integers.

- `coverageWindows(enrollments, companyActiveWindows) → windows` — intersection, merged.
- `covered(windows, minute) → bool` — half-open `[from, to)`.
- `peakEnrolled(enrollmentWindows, monthFromDay, monthToDay) → int` — per day, distinct people
  enrolled at any moment of that day; the max over the month's days (spec: "on any day"). One
  person counts once per day even with several windows.
- `billedSeats(peak, minimumSeats) → int` = max.
- `invoiceTotal(billedSeats, pricePerSeat) → int` = product (whole EGP; VAT pending R0c).
- `dueDay(issueDay) = issueDay + 15`; grace = the 7 full days after the due day; suspension starts
  at 00:00 Cairo of `dueDay + 8` (issued 1 Nov → due 16 Nov → suspended from 24 Nov 00:00). Vectors
  pin it.
- `suspendedWindows(invoices, now)` — from suspension start until the moment the last overdue
  invoice is marked paid.
- `suppress(count) → count | null` with k = 5 (dashboard, not money; Dart-only, but vectors too so a
  future server aggregate matches).

## R4 — Invoices: when and how many

Lazy, idempotent issue on read (same idea as 007's auto-receive "runs once"): every read of a
company's invoices issues any missing month from the contract start up to the last closed month.
Key per month (`company.invoice.<companyId>.<yyyy-mm>`) makes a second issue a no-op. Demo-clock
jumps over several months issue each month once (SC-004). The "1st of the month at 00:00" is the
earliest moment a month is closed.

Payment reference: `GR-<companyShortId>-<yyyymm>` (unique per company and month). Goora bank
details are a config value with placeholder text in the fakes (**founder to supply real details**).

## R5 — Where the company side lives (Q9 default)

In-app, same Flutter app, same phone-OTP login. Entry: Settings → "حساب الشركة / Company account".
Any signed-in user can open it: no company → register; pending → "waiting for Goora"; HR contact of
an active/suspended/ended company → company home (status, seats, price, latest invoice) with Roster,
Invoices, Dashboard, Log and (US6) Statement. A person who is not the HR contact sees only their own
enrollment state there. No new role in the rider/driver switch: being HR is a property of the
person on the company, not a third app mode (constitution IX).

Goora-staff actions are demo actions under Settings → Demo (approve company, mark invoice paid,
change HR contact, end contract), like 005/007/008/009.

## R6 — Privacy design (constitution IV)

- Repository boundary: the HR-facing repository methods return only `RosterRow {name, workEmail,
  enrolledAt, leftAt?}`, `Invoice`, `LogEntry`, `DashboardMonth` (numbers with suppression) and
  (US6) `StatementLine` for consenting employees. No method returns a person id, group, pickup,
  time, reliability, share status or role to HR. Tests assert the types, not just the screens.
- Dashboard numbers come from a pure aggregator (`CompanyDashboard.build`) that receives per-person
  facts and returns only totals; suppression (k = 5) is applied inside it, before anything reaches
  presentation.
- Route gaps are counted by home `Area` (the coarse area enum, never an address or pickup point).
- Server (later): HR reads go through security-definer functions/views, never raw tables; RLS
  denies HR any select on rides, shares or profiles (R9).

## R7 — Dashboard estimates (constants are estimates, labelled so in the app)

- **Money saved by employees** = Σ over employee rider trips of (leg trip cost − share paid).
  Uses the app's own numbers (e.g. demo corridor 160 / 3 → 160 − 40 = 120 EGP per rider trip). No
  outside constant. One-line method copy: "what driving alone would cost minus the share paid".
- **CO₂ avoided** = Σ rider trips × leg km × factor. Leg km per corridor: Cairo ↔ Ismailia 123 km
  (verified in 006 research); Sheikh Zayed ↔ Smart Village **13 km** per leg (P7, 2026-10-29) —
  from one hotel listing (12.5 km, 16 min by car) and a property guide (~30 min via the 26th of July
  Corridor); no official figure, so it stays an estimate and the app says "about". Factor **0.1645 kg
  CO₂e/km**, average petrol car, UK government (DESNZ/DEFRA) GHG conversion factors 2024, read via
  the Climatiq mirror and a Durham University copy of the 2023-24 sheet — **not** read from the
  government file itself; confirm there before the lawyer/marketing copy quotes it. Egypt's fleet
  differs, so the app labels CO₂ "estimate" and shows the method line. Constant lives in
  `CompanyDashboardTerms.co2KgPerKm` (0.1645) and the seed leg km in `CompanySeed.legKm` (13).
- **Parking spaces freed per workday** = employee rider trips on going legs in the month ÷ workdays
  (Sun–Thu) in the month, rounded down. Assumes each rider would otherwise drive alone — stated in
  the method line.
- **Carpool rate** = active ÷ enrolled (both may be suppressed).
- **Trips shared** = completed legs (group or one-off) with at least one employee aboard as rider
  or driver; each leg counts once however many employees were in the car.
- **Route gaps** = home areas with ≥ 5 enrolled employees who have a commute profile and no group.

## R8 — Interplay with 004/005/007/008/009

- 007: the driver's share is untouched; open "ماستلمتش" still blocks booking (guard order of 009
  FR-008 unchanged: owes driver → Goora overdue → ID → method).
- 008: while covered the fee is 0, so no bundle trip is used (008 decided a bundle trip is not used
  when the fee is 0) and nothing lands on the balance. A balance owed before joining stays and
  settles as usual. While suspended, fees land on the balance as for anyone.
- 004: enrolling replaces the personal plan; its remaining paid days are stored as paused
  (`company.paused.<personId>` = plan JSON + days left) and restored on leaving with
  `untilDate = leave date + days left`. A yearly plan pauses the same way.
- 009: enrolling doesn't verify the rider's ID; the ID check before the first trip still applies.
- Trial: enrolling sets `wallet.noTrial.<personId>` (Q11 default: no trial after leaving).

## R9 — Server shape (described for later; this lane touches no `supabase/**`)

One migration `supabase/migrations/<ts>_company_network.sql`: `companies`, `company_domains`
(unique `domain`), `enrollments`, `invoices`, `company_log`, `hr_consents`, `paused_plans`. RLS on
every table: an employee reads their own enrollment/consent; the HR contact reads their company row,
invoices and log; roster only through a view limited to the four roster columns; dashboard and
statement only through security-definer functions that apply k = 5 and consent. Staff writes go
through the service role. Invoice issuing = a scheduled Edge Function using `_shared/company.ts`.

## R10 — Seed for the demo

`CompanySeed`: Valeo (`valeo.com`), active from the 1st of the current demo month minus 2 months,
annual contract, minimum 20, price from config (99 by Q1 default), 12 seeded employees (8 active
each month) with per-month activity facts (rider trips, driver trips, home area, has group) so the
invoice shows the minimum-20 case, the dashboard shows real totals, and one route-gap area with 3
waiting employees is suppressed. The demo user becomes an employee only by enrolling
(their verified work email reads `@valeo.com`). One extra pending company ("Orange Business",
`orange.com`) shows the pending state. **Seed numbers are placeholders**, labelled so in the seed.

## R11 — Drafted copy (founder review, ar first)

Drafted at implementation in the ARB files; list every new key here for review, as 004 R5 / 005 R16
did. Lexicon: مشوار, السواق, كرسي, موثّق. Example lines (drafts):

| Key | ar | en |
|---|---|---|
| companyNotOnGoora | شركتك لسه مش على Goora | Your company isn't on Goora yet |
| companyTellHr | ابعت لـ HR بتاعكم | Tell your HR |
| companyConsentSees | شركتك هتشوف: اسمك، إيميل الشغل، ومن إمتى مشترك | Your company will see: your name, work email and since when you joined |
| companyConsentNever | عمرها ما هتشوف مشاويرك، مكان ركوبك، ولا مواعيدك | It never sees your trips, pickup point or times |
| companyPlanPaused | خطة شركتك متوقفة دلوقتي، رسوم المشوار رجعت عادي | Your company plan is paused for now; the usual trip fee applies |
| fewerThanFive | أقل من 5 | Fewer than 5 |

## Lane B notes — 2026-10-20 (T002, P2, P3 on `010-company-network`, new files only)

Written by the Lane B session of the 2026-10-20 parallel round. The founder chose to start before 006
merges with **new files only**; every task that edits an existing file is left open in tasks.md with
"waits for 006 merge". Founder questions Q1–Q11 are still open: the code uses each recommended
default.

### R0 addendum — where the flags live
The existing config home is `lib/core/config/env.dart` (an existing file, outside this lane), so
`CompanyFlags.companyInvoicesLive` and `CompanyFlags.hrStatementExport` are plain `false` constants in
the new `lib/features/company/company_flags.dart` (test `company_flags_test.dart`). Plain constants,
not `--dart-define`s, so turning one on is a reviewed code change after the R0 answer is written here.
Rejected: a `bool.fromEnvironment` next to `Env` (needs the existing file; a build flag could switch
real invoices on before the lawyer answers). May move next to `Env` after 006 merges.

### Every number a founder answer would change — one constant each
| Founder item | Default used | Constant |
|---|---|---|
| Q1 price per employee per month | 99 EGP | `CompanyTerms.pricePerSeat` |
| Q2 billing basis | peak enrolled per day, drivers count, no pro-rating | rule shape `CompanyRules.peakEnrolled` (+ twin) |
| Q3 minimum seats | 20 | `CompanyTerms.minimumSeats` |
| Q4 contract | 12 months, 30 days' notice | `CompanyTerms.contractMonths`, `CompanyTerms.noticeDays` |
| Q10 due | issue + 15 days | `CompanyRules.dueAfterDays` = TS `DUE_AFTER_DAYS` |
| Q10 grace | 7 days, suspended 00:00 on due + 8 | `CompanyRules.graceDays` = TS `GRACE_DAYS` |
| clarification k | 5 | `CompanyRules.suppressBelow` = TS `SUPPRESS_BELOW` |
| R4 Goora bank details | placeholder text | `CompanyTerms.bankDetails` (**founder to supply**) |
| R7 leg km SZ ↔ SV | 13 km, estimate (one listing, no official figure) | `CompanySeed.legKm` |
| R10 seed money saved | 160 − 40 = 120 EGP per rider trip | `CompanySeed._savedPerTrip` |

The three rule constants exist in Dart, TS and `gen_company_vectors.py` by the twin rule; the
50 vectors fail on either side if one drifts. Q5, Q7, Q9, Q11 carry no number in P2/P3 (they shape
P4–P8). Q8 = the two flags above.

### Choices the docs left open (picked, with the rejected option)
1. **Seed = 12 employees**, not the 24 in the round brief: R10 and analyze F3 say 12 so the
   minimum-20 invoice shows (20 × 99 = 1,980), and the spec's independent tests use 12. Rejected 24:
   it bills 24 and hides the minimum case.
2. `register` takes `personId` (the contract had none): the HR contact must be a known person.
   Rejected: a hidden "current user" seam in the fake.
3. The pending offer is `PendingCompany(companyName)` (contract: `Pending`). Rejected the bare name:
   too generic beside other features' imports. The screen shows "not on Goora yet" for it (US1 AC5).
4. A **suspended** company still offers `CanEnroll` (still a customer; coverage starts once paid);
   an **ended** one reads `NotOnGoora`. Rejected: refusing to enroll while suspended (punishes the
   employee for the company's debt, against FR-015's spirit).
5. Coverage counts only suspensions that **have started** at the moment asked: an unpaid invoice
   before its suspension day cuts nothing yet (it may still be paid). Rejected: showing the future
   cut (speculative; would make coverage change when nothing happened).
6. `Enrollment` keeps the roster `name` from the consent moment (data-model had no name field; the
   roster needs it, and the employee agreed the company sees it).
7. `Invoice` stores `paidAt` (exact moment), `paidOn` is derived: coverage returns "from that moment"
   (FR-014) needs the time of day.
8. Log `detail` also holds the domain (domain added/removed) and the month (invoice issued/paid) —
   neither is personal data. data-model said only the roster name for employee entries.
9. A company ended at 00:00 on a 1st gets its final invoice for the month before (the end month had
   no active minute). A contract end date that passes ends the company lazily at 00:00 that day,
   actor Goora (FR-019).
10. The HR-only check (`NotHrContact`) is defined but not enforced in the fake: the contract's HR
    methods take no caller id. P4/P6 enforce it at the screen, or add a caller id then.
11. The seed pays its own closed months on their issue day at 11:00 (`SEED-<month>`), so the demo
    never opens suspended. Later months are issued lazily and stay unpaid until the demo action.
12. `providers.dart` gives a person lookup that knows nobody yet ("no work email") until T017 adds
    `TrustProfile.workEmail`. It imports no wallet or marketplace code (tested), so the T019 seam
    cannot form a provider cycle.
13. `dashboard`, `hrConsent`, `setHrConsent`, `statement` throw `UnimplementedError` until P7/P8
    (005 precedent). `CompanyHome`, `EmployeeMonthFacts` and the read models exist already so P7/P8
    add no domain churn.
14. Touching windows merge (`[a, b)` + `[b, c)` = `[a, c)`); empty windows are dropped and never count
    toward a day's peak (vectors pin both).
15. Public mail domains: 19 listed in `CompanyDomains.public` (gmail, yahoo, outlook, hotmail, live,
    msn, icloud, me, mac, aol, proton, gmx, mail, yandex, zoho …). A longer list can replace it.

### What waits for 006 (existing files)
T001 (brief + constitution, founder OK) · T003–T007 (`plan.dart` coverage, `payment_method.dart`,
`fake_marketplace_repository.dart` booking on `coversTrip`) · T017 (`trust.dart` workEmail) · T018–T019
(wallet seam) · T020 (notices + ARB) · T021 (settings reset clears `company.*` — the fake already has
`FakeCompanyRepository.clearAllKeys(prefs)` for it).

## Lane A notes — 2026-10-20 #2 (P1 T003–T007, P3 seams T017–T021, after the 006 merge)

P1 is written under R2 ("P1 spike result"). Founder Q1–Q11 still open: defaults unchanged.

### Seams as built (choices, with the rejected option)
1. **Wallet API** (`WalletRepository`): `startCompanyPlan(personId, now)`, `endCompanyPlan(personId, now)`,
   `pausedPlan(personId)` (`PausedPlan` = type, price, daysLeft). `daysLeft` = paid-until − the enroll
   date; a lapsed or due plan pauses nothing. On leaving, the paused plan comes back with
   `startDate = leave moment`, `untilDate = leave date + daysLeft`; no paused plan → the plan key is
   removed (per trip).
2. **No re-pricing of past trips.** Wallet activity is derived from the *current* plan, so swapping
   plans would re-price trips already taken (a Monthly trip turning into a fee, a company trip
   turning into a fee after leaving). Before a plan is replaced, what it covered up to that moment is
   kept as windows in `wallet.coveredBefore.<id>`; a trip is fee-free if the current plan or one of
   those windows covers it. T018 pins it: balance, bundle trips and every activity row are identical
   before/after start and before/after end.
3. **No trial from the enroll moment**: `wallet.noTrialFrom.<id>` (a moment), not the old
   `wallet.noTrial.<id>` bool. Rejected the bool: it turns the trips a rider already took on the
   trial into fees, moving the owed balance. Trips before the moment keep their trial.
4. `company.paused.<id>` lives under `company.` (research R8), so Settings → Reset clears it with the
   company network; the two new wallet keys are `wallet.*` and go with the wallet.
5. **Coverage seam wiring** (`wallet/data/providers.dart`): `companyCoverage` reads the company
   provider when called (never while building). It returns null for someone who never enrolled
   (`CompanyRepository.hasEnrolled`, new), so a company plan from before 010 (the old verify sheet,
   test seeds) keeps covering from its start until P4 replaces that flow. Rejected: "empty windows →
   null" (wrong for someone who enrolled while their company was suspended).
6. **Who calls start/end** is left for P4 (enroll) and P6 (every leave path): the company provider
   may not import wallet code (`company_providers_test.dart`), so `FakeCompanyRepository` cannot call
   the wallet itself. Recommended for P4: give `FakeCompanyRepository` an `onPlanChange` function
   (joined/left, person, moment) and wire it from `wallet/data/providers.dart`'s side, or call both
   repositories from the enroll/leave controller. Pick one in P4; T037 tests every leave path.
7. **Person lookup** (`company/data/providers.dart`): the signed-in person only (the fake has no
   other accounts); roster name = first + last name from the profile, work email from Trust.
   Signed out → nobody → "no work email".
8. **Trust work email**: `TrustProfile.workEmail`, fake `<first>@valeo.com`
   (`FakeTrustRepository.workEmailFor`); a first name with no Latin letters gives
   `employee@valeo.com`. Rejected: an Arabic local part (valid in theory, unreadable on the HR roster
   and outside the domain check's tests).

### T020 split — copy now, notice kinds in P4
The notice copy is rendered by an exhaustive `switch (n.kind)` in `daily/presentation/labels.dart`,
which is Lane B's file this round; adding `NoticeKind` values without new arms there breaks the
build. So this lane added only the five ARB keys (end of both files, `flutter gen-l10n` run) and a
copy test. The four kinds + their label arms + the posts land together in P4, after Lane B merges.
Rejected: touching labels.dart (outside this lane), a `default` arm (hides a missing notice copy).

| Key | ar | en |
|---|---|---|
| nCompanyPlanStarted | خطة {company} شغّالة: مشاويرك من غير رسوم Goora. | Your {company} plan is on: no Goora fee on your trips. |
| nCompanyPlanEnded | خطة {company} خلصت. رسوم Goora على المشوار رجعت عادي. | Your {company} plan has ended. The usual Goora fee applies to your trips. |
| nCompanyPlanPaused | خطة شركتك متوقفة دلوقتي، رسوم Goora على المشوار رجعت عادي. | Your company plan is paused for now; the usual Goora fee applies to your trips. |
| nCompanyPlanResumed | خطة شركتك رجعت تشتغل: مشاويرك من غير رسوم Goora تاني. | Your company plan is back on: no Goora fee on your trips again. |
| nPersonalPlanBack | اشتراكك رجعلك، وفاضل فيه {days} يوم. | Your own plan is back, with {days} days left. |

Paused/resumed carry no amount (Q10 "neutral notice"). Founder review pending like every R11 line.

### Still open after this lane
- The router's pay-method guard still asks `coversDate` (day level, `lib/app/router.dart`, not this
  lane's file): a leaver keeps reaching Today for the rest of the leave day. Fine for P4; revisit if
  the walk shows it.

## P4 notes — 2026-10-20 (US1 + US2, T020 rest, T022–T029)

Founder Q1–Q11 still open: defaults unchanged (99 EGP, minimum 20).

### Choices (picked, with the rejected option)
1. **Who calls the wallet seam** (Lane A notes #6): `CompanyEnrollment.enroll/leave` in
   `company/presentation/company_controller.dart` calls `CompanyRepository.enroll/leave`, then
   `WalletRepository.startCompanyPlan/endCompanyPlan`, then posts the notice. Rejected an
   `onPlanChange` function on the fake: the HR-side leave paths (remove, domain removed, contract
   end) happen inside the company fake with no wallet call either way, so P6 (T037) needs a
   catch-up seam regardless; one presentation helper is the smaller step now.
2. **Register = name + work email**; the company's domain is the email's domain, more domains
   later (`addDomain`, P6). A code to that email proves it — fake: `FakeOtpProvider.testCode`
   (123456); real delivery is server work (R9). Public and taken domains are refused *before* a
   code is sent, as the email field's error. Rejected a separate domain field (a second input that
   must match the email anyway).
3. `companyAccountProvider` = (HR home, offer, paused plan) for the signed-in person. Screens keep
   the last value while it reloads, so the offer view is never torn down mid-join.
4. Wallet: a company plan with **no enrollment behind it** (pre-010 seeds, `memberPrefs`) keeps the
   old plain plan card; only an `Enrolled` offer shows "Company · Valeo", the paused line and
   Leave. Rejected migrating old plans (they are test seeds only).
5. **`personalPlanBack` is a fifth notice kind** (the contract listed four): the ARB key existed
   and the leave flow needs it. Paused/Resumed have kinds and copy but are posted by P5
   (suspension), not yet.
6. Settings → Demo: "Goora approves my company" approves my pending company, else the seeded
   Orange Business; "Make me Valeo's HR contact" = `demoSetHrContact`.
7. The HR home shows status, domain, minimum, price, contract dates and the privacy note; no
   buttons for Roster/Invoices/Dashboard/Log until P5–P7 add their screens (no dead ends).
8. Arabic copy writes the name **جورة** (17 existing keys did; the 4 notice keys drafted in P3 said
   "Goora" — fixed).
9. T028 checks the P1 seams (green on first run): fee 0 on a group trip and a one-off seat, share
   unchanged, reclaim right while covered and gone one minute after leaving, an owed share still
   blocks. The 008 overdue-fee block is not re-tested here (the gate order is pure,
   `booking_gate_test.dart`).
10. `GooraTextField` errors wrap to 3 lines (a refusal reason is a sentence; Arabic runs longer).

### R11 — keys added in P4 (founder review, ar first)
| Key | ar | en |
|---|---|---|
| companyAccountTitle | حساب الشركة | Company account |
| companyAccountSub | سجّل شركتك لو إنت HR، أو شوف خطة شركتك | Register your company if you're in HR, or see your company plan |
| companyRegisterCta | سجّل شركتك | Register your company |
| companyRegisterIntro | إنت من HR؟ سجّل شركتك، وموظفينكم يركبوا من غير رسوم جورة. | In HR? Register your company so your employees ride with no Goora fee. |
| companyRegisterSub | هنتأكد من إيميل شغلك، وفريق جورة هيفعّل الحساب بعد ما العقد يتمضي. | We check your work email. The Goora team turns the account on once the contract is signed. |
| companyNameLabel · companyNameError | اسم الشركة · الاسم لازم يكون من 2 لـ 60 حرف | Company name · Use 2 to 60 characters |
| companyWorkEmailLabel · companyEmailInvalid | إيميل شغلك · اكتب إيميل صحيح، زي name@company.com | Your work email · Enter a valid email, like name@company.com |
| companyPublicDomain | {domain} إيميل عام أي حد يقدر يعمل عليه حساب. استخدم إيميل الشغل. | {domain} is a public email service anyone can sign up to. Use your work email. |
| companyDomainTaken | {domain} متسجّل لشركة تانية على جورة. | {domain} is already registered to another company on Goora. |
| companySendCode · companyCodeSent · companyCodeLabel · companySubmit | ابعتلي كود · بعتنا كود لـ {email} · الكود · ابعت الطلب | Send me a code · We sent a code to {email} · Code · Send the request |
| companyStatusPending · Active · Suspended · Ended | مستني موافقة جورة · شغّال · متوقف لحد الدفع · العقد خلص | Waiting for Goora · Active · Paused until paid · Contract ended |
| companyPendingBody | طلب {company} وصلنا. هنفعّل الحساب أول ما العقد يتمضي. | We got {company}'s request. We'll turn the account on once the contract is signed. |
| companyDomainsLine · companyMinSeats · companyPriceLine · companyContractLine | الدومين: {domains} · أقل عدد في الفاتورة: {count} موظف · {amount} ج لجورة عن كل موظف في الشهر · العقد من {start} لـ {end} | Domain: {domains} · Billed for at least {count} employees · {amount} EGP to Goora per employee a month · Contract {start} to {end} |
| companyHomeNote | الشركة عمرها ما بتشوف مشاوير الموظفين ولا أماكن ركوبهم. | The company never sees employees' trips or pickup points. |
| companyMineTitle · companyEnrolledLine · companyCanEnrollLine · companyJoinCta | خطة شركتك · مشترك في خطة {company} من {date} · {company} بتدفع رسوم جورة عنك على كل مشوار. · اشترك من خلال {company} | Your company plan · On {company}'s plan since {date} · {company} pays Goora's fee for you on every trip. · Join through {company} |
| companyNotOnGoora · companyNotOnGooraBody · companyTellHr | شركتك لسه مش على جورة · قول لـ HR بتاعكم عن جورة. لحد ما يشتركوا، تقدر تدفع بالمشوار أو تشترك لوحدك. · ابعت لـ HR بتاعكم | Your company isn't on Goora yet · Tell your HR about Goora. Until they join, you can pay per trip or subscribe yourself. · Tell your HR |
| companyShareText | جورة بيجمّع زمايل الشغل في مشوار يومي واحد، وبيقسموا التكلفة. وفيه خطة للشركات: الشركة تدفع رسوم جورة، والموظفين يركبوا من غير رسوم. {link} | Goora groups colleagues into one daily commute, and they share the cost. With its company plan, the company pays Goora's fee and employees ride with no fee. {link} |
| consentTitle | قبل ما تشترك من خلال {company} | Before you join through {company} |
| consentSees* | شركتك هتشوف: اسمك · إيميل شغلك · من إمتى مشترك | Your company will see: Your name · Your work email · Since when you joined |
| consentNever* | عمرها ما هتشوف: مشاويرك ومواعيدها · بيتك أو مكان ركوبك · مين راكب معاك · فلوسك أو اللي دفعته للسواق | It will never see: Your trips or their times · Your home or pickup point · Who rides with you · Your money or what you paid the driver |
| consentFeeLine | رسوم جورة على مشاويرك هتبقى 0. نصيب السواق بتدفعه له زي ما هو. | Goora's fee on your trips becomes 0. You still pay the driver's share to the driver. |
| consentPausedLine | اشتراكك الشخصي (فاضل {days} يوم) هيتوقف، ويرجعلك لو سبت الشركة. | Your own plan ({days} days left) pauses and comes back if you leave your company. |
| consentAgree · consentDecline | موافق، اشترك · مش دلوقتي | Agree and join · Not now |
| planCompanyOf · planCompanyPaused | شركة · {company} · اشتراكك الشخصي متوقف: فاضل {days} يوم، يرجعلك لو سبت الشركة. | Company · {company} · Your own plan is paused: {days} days left, back if you leave your company. |
| companyLeave · companyLeaveTitle · companyLeaveBody · companyLeaveConfirm | سيب خطة الشركة · تسيب خطة {company}؟ · من دلوقتي رسوم جورة هترجع على مشاويرك. المشاوير اللي فاتت مش هتتغير. · أيوه، سيبها | Leave the company plan · Leave {company}'s plan? · From now on Goora's fee applies to your trips. Trips you already took don't change. · Yes, leave |
| demoApproveCompany · demoMakeMeHr | جورة توافق على شركتي · خليني HR بتاع Valeo | Goora approves my company · Make me Valeo's HR contact |

### Still open after P4
- T030 done 2026-10-21: walk report `walk/README.md` (F-1 contract dates lack the year, F-2 wallet rules still mention a 10% fee on a company plan, F-3 stale top-up banner).
- The router's pay-method guard still asks `coversDate` (Lane A notes): unchanged.

## P6 notes — 2026-10-29 (US4 roster, leaving, log, T036–T039)

Founder Q1–Q11 still open: defaults unchanged.

### Choices (picked, with the rejected option)
1. **One leave path on the employee's side.** `companyAccountProvider` runs `_syncLeave` whenever no
   enrollment is open: if the wallet plan is still a company plan with coverage behind it, it ends it
   at `CompanyRepository.lastLeave(...).at` (new), brings a paused plan back, posts
   `companyPlanEnded` (+ `personalPlanBack`) once, and refreshes plan/pricing/wallet. Self-leave now
   goes the same way (`CompanyEnrollment.leave` = `company.leave` + re-read). Rejected: an
   `onPlanChange` callback on the fake (the company network may not reach the wallet, and HR-side
   leaves happen while the employee's app is closed — the real backend has the same gap).
2. Fees are right **before** the sync runs: the plan's coverage already ends at the leave moment
   through the T019 seam. Only the notice and the plan card wait for the next company-area read
   (Wallet card or `/company`) — the same lag P5 has for suspension notices.
3. `demoSetHrContact` takes `String?`: null = the HR contact left; the company stays active with no
   HR contact, `/company` shows everyone only their own plan (T039). Settings → Demo: "Goora ends
   Valeo's contract", "Valeo's HR contact left the company" (re-name with "Make me Valeo's HR").
4. Domains get their own card on the HR home (active or suspended only): list, Add (shape check,
   public and taken refused before saving), Remove with confirm; the last domain has no Remove. The
   pending home keeps the one-line "Domain:" summary.
5. Log entries written in the same minute sort newest-written first (Dart's sort is not stable).
6. `companyAccountProvider` reads every repository **before its first await** and passes them to
   the catch-up helpers (`_Deps`): it is invalidated often (demo actions, screens), and Riverpod 3
   throws `UnmountedRefException` on `ref.read` after a rebuild. Found by `company_invoices_test`.
7. Arabic leaver copy avoids gendered verbs: "آخر يوم في الخطة: {date}", "خرج من الخطة: {name}" is
   the one gendered form left (founder review).

### R11 — keys added in P6 (founder review, ar first)
| Key | ar | en |
|---|---|---|
| companyRosterCta · companyRosterTitle | الموظفين المشتركين | Enrolled employees |
| companyRosterCount | {count} مشترك دلوقتي | {count} enrolled now |
| companyRosterNote | ده كل اللي الشركة بتشوفه: الاسم والإيميل ومن إمتى مشترك. | This is all the company sees: name, email and since when. |
| companyRosterSince · companyRosterLeft | مشترك من {date} · آخر يوم في الخطة: {date} | Since {date} · Left on {date} |
| companyRosterEmpty | مفيش موظفين مشتركين لسه. قول لزمايلك يشتركوا من خلال الشركة من جورة. | No employees enrolled yet. Tell your colleagues to join through the company in Goora. |
| companyRosterRemove · …Title · …Body · …Confirm | شيل · تشيل {name} من خطة الشركة؟ · من دلوقتي رسوم جورة هترجع على مشاويرهم، والمشاوير اللي فاتت مش هتتغير. هيتحسبوا في فاتورة الشهر ده. · أيوه، شيل | Remove · Remove {name} from the company plan? · From now on Goora's fee applies to their trips; trips already taken don't change. They still count on this month's invoice. · Yes, remove |
| companyLogCta · companyLogTitle · companyLogEmpty | سجل التغييرات · مفيش تغييرات لسه. | Change log · No changes yet. |
| companyLogMeta · ByHr · ByEmployee · ByGoora | {actor} · {date} · HR · الموظف · جورة | {actor} · {date} · HR · Employee · Goora |
| companyLog* kinds | الحساب اتفعّل · دومين اتضاف/اتشال: {domain} · اتشال من الخطة: {name} · خرج من الخطة: {name} · فاتورة اتعملت/اتدفعت: {month} · الخطة اتوقفت لحد الدفع · الخطة رجعت تشتغل · العقد خلص · مسؤول HR اتغيّر | Account approved · Domain added/removed: {domain} · Removed from the plan: {name} · Left the plan: {name} · Invoice issued/paid: {month} · Plan paused until paid · Plan back on · Contract ended · HR contact changed |
| companyDomainsTitle · companyDomainsNote | الدومينات · أي حد إيميل شغله على الدومينات دي يقدر يشترك من خلال الشركة. | Domains · Anyone whose work email is on these domains can join through the company. |
| companyAddDomain · companyDomainLabel · companyDomainInvalid · companyDomainAddCta | ضيف دومين · الدومين · اكتب دومين صحيح، زي company.com · ضيف | Add a domain · Domain · Enter a valid domain, like company.com · Add |
| companyDomainRemove · …Title · …Body | شيل {domain} · تشيل {domain}؟ · الموظفين المشتركين بإيميل على {domain} هيخرجوا من الخطة دلوقتي، ورسوم جورة هترجع على مشاويرهم. | Remove {domain} · Remove {domain}? · Employees enrolled with a {domain} email leave the plan now, and Goora's fee applies to their trips. |
| demoEndContract · demoHrLeft | جورة تنهي عقد Valeo · مسؤول HR بتاع Valeo ساب الشركة | Goora ends Valeo's contract · Valeo's HR contact left the company |

### Still open after P6
- T040: quickstart 6 on the emulator (not walked this session).
- Log invoice months show as `yyyy-mm` (same as the invoice list) — a month-name format is a polish item.


## P7 notes — 2026-10-29 (US5 dashboard, T041–T044)

### Choices (picked, with the rejected option)
1. **Trips shared counts each leg once** by a `legIds` set on `EmployeeMonthFacts` (riders and the driver of one car share ids). Rejected: Σ per-person trips (counts a full car 4x).
2. **Every figure is suppressed on the number of people it is built from**, not on enrolled: enrolled ← all employees; active, carpool rate, trips shared ← active; groups ← employees in a group; money, CO₂ ← employees who rode; parking ← employees who rode a going leg. Carpool rate is null when either side is.
3. **Parking per workday for the running month divides by the workdays so far** (Sun–Thu up to today), not the whole month — else early in the month it reads near 0. Closed months use the whole month. Rejected: whole month always (R7 text) because it misleads "so far".
4. **Month picker = pills**, labels `m/yyyy`; the running one reads "(so far)". No month names (avoids 12 ARB keys x 2).
5. **Fake data**: Valeo's seeded facts repeat every month; a company with no seed facts counts open enrollments as headcount only (no commute profile, no route-gap effect), so a fresh company shows "Fewer than 5" everywhere.
6. Privacy test scans field names in `hr_views.dart` (Dart has no reflection in tests) plus checks the seeded output holds no name/email/id.

### R7 constants — what is and is not verified
- CO₂ factor 0.1645 kg CO₂e/km (UK DESNZ/DEFRA 2024, average petrol car): read from a Climatiq mirror and a Durham University copy of the 2023-24 sheet, **not** from the government file. Egypt's fleet differs. Shown as "estimate" with its method.
- SZ ↔ SV 13 km per leg: one hotel listing (12.5 km, 16 min); no official figure. Seed only; real facts will carry measured km.

### R11 — keys added in P7 (founder review, ar first)
| Key | ar | en |
|---|---|---|
| companyDashboardCta · Title | أرقام الشركة | Company numbers |
| companyDashboardSoFar | {month} (لحد دلوقتي) | {month} (so far) |
| companyDashboardNote | أرقام إجمالية بس. مفيش اسم ولا مشوار ولا مكان ركوب لأي موظف. | Totals only. No employee's name, trip or pickup point. |
| companyDashboardFewer · FewerNote | أقل من 5 · أي رقم طالع من أقل من 5 موظفين بنخبّيه، عشان محدش يتعرف. | Fewer than 5 · A figure from fewer than 5 employees is hidden, so no one can be picked out. |
| companyDashboardEnrolled · Active · ActiveMethod | موظفين مشتركين · موظفين نشطين الشهر ده · نشط يعني ركب أو سوّق مشوار واحد على الأقل. | Employees enrolled · Active employees this month · Active means at least one trip as a passenger or driver. |
| companyDashboardCarpool · CarpoolMethod | نسبة المشاركة · النشطين ÷ المشتركين. | Carpool rate · Active ÷ enrolled. |
| companyDashboardGroups · Trips · TripsMethod | مجموعات مشاوير فيها موظفين · مشاوير اتشاركت · كل مشوار بيتعد مرة واحدة، حتى لو كذا موظف في العربية. | Commute groups with employees · Trips shared · Each trip counts once, however many employees were in the car. |
| companyDashboardSaved · SavedMethod | توفير تقديري · تكلفة المشوار لو سقت لوحدك ناقص حصة الكرسي اللي اتدفعت. تقدير. | Estimated savings · What driving alone would cost minus the seat share paid. An estimate. |
| companyDashboardCo2 · Co2Method · Kg · Percent | كربون اتوفّر (تقدير) · الكيلومترات × 0.1645 كجم كربون للكيلو، متوسط عربية بنزين. تقدير مش قياس. · {kg} كجم · {pct}% | CO₂ avoided (estimate) · Kilometres × 0.1645 kg CO₂ per km, an average petrol car. An estimate, not a measurement. · {kg} kg · {pct}% |
| companyDashboardParking · ParkingMethod | أماكن ركن فاضية كل يوم شغل · مشاوير الذهاب كراكب ÷ أيام الشغل (الأحد–الخميس). بنفترض إن كل راكب كان هيسوق لوحده. | Parking spaces freed per workday · Going trips as a passenger ÷ workdays (Sun–Thu). Assumes each passenger would otherwise drive alone. |
| companyDashboardGapsTitle · GapRow · GapsEmpty | مناطق فيها موظفين من غير مجموعة · {area} · {count} موظف مستنيين · مفيش منطقة فيها 5 موظفين أو أكتر مستنيين مجموعة. | Areas with employees but no group · {area} · {count} employees waiting · No area has 5 or more employees waiting for a group. |
| companyDashboardEmpty | الأرقام بتظهر أول ما الحساب يتفعّل. | Numbers appear once the account is active. |

### P7 notes — N-16 check (2026-10-29, autonomous session)
Savings formula `Σ(leg cost − share)` is right: checked by hand against R7/R10 (160 − 160/4 = 120 per rider trip; 132 rider trips × 120 = 15,840) and pinned in `test/unit/company_dashboard_test.dart`. The "208 per trip" in the walk was 15,840 ÷ 76 *shared legs*, a different count — not an error in the formula.

## P8 notes — 2026-10-29 (US6 HR statement, T046–T049)

Founder Q6, Q7 still open: the spec defaults were taken. Q8 b (Law 151/2020 wording of the opt-in) is the
open legal item: the copy below is a draft for the lawyer.

### Choices (picked, with the rejected option)
1. **Consent is a history, read at the month end.** `company.hrConsent.<companyId>.<personId>` = list of
   `{on, at}` (data-model). A month's statement includes a person if they were enrolled AND consent was on
   at 00:00 on the 1st of the next month (`HrStatement.build`). So withdrawing on the 15th leaves that
   month out and earlier ones unchanged. Rejected: a stored on/off flag (an issued month would change).
2. **A statement exists only for a closed month.** `statement()` returns nothing while the month runs;
   the screen lists closed months only, newest first. Rejected: a "so far" statement (consent can still change).
3. **Joining again starts from off.** `enroll` appends an `off` if the last change was `on`; leaving ends
   it for `hrConsent` (no open enrollment = false). Rejected: carrying the old yes over a leave.
4. **Only received / auto-received shares, rider trips only** (Q7, AC6): `TripShare.asRider == false` and
   pending / not received / disputed never reach a line. HR sees name, date, leg, share — nothing else
   (`StatementLine`, field list pinned in a test next to the privacy test).
5. **The statement's source is a seam**, `TripSharesSource`, defaulting to `CompanySeed.sharesFor`. The seed
   gives Valeo shares from the same facts as the dashboard (one going + one return per workday, 40 EGP each);
   the signed-in person's real shares wait for the server (R9). Rejected: reading the wallet from the company
   network (R8: it may not).
6. **Seed consents (placeholders):** Dina, Hossam, Yasmin and Karim agreed; Yasmin withdrew on the 15th of the
   second month; Karim drives, so he has no line; Hossam has 3 shares that stay off (not received, disputed,
   pending) and 1 auto-received that counts.
7. **No export.** `CompanyFlags.hrStatementExport` stays false; the screen has no export or share control and
   a test pins both (constitution VIII). Goora's fee is shown as `0` in one line.
8. **Where the switch lives:** `HrConsentToggle` on the Wallet's company card (above Leave), off by default,
   the "what HR sees" text always visible under it. Turning it off asks first ("statements already issued
   stay"); turning it on needs no confirm. Rejected: a confirm on turning on (the sentence is already on screen).
9. The HR home gets a fifth button "Trips statement" next to Numbers; route `/company/statement`.

### R11 — keys added in P8 (founder review, ar first)
| Key | ar | en |
|---|---|---|
| companyHrShareTitle | ابعت مشاويري لـ HR | Share my trips with HR |
| companyHrShareSees | الشركة هتشوف: اسمك، وتاريخ كل مشوار ركبته كراكب، الذهاب ولا الرجوع، والحصة اللي دفعتها للسواق. مش هتشوف مكان الركوب ولا الميعاد ولا السواق. | Your company will see: your name, the date of each trip you rode as a passenger, going or return, and the share you paid the driver. It never sees the pickup point, the time or the driver. |
| companyHrShareOffLine · OnLine | مقفول. الشركة مش بتشوف مشاويرك. · شغال. الشركة بتستلم كشف الشهر اللي فات أول كل شهر. | Off. Your company doesn't see your trips. · On. Your company gets last month's statement on the 1st of each month. |
| companyHrShareStopTitle · Body · Confirm | توقّف إرسال مشاويرك لـ HR؟ · الكشوف اللي الشركة استلمتها قبل كده هتفضل زي ما هي. الكشف الجاي وأي كشف بعده مش هيشمل مشاويرك. · أيوه، وقّف | Stop sharing your trips with HR? · Statements your company already received stay as they are. The next one, and every one after, leaves your trips out. · Yes, stop |
| companyStatementCta · Title | كشف المشاوير · كشف المشاوير الشهري | Trips statement · Monthly trips statement |
| companyStatementNote | الموظفين اللي وافقوا يشاركوا مشاويرهم بس هما اللي بيظهروا هنا. أي حد تاني مش موجود، ولا حتى اسمه. | Only employees who agreed to share their trips appear here. No one else is listed, not even a name. |
| companyStatementFee | رسوم جورة على المشاوير دي: {amount}. كل حصة اتدفعت للسواق على طول. | Goora's fee on these trips: {amount}. Each share was paid straight to the driver. |
| companyStatementPerson · Share · Total | {count} مشوار · {amount} ج · {amount} ج للسواق · إجمالي الحصص: {amount} ج | {count} trips · {amount} EGP · {amount} EGP to the driver · Total shares: {amount} EGP |
| companyStatementEmpty · NoMonths | مفيش موظف وافق يشارك مشاويره في الشهر ده. · أول كشف بيظهر بعد ما أول شهر يخلص. | No employee shared their trips for this month. · The first statement appears once the first month has ended. |

Arabic notes for founder review: "أيوه، وقّف" is a masculine imperative, like the existing "شيل" and "سيبها" (same register,
same open gender question as "خرج من الخطة"). "الشركة بتستلم كشف ... أول كل شهر" promises a delivery the fake does not do
(HR opens the screen; nothing is sent), so the copy may need "تقدر تشوف" once the real flow is known. Wording waits for Q8 b.

### Not done / not walked
- **T049 quickstart 8: not walked** (no emulator this run). Covered by widget tests ar + en only.
- Red-first was not observed for T046/T048: the tests were written before the code but not run against
  a missing implementation (both would have failed to compile).

### R11 — full list of 010 ARB keys, all phases (T053, **for founder review**, ar first)

Every key 010 added to `app_ar.arb` / `app_en.arb` on this branch compared with main at b198795 (139 keys), ar and en side by side. P8 keys (`companyHrShare*`, `companyStatement*`) are listed in "R11 — keys added in P8" once that phase is committed. Nothing here is founder-approved yet.

**Flag — gendered wording:** `companyLogEmployeeLeft` reads "خرج من الخطة: {name}", the masculine verb for a person whose gender the app does not know. Neutral options for the founder: "الخروج من الخطة: {name}" (noun form, my pick) or "{name} · خرج/خرجت" (not neutral). Same masculine-generic pattern in `companyDomainRemoveBody` ("هيخرجوا", plural — normal Egyptian usage, lower risk).

Four older keys changed wording and are also up for review: `nCompanyPlanStarted`, `nCompanyPlanEnded`, `nCompanyPlanPaused`, `nCompanyPlanResumed`.

| Key | ar | en |
|---|---|---|
| howPayRule1Company | بتدفع نصيب السواق ليه على طول، كاش أو InstaPay. خطة شركتك بتغطي رسوم جورة، فمفيش عليك رسوم خدمة. | You pay your driver's share directly, by cash or InstaPay. Your company plan covers Goora's fee, so you pay no service fee. |
| companyAccountTitle | حساب الشركة | Company account |
| companyAccountSub | سجّل شركتك لو إنت HR، أو شوف خطة شركتك | Register your company if you're in HR, or see your company plan |
| companyRegisterCta | سجّل شركتك | Register your company |
| companyRegisterIntro | إنت من HR؟ سجّل شركتك، وموظفينكم يركبوا من غير رسوم جورة. | In HR? Register your company so your employees ride with no Goora fee. |
| companyRegisterSub | هنتأكد من إيميل شغلك، وفريق جورة هيفعّل الحساب بعد ما العقد يتمضي. | We check your work email. The Goora team turns the account on once the contract is signed. |
| companyNameLabel | اسم الشركة | Company name |
| companyNameError | الاسم لازم يكون من 2 لـ 60 حرف | Use 2 to 60 characters |
| companyWorkEmailLabel | إيميل شغلك | Your work email |
| companyEmailInvalid | اكتب إيميل صحيح، زي name@company.com | Enter a valid email, like name@company.com |
| companyPublicDomain | {domain} إيميل عام أي حد يقدر يعمل عليه حساب. استخدم إيميل الشغل. | {domain} is a public email service anyone can sign up to. Use your work email. |
| companyDomainTaken | {domain} متسجّل لشركة تانية على جورة. | {domain} is already registered to another company on Goora. |
| companySendCode | ابعتلي كود | Send me a code |
| companyCodeSent | بعتنا كود لـ {email} | We sent a code to {email} |
| companyCodeLabel | الكود | Code |
| companySubmit | ابعت الطلب | Send the request |
| companyStatusPending | مستني موافقة جورة | Waiting for Goora |
| companyStatusActive | شغّال | Active |
| companyStatusSuspended | متوقف لحد الدفع | Paused until paid |
| companyStatusEnded | العقد خلص | Contract ended |
| companyPendingBody | طلب {company} وصلنا. هنفعّل الحساب أول ما العقد يتمضي. | We got {company}'s request. We'll turn the account on once the contract is signed. |
| companyDomainsLine | الدومين: {domains} | Domain: {domains} |
| companyMinSeats | أقل عدد في الفاتورة: {count} موظف | Billed for at least {count} employees |
| companyPriceLine | {amount} ج لجورة عن كل موظف في الشهر | {amount} EGP to Goora per employee a month |
| companyContractLine | العقد من {start} لـ {end} | Contract {start} to {end} |
| companyHomeNote | الشركة عمرها ما بتشوف مشاوير الموظفين ولا أماكن ركوبهم. | The company never sees employees' trips or pickup points. |
| companyMineTitle | خطة شركتك | Your company plan |
| companyEnrolledLine | مشترك في خطة {company} من {date} | On {company}'s plan since {date} |
| companyCanEnrollLine | {company} بتدفع رسوم جورة عنك على كل مشوار. | {company} pays Goora's fee for you on every trip. |
| companyJoinCta | اشترك من خلال {company} | Join through {company} |
| companyNotOnGoora | شركتك لسه مش على جورة | Your company isn't on Goora yet |
| companyNotOnGooraBody | قول لـ HR بتاعكم عن جورة. لحد ما يشتركوا، تقدر تدفع بالمشوار أو تشترك لوحدك. | Tell your HR about Goora. Until they join, you can pay per trip or subscribe yourself. |
| companyTellHr | ابعت لـ HR بتاعكم | Tell your HR |
| companyShareText | جورة بيجمّع زمايل الشغل في مشوار يومي واحد، وبيقسموا التكلفة. وفيه خطة للشركات: الشركة تدفع رسوم جورة، والموظفين يركبوا من غير رسوم. {link} | Goora groups colleagues into one daily commute, and they share the cost. With its company plan, the company pays Goora's fee and employees ride with no fee. {link} |
| consentTitle | قبل ما تشترك من خلال {company} | Before you join through {company} |
| consentSeesTitle | شركتك هتشوف | Your company will see |
| consentSeesName | اسمك | Your name |
| consentSeesEmail | إيميل شغلك | Your work email |
| consentSeesSince | من إمتى مشترك | Since when you joined |
| consentNeverTitle | عمرها ما هتشوف | It will never see |
| consentNeverTrips | مشاويرك ومواعيدها | Your trips or their times |
| consentNeverPlace | بيتك أو مكان ركوبك | Your home or pickup point |
| consentNeverWho | مين راكب معاك | Who rides with you |
| consentNeverMoney | فلوسك أو اللي دفعته للسواق | Your money or what you paid the driver |
| consentFeeLine | رسوم جورة على مشاويرك هتبقى 0. نصيب السواق بتدفعه له زي ما هو. | Goora's fee on your trips becomes 0. You still pay the driver's share to the driver. |
| consentPausedLine | اشتراكك الشخصي (فاضل {days} يوم) هيتوقف، ويرجعلك لو سبت الشركة. | Your own plan ({days} days left) pauses and comes back if you leave your company. |
| consentAgree | موافق، اشترك | Agree and join |
| consentDecline | مش دلوقتي | Not now |
| planCompanyOf | شركة · {company} | Company · {company} |
| planCompanyPaused | اشتراكك الشخصي متوقف: فاضل {days} يوم، يرجعلك لو سبت الشركة. | Your own plan is paused: {days} days left, back if you leave your company. |
| companyLeave | سيب خطة الشركة | Leave the company plan |
| companyLeaveTitle | تسيب خطة {company}؟ | Leave {company}'s plan? |
| companyLeaveBody | من دلوقتي رسوم جورة هترجع على مشاويرك. المشاوير اللي فاتت مش هتتغير. | From now on Goora's fee applies to your trips. Trips you already took don't change. |
| companyLeaveConfirm | أيوه، سيبها | Yes, leave |
| demoApproveCompany | جورة توافق على شركتي | Goora approves my company |
| demoMakeMeHr | خليني HR بتاع Valeo | Make me Valeo's HR contact |
| companyInvoicesCta | الفواتير | Invoices |
| companyInvoicesTitle | فواتير الشركة | Company invoices |
| companyInvoicesEmpty | لسه مفيش فواتير. أول فاتورة بتتعمل أول الشهر الجاي. | No invoices yet. The first one is issued at the start of next month. |
| companyInvoiceMonthLabel | فاتورة {month} | Invoice {month} |
| companyInvoiceMath | {seats} موظف × {price} ج = {total} ج | {seats} employees × {price} EGP = {total} EGP |
| companyInvoicePeak | أكتر عدد موظفين اتسجلوا في الشهر: {count} | Most employees enrolled in the month: {count} |
| companyInvoicePaid | اتدفعت | Paid |
| companyInvoiceWaiting | مستنية الدفع | Waiting for payment |
| companyInvoiceOverdue | متأخرة | Overdue |
| companyInvoiceDue | آخر ميعاد للدفع {date} | Pay by {date} |
| companyInvoiceReferenceTitle | اكتب الرقم ده في التحويل | Write this on the transfer |
| companyInvoiceBankTitle | حساب جورة | Goora's bank account |
| companyInvoiceSuspendNote | لو الفاتورة لسه ماتدفعتش في {date}، خطة الشركة بتتوقف لحد الدفع، ورسوم جورة بترجع على مشاوير الموظفين. | If this is still unpaid on {date}, the company plan pauses until it is paid and Goora's fee applies to employees' trips. |
| companyInvoicePaidOn | اتدفعت يوم {date} · مرجع البنك {ref} | Paid on {date} · bank reference {ref} |
| demoMarkInvoicePaid | جورة تأكد دفع الفاتورة | Goora marks the invoice paid |
| demoSkipToSuspension | قدّم الساعة لحد يوم إيقاف خطة الشركة | Skip to the day the company plan pauses |
| companyRosterCta | الموظفين المشتركين | Enrolled employees |
| companyRosterTitle | الموظفين المشتركين | Enrolled employees |
| companyRosterCount | {count} مشترك دلوقتي | {count} enrolled now |
| companyRosterNote | ده كل اللي الشركة بتشوفه: الاسم والإيميل ومن إمتى مشترك. | This is all the company sees: name, email and since when. |
| companyRosterSince | مشترك من {date} | Since {date} |
| companyRosterLeft | آخر يوم في الخطة: {date} | Left on {date} |
| companyRosterEmpty | مفيش موظفين مشتركين لسه. قول لزمايلك يشتركوا من خلال الشركة من جورة. | No employees enrolled yet. Tell your colleagues to join through the company in Goora. |
| companyRosterRemove | شيل | Remove |
| companyRosterRemoveTitle | تشيل {name} من خطة الشركة؟ | Remove {name} from the company plan? |
| companyRosterRemoveBody | من دلوقتي رسوم جورة هترجع على مشاويرهم، والمشاوير اللي فاتت مش هتتغير. هيتحسبوا في فاتورة الشهر ده. | From now on Goora's fee applies to their trips; trips already taken don't change. They still count on this month's invoice. |
| companyRosterRemoveConfirm | أيوه، شيل | Yes, remove |
| companyLogCta | سجل التغييرات | Change log |
| companyLogTitle | سجل التغييرات | Change log |
| companyLogEmpty | مفيش تغييرات لسه. | No changes yet. |
| companyLogMeta | {actor} · {date} | {actor} · {date} |
| companyLogByHr | HR | HR |
| companyLogByEmployee | الموظف | Employee |
| companyLogByGoora | جورة | Goora |
| companyLogApproved | الحساب اتفعّل | Account approved |
| companyLogDomainAdded | دومين اتضاف: {domain} | Domain added: {domain} |
| companyLogDomainRemoved | دومين اتشال: {domain} | Domain removed: {domain} |
| companyLogEmployeeRemoved | اتشال من الخطة: {name} | Removed from the plan: {name} |
| companyLogEmployeeLeft | خرج من الخطة: {name} | Left the plan: {name} |
| companyLogInvoiceIssued | فاتورة اتعملت: {month} | Invoice issued: {month} |
| companyLogInvoicePaid | فاتورة اتدفعت: {month} | Invoice paid: {month} |
| companyLogSuspended | الخطة اتوقفت لحد الدفع | Plan paused until paid |
| companyLogResumed | الخطة رجعت تشتغل | Plan back on |
| companyLogContractEnded | العقد خلص | Contract ended |
| companyLogHrChanged | مسؤول HR اتغيّر | HR contact changed |
| companyDomainsTitle | الدومينات | Domains |
| companyDomainsNote | أي حد إيميل شغله على الدومينات دي يقدر يشترك من خلال الشركة. | Anyone whose work email is on these domains can join through the company. |
| companyAddDomain | ضيف دومين | Add a domain |
| companyDomainLabel | الدومين | Domain |
| companyDomainInvalid | اكتب دومين صحيح، زي company.com | Enter a valid domain, like company.com |
| companyDomainAddCta | ضيف | Add |
| companyDomainRemove | شيل {domain} | Remove {domain} |
| companyDomainRemoveTitle | تشيل {domain}؟ | Remove {domain}? |
| companyDomainRemoveBody | الموظفين المشتركين بإيميل على {domain} هيخرجوا من الخطة دلوقتي، ورسوم جورة هترجع على مشاويرهم. | Employees enrolled with a {domain} email leave the plan now, and Goora's fee applies to their trips. |
| demoEndContract | جورة تنهي عقد Valeo | Goora ends Valeo's contract |
| demoHrLeft | مسؤول HR بتاع Valeo ساب الشركة | Valeo's HR contact left the company |
| companyDashboardCta | أرقام الشركة | Company numbers |
| companyDashboardTitle | أرقام الشركة | Company numbers |
| companyDashboardSoFar | {month} (لحد دلوقتي) | {month} (so far) |
| companyDashboardNote | أرقام إجمالية بس. مفيش اسم ولا مشوار ولا مكان ركوب لأي موظف. | Totals only. No employee's name, trip or pickup point. |
| companyDashboardEmpty | الأرقام بتظهر أول ما الحساب يتفعّل. | Numbers appear once the account is active. |
| companyDashboardFewer | أقل من 5 | Fewer than 5 |
| companyDashboardFewerNote | أي رقم طالع من أقل من 5 موظفين بنخبّيه، عشان محدش يتعرف. | A figure from fewer than 5 employees is hidden, so no one can be picked out. |
| companyDashboardEnrolled | موظفين مشتركين | Employees enrolled |
| companyDashboardActive | موظفين نشطين الشهر ده | Active employees this month |
| companyDashboardActiveMethod | نشط يعني ركب أو سوّق مشوار واحد على الأقل. | Active means at least one trip as a passenger or driver. |
| companyDashboardCarpool | نسبة المشاركة | Carpool rate |
| companyDashboardCarpoolMethod | النشطين ÷ المشتركين. | Active ÷ enrolled. |
| companyDashboardGroups | مجموعات مشاوير فيها موظفين | Commute groups with employees |
| companyDashboardTrips | مشاوير اتشاركت | Trips shared |
| companyDashboardTripsMethod | كل مشوار بيتعد مرة واحدة، حتى لو كذا موظف في العربية. | Each trip counts once, however many employees were in the car. |
| companyDashboardSaved | توفير تقديري | Estimated savings |
| companyDashboardSavedMethod | تكلفة المشوار لو سقت لوحدك ناقص حصة الكرسي اللي اتدفعت. تقدير. | What driving alone would cost minus the seat share paid. An estimate. |
| companyDashboardCo2 | كربون اتوفّر (تقدير) | CO₂ avoided (estimate) |
| companyDashboardCo2Method | الكيلومترات × 0.1645 كجم كربون للكيلو، متوسط عربية بنزين. تقدير مش قياس. | Kilometres × 0.1645 kg CO₂ per km, an average petrol car. An estimate, not a measurement. |
| companyDashboardKg | {kg} كجم | {kg} kg |
| companyDashboardMoney | {amount} ج | {amount} EGP |
| companyDashboardPercent | {pct}% | {pct}% |
| companyDashboardParking | أماكن ركن فاضية كل يوم شغل | Parking spaces freed per workday |
| companyDashboardParkingMethod | مشاوير الذهاب كراكب ÷ أيام الشغل (الأحد–الخميس). بنفترض إن كل راكب كان هيسوق لوحده. | Going trips as a passenger ÷ workdays (Sun–Thu). Assumes each passenger would otherwise drive alone. |
| companyDashboardGapsTitle | مناطق فيها موظفين من غير مجموعة | Areas with employees but no group |
| companyDashboardGapRow | {area} · {count} موظف مستنيين | {area} · {count} employees waiting |
| companyDashboardGapsEmpty | مفيش منطقة فيها 5 موظفين أو أكتر مستنيين مجموعة. | No area has 5 or more employees waiting for a group. |

## Autonomous session notes — 2026-10-29
- Several sessions shared worktree Goora-010; split agreed by message: P8 (T046–T049) = goora-2e; N-13, N-16, wallet plural, T050–T054 = this session. Commits stage only own hunks.
- N-13: digits stay Western with "," in ar and en (spec default: every other money line does the same).

## P8/P9 notes (autonomous run) — analyze pass, session goora-5b, 2026-10-29

`/speckit-analyze` on 010 after P7: 0 critical, 0 high, 5 medium, 6 low. Doc-only fixes applied (branch/status headers in spec, plan, tasks; plan file names and key estimate; T001 wording). Below: what was NOT a doc fix, each with the conservative default taken and why. Founder reviews later.

| ID | Finding | Default taken (why) |
|---|---|---|
| U1 | Statement rows (date, leg, share) have no source in the fakes: `EmployeeMonthFacts` holds counts only and the company provider may not import wallet (R8). | The P8 session picks the source and writes it here. Rule: a function seam, never a wallet import in `company/data`. |
| U2 | `statement(...)` is the only call returning individual data and takes no caller id; `NotHrContact` is not enforced in the fake. | Screen-level guard stays (`home == null` → not-HR state). Add a test that a non-HR user sees no statement. Server RLS (R9) is the real guard. |
| A1 | FR-025 / US6 AC2 "Goora fees show as 0" is untrue while a company is suspended (FR-013: employees pay the fee then). | The statement shows date, leg and share paid only; no fee column. Most conservative: states nothing that can be wrong. |
| C1 | Edge cases with no task and no test: employee moves to another domain, price change mid-contract, driver-only employee enrols, 009 ID check not skipped on enrol. | Listed here, not built. P9 can add them; none blocks P8. |
| C2 | T051 covers dashboard + invoice at 1.3× only; no company test uses a text scale; roster, home, register, consent, log and statement are unchecked at 1.3× and 44 px (constitution VII). | Widen T051 to every company screen. |
| A2 | FR-021/FR-022 hide "employees enrolled" under 5 while the roster (FR-016) lists every name, so hiding the headcount adds no privacy. | Kept hidden (conservative; spec text literal). Pinned by `company_unwalked_states_test.dart` ("4 employees"). Founder to confirm. |
| A3 | SC-001 (3 min) and SC-002 (1 min) cannot be tested in fakes. | Time them in the T054 device walk, or drop them. |
| E1 | T052 already holds: `test/architecture/no_hardcoded_values_test.dart` lines 20 and 23 scan `lib/features` recursively, so `lib/features/company` is covered. | Tick T052 with this note (not ticked here: another session owns the tick). |

Also added by this session: `test/widget/company_unwalked_states_test.dart` (6 tests, ar + en): removed employee's next trip (fee 4 back on the plan card, "plan ended" notice in the inbox, can enrol again) and the dashboard with 5 and with 4 employees. Both were "not walked" in walk 5.

### Integration run — branch `010-integration`, session goora-5b, 2026-10-29
Autonomous run, no questions to the founder. Q1–Q11 stay open; code reads `CompanyTerms`. One bullet per queue item, added in that item's commit.

- **Item 1 — merges.** `fix/wallet-caption-demo-corridor` (Arabic "25 مشوار" plural + Settings → Demo corridor switch) and `010-demo-corridor-tests` (removed-employee + "Fewer than 5" tests, analyze doc fixes) merged with merge commits. Conflicts: `demo_section.dart` (both sides kept: the six 010 company demo buttons and the corridor switch) and this file (both sides kept). `flutter gen-l10n` produced no change; ar/en parity 775/775. `010-company-network` moved 3 commits during the run (ticks, unused-import fix, NEXT_GOAL) and was merged in too. Gates: analyze 0, flutter 1690, node 276.
- **Item 2 — T050–T053 verified, not re-ticked.** The boxes were already ticked in `a1bc256` and the notes hold: T050 `c2fccaf` adds `company_screens_golden_test.dart` and 8 PNGs (home, consent, invoice, dashboard × ar/en); T051 `e934c33` adds the contrast pairings and `company_text_scale_test.dart`; T052 `45e8783` makes the token scan prove it reaches `lib/features/company`; T053 `129022d` is the R11 key list. The four test files run alone: 63 tests, all pass. T054: README section exists (`74a2af8`); the ar + en emulator walk is **not walked** (no emulator in this run). P8 (T046–T049) is committed on 010 (`2de6802`) and ticked there.
