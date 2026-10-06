---
description: "Task list for feature 003: Commute Groups and the Daily Commute"
---

# Tasks: Commute Groups and the Daily Commute

**Input**: `specs/003-daily-commute/` (plan, spec, research, data-model, contracts, quickstart)

**Tests**: REQUIRED — constitution VIII and FR-011/FR-034/FR-036: unit tests with the brief's exact
numbers at each boundary, shared vectors on Dart + Node, widget tests ar + en for every new screen,
goldens RTL + LTR for new core widgets.

**Order**: P1 (US1–US3) → P2 (US4–US6) → P3 (US7) → Server → Polish. Each P-block ends with green
`flutter analyze` + `flutter test` and can be committed on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1…US7 from spec.md
- "R#" = section of research.md; "FR-###" = spec requirement

---

## Phase 1: Setup

- [X] T001 Add `url_launcher` and `share_plus` with `flutter pub add` (latest stable; reason in plan Complexity Tracking) and add the `tel` `<queries>` intent to `android/app/src/main/AndroidManifest.xml` (R9)
- [X] T002 [P] Add `shareBaseUrl` (`String.fromEnvironment`, placeholder default) to `lib/core/config/env.dart` and `.env.example` (R10)
- [X] T003 Add 003 ARB keys to `lib/core/l10n/app_ar.arb` and `lib/core/l10n/app_en.arb`: Today / Week / Trust copy taken from the prototype's ar/en dictionary in `Goora Prototype.html` (brief wins: no Goora-fee lines, 160 not 180) plus the drafted keys in research R14; run `flutter gen-l10n`

---

## Phase 2: Foundational (blocks every story)

**Time core**

- [X] T004 [P] `lib/core/time/calendar_date.dart` (CalendarDate: weekday → `Day`, addDays, monthKey, compare, daysBetween) and `lib/core/time/wall_time.dart` (WallTime = CalendarDate + Clock; compare, plusMinutes, minutesUntil) per R2
- [X] T005 [P] `lib/core/time/now_provider.dart`: Riverpod `nowProvider` returning `WallTime Function()` from local time; debug-only override read from `debug.demoNow` (R11)
- [X] T006 [P] `test/unit/calendar_test.dart`: weekday → Day for a known week, month rollover, year rollover, monthKey, WallTime ordering across midnight

**Domain model**

- [X] T007 Extend `lib/features/commute/domain/group.dart`: `Stop`, `Vehicle` (+ colour enum), `Member.seats/vehicle/phone/privacy/days` (all optional), `CommuteGroup.stops/arrival/arrivalName/rotationStart` with defaults so every 002 constructor and test still compiles unchanged (data-model "Additions")
- [X] T008 [P] `lib/features/daily/domain/privacy.dart`: `PrivacyPreference` enum, `PersonFacts`, `PrivacyRules.accepts` / `available` (R7)
- [X] T009 [P] `lib/features/daily/domain/` value types: `ride.dart` (Ride, RideStatus), `schedule.dart` (Duty, LegAssignment, ScheduleDay), `absence.dart` (Absence, AbsenceKind, UndoResult), `check_in.dart` (StopCheckIn, Outcome, PassengerOutcome), `charge.dart` (Charge, ChargeReason), `notice.dart` (Notice, NoticeKind, NoCoverOption), `trust.dart` (VerificationItem, TrustProfile, TrustedContact, SosAlert, Reliability, ReliabilityEvent) — JSON for each stored type; ride id `<groupId>:<yyyy-mm-dd>:<going|return>`
- [X] T010 `lib/features/daily/domain/rotation_planner.dart`: per-leg greedy fair rotation over 4-week periods from `rotationStart`, ties → longest since last drive → lowest id; `unavailable` set; planned vs actual assignments (R5)
- [X] T011 [P] `test/unit/rotation_planner_test.dart`: 2 drivers and 3 drivers × 4 weeks → max − min ≤ 1 per leg per period (SC-005); going-only / return-only drivers only get their leg; a driver's chosen days respected; an unavailable day reassigns without changing period counts; deterministic output
- [X] T012 [P] `test/unit/privacy_test.dart`: every pref × (woman/man, same/different/no company, same/different/no compound) for `accepts`; `available` rules (womenOnly women only, sameCompany needs verified work email, sameCompound needs a compound)
- [X] T013 Interfaces per `contracts/repositories.md`: `lib/features/daily/domain/daily_commute_repository.dart`, `trust_repository.dart`, `phone_dialer.dart`, `trip_sharer.dart`, `location_source.dart`

