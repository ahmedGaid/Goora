# Research: Foundation, Design System and Onboarding

All Technical Context unknowns resolved. Package versions checked on pub.dev on 2026-10-05
against Flutter 3.44.4 / Dart 3.12.2.

## R1 State: flutter_riverpod 3.4 + riverpod_annotation 4.0 (+ riverpod_generator 4.0, build_runner 2.16 dev)

- **Decision**: Riverpod with code generation, as the brief's plan prompt mandates.
- **Rationale**: brief §4; testable overrides for fake repositories in widget tests.
- **Alternatives**: hand-written providers (allowed by Riverpod, but the brief names the generator).
- Generated `*.g.dart` files are committed so `flutter test` works without running build_runner.

## R2 Routing: go_router 18.0

- **Decision**: one `GoRouter` with a `redirect` that sends a launching user to their resume step
  (see data-model `OnboardingStep`). Gallery route registered only when `kDebugMode`.
- **Rationale**: brief §4; redirect gives the "resume where I left off" edge case for free.

## R3 Localization: flutter_localizations + intl 0.20, ARB in `lib/core/l10n`

- **Decision**: `l10n.yaml` with `arb-dir: lib/core/l10n`, `template-arb-file: app_ar.arb`,
  output into the source tree (synthetic package is deprecated in current Flutter).
- Locale persisted in shared_preferences; default `ar` when nothing stored (device locale is
  ignored: Arabic-first per constitution III).
- Western digits: Flutter formats digits via `intl`; `ar` would default to Eastern Arabic digits
  only when using `NumberFormat` with the `ar` locale's native digits — all numbers are formatted
  through a helper that uses `NumberFormat(..., 'en')` so digits stay Western in both locales.

## R4 Persistence: shared_preferences 2.5

- **Decision**: stores locale, the fake account registry (phone → exists) and the local profile
  (JSON). Behind `ProfileRepository` / `AuthRepository` interfaces.
- **Rationale**: smallest thing that persists across restarts; replaced by Supabase later.

## R5 Icons: lucide_icons_flutter 3.1

- **Decision**: Lucide outline icons (2 px stroke, round caps) per brief §3.4.
- **Alternatives**: `lucide_icons` 0.257 — rejected, requires Dart < 3.
- RTL mirroring: directional icons (arrow-right/left, chevrons) are wrapped by a `DirectionalIcon`
  helper that flips horizontally when `Directionality` is RTL; others are not flipped.

## R6 Backend: Supabase deferred for this feature

- **Decision**: no `supabase_flutter` dependency yet. `FakeAuthRepository` accepts the
  development code `123456` (shown on the code screen only while the fake is active) and records
  registered numbers in shared_preferences.
- **Rationale**: constitution "until keys are provided, run against fake repositories";
  constitution IX (no package without a use). The real `SupabaseAuthRepository` is added when the
  founder supplies URL + anon key.
