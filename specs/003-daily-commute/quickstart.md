# Quickstart: validate feature 003

## Prerequisites

Flutter 3.44 / Dart 3.12, Node 24. Work in the `feature/003-daily-commute` worktree.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Gates (all must pass)

```bash
flutter analyze                            # zero issues
flutter test                               # unit + widget (ar/en) + goldens + vectors
node --test "supabase/functions/_shared/*.test.ts"    # TS rules on the same vectors
```

## Manual run (fake data, debug build)

```bash
flutter run
```

1. **Rider (US1)**: sign up → I need a ride → Every day → Sheikh Zayed → Smart Village → Find →
   Join → Plan placeholder → Continue → Today tab. Check hero, legs (Covered), map, driver card,
   timeline, tiles ("40 EGP to the driver · no per-trip fees"), Share + SOS. Switch to English:
   same tab, same state.
2. **Cancel (US2)**: Settings → Demo → time 8:55 PM → Today → I can't come tomorrow → sheet says
   free → confirm → info banner; "Undo, I'm coming" works. Repeat at 9:05 PM → sheet shows 40 EGP
   (both legs) before confirming; undo is refused calmly.
3. **Driver (US3)**: sign up as driver → join → Today shows "Tomorrow · …" hero; contribution =
   passengers × 40 × trips. Confirm / Undo. Demo time ride-day 7:15 → "I've arrived at Main Gate" →
   5:00 countdown; "No-show" disabled until it ends, then "No-show · full share charged".
4. **Backup + Week (US4/US5)**: Demo → "Driver can't drive next Tuesday" → rider sees the warning
   banner "… will drive instead"; Week shows "(backup)". Demo → "no cover" → notice with three
   options; "Take the day off" is free.
5. **Trust (US6)**: reliability 96 % with caption; privacy pills (Women only hidden for men, Same
   company disabled without a work email); Switch to driver mode → setup in driver mode.
6. **Safety (US7)**: during a demo trip the marker moves; Share opens the share sheet (no home
   location in the text); SOS → Call 122 opens the dialler with 122.

Expected numbers are the brief's: 9 PM, half share 20, full share 40, 5 minutes, 2 → warning,
3 → removal, reliability 96 % on the seed.