**Fake data and wiring**

- [X] T014 Extend `lib/features/commute/data/corridor_seed.dart` (stops Main Gate 7:20 / Central St. 7:25, arrival Smart Village Gate 2 8:05, vehicles, seats, fake phones +20 10 0000 000x, rotationStart) keeping every 002 matching number unchanged; create `lib/features/daily/data/daily_seed.dart` (30-day history giving the seeded person 96 % with 1 late cancel this month, network drivers for backup steps 3–4, trust statuses) per R11
- [X] T015 `lib/features/daily/data/fake_daily_commute_repository.dart`: `myGroup` (seed group + the person as member with their role/legs from 002 profile + membership), `schedule` (RotationPlanner + stored absences/backups), `ride`, notices stream, storage keys from data-model; action methods stubbed to throw `UnimplementedError` until their story
- [X] T016 [P] `lib/features/daily/data/url_phone_dialer.dart`, `share_plus_sharer.dart`, and `lib/features/daily/data/providers.dart` (repositories, dialer, sharer, location source; all overridable)
- [X] T017 Rerun `flutter analyze` and the 002 suite (`flutter test test/unit test/widget test/golden`) — must stay green after T007/T014

**Shell and routing (FR-001, FR-002)**

- [X] T018 [P] Core widgets in `lib/core/widgets/`: `goora_stat_tile.dart`, `goora_progress_bar.dart`, `goora_status_chip.dart` (icon + text: covered, waiting, pickedUp, noShow, backup, off), live-marker option on `goora_route_map.dart`; add each to `lib/features/design_gallery/presentation/design_gallery_screen.dart` (R13)
- [X] T019 [P] `test/golden/daily_widgets_golden_test.dart` + goldens RTL/LTR for T018 widgets
- [X] T020 `lib/features/daily/presentation/shell/app_shell.dart` (GooraBottomNav: Today · Week · Wallet · Trust, labelled) and `lib/features/daily/presentation/wallet/wallet_tab.dart` (004 placeholder card); `lib/app/routes.dart` + `lib/app/router.dart`: `StatefulShellRoute.indexedStack` with `/today`, `/week`, `/wallet`, `/trust`; drop `PlaceholderKind.today` (R1)
- [X] T021 `lib/features/onboarding/presentation/onboarding_routes.dart`: members (membership key present) resume at `/today`; `lib/features/placeholder/presentation/placeholder_screen.dart`: plan placeholder gets "Continue" → `/today` (FR-002)
- [X] T022 `test/widget/shell_flow_test.dart`: driver Join → shell with Today selected; rider Join → plan → Continue → shell; restart with membership → shell; language switch keeps the current tab (ar + en)

**Checkpoint**: shell reachable, rules foundation and seed in place, 002 suite green.

---

## Phase 3: US1 — My ride today, as a rider (P1) 🎯 MVP

**Goal**: rider opens the app and sees today's ride end to end. **Independent test**: seeded rider,
fixed clock, every element of US1/AC2 in ar + en.

- [X] T023 [US1] `lib/features/daily/presentation/today/today_controller.dart`: next ride day, my legs and their actual drivers, pickup stop (nearest group stop to home — only the stop is exposed), pickup countdown, price per trip, non-working-day / off state
- [X] T024 [US1] `lib/features/daily/presentation/today/today_screen.dart` (rider vs driver layout switch) and `rider_today.dart`: greeting; hero "Your ride is confirmed · time · route"; legs card with Covered chips and the separate-trips note (US1/AC3 single leg / other group); map card with "Pickup in N min"; driver card (avatar, name, verified badge, car + colour, rating, "Call driver"); timeline (GooraTimelineRow); Return time + "You pay per trip" tiles ("40 EGP to the driver · no per-trip fees", FR-004); Share trip + SOS buttons (wired in US7, visible now); "I can't come tomorrow" + caption; "Need an extra trip? Book a seat" → `/empty-seats`
- [X] T025 [US1] "Call driver" via `PhoneDialer` only for the current or next trip's driver (US1/AC4); next ride day hero without countdown when today is not a ride day (US1/AC5)
- [X] T026 [US1] `lib/features/daily/presentation/labels.dart`: day, leg, stop, vehicle colour, status, notice kind → l10n
- [X] T027 [P] [US1] `test/widget/today_rider_test.dart`: all AC2 elements ar + en with fixed clock; one-leg rider; Call driver dials the seeded number (fake dialer); off day → next ride day, no countdown; extra-trip entry routes to `/empty-seats`; no "fee" text other than "no per-trip fees"

