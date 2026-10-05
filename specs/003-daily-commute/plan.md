# Implementation Plan: Commute Groups and the Daily Commute

**Branch**: `feature/003-daily-commute` | **Date**: 2026-10-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-daily-commute/spec.md`

## Summary

Replace the `/today` placeholder with the app's four-tab shell (Today · Week · Wallet · Trust) for
group members. Add four pure-Dart rule modules with the brief's exact numbers — `AttendanceRules`
(9 PM cut-off, half share, 5-minute no-show, 2 → warning, 3 → removal), `ReliabilityRules` (kept ÷
booked over 30 days), `RotationPlanner` (fair 4-week rotation per leg) and `BackupService` (§6.6
search order) — plus a small `PrivacyPreference` model that feeds 002 matching. Screens: rider
Today, driver Today with pickup check-in, Week, Trust, a Wallet placeholder, an in-app inbox, and a
simulated live trip with Share and SOS. All data comes from a fake `DailyCommuteRepository` and
`TrustRepository` over shared_preferences, driven by an injectable clock. The four rule modules are
mirrored in TypeScript for the Supabase Edge Functions (evening cut-off job, day actions) and pinned
to the Dart versions by shared JSON test vectors, as in 002. SQL (RLS on every table) is written,
not deployed.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; TypeScript (Deno-compatible, tested on Node 24)

**Primary Dependencies**: two new Flutter packages, each behind an app interface (research R9):
`url_launcher` (open the dialler for "Call driver" and "Call 122") and `share_plus` (system share
sheet for "Share trip"). Versions: latest stable at `flutter pub add` time. No other new packages;
no FCM or maps package in this feature (keys not available).

**Storage**: shared_preferences (fake membership, absences, check-ins, confirmations, delays,
backup assignments, charges, privacy, trusted contacts, inbox, SOS alerts); Supabase Postgres schema
prepared in `supabase/migrations/`.

**Testing**: flutter_test — unit (attendance, reliability, rotation, backup, privacy, calendar,
vectors), widget (Today rider/driver, Week, Trust, Wallet, inbox, SOS sheet × ar/en; shell flow),
golden (new core widgets RTL + LTR); `node --test` for the TypeScript rules against the same
vectors.

**Target Platform**: Android 7+ / iOS 14+ (app); Supabase Edge Functions + pg_cron (server, later)

**Project Type**: mobile-app + server functions

**Performance Goals**: Today renders from local fake data in < 1 s (SC-001 ≤ 5 s); live position
refresh ≤ 10 s (simulated every 5 s); countdowns tick each second without rebuilding the whole tab.

**Constraints**: home points never leave the person's own records; rule code has no time zones
(wall-clock Cairo time in, research R2); Western digits; no keys in repo; no Goora fee anywhere.

**Scale/Scope**: 1 shell + 5 tab/screen surfaces + 3 sheets, 5 domain modules, ~4 new core widgets,
seed extended for one group's 4-week schedule, 1 SQL migration, 2 Edge Functions, 4 TS modules.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Daily ride, cancellation, backup and safety are the core commute loop | ✅ | ✅ |
| II Cost-sharing | Riders pay the fixed group price (40) even on backup days; late cancel = half share, no-show = full share, both owed to the driver; no Goora fee; no bidding; off-duty drivers pay like riders | ✅ | ✅ |
| III Arabic-first | All copy in ARB (prototype dictionary + drafted keys for review); directional widgets; ar/en widget tests | ✅ | ✅ |
| IV Privacy | Riders anonymous to drivers until "Picked up"; share link shows pickup point + route + live position only; RLS: own group's schedule only, home point owner-only | ✅ | ✅ |
| V Trust & safety | Share + SOS on Today at all times; SOS → Call 122 in 2 taps; verification checklist shown; driver mode needs license + vehicle verified | ✅ | ✅ |
| VI Design system | New pieces (stat tile, progress bar, status chip, live marker on route map) go in `lib/core/widgets` with goldens | ✅ | ✅ |
| VII Accessible | ≥ 44 px, labelled icon buttons (call, SOS, share, inbox), status = text + icon, never colour alone | ✅ | ✅ |
| VIII Testable | Rules pure Dart with brief numbers at exact boundaries; shared vectors with server; widget tests ar + en | ✅ | ✅ |
| IX Simplicity | Two packages with stated reasons (R9); one cover per leg (no rider splitting); in-app inbox instead of push | ✅ | ✅ |
| Secrets / open items | Keys only via `.env`; share-link base URL from `Env`; SMS to trusted contacts recorded only (provider open); charges kept as records until 004 | ✅ | ✅ |

## Project Structure

### Documentation (this feature)

```text
specs/003-daily-commute/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/ (repositories.md, edge-functions.md)
└── tasks.md
```

### Source Code

```text
lib/app/
├── router.dart                    # StatefulShellRoute (today/week/wallet/trust); /today stays the entry
└── routes.dart                    # + week, wallet, trust
lib/core/widgets/
├── goora_stat_tile.dart           # "Return time" / "You pay per trip" tiles
├── goora_progress_bar.dart        # reliability bar (value + text, never colour alone)
├── goora_status_chip.dart         # Covered / Notified · waiting / Picked up / No-show (icon + text)
└── goora_route_map.dart           # + optional live driver marker (progress 0–1)
lib/core/time/
├── calendar_date.dart             # date without time; Day mapping; +days; month key
├── wall_time.dart                 # CalendarDate + Clock (Cairo wall clock), compare, minus
└── now_provider.dart              # injectable "now"; debug demo-clock override
lib/features/daily/
├── domain/   attendance_rules.dart · reliability_rules.dart · rotation_planner.dart
│             backup_service.dart · privacy.dart · ride.dart · schedule.dart · absence.dart
│             check_in.dart · charge.dart · notice.dart · trust.dart
│             daily_commute_repository.dart · trust_repository.dart
│             location_source.dart · phone_dialer.dart · trip_sharer.dart
├── data/     daily_seed.dart · fake_daily_commute_repository.dart · fake_trust_repository.dart
│             simulated_location_source.dart · url_phone_dialer.dart · share_plus_sharer.dart
│             providers.dart
└── presentation/
    shell/    app_shell.dart (tabs + bottom nav)
    today/    today_screen.dart · rider_today.dart · driver_today.dart · pickup_check_in.dart
              cant_come_sheet.dart · delay_sheet.dart · today_controller.dart
    week/     week_screen.dart · week_controller.dart
    trust/    trust_screen.dart · trusted_contacts_sheet.dart · trust_controller.dart
    wallet/   wallet_tab.dart (placeholder, 004)
    inbox/    inbox_sheet.dart
    safety/   sos_sheet.dart · share_trip.dart
    labels.dart                    # day / leg / status / notice → l10n
