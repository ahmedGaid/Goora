---
description: "Task list for feature 001: Foundation, Design System and Onboarding"
---

# Tasks: Foundation, Design System and Onboarding

**Input**: Design documents from `specs/001-foundation-onboarding/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: REQUIRED (constitution VIII + spec FR-024/SC-002/SC-003): unit tests for domain rules,
widget tests for every screen in ar + en, golden tests for core widgets in RTL + LTR, and the
no-hard-coded-values scan.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1 welcome+language · US2 sign-up · US3 role+frequency · US4 settings · US5 gallery

---

## Phase 1: Setup

- [x] T001 Create the Flutter app at repo root (`flutter create --org app.goora --project-name goora --platforms android,ios .`), set Android minSdk 24 in `android/app/build.gradle.kts` and iOS 14 in the Xcode project (`ios/Podfile` is generated on first `pod install`)
- [x] T002 Add dependencies in `pubspec.yaml`: flutter_riverpod, riverpod_annotation, go_router, flutter_localizations (sdk), intl, shared_preferences, lucide_icons_flutter; dev: riverpod_generator, build_runner (research R1–R5)
- [x] T003 [P] Configure `analysis_options.yaml`: flutter_lints + strict-casts/inference/raw-types, exclude `**/*.g.dart` and generated l10n (research R11)
- [x] T004 [P] Create `.env.example` (SUPABASE_URL, SUPABASE_ANON_KEY, GOOGLE_MAPS_API_KEY, all empty) and `lib/core/config/env.dart` reading them with `String.fromEnvironment`; confirm `.env` is git-ignored (research R6)
- [x] T005 [P] Generate static Cairo and Plus Jakarta Sans TTFs (400/500/600/700/800) from the google/fonts OFL variable fonts with fontTools, place in `assets/fonts/` with `OFL.txt`, declare families in `pubspec.yaml` (research R7)
- [x] T006 [P] Create `l10n.yaml` (arb-dir `lib/core/l10n`, template `app_ar.arb`, non-synthetic output) and enable `generate: true` (research R3)

---

## Phase 2: Foundational (blocks every story)

### Design tokens

- [x] T007 [P] `lib/core/theme/app_colors.dart` exactly as brief §3.1
- [x] T008 [P] `lib/core/theme/app_radii.dart` and `lib/core/theme/app_spacing.dart` from brief §3.3 + research R8 extra tokens
- [x] T009 [P] `lib/core/theme/app_typography.dart`: §3.2 table tokens + R8 tokens, per-locale font family (Cairo for ar, Plus Jakarta Sans for en), wordmark always Plus Jakarta Sans 800 / ls −2, line height 1.5 body/caption and 1.2 headings
- [x] T010 `lib/core/theme/app_theme.dart`: `ThemeData(useMaterial3: true)`, `ColorScheme.light(primary, secondary: green, surface, error: danger)`, `scaffoldBackgroundColor: background`, text theme by locale (brief §3.5)
- [x] T011 [P] `lib/core/theme/app_format.dart`: number formatting with Western digits in both locales (research R3)

### Shared components (`lib/core/widgets/`, brief §3.4)

- [x] T012 [P] `goora_icons.dart` (Lucide aliases). _Done differently: Lucide's `*Dir` icons set `matchTextDirection`, so no custom `directional_icon.dart` was needed._
- [x] T013 [P] `goora_primary_button.dart` (54 h, radius 16, primary fill / mint-on-dark variant, optional trailing mirrored arrow)
- [x] T014 [P] `goora_ghost_button.dart` (48 h, white, 1 px borderStrong, danger variant; on-dark outline variant for welcome "Log in")
- [x] T015 [P] `goora_dashed_button.dart` (48 h, radius 14, dashed disabled border)
- [x] T016 [P] `goora_card.dart` + `goora_hero_card.dart` (divider rows; primary fill hero, padding 20)
- [x] T017 [P] `goora_pill.dart` + `goora_chip.dart` (min 44×44 pill selected/unselected; chip radius 999)
- [x] T018 [P] `goora_radio_card.dart` (2 px border, radio on end side, 22 px radio with 7 px ring / 2 px disabled ring, icon tile 64 / radius 18, optional chip)
- [x] T019 [P] `goora_avatar.dart` (sizes 40/44/48/52, photo or initials on palette, group stack overlap −12 with 3 px white ring via margin-start)
- [x] T020 [P] `goora_banner.dart` (warning/info, radius 18, padding 14×16, title, body, optional action)
- [x] T021 [P] `goora_stepper.dart` (48 px circular −/+, enabled primary, disabled background+border, semantic labels)
- [x] T022 [P] `goora_progress_dots.dart` (current 28×5 green, done 14×5 green, future 14×5 borderStrong, gap 6 — research R9)
- [x] T023 [P] `goora_bottom_nav.dart` (4 tabs, 22 px icon, 12/700 label, active greenText, inactive textMuted, bottom pad 22)
- [x] T024 [P] `goora_timeline_row.dart` (14 px dot: green pickup, disabled transit, mapDestination arrival)
- [x] T025 [P] `goora_logo.dart` (CustomPainter arc ring stroke 7 mint ~70%, round caps, 5 px center dot, + wordmark)
- [x] T026 [P] `language_pill.dart` (globe icon + other-language label, top-end placement helper, semantic label)

### App shell, l10n, state

- [x] T027 Seed `lib/core/l10n/app_ar.arb` and `app_en.arb` with every brief §7 key, prototype copy (research R12 list) and drafted sign-up/settings copy; run `flutter gen-l10n`
- [x] T028 `lib/core/storage/preferences.dart`: SharedPreferences provider (overridable in tests)
- [x] T029 `lib/app/locale_controller.dart`: persisted locale, default `ar`
- [x] T030 `lib/app/goora_app.dart` + `lib/main.dart`: `MaterialApp.router` with locale, supported locales, delegates, theme by locale
- [x] T031 `test/helpers/pump_app.dart`: pump any widget in ar or en with bundled fonts loaded and provider overrides

### Foundational tests

- [x] T032 [P] `test/golden/components_golden_test.dart`: every component above in RTL and LTR (goldens committed)
- [x] T033 [P] `test/architecture/no_hardcoded_values_test.dart` scanning `lib/features/**` + `lib/app/**` (research R10)
- [x] T034 [P] `test/unit/theme_tokens_test.dart`: AppColors hex values and radii/spacing equal brief §3

**Checkpoint**: tokens, components, l10n, locale state and test helpers ready.

---

## Phase 3: US1 — Welcome screen in my language (P1) 🎯 MVP

**Goal**: branded welcome in Arabic by default; one-tap persisted language switch.
**Independent test**: launch, switch language, relaunch — language kept.

- [x] T035 [P] [US1] Widget test `test/widget/welcome_screen_test.dart` (ar + en: taglines order, buttons, pill label, RTL/LTR direction, arrow mirrored)
- [x] T036 [P] [US1] Unit test `test/unit/locale_controller_test.dart` (default ar, persists en)
- [x] T037 [US1] `lib/features/onboarding/presentation/welcome_screen.dart` (forest bg, logo + wordmark, taglines, splashSub, mint "Get started" with arrow, on-dark outline "Log in", language pill)
- [x] T038 [US1] `lib/app/router.dart` with `/` route and initial redirect skeleton

---

## Phase 4: US2 — Sign up with my Egyptian phone number (P1)

**Goal**: phone → code → name/gender with fake auth; log-in skips profile.
**Independent test**: complete sign-up with code 123456 and land on role screen.

- [x] T039 [P] [US2] Unit test `test/unit/phone_number_test.dart` (all accepted formats, prefixes 010/011/012/015, rejects others)
- [x] T040 [P] [US2] Unit test `test/unit/fake_auth_repository_test.dart` (wrong code, existing vs new account, offline)
- [x] T041 [P] [US2] `lib/features/onboarding/domain/phone_number.dart`, `gender.dart`, `profile.dart`, `auth_repository.dart`, `profile_repository.dart` (data-model, contracts/repositories.md)
- [x] T042 [US2] `lib/features/onboarding/data/fake_auth_repository.dart` + `local_profile_repository.dart` + Riverpod providers
- [x] T043 [US2] `phone_screen.dart` + controller (mode signup/login, validation hint, network error + retry)
- [x] T044 [US2] `otp_screen.dart` + controller (6 digits, wrong-code error, 60 s resend, dev hint when fake, change number)
- [x] T045 [US2] `profile_screen.dart` + controller (first/last name, gender pills, private note)
- [x] T046 [US2] Routes `/phone`, `/otp`, `/profile`; login-with-existing-account → resume step. _`/home` dropped: a returning user resumes at their destination placeholder, so `/home` was unreachable._
- [x] T047 [P] [US2] Widget tests `test/widget/phone_screen_test.dart`, `otp_screen_test.dart`, `profile_screen_test.dart` (ar + en)

---

## Phase 5: US3 — Role and frequency (P1)

**Goal**: role → frequency → correct destination, with progress dots and resume.
**Independent test**: all four role × frequency combinations reach the right placeholder.

- [x] T048 [P] [US3] Unit test `test/unit/onboarding_flow_test.dart` (resumeStep cases, destinationFor 4 combos, progressIndex)
- [x] T049 [P] [US3] `lib/features/onboarding/domain/role.dart`, `frequency.dart`, `onboarding_flow.dart`
- [x] T050 [US3] `role_screen.dart` (dots step 0, two radio cards with car/person icons, note, Continue disabled until picked, back)
- [x] T051 [US3] `frequency_screen.dart` (dots step 1, Every day preselected + Best value chip, role-specific sublines, back keeps role)
- [x] T052 [US3] `lib/features/placeholder/presentation/placeholder_screen.dart` (commute setup with dots step 2; Empty seats today; Offer a trip; back → frequency)
- [x] T053 [US3] Router: `/role`, `/frequency`, `/commute-setup`, `/empty-seats`, `/offer-trip`; full launch redirect via `OnboardingFlow.resumeStep`
- [x] T054 [P] [US3] Widget tests `test/widget/role_screen_test.dart`, `frequency_screen_test.dart`, `placeholder_screen_test.dart` (ar + en, all four sublines)
- [x] T055 [US3] Widget flow test `test/widget/onboarding_flow_test.dart` (welcome → … → destination for 4 combos)

---

## Phase 6: US4 — Settings: language and role (P2)

- [x] T056 [US4] `lib/features/settings/presentation/settings_screen.dart` (language pill, role switch using toDriver/toRider), route `/settings`, entry from placeholders/home
- [x] T057 [P] [US4] Widget test `test/widget/settings_screen_test.dart` (ar + en; switching persists)

---

## Phase 7: US5 — Design gallery (P2)

- [x] T058 [US5] `lib/features/design_gallery/presentation/design_gallery_screen.dart` (every component + states, color swatches, type scale, radii, spacing; language pill), `/debug/gallery` only in `kDebugMode`, long-press welcome logo opens it
- [x] T059 [P] [US5] Widget test `test/widget/design_gallery_screen_test.dart` (ar + en render without overflow)

---

## Phase 8: Polish

- [x] T060 Accessibility pass: every tappable ≥ 44 px, semantic labels on icon-only buttons, text scale 1.3 renders without overflow on onboarding screens (add to widget tests)
- [x] T061 Run `flutter analyze` (0 issues) and `flutter test` (all green); run quickstart.md steps
- [x] T062 [P] README.md: run/test commands, dev code 123456, `.env` usage

---

## Dependencies & Execution Order

- Setup (T001–T006) → Foundational (T007–T034) → US1 → US2 → US3 → US4, US5 → Polish.
- US2 needs the router from US1 (T038). US3 needs the profile + auth from US2 for resume logic.
- US4 and US5 are independent of each other once US3 is done.
- Within a story: domain + unit tests before screens; screens before their widget tests pass.

## Parallel Example: Foundational components

```text
T013 goora_primary_button · T014 goora_ghost_button · T015 goora_dashed_button · T017 pill+chip
T018 radio card · T019 avatar · T020 banner · T021 stepper · T022 progress dots — all separate files
```

## Implementation Strategy

MVP = Setup + Foundational + US1 (branded bilingual welcome). Then US2 → US3 complete onboarding;
US4 + US5 close the feature. Commit after each phase.

---

## Phase 9: Convergence

- [x] T063 Assert Western digits render in Arabic (OTP countdown shows "60", not "٦٠") in `test/widget/onboarding_screens_test.dart` per FR-004 (partial)
- [x] T064 Extend the 1.3× text-size test to the code, profile, settings and placeholder screens in `test/widget/onboarding_screens_test.dart` per spec Edge Cases (partial)
- [x] T065 Remove unused `lib/core/theme/app_format.dart` (gen-l10n already prints Western digits; add a formatter when a feature first formats money) per plan: research R3 (unrequested)
- [x] T066 Update `specs/001-foundation-onboarding/contracts/routes.md`: drop `/home` and the `?mode=` phone parameter, which the implementation removed as unreachable/unneeded, per plan: contracts/routes.md (contradicts)
