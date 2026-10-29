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
  (verified in 006 research); Sheikh Zayed ↔ Smart Village **unverified** (measure at
  implementation). Factor 0.17 kg CO₂/km for an average petrol car is **recalled, unverified** —
  look up a citable source (e.g. an IPCC or EEA figure) before shipping and record it here.
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
| R7 leg km SZ ↔ SV | 20 km, **unverified** | `CompanySeed.legKmPlaceholder` (measure before T043) |
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
