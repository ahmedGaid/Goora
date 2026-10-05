# Quickstart: validate feature 001

## Prerequisites

- Flutter 3.44+ stable (`flutter --version`), an Android emulator/device or iOS simulator.
- No keys needed: auth and profile run on fakes.

## Gates (from repo root)

```bash
flutter pub get
flutter analyze            # expect: No issues found!
flutter test               # unit + widget (ar/en) + golden + no-hardcoded-values scan
```

## Manual run

```bash
flutter run                # optional later: flutter run --dart-define-from-file=.env
```

1. First launch → welcome screen in Arabic, RTL, forest background, "مشوارك.. سوا." large.
2. Tap the "English" pill → everything flips to English/LTR. Kill and relaunch → still English.
3. "Get started" → enter `01012345678` → code screen shows "Test code: 123456" → enter it.
4. Fill first name, last name, gender → role screen (dot 1 wide green).
5. Pick "I need a ride" → Continue → frequency screen: "Every day" preselected with "Best value";
   sublines are the rider ones. Back → role still selected.
6. Every day → Continue → commute setup placeholder (dot 3 wide, dots 1–2 green).
7. Kill app, relaunch → resumes at the last incomplete step, not the welcome screen.
8. Settings (from the placeholder) → switch to driver → frequency sublines now show driver text.
9. Driver + Just one trip → "Offer a trip" placeholder; rider + Just one trip → "Empty seats today".
10. Debug build: long-press the welcome logo → Design gallery; switch language inside it.

## Expected

All four role × frequency combinations route correctly; no screen shows overflow stripes in either
language; every button is at least 44 px tall.
