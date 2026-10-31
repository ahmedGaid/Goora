# Goora

**Go together. Every day.** · **مشوارك.. سوا.**

A daily-commute coordination app for Egypt (Flutter, Arabic-first). The product source of truth is
[`GOORA_SPEC_KIT_BRIEF.md`](GOORA_SPEC_KIT_BRIEF.md); the rules for building it are in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md); each feature's spec, plan and
tasks live in [`specs/`](specs/).

## Run

```bash
flutter pub get
flutter run                                   # Android or iOS device/emulator
```

No backend keys are needed yet: sign-in runs on a fake. Use any Egyptian mobile number
(e.g. `01012345678`) and the test code **123456**.

When keys exist, copy `.env.example` to `.env` (git-ignored), fill it in and run
`flutter run --dart-define-from-file=.env`.

## Check

```bash
flutter analyze                               # must say: No issues found!
flutter test                                  # unit + widget (ar/en) + golden + token scan
flutter test --update-goldens test/golden     # only after an intended visual change
```

Goldens are rendered on Windows; other platforms may need regenerating.

## Server (Supabase, not deployed yet)

`supabase/` holds the schema (`migrations/`, PostGIS + row-level security) and the `match` Edge
Function. The matching rules exist twice on purpose — `lib/features/commute/domain/matching_service.dart`
(app) and `supabase/functions/_shared/matching.ts` (server) — and both must pass the same vectors:

```bash
node --test "supabase/functions/_shared/*.test.ts"   # Node 24+, no install needed
python test/fixtures/gen_matching_vectors.py         # only when the rules change
```

Feature 003 adds the daily-commute rules the same way — attendance, reliability, rotation and
backup each exist in Dart (`lib/features/daily/domain/`) and TypeScript
(`supabase/functions/_shared/`), checked against shared vectors:

```bash
python test/fixtures/gen_daily_vectors.py            # only when a rule changes
```

`migrations/20261006000000_daily_commute.sql` adds rides, absences, check-ins, charges, notices,
trusted contacts and SOS alerts (RLS on every table; home points never leave the database).
`commute-day` runs every member action and `evening-cutoff` is the 9 PM job (pg_cron). Before the
job can run, add two Vault secrets: `project_url` and `service_role_key`.

Deploying needs the founder's Supabase project keys (in `.env`, never committed).

### Running against local Supabase (feature 011)

The app runs on its on-device fakes unless the build asks for the backend **and** it answers.
`BACKEND_LIVE=true` plus `SUPABASE_URL` / `SUPABASE_ANON_KEY` switch every repository (sign-in,
profile, commute, daily, trust, wallet, marketplace, company) to its `Supabase*Repository`; if the
health check fails at start-up the app runs on the fakes for that run. Local only: sign-in is a
bridge (`p<phone digits>@phone.goora.test` with the fake code) that refuses any non-local URL, and
the payment provider is still the fake (real OTP and payments are 012).

```bash
supabase start                      # Docker; prints the local API URL and anon key
supabase db reset                   # applies supabase/migrations/* then supabase/seed.sql
supabase test db                    # pgTAP: supabase/tests/*.test.sql (RLS, privacy, money rules)
flutter run --dart-define=BACKEND_LIVE=true \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=<local anon key>
```

**Seed (feature 013).** `supabase db reset` also loads `supabase/seed.sql`: the app's 14 demo
groups on the Sheikh Zayed → Smart Village and Cairo ↔ Ismailia corridors (with pickup points),
and a company "Demo Motors" (`demomotors.test`) with six enrolled employees, five of whom said
yes to sharing trips with HR. Everything in it is fictional and has no password, so the seeded
people cannot sign in: sign up as yourself with the test code and join a seeded group. Applying
the seed again changes nothing (`supabase/tests/80_seed.test.sql` checks it).

**Live mode behaves like the fakes (013).** The wallet's fee state (the 5 fee-free trips, what is
owed, when it fell due at 150 EGP or 30 at month end, overdue after 3 days) is decided in the
database by `wallet_state()`, and the server refuses Book / Post / accept / Join while a balance is
overdue. Seat offers carry the driver's first name, the driver's day lists group legs, `reclaim`
and the finished one-offs work, an unstored daily ride is stored on first read (real share token),
and the company dashboard shows money, CO₂, parking and route gaps only when five or more people
stand behind them. Goora-staff actions are the `staff_*` SQL functions, callable with the service
role only; the app's demo buttons do nothing on the real backend.

If another project's stack already holds the default ports, run a scratch copy of `supabase/`
with every port +1000 and its own `project_id` (API `55321`, DB `55322`) instead of editing
`supabase/config.toml` (research D19). The contract tests (`test/contract/`) run each seam's
fake and Supabase implementation against the same cases with an in-memory gateway, no Docker
needed: `flutter test test/contract`.

**No Docker?** `supabase/scratch/run_scratch.sh` runs the migrations, the seed and the pgTAP files on
a throwaway native PostgreSQL 16 (shim for the Supabase roles, `auth.users` and PostGIS; real pgTAP
v1.3.3). It is a stopgap for a machine where Docker does not answer — report such a run as
"scratch PG16 + shim", not as `supabase test db`. The pgTAP file `supabase/tests/60_vectors.test.sql`
is generated from `test/fixtures/*.json`: run `node supabase/tests/gen_vector_tests.mjs` after a rule
vector changes (`node --test` fails while it is stale).

## Daily commute demo (debug builds)