---

## Phase 4: US2 — Can't come: cancellation and no-show rules (P1)

**Goal**: §6.5 rules exactly, with charges recorded. **Independent test**: fixed clock, cancel
before/after 9 PM, no-shows → charges, banners, standing.

- [X] T028 [US2] `lib/features/daily/domain/attendance_rules.dart` with `AttendanceLimits` (21:00, 5 min, 2, 3): cutoffFor, cancelCharge, canCancel, canUndo, noShowAvailableAt, canMarkNoShow, noShowCharge, standing, driverNoShow, driverCantDriveLate (R3)
- [X] T029 [P] [US2] `test/unit/attendance_rules_test.dart`: 20:59 free / 21:00 late = 20; both legs late = 40; Sunday ride → Saturday 21:00 cut-off; cancel after pickup time refused; undo before cut-off ok, after refused; no-show at 4:59 refused, 5:00 allowed; full share 40; standing 1 ok / 2 warning / 3 removal; going + return same day = 2; month boundary resets count; driver no-show at pickup + 5; price even → exact half
- [X] T030 [US2] Implement in the fake repository: `cancel`, `undoCancel` (seat taken by the waitlist at the cut-off, R3), `notComingNextWeek`, `chargesOwed`, `noShowsInMonth`, standing effects (warning notice at 2; removal at 3 clears membership and frees the seat), reliability events, `chooseNoCoverOption(dayOff)`
- [X] T031 [P] [US2] `test/unit/fake_daily_repository_test.dart`: each repository action above with a fixed clock — charges owed to the driver with the right amounts, no Goora fee, events written, removal clears membership but keeps the commute profile
- [X] T032 [US2] `lib/features/daily/presentation/today/cant_come_sheet.dart`: legs to cancel (both by default), exact charge shown before confirming (free / N EGP), confirm; "Not coming next week" action with confirm; info banner "You're off tomorrow…" + "Undo, I'm coming"; late-cancel banner; undo-refused message; warning banner at 2; removal notice with "Find me a new group" → `/commute-setup`
- [X] T033 [US2] Debug-only Demo section in `lib/features/settings/presentation/settings_screen.dart`: demo time presets (ride-day 7:15 AM, 8:55 PM, 9:05 PM, real time) and "Reset demo data" (R11); hidden in release
- [X] T034 [P] [US2] `test/widget/cancel_test.dart` (ar + en): 2 taps to cancel with the exact charge visible (SC-002); free banner + undo; late cancel shows 40 for both legs; undo refused copy; warning banner; removal notice routes to setup

---

## Phase 5: US3 — Tomorrow's drive and pickup check-in, as a driver (P1)

**Goal**: driver Today + check-in producing no-show facts. **Independent test**: seeded driver,
confirm/undo, check-in with one picked up + one no-show, timers and charges.

