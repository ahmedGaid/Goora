# Implementation Plan: Foundation, Design System and Onboarding

**Branch**: `feature/001-foundation-onboarding` | **Date**: 2026-10-05 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-foundation-onboarding/spec.md`

## Summary

Create the Flutter app, the full Goora design system (tokens + every §3.4 component + a debug-only
Design gallery), Arabic-first localization with a persisted in-app language switch, and the
onboarding flow: welcome → phone → code → name/gender → role → frequency → placeholder destination,
plus a minimal Settings screen (language + role). Auth and profile storage sit behind repository
interfaces with fake/local implementations, so the app runs with no backend and no keys. Domain
rules for this feature (phone validation/normalisation, onboarding routing, resume step) are pure
Dart with unit tests.

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44 stable

**Primary Dependencies**: flutter_riverpod + riverpod_annotation (riverpod_generator, build_runner
dev), go_router, flutter_localizations + intl (ARB), shared_preferences, lucide_icons_flutter.
Fonts bundled as assets. No Supabase package yet (see research R6).

**Storage**: shared_preferences (device) for language, fake account registry and local profile.
Supabase arrives when the founder provides keys.

**Testing**: flutter_test — unit tests (domain), widget tests per screen in ar + en, golden tests
for core widgets in RTL + LTR, plus a source-scan test that fails on hard-coded colors, font sizes,
radii or string literals in feature code.

**Target Platform**: Android 7+ (API 24), iOS 14+

**Project Type**: mobile-app (single Flutter project at repo root)

**Performance Goals**: language switch applies within one frame; onboarding completable in < 2 min

**Constraints**: offline-capable fonts; light mode only; no real keys in source; Western digits

**Scale/Scope**: 10 screens (welcome, phone, code, profile, role, frequency, settings, gallery,
home + destination placeholders) + 15 shared components

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | Every screen serves getting a commuter onboarded | ✅ | ✅ |
| II Cost-sharing | No pricing in this feature; driver sublines keep "Always free" | ✅ | ✅ |
| III Arabic-first, RTL | `ar` default; ARB only; directional widgets; directional icons mirror; widget tests ar + en | ✅ | ✅ |
| IV Privacy | Gender stored privately, never displayed to others; no addresses collected yet | ✅ | ✅ |
| V Trust & safety | Phone OTP required before role choice; ID/licence deferred to feature 003 (spec Assumptions) | ✅ | ✅ |
| VI One design system | Tokens only in `lib/core/theme`; components in `lib/core/widgets`; source-scan test enforces | ✅ | ✅ |
| VII Accessible | ≥ 44 px targets in components; semantic labels on icon-only buttons; radio mark + border, not color alone | ✅ | ✅ |
| VIII Testable | Feature-first folders; Riverpod; repositories behind interfaces; pure-Dart domain + unit tests | ✅ | ✅ |
| IX Simplicity | 6 runtime packages, each with a reason (research R1–R5); Supabase deferred | ✅ | ✅ |
| Secrets | `.env` git-ignored + `.env.example`; read via `--dart-define-from-file` (no package) | ✅ | ✅ |

No violations → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-foundation-onboarding/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── routes.md
│   └── repositories.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app/
│   ├── goora_app.dart            # MaterialApp.router, locale + theme wiring
│   ├── router.dart               # go_router routes + onboarding redirect
│   └── locale_controller.dart    # persisted locale (Riverpod)
├── core/
│   ├── config/env.dart           # String.fromEnvironment keys (empty until provided)
│   ├── storage/preferences.dart  # SharedPreferences provider
│   ├── theme/                    # app_colors, app_typography, app_radii, app_spacing, app_theme
│   ├── widgets/                  # goora_*.dart — the 15 shared components + language pill
│   └── l10n/                     # app_ar.arb, app_en.arb + generated AppLocalizations
└── features/
    ├── onboarding/
    │   ├── domain/        # phone_number, role, frequency, gender, profile, onboarding_flow,
    │   │                  # auth_repository, profile_repository
    │   ├── data/          # fake_auth_repository, local_profile_repository
    │   └── presentation/  # welcome, phone, otp, profile, role, frequency screens + controllers
    ├── settings/presentation/settings_screen.dart
    ├── placeholder/presentation/placeholder_screen.dart
    └── design_gallery/presentation/design_gallery_screen.dart   # debug only

assets/fonts/   # Cairo-*.ttf, PlusJakartaSans-*.ttf (static 400/500/600/700/800) + OFL.txt

test/
├── helpers/pump_app.dart          # pumps a widget in ar or en with fonts loaded
├── unit/                          # domain tests
├── widget/                        # every screen × {ar, en}
├── golden/                        # core widgets × {RTL, LTR}
└── architecture/no_hardcoded_values_test.dart
```

**Structure Decision**: one Flutter app at the repo root, feature-first folders as the constitution
requires. Shared design system in `lib/core`; each feature owns `domain/data/presentation`.

## Complexity Tracking

None.
