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

## Daily commute demo (debug builds)

After joining a group the app opens on **Today**. Settings → **Demo** moves a demo clock to the
moments the rules care about (ride day 7:15 AM, 8:55 PM / 9:05 PM the evening before), makes the
driver arrive at your stop (live trip), simulates a driver who can't drive (with or without a
backup), and resets the fake data. Release builds always use real time. New packages in 003:
`url_launcher` (Call driver, Call 122) and `share_plus` (Share trip).

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
