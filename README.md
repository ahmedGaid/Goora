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