lib/features/commute/
├── domain/group.dart              # + Member.seats, vehicle, phone, privacy, days; CommuteGroup.stops, arrival
├── data/corridor_seed.dart        # + stop names/times, vehicles, phones (002 numbers unchanged)
└── presentation/commute_controller.dart   # Seeker built with the saved PrivacyPreference
lib/features/onboarding/presentation/onboarding_routes.dart   # members resume at /today
lib/features/placeholder/presentation/placeholder_screen.dart # plan → "Continue" to /today
lib/features/settings/presentation/settings_screen.dart       # debug-only Demo section (R11)
supabase/
├── migrations/20261006000000_daily_commute.sql
└── functions/_shared/ attendance.ts · reliability.ts · rotation.ts · backup.ts (+ .test.ts each)
    functions/commute-day/index.ts · functions/evening-cutoff/index.ts
test/fixtures/ attendance_vectors.json · reliability_vectors.json · rotation_vectors.json
               backup_vectors.json
test/unit/  calendar_test · attendance_rules_test · reliability_rules_test · rotation_planner_test
            backup_service_test · privacy_test · daily_vectors_test
test/widget/ today_rider_test · today_driver_test · week_test · trust_test · shell_flow_test
             safety_test
test/golden/ daily_widgets_golden_test.dart (+ goldens)
```

**Structure Decision**: a new `daily` feature folder for everything that happens after joining a
group (Today, Week, Trust, safety); `commute` keeps groups and matching and only gains the fields
003 needs. Calendar/wall-clock types live in `lib/core/time` because rules, UI and tests all share
them. Server code stays under `supabase/`, rules mirrored once in TypeScript and pinned by vectors.

## Phasing (maps to tasks.md)

- **P1 — US1–US3**: shell + routing, time core, seed, `AttendanceRules`, rider Today, cancel sheet,
  driver Today, check-in, no-show charges and standing, inbox. Shippable on its own.
- **P2 — US4–US6**: `RotationPlanner`, `BackupService`, Week tab, banners, `ReliabilityRules`,
  Trust tab, privacy → matching, role switch, trusted contacts.
- **P3 — US7**: simulated live position, Share trip, SOS.
- **Server (after P2)**: TS mirrors + vectors, migration, two Edge Functions.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Rules in Dart and TypeScript | FR-033: the evening job must use the same rules and tests as the app | Server-only can't run on fake data; Dart-only can't run in the Edge Function. Shared vectors keep both identical (002 pattern). |
| Two new packages | "Call driver", "Call 122" need the dialler; "Share trip" needs the share sheet (FR-029/030) | Hand-written platform channels are more code and more risk than two widely used plugins; both sit behind interfaces so tests use fakes. |