- **Secrets wiring now**: `.env.example` lists `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `GOOGLE_MAPS_API_KEY`; `.env` is git-ignored; values are read with `String.fromEnvironment` and
  `flutter run --dart-define-from-file=.env` (built into Flutter, no package).

## R7 Fonts: static TTF instances of Cairo and Plus Jakarta Sans

- **Decision**: take the OFL variable fonts from the google/fonts repository and cut static
  instances (400, 500, 600, 700, 800) with fontTools `varLib.instancer`; ship them in
  `assets/fonts/` with `OFL.txt`.
- **Rationale**: Flutter maps `FontWeight` to static faces reliably on every platform and in tests;
  variable-axis mapping is inconsistent. No runtime fetching (brief §3.2).
- **Alternatives**: `google_fonts` package — rejected, fetches at runtime by default.

## R8 Non-token values from §3.4 (founder decision 2026-10-05: add as named tokens)

| Token | Value | Used by |
|---|---|---|
| `AppRadii.banner` | 18 | GooraBanner |
| `AppRadii.dashed` | 14 | GooraDashedButton |
| `AppSpacing.listCardPad` | 18 | list cards |
| `AppSpacing.bannerV` / `bannerH` | 14 / 16 | GooraBanner padding |
| `AppSpacing.chipV` / `chipH` | 6 / 12 | GooraChip padding |
| `AppSpacing.pillH` | 12 | GooraPill |
| `AppTypography.button` | 16 / 700 | GooraPrimaryButton |
| `AppTypography.buttonSecondary` | 15 / 600 | GooraGhostButton |
| `AppTypography.dashed` | 13.5 / 600 | GooraDashedButton |
| `AppTypography.chip` | 13 / 700 | GooraChip |
| `AppTypography.pill` | 14 / 700 (selected), 14 / 600 (unselected) | GooraPill |
| `AppTypography.taglineLarge` / `taglineSmall` | 24 / 700, 20 / 700 | Welcome (prototype values) |
| `AppTypography.splashSub` | 15 / 400, line height 1.7 | Welcome (prototype value) |

Sizes not in §3 come from the prototype markup, which the brief names as the source of §3.

## R9 Progress dots (founder decision 2026-10-05)

Current step: 28 × 5 `green`; completed steps: 14 × 5 `green`; future: 14 × 5 `borderStrong`;
gap 6.

## R10 Enforcing "no hard-coded values"

- **Decision**: `test/architecture/no_hardcoded_values_test.dart` scans `lib/features/**` and
  `lib/app/**` for `Color(`, `Colors.`, `fontSize:`, `BorderRadius.circular(<digit>`,
  `Radius.circular(<digit>`, `EdgeInsets.only(left|right`, `Alignment.centerLeft/Right` and
  quoted string literals inside `Text(`; fails with file:line.
- **Rationale**: SC-003 must be verifiable automatically; runs inside `flutter test`.

## R11 Lints

- **Decision**: `flutter_lints` (from `flutter create`) + analyzer `strict-casts`,
  `strict-inference`, `strict-raw-types`; generated files excluded.
- **Alternatives**: very_good_analysis — allowed by the brief, but adds a package for little gain.

## R12 Drafted copy for screens with no source copy (founder decision: Claude drafts, founder reviews)

Every string below is listed again in the feature summary for founder review.

| key | ar | en |
|---|---|---|
| phoneTitle | رقم موبايلك إيه؟ | What's your mobile number? |
| phoneSub | هنبعتلك كود في رسالة عشان نتأكد إنه رقمك. | We'll text you a code to confirm it's yours. |
| phoneLabel | رقم الموبايل | Mobile number |
| phoneHint | رقم موبايل مصري: 11 رقم بيبدأ بـ 01 | An Egyptian mobile: 11 digits starting with 01 |
| sendCode | ابعتلي الكود | Send me the code |
| otpTitle | اكتب الكود | Enter the code |
| otpSub | بعتناه على {phone} | We sent it to {phone} |
| otpWrong | الكود ده مش مظبوط. جرّب تاني. | That code doesn't match. Try again. |
| otpResendIn | تقدر تطلب كود جديد بعد {seconds} ثانية | You can ask for a new code in {seconds}s |
| otpResend | ابعت كود جديد | Send a new code |
| otpDevHint | كود التجربة: 123456 | Test code: 123456 |
| changeNumber | غيّر الرقم | Change number |
| networkError | مقدرناش نبعت الكود دلوقتي. اتأكد من النت وجرّب تاني. | We couldn't send the code right now. Check your connection and try again. |
| retry | جرّب تاني | Try again |
| profileTitle | نتعرّف عليك | Let's get to know you |
| profileSub | عشان مجموعتك تعرف هتركب مع مين. | So your group knows who they're riding with. |
| firstName | الاسم الأول | First name |
| lastName | اسم العيلة | Last name |
| genderLabel | النوع | Gender |
| male / female | راجل / ست | Male / Female |
| genderNote | بنستخدمه بس لاختيار «ستات بس»، ومحدش بيشوفه. | Used only for the women-only option. No one else sees it. |
| settingsTitle | الإعدادات | Settings |
| languageLabel | اللغة | Language |
| roleLabel | بتتحرك إزاي | How you travel |
| comingSoonTitle | الشاشة دي جاية قريب | This screen is coming soon |
| comingSoonBody | بنجهّزها دلوقتي. اختيارك اتحفظ. | We're building it now. Your choice is saved. |
| homeGreeting | أهلًا {name} | Hi {name} |

Prototype copy reused verbatim: `back`, `continue`, `langBtn`, `langAria`, `tagline1/2`,
`splashSub`, `canDriveSub`, `needRideSub`, `switchAnytime`, `freqSub`, `fRegRider`, `fOnceRider`,
`fRegDriver`, `fOnceDriver`, `toDriver`, `toRider`, `ooTitle` (Empty seats today), `offTitle2`
(Offer a trip).