- [X] T035 [US3] Implement in the fake repository: `setConfirmed`, `reportDelay` (5/10/15, shifts stop times), `cantDrive` (absence + late flag + reliability event; returns `BackupResult.none` until US4), `arrivedAt`, `mark` (refuses noShow before 5 min; switchable until start; last mark counts), `startTrip`, `endTrip`; each emits the right notices (FR-014)
- [X] T036 [US3] `lib/features/daily/presentation/today/driver_today.dart`: greeting + "You're driving tomorrow."; "Offer a trip" → `/offer-trip` and "Find riders" → `/offer-trip` placeholders; hero "Tomorrow · direction · N passengers" with stops + times and "Return from … time" when both ways; "Estimated contribution" = passengers × price × trips (FR-013); Confirm ⇄ "Undo confirmation" with "Confirmed. Your passengers have been notified."; Report delay; Can't drive (confirm); "Requests on your route" placeholder + detour note; "Riding <day> with <driver>" card on off-duty days with cancel (FR-022a)
- [X] T037 [US3] `lib/features/daily/presentation/today/delay_sheet.dart` (5 / 10 / 15 min → new time shown)
- [X] T038 [US3] `lib/features/daily/presentation/today/pickup_check_in.dart`: "I've arrived at <stop>" per stop in order; note "Passengers get notified. You wait 5 minutes max."; per passenger row "Notified · waiting" + 5:00 countdown (widget-scoped ticker), "Picked up" at once, "No-show" disabled with remaining time until 5:00; "No-show · full share charged" + note; riders shown as "Verified rider" / "Verified rider (woman)" + rating until picked up, then name + photo (FR-016); "Start trip" / "End trip"
- [X] T039 [US3] `lib/features/daily/presentation/inbox/inbox_sheet.dart`: bell on Today header (labelled, unread count as text) → notices list, designed empty state
- [X] T040 [P] [US3] `test/widget/today_driver_test.dart` (ar + en): hero values and contribution (2 passengers × 40 × 2 = 160); confirm ⇄ undo text; delay sheet; can't drive confirm; check-in countdown with fake clock — No-show disabled at 4:59, enabled at 5:00, charge row text; anonymity before pickup, name after; switching Picked up → No-show before start; inbox shows the rider-facing notices

**Checkpoint P1**: US1–US3 work on fake data; `flutter analyze` + `flutter test` green. Commit.

---

## Phase 6: US4 — Backup when a driver can't drive (P2)

**Goal**: §6.6 search order with banners and no-cover options. **Independent test**: seeded
driver unavailable → cover by order; no-cover path.

