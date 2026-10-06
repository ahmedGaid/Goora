---
name: goora-stack
description: Architecture, conventions, and hard rules for the Goora Flutter app (daily-commute coordination for Egypt) at C:\AhmedGaid\Goora — feature-first layers, Riverpod state, matching/pricing domain rules duplicated in Dart+TS, i18n ar/en, and the gates to run before claiming done. Recall when building, editing, refactoring, or reviewing ANY code in the project.
---

# goora-stack — architecture & conventions

**Stack**: Flutter (Dart ^3.12), Riverpod (`flutter_riverpod` + `riverpod_generator`), `go_router`,
`intl` for ARB l10n, Supabase backend (`supabase/` — PostGIS + RLS migrations + a `match` Edge
Function), Node 24 for the TS side of shared domain logic.

## Layers
`lib/features/<feature>/{data,domain,presentation}` — feature-first, not layer-first. `domain/`
is pure Dart, no Flutter imports, unit-testable. `data/` holds repositories behind abstract
interfaces (per Constitution VIII). `presentation/` is widgets + Riverpod providers.
Shared pieces: `lib/core/theme/` (tokens — `AppColors`, `AppTypography`, `AppRadii`,
`AppSpacing`, `AppSizes`; raw values live ONLY here), `lib/core/widgets/` (shared components,
prefixed `Goora*`), `lib/core/l10n/` (`app_ar.arb` / `app_en.arb`, generated via `flutter gen-l10n`
— driven by `l10n.yaml`, so CLI flags to `flutter build`/`flutter gen-l10n` are ignored once that
file exists).

## The twin-implementation rule
Matching and pricing rules exist **twice on purpose**: `lib/features/commute/domain/*.dart` (app)
and `supabase/functions/_shared/*.ts` (server, runs in the Edge Function). Both MUST pass the same
vectors — a change to one without the other is a bug, not a style choice. Verify with:
```
flutter test                                          # Dart side, incl. the vectors
node --test "supabase/functions/_shared/*.test.ts"    # TS side, same vectors, Node 24+, no install
```

## Hard rules (Constitution — `.specify/memory/constitution.md`)
- **Cost-sharing, never a taxi (non-negotiable, Law 87/2018):** riders' total payments must never
  exceed the full trip cost; price is system-calculated within ±20% of the suggested contribution;
  no bidding; a driver caps at 2 offered trips/day. Any change near pricing/matching needs this
  checked, not just tests passing.
- **RTL-correct, directional-only layout:** `EdgeInsetsDirectional`, `AlignmentDirectional`,
  start/end — never `left`/`right`. Directional icons mirror in RTL.
- **No hard-coded strings** — every user-facing string is an ARB key in both `app_ar.arb` and
  `app_en.arb`. Parity is checked (see Gates).
- **Privacy by design:** home addresses never exposed (pickup points only); rider name/photo
  hidden from drivers until accepted/boarded.
- **One design system:** no ad-hoc colors/sizes/radii in feature code — only `lib/core/theme`.
- **Accessible by default:** ≥44px touch targets, ≥4.5:1 text contrast, semantic labels on
  icon-only buttons, never color-alone. (Non-text UI parts get a narrower ≥3:1 bar, and even that
  can be waived when the same value is always shown as text too — see `contrast_test.dart`'s
  documented exception for `GooraProgressBar`.)
- **Testable architecture:** domain logic MUST be pure Dart with unit tests using the brief's
  exact numbers; each feature ships widget tests for its main screens in both locales.

## Gates — run before claiming done
```
flutter analyze                                # must be 0 issues
flutter test                                   # unit + widget (ar/en) + golden + token scan
node --test "supabase/functions/_shared/*.test.ts"
```
After any `.arb` edit: `flutter gen-l10n` (driven by `l10n.yaml`) regenerates
`app_localizations_*.dart` — commit both the arb and the generated file together.
Goldens are rendered on Windows; regenerate with `flutter test --update-goldens test/golden` only
after an intended visual change, on Windows.

## Device testing
No backend keys needed for a manual run — sign-in uses a fake OTP (any Egyptian mobile number,
code `123456`). `flutter run` targets whatever `flutter devices` lists. For a standalone install
(no persistent debug session): `flutter build apk --debug`, then
`adb install -r build/app/outputs/flutter-apk/app-debug.apk` and launch with
`adb shell monkey -p app.goora.goora -c android.intent.category.LAUNCHER 1` — `flutter install`
defaults to looking for a release APK even after a `--debug` build, so it fails unless pointed at
the debug one explicitly.

## Where detail lives
- Product brief / canon → `GOORA_SPEC_KIT_BRIEF.md`.
- Spec-driven workflow → `.specify/`, `specs/NNN-*/` (spec, plan, research, tasks per feature).
- Live state → [[goora-status]] · brand/voice → [[goora-brand]] · resume flow → [[goora-resume]].