After joining a group the app opens on **Today**. Settings → **Demo** moves a demo clock to the
moments the rules care about (ride day 7:15 AM, 8:55 PM / 9:05 PM the evening before), makes the
driver arrive at your stop (live trip), simulates a driver who can't drive (with or without a
backup), and resets the fake data. Release builds always use real time. New packages in 003:
`url_launcher` (Call driver, Call 122) and `share_plus` (Share trip).

## Wallet and payment model (feature 004)

After joining a group a rider picks how to pay: **cash to the driver** for their first 10 trips,
or the **wallet** (40 EGP to the driver + a 10% service fee = 44 per trip). Subscribing (149/month,
1,490/year, or a company plan) is optional and removes the fee. Drivers never pay anything. The
rules are pure Dart — `PricingService.serviceFee/riderTotal` (commute domain), `CashTrialPolicy`,
`FeeSavingsCalculator` (wallet domain) — and the fee rule has a TypeScript twin on shared vectors:

```bash
python test/fixtures/gen_pricing_vectors.py          # only when the fee rule changes
```

The wallet derives each rider's trips from 003's settled ride outcomes and prices them at read
time (research R7), so a trip's fee is never stored twice. Trips before the rider set up payment
aren't billed. In the fakes Youssef (group sz-0725) is a cash rider, so a driver on that group
gets "Received cash" / "Didn't pay" after ending a trip. `FakePaymentProvider`'s `shouldFail`
hook (top-up/withdrawal failure) is wired only in widget tests, not in Settings → Demo. No new
packages.

## Seat marketplace (feature 005)

One-off trips next to the daily commute groups: a rider **books an empty seat** or **posts a trip**, a driver
**offers a trip** or **finds riders** who posted, and a subscriber can take a one-off seat before 9 PM the
evening before (the booker gets everything back). All of it runs on fake data in `lib/features/marketplace/`;
the rules (two trips a driver per day, the cost cap, the refund, cash rounding to 5 EGP) are pure Dart with a
TypeScript twin in `supabase/functions/_shared/marketplace.ts` and shared vectors in `test/fixtures/`.

Try it in a debug build (any Egyptian number, code `123456`): choose "Just one trip" as a rider or a driver.
Settings → Demo has the fake other side: "A rider books your seat", "A driver accepts your request",
"A subscriber takes this seat", "Verify my driver documents". "Reset demo data" clears it all.

## Company network (feature 010)

A company pays **Goora's service fee** for its employees' commute rides: an employee who joins through their company rides without the fee, and the company gets a monthly invoice. The driver's share is never touched; it still goes straight from rider to driver, so this stays cost-sharing, not a taxi. Everything runs on fake data in `lib/features/company/` (spec: `specs/010-company-network/`).

- **Register and join.** Settings → Company account: a company signs up with a work-email domain and waits for Goora to approve it. An employee with a verified work email joins from Plan → "Through my company", after a consent sheet that lists what the company sees (name, work email, when they joined) and never sees (trips, pickup points, who rode with them).
- **Invoices.** One per closed month: seats × price per seat, with a 20-seat minimum, a transfer reference and a due date. Goora marks it paid by hand (a demo action in Settings → Demo). An invoice unpaid past its due date pauses coverage for the company's employees.
- **Roster and log.** The HR contact sees names, work emails and join dates, and can remove an employee; a log records who did what.
- **Company numbers.** Monthly totals (active employees, trips shared, estimated savings, CO₂, parking spaces freed) in words with their method; any figure built from fewer than 5 employees shows "Fewer than 5". No individual appears.
- **Switches, off for now.** `CompanyFlags.companyInvoicesLive` and `CompanyFlags.hrStatementExport` stay `false` until the lawyer answers (constitution VIII).

Walked 2026-10-29, see `specs/010-company-network/walk5/REPORT.md`. Emulator walk-through steps are not written here yet.

## Map tiles (feature 012)

The match result and Today screens show the group's pickup points on a small map (tap for a
bigger one). It is display only: matching runs on the server, and the map only ever gets public
pickup points, never a home. The map sits behind one switch (`lib/core/map/pickup_map_renderer.dart`),
so the tile provider can change without touching the screens.

- **No tile URL (the default, every test and demo build):** the app draws a sketch of the points in
  order with a "sketch, not to scale" note, and makes no map network calls.
- **With a tile provider:** pass its address at build time. Public OpenStreetMap tiles must not be
  used in production; the provider is a founder decision. Never commit a real key.

```bash
flutter run \
  --dart-define=MAP_TILE_URL_TEMPLATE="https://tiles.example.com/{z}/{x}/{y}.png?key={key}" \
  --dart-define=MAP_TILE_API_KEY=YOUR_KEY \
  --dart-define=MAP_TILE_ATTRIBUTION="© Example Tiles"
```

`{key}` in the template is filled from `MAP_TILE_API_KEY`. The "© OpenStreetMap contributors"
credit (plus `MAP_TILE_ATTRIBUTION`, if set) shows on every map with tiles. The same two keys can
go in `.env` and be passed with `--dart-define-from-file=.env`. Release Android builds need the
`INTERNET` permission in the manifest for tiles. Spec: `specs/012-osm-map/`.

## Code generation

Riverpod providers and l10n are generated and committed. After changing a `@riverpod` provider or
an ARB file:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Layout

```text
lib/app/                 app root, router, locale
lib/core/theme/          the only place raw colors, sizes, radii live
lib/core/widgets/        shared Goora components
lib/core/l10n/           app_ar.arb (default) + app_en.arb
lib/features/<feature>/  domain (pure Dart) · data · presentation
```

Debug builds: long-press the logo on the welcome screen to open the **Design gallery**.