- [ ] T041 [US4] `lib/features/daily/domain/backup_service.dart`: steps sameGroup → nearbyGroup → sameCompany → sameCommunity; pass = available + free seats ≥ passengers + 002 hard constraints via `MatchingService.evaluate` (driver Seeker limited to the leg and day) + every passenger's `PrivacyRules.accepts`; within a step least detour → rating → id; `BackupResult.covered(cover, step)` / `none` (R6)
- [ ] T042 [P] [US4] `test/unit/backup_service_test.dart`: each step wins only when earlier steps have no passing candidate; same-group beats a better nearby candidate; seats too few → skipped; constraint fail at limit + 1, pass at limit; women-only passenger rejects a male cover; no candidates → none; group price unchanged on covered days
- [ ] T043 [US4] Fake repository: `cantDrive` runs `BackupService` over candidates built from the seed (off-duty group drivers, other corridor groups' drivers, network drivers), stores the `LegAssignment` override, emits `backupCover` or `noCover` notices; `noCover` is created by the cut-off at the latest (FR-020)
- [ ] T044 [US4] Rider Today banners: warning "<driver> can't drive on <day>" + "<cover> will drive instead. Your commute is still covered — nothing for you to do." + "Got it"; no-cover card with the three options (empty seat → `/empty-seats`, post trip → `/post-trip`, day off → free absence)
- [ ] T045 [US4] Demo section: "Driver can't drive next Tuesday" and "Driver can't drive — no cover" actions (R11)
- [ ] T046 [P] [US4] `test/widget/backup_test.dart` (ar + en): cover banner text and Got it; no-cover options route correctly; day off creates a free absence

---

## Phase 7: US5 — My week (P2)

**Goal**: Week tab schedule. **Independent test**: seeded group, fixed date, backup + absence in
place, rider and driver views.

- [ ] T047 [US5] `lib/features/daily/presentation/week/week_controller.dart` + `week_screen.dart`: "Your commute schedule", route and time, one row per working day with avatar and "<name> drives" / "You drive"; detail line — riders "Going: … · Return: …", drivers "<direction> · N riders" or "You ride"; "<cover> (backup)" labels; off rows "You're off · Cancelled before 9 PM · no charge" or the late text; rotation note; "Not coming next week" (reuses T032 flow)
- [ ] T048 [P] [US5] `test/widget/week_test.dart` (ar + en): rider and driver rows for a seeded week with one backup and one absence; rotation spreads days between Ahmed and Mohamed

---

## Phase 8: US6 — Trust: profile, verification, reliability and privacy (P2)

**Goal**: Trust tab, reliability, privacy feeding matching. **Independent test**: rider and driver
views; privacy choice changes matching results.

- [ ] T049 [US6] `lib/features/daily/domain/reliability_rules.dart`: 30-day window, booked/missed, round half up, 0 booked → 100, month caption counts (R4)
- [ ] T050 [P] [US6] `test/unit/reliability_rules_test.dart`: 12.5 / 13 → 96; 0 → 100; 1 no-show of 4 → 75; 1 late of 2 → 75; free cancel not booked; day 30 vs 31 window edge; .5 rounds up; month counts reset on the 1st while % does not
- [ ] T051 [US6] `lib/features/daily/data/fake_trust_repository.dart`: profile from 001 profile + seed statuses, privacy get/set with availability, trusted contacts (max 3, `PhoneNumber` validation), `sendSos` recorded
- [ ] T052 [US6] `lib/features/daily/presentation/trust/trust_controller.dart` + `trust_screen.dart`: avatar, name, "Verified member · rating ★"; checklist (rider: license + vehicle "Not needed"; driver: all five) statuses only (FR-023a); reliability card with % text, `GooraProgressBar`, caption; "Switch to driver/rider mode"; "Who can ride with me" pills with availability hints and the applies-to-future note (FR-026); trusted contacts entry
- [ ] T053 [US6] `lib/features/daily/presentation/trust/trusted_contacts_sheet.dart`: add / remove up to 3 (name + Egyptian mobile), designed empty state
- [ ] T054 [US6] Role switch: rider → `/commute-setup` in driver mode, with the "license and vehicle need verifying" note blocking driver matching while not verified; driver → rider keeps the saved commute (US6/AC4); update `lib/features/commute/presentation/commute_controller.dart` to build `Seeker` privacy flags from the saved `PrivacyPreference` (FR-024)
- [ ] T055 [P] [US6] `test/widget/trust_test.dart` (ar + en): rider vs driver checklist; 96 % bar + caption; Women only hidden for a man; Same company disabled without work email with hint; choosing a pill persists; role switch routes; contacts add/remove and max 3
- [ ] T056 [P] [US6] Extend `test/unit/matching_service_test.dart`: a seeker with `womenOnly` / `sameCompany` from `PrivacyPreference` excludes the groups 002 rules exclude (FR-024)

**Checkpoint P2**: US4–US6 work; analyze + tests green. Commit.

---

## Phase 9: US7 — Live trip, share and SOS (P3)

**Goal**: safety one tap away; simulated live position. **Independent test**: simulated trip
moves the marker; Share and SOS paths.

- [ ] T057 [US7] `lib/features/daily/data/simulated_location_source.dart`: 5 s ticks from driver arrival to arrival, progress = elapsed ÷ trip minutes (R8); wire the live marker + countdown into the rider map card during an active trip
- [ ] T058 [US7] `lib/features/daily/presentation/safety/share_trip.dart`: message (route areas, driver first name, car, expected arrival, `Env.shareBaseUrl/t/<token>`) via `TripSharer`; never a home location (FR-031)
- [ ] T059 [US7] `lib/features/daily/presentation/safety/sos_sheet.dart`: one confirm step → "Call 122" (`PhoneDialer.dial('122')`) + "Alert my trusted contacts" (records `SosAlert`, "We sent them your trip link"); no contacts → Call 122 + "Add a trusted contact" → Trust tab; works with no active trip (FR-029/030)
- [ ] T060 [P] [US7] `test/widget/safety_test.dart` (ar + en): marker progress advances with a fake location stream; share text contains route + driver + link and no home area point; SOS → Call 122 in 2 taps (SC-006) dials "122"; alert recorded with contacts; no-contacts path

---

## Phase 10: Server (ready, not deployed)

- [ ] T061 [P] `test/fixtures/{attendance,reliability,rotation,backup}_vectors.json` hand-computed per `contracts/edge-functions.md` minimum cases + `test/unit/daily_vectors_test.dart` running them against the Dart rules
- [ ] T062 [P] `supabase/functions/_shared/attendance.ts`, `reliability.ts`, `rotation.ts`, `backup.ts` mirroring T028/T049/T010/T041 (erasable TS, `.ts` imports, wall-time inputs)
- [ ] T063 `supabase/functions/_shared/{attendance,reliability,rotation,backup}.test.ts` loading the same vectors (`node --test`)
- [ ] T064 `supabase/migrations/20261006000000_daily_commute.sql`: tables per R12, RLS on every table (own group's rides only, own absences/contacts/alerts, drivers write check-ins for their rides, no home point exposure) (FR-032). _Written, not executed._
- [ ] T065 `supabase/functions/commute-day/index.ts` and `supabase/functions/evening-cutoff/index.ts` (pg_cron 21:00 Africa/Cairo, idempotent) as thin adapters per contract (FR-033). _Written, not executed._

---

## Phase 11: Polish

- [ ] T066 [P] Add new text/background pairs (hero on dark, status chips, banners, progress bar) to `test/unit/contrast_test.dart`; 1.3× text scale + tap-target + label guidelines on Today, Week, Trust, sheets
- [ ] T067 [P] Confirm `test/architecture/no_hardcoded_values_test.dart` covers `lib/features/daily` and `lib/core/time`
- [ ] T068 List every drafted key (R14 + any added during build) in `specs/003-daily-commute/research.md` R14 for founder review
- [ ] T069 Gates: `flutter analyze` (0 issues), `flutter test`, `node --test supabase/functions/_shared/`; run quickstart.md manual steps on a device/emulator; README: 003 section (demo section, new packages)

---

## Dependencies & Execution Order

```text
Setup (T001–T003) → Foundational (T004–T022)
  → US1 (T023–T027) → US2 (T028–T034) → US3 (T035–T040)        ← P1, commit
  → US4 (T041–T046) → US5 (T047–T048) → US6 (T049–T056)        ← P2, commit
  → US7 (T057–T060)                                             ← P3
  → Server (T061–T065; needs T010, T028, T041, T049) → Polish (T066–T069)
```

- US2 uses the Today screen from US1 (cancel entry). US3's `cantDrive` returns `none` until US4.
- US5 reads backups (US4) and absences (US2); it renders without them if built earlier.
- US6 is independent of US4/US5 except the role switch reusing 002 setup.
- US7 needs only the Today buttons from US1 and trusted contacts from US6 (SOS still works without).

## Parallel Examples

- Foundational: T004, T005, T006, T008, T009, T012 together; then T010 + T011; T018 + T019 alongside T015.
- US2: T029 (tests) alongside T030; T034 after T032.
- US6: T049 + T050 + T051 together, then T052–T054; T055 + T056 last.
- Server: T061 + T062 together, then T063.

## Implementation Strategy

1. **Session 1 (P1)**: Setup + Foundational + US1–US3 → MVP: a group rides every day with fair
   rotation, cancellation and no-show rules, driver check-in. Commit + converge.
2. **Session 2 (P2)**: US4–US6 → backup, Week, Trust, privacy into matching. Commit + converge.
3. **Session 3 (P3 + server + polish)**: US7, TS mirrors + vectors, SQL, functions, polish gates.

---

## Phase 12: Convergence

- [ ] T070 Apply `AttendanceRules.driverNoShow` in the fake repository: when a driver neither checked in nor cancelled by first pickup + 5 min, record a `noShow` reliability event for the driver and apply the same 2 → warning / 3 → removal standing per FR-010, FR-009 (partial)
- [ ] T071 Compute free seats per leg and day (`onDuty.seats − riders − off-duty drivers + absent`) and keep a ride from carrying more passengers than the on-duty car's seats per FR-022a (partial)
- [ ] T072 Settle passenger marks automatically once a trip's arrival time has passed without "End trip", so no-show charges and kept trips are always recorded per plan: research R11 (partial)
- [ ] T073 Move user-facing strings joined in code (`share_trip.dart` car line, `demo_section.dart` time line) into ARB keys per Constitution III (contradicts)
- [ ] T074 Add a widget test: a returning member who signs in by OTP lands on the shell with Today selected per FR-002 (partial)
