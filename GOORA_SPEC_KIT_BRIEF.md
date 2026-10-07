# Goora: Spec Kit Kickoff Brief for Claude Code

> **Goora: Go together. Every day.** · **مشوارك.. سوا.**
> A daily-commute coordination app for Egypt. It matches people who live near each other, work in the same place and travel at similar times, then runs their recurring commute as a trusted group.

This file is the single source of truth for starting the Flutter app with **GitHub Spec Kit** in **Claude Code**. Keep it at the repo root and follow the steps in order. Every product decision below has already been made. Do not re-open a decision unless a spec step finds a real contradiction.

---

## 0. Setup (run in a terminal)

```bash
# Prereqs: Python 3.11+, uv, Flutter (stable), Claude Code
uv tool install specify-cli
specify init goora --integration claude
cd goora
cp /path/to/GOORA_SPEC_KIT_BRIEF.md .
claude
```

Spec Kit installs its skills into `.claude/skills`. Inside Claude Code, run each `/speckit-*` command below **one at a time**, and review the generated file before moving to the next one.

**Workflow:** the constitution runs once. Then, for each feature: `specify → (clarify) → plan → tasks → (analyze) → implement → converge`. Repeat `implement → converge` until the result is **Converged**.

> The core commands are `/speckit-constitution`, `/speckit-specify`, `/speckit-plan`, `/speckit-tasks`, `/speckit-implement` and `/speckit-converge`. The quality gates (clarify, checklist, analyze) are optional. If a command name differs in your installed version, run `specify --help` or check `.claude/skills`.

---

## 1. Constitution: run once

```text
/speckit-constitution Read GOORA_SPEC_KIT_BRIEF.md fully first. Create the Goora constitution with these non-negotiable principles:

1. Commute-first. Every feature must make the daily commute easier, more reliable, cheaper, safer or more predictable. If it does not, it is out of scope.
2. Cost-sharing, never a taxi. Drivers recover fuel and toll costs. They never profit. Prices are system-calculated within a capped range, with no bidding or negotiation and a maximum of 2 offered trips per driver per day. This is a legal boundary (Egypt Law 87/2018), not a style preference.
3. Arabic-first, RTL-correct. Egyptian Arabic is the default locale and English is secondary. Every screen must render correctly in RTL and LTR. No hard-coded strings: all copy goes through ARB localization. Use directional widgets (EdgeInsetsDirectional, AlignmentDirectional, start/end), never left/right.
4. Privacy by design. Never expose home addresses, only pickup points. A rider's name and photo are hidden from drivers until a request is accepted or the rider boards. Companies never see individual employee data without explicit consent.
5. Trust and safety are features. Phone OTP plus ID verification are required. Drivers also need a verified license and vehicle. SOS and trip sharing are always one tap away during a trip.
6. One design system. All UI uses the Goora tokens in this brief (AppColors, AppTypography, AppRadii, AppSpacing) and shared components. No ad-hoc colors, font sizes or radii in feature code.
7. Accessible by default. Touch targets are at least 44 px. Text contrast is at least 4.5:1. Every icon-only button has a semantic label. Information is never conveyed by color alone.
8. Testable architecture. Use feature-first folders, Riverpod for state, a repository pattern behind interfaces, and pure-Dart domain logic (matching, pricing, attendance rules) with unit tests. Each feature ships with widget tests for its main screens in both locales.
9. Simplicity over cleverness. Build the smallest thing that proves the network. Defer anything not in the current feature spec.
```

---

## 2. Feature roadmap

Build these features in order. Each one is a separate `/speckit-specify` run.

| # | Feature | Proves |
|---|---|---|
| 001 | Foundation, design system and onboarding | The app looks like Goora and works in both languages |
| 002 | Commute profile and smart matching | We can find compatible people |
| 003 | Commute groups and the daily commute | Groups actually ride together every day |
| 004 | Wallet and subscription | People pay |
| 005 | Seat marketplace: empty seats, post a trip, offer a trip | One-off demand feeds the daily groups |
| 006 | Company network (B2B), later | Companies pay |

Section 5 has the specify prompt for each feature, and Section 4 has the plan prompt.

---

## 3. Design system: exact tokens

These values come from the approved prototype. Use them **exactly**.

### 3.1 Colors

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const forest      = Color(0xFF0B3B2E); // splash background, deepest brand
  static const primary     = Color(0xFF0E3B2F); // primary buttons, hero cards, avatar "me"
  static const green       = Color(0xFF1FA463); // selected state, progress, check icons, active pills
  static const mint        = Color(0xFF2BC275); // accent on dark, logo, CTA on dark backgrounds
  static const greenText   = Color(0xFF0E6B45); // green text/links on light, "covered", positive amounts
  static const mintSurface = Color(0xFFE7F5EC); // success/info chips, icon tiles, highlight rows

  // Neutrals (light UI)
  static const background    = Color(0xFFF5F4EF); // app background (warm off-white)
  static const surface       = Color(0xFFFFFFFF); // cards
  static const border        = Color(0xFFE6E8E2); // card border
  static const borderStrong  = Color(0xFFD7DCD6); // ghost buttons, unselected pills
  static const divider       = Color(0xFFEEF0EB); // rows inside cards
  static const textPrimary   = Color(0xFF10231C);
  static const textBody      = Color(0xFF33433C);
  static const textSecondary = Color(0xFF56645E);
  static const textMuted     = Color(0xFF8A968F); // inactive tab labels, zero amounts
  static const disabled      = Color(0xFFB8C2BC); // unselected radio ring, disabled steppers, dashed borders

  // On dark (forest/primary backgrounds)
  static const onDarkSecondary = Color(0xFFA9C9B9);
  static const onDarkBody      = Color(0xFFD9EFE3);
  static const onDarkBorder    = Color(0xFF3E6B5B);
  static const onDarkDivider   = Color(0xFF23574A);

  // Status
  static const warningBg     = Color(0xFFFFF4E5);
  static const warningBorder = Color(0xFFF5C98A);
  static const warningTitle  = Color(0xFF8A4B00);
  static const warningBody   = Color(0xFF5B3A10);
  static const infoBg        = Color(0xFFEEF2F7);
  static const infoBorder    = Color(0xFFC9D4E3);
  static const infoTitle     = Color(0xFF23364F);
  static const infoBody      = Color(0xFF3A4A60);
  static const danger        = Color(0xFFC93A3A); // SOS button fill
  static const dangerText    = Color(0xFFA33030); // "can't drive", "no-show", cancel
  static const dangerBorder  = Color(0xFFE3B4B4);

  // Map
  static const mapLand        = Color(0xFFEAF0E8);
  static const mapDestination = Color(0xFFD64545);

  // Avatar fallbacks (initials on these, white text)
  static const avatarPalette = [
    Color(0xFFC9A27A), Color(0xFF5B7C99), Color(0xFFB5677D), Color(0xFF7A8F55),
  ];
}
```

### 3.2 Typography

- **Arabic locale:** **Cairo** (weights 400 to 800).
- **English locale:** **Plus Jakarta Sans** (weights 400 to 800).
- **The "Goora" wordmark** is always Plus Jakarta Sans, weight 800, with letter spacing −2, in both locales.
- **Numbers** use Western digits (7:25, 40) in both locales.
- **Bundle the font files** in `assets/fonts/` so they work offline. Do not fetch them at runtime.

| Token | Size | Weight | Use |
|---|---|---|---|
| `wordmark` | 56 | 800 (ls −2) | Splash logo |
| `display` | 38 | 800 | Wallet balance, big money |
| `h1` | 28 | 800 | Screen titles ("Where do you go every day?") |
| `h2` | 24 | 800 | Tab titles ("Your commute schedule") |
| `title` | 22 | 800 | Greeting ("Good morning, Omar") |
| `heroTime` | 26 | 800 | Confirmed ride time |
| `section` | 16 | 700 | Section labels inside forms/cards |
| `bodyStrong` | 15 | 700 | List item titles, names |
| `body` | 15 | 400/600 | Body |
| `bodySmall` | 14 | 400 | Secondary lines |
| `caption` | 12.5 | 400/600 | Notes, rules, meta |
| `micro` | 12 | 600/700 | Tab labels, chip text, stat labels |

Line height is 1.5 for body and caption text, and 1.2 for headings.

### 3.3 Shape and spacing

```dart
abstract final class AppRadii {
  static const pill = 12.0;      // selectable pills, small buttons, icon tiles (44px)
  static const button = 16.0;    // primary & ghost buttons, alert banners (18)
  static const card = 20.0;      // standard cards, role cards
  static const hero = 22.0;      // dark hero cards (confirmed ride, wallet balance)
  static const chip = 999.0;     // status chips ("92% match", "Verified member")
  static const tile = 18.0;      // large icon tile (64px) on role cards
}
abstract final class AppSpacing {
  static const pageH = 24.0;     // onboarding/flow screens horizontal padding
  static const tabH = 20.0;      // in-app tab screens horizontal padding
  static const gap = 14.0;       // default vertical gap between blocks
  static const cardPad = 16.0;   // card inner padding (18 for list cards)
  static const heroPad = 20.0;
}
```

### 3.4 Components (build these once in `lib/core/widgets/`)

| Component | Spec |
|---|---|
| `GooraPrimaryButton` | Full width, height 54, radius 16, `primary` fill, white 16/700 text, optional trailing arrow icon (mirrored in RTL). On dark screens, use a `mint` fill with `forest` text. |
| `GooraGhostButton` | Full width, height 48, radius 16, white fill, 1 px `borderStrong` border, `primary` 15/600 text. The danger variant uses `dangerText` text. |
| `GooraDashedButton` | Height 48, radius 14, 1 px dashed `disabled` border, `textSecondary` 13.5/600. Used only for demo or secondary actions. |
| `GooraCard` | White, radius 20, 1 px `border`. Rows inside are separated by 1 px `divider`. |
| `GooraHeroCard` | `primary` fill, radius 22, padding 20. Text is white, with `onDarkSecondary` labels and `onDarkBody` sublines. |
| `GooraPill` | Min 44×44, radius 12, horizontal padding 12. Selected state: `green` fill, white 14/700 text. Unselected state: white fill, `borderStrong` border, `textSecondary` 14/600 text. Used for days, seats, direction, plans and privacy. |
| `GooraChip` | Radius 999, padding 6×12, `mintSurface` background, `greenText` 13/700 text. |
| `GooraRadioCard` | Radius 20, 2 px border (`green` when selected, `border` when not), with the radio on the end side. Selected radio: 22 px circle with a 7 px `green` ring. Unselected: a 2 px `disabled` ring. |
| `GooraAvatar` | A circle showing the photo or initials on a palette color, with white bold text. Sizes 40, 44, 48 and 52. Group stacks overlap by −12 using margin-start, with a 3 px white ring. |
| `GooraBanner` | Warning or info variants using the status colors, radius 18, padding 14×16, with a bold title, a body line and an optional text action. |
| `GooraStepper` | − / value / +, with 48 px circular buttons. Enabled: `primary` fill. Disabled: `background` fill with a `border` outline and `disabled` icon. |
| `GooraProgressDots` | Onboarding progress. Bars are 5 px tall, 14 px wide and 28 px wide when active, `green` when active and `borderStrong` when not, with a gap of 6. |
| `GooraBottomNav` | 4 tabs on a white background with a 1 px `border` top line. Icon is 22 px, label is 12/700. Active: `greenText`. Inactive: `textMuted`. Bottom padding is 22. |
| `GooraTimelineRow` | A 14 px dot (`green` for pickup, `disabled` for the transit leg, `mapDestination` for arrival) with a title and subline. |
| `GooraLogo` | An arc ring (stroke 7, `mint`, ~70% of the circle, round caps) with a 5 px `mint` center dot, next to the wordmark. Paint it with a `CustomPainter`. |

**Icons:** use outline stroke icons with a 2 px stroke and round caps (`lucide_icons` or a similar package). Do not use emoji or filled Material icons. Directional icons (back, forward, arrows) must mirror in RTL.

### 3.5 Theme wiring

- Build a `ThemeData` with `useMaterial3: true` and a `ColorScheme.light(primary: AppColors.primary, secondary: AppColors.green, surface: AppColors.surface, error: AppColors.danger)`.
- Set `scaffoldBackgroundColor: AppColors.background`.
- Choose the text theme by locale: `ar` uses Cairo and `en` uses Plus Jakarta Sans.
- The app is light mode only for the MVP.

---

## 4. Plan prompt (tech stack): use it with `/speckit-plan` for every feature

```text
/speckit-plan Follow GOORA_SPEC_KIT_BRIEF.md sections 3 and 6. Stack:

- Flutter (latest stable), Dart 3, Android + iOS. Min Android 7 (API 24), iOS 14.
- State: flutter_riverpod (with riverpod_generator). Routing: go_router.
- Localization: flutter_localizations + intl with ARB files (app_ar.arb default, app_en.arb). Locale switch in-app, persisted. RTL via Directionality from locale.
- Fonts bundled as assets: Cairo, Plus Jakarta Sans. Theme from section 3 (AppColors, AppTypography, AppRadii, AppSpacing) in lib/core/theme.
- Backend: Supabase. Postgres + PostGIS for locations and route distance, Supabase Auth with phone OTP, Row Level Security on every table, Edge Functions (TypeScript) for matching, pricing and scheduled jobs (nightly 9 PM cancellation cutoff, weekly payouts).
- Maps: google_maps_flutter for display, Google Directions/Distance Matrix via Edge Function only (never from the client, protects the API key).
- Notifications: Firebase Cloud Messaging.
- Payments: a PaymentProvider interface with a FakePaymentProvider for now; real provider (Paymob, InstaPay, Vodafone Cash, cards) in a later feature. Never store card data.
- Architecture: feature-first folders (lib/features/<feature>/{data,domain,presentation}), repositories behind abstract interfaces, pure-Dart domain services (MatchingService, PricingService, AttendanceRules) with unit tests.
- Testing: unit tests for domain rules, widget tests for each screen in ar + en, golden tests for core widgets in RTL + LTR.
- Lints: very_good_analysis or flutter_lints strict.
Keep the plan scoped to the current feature only.
```

---

## 5. Specify prompts: one per feature

### Feature 001: Foundation, design system and onboarding

```text
/speckit-specify Read GOORA_SPEC_KIT_BRIEF.md (sections 3, 6, 7). Build the Goora app foundation and onboarding:

1. Design system: all tokens and every shared component from section 3.4, plus a hidden debug "Design gallery" screen showing every component in AR and EN.
2. Localization: Arabic (default, RTL) and English (LTR); a globe-icon language pill in the top end corner of onboarding screens and in Settings. Seed ARB files with section 7 strings.
3. Splash/Welcome: forest background, Goora logo + wordmark, Arabic tagline "مشوارك.. سوا." as the big line in AR (English tagline secondary) and vice versa in EN, a short description, primary CTA "Get started" (mint fill) and outline "Log in". Nothing else, so the welcome screen stays simple.
4. Phone sign-up: Egyptian mobile (+20) with OTP, then first name + last name + gender (used only for women-only preference).
5. Role choice: two radio cards, "I can drive" (car icon) / "I need a ride" (person icon), with the note "You can switch anytime." Users can switch roles later from Settings.
6. Frequency choice, right after the role: "Every day or just once?" (subline "You can always do the other one later."). There are two radio cards. "Every day" (calendar icon) carries a "Best value" chip and is selected by default. "Just one trip" (route icon). The sublines change by role:
   - Rider, every day: "A fixed group for your daily commute. First month free."
   - Rider, once: "Book an empty seat or post your trip. No subscription."
   - Driver, every day: "Share your daily commute with a fixed group. Always free."
   - Driver, once: "Offer your empty seats on a trip you're already making."
   Routing: every day → commute setup (feature 002). Rider + once → Empty seats today (feature 005-A). Driver + once → Offer a trip (feature 005-C). Until feature 005 exists, the once paths show a placeholder.
7. Onboarding progress dots across role → frequency → commute setup.
Acceptance: every screen passes the RTL/LTR widget tests; no hard-coded strings or colors in feature code; touch targets at least 44 px.
```

### Feature 002: Commute profile and smart matching

```text
/speckit-specify Read GOORA_SPEC_KIT_BRIEF.md sections 6.1–6.3. Build the commute profile and matching:

Commute setup screen ("Where do you go every day?"): Home and Work (place search + map pin; store exact coordinates privately, show only area names), departure time, return time, working days (7 day pills, default Sun–Thu). If driver: empty seats (1–4), which trips they drive (Both ways / Going only / Return only), and contribution per rider using the stepper (range and rules in 6.2). Show "You recover per day = seats × price × trips".

Matching (server-side Edge Function, pure logic mirrored in Dart for tests): hard constraints and scoring in 6.3. Going and return are matched independently.

Match result screen: "92% match" chip, "We found your commute group!", stacked avatars, member count, route, time + days, 4 stats (drivers, riders, fixed/wk, EGP/trip), the line "40 EGP to the driver · no per-trip fees", a "Why this group" card listing reasons with check icons, a "See other options" toggle listing alternative matches with %, and the primary CTA "Join this group".

No-match state: "You're #7 on the Sheikh Zayed → Smart Village list — we'll notify you as soon as we have a match", plus a CTA to post a trip request (feature 005).
```

### Feature 003: Commute groups and the daily commute

```text
/speckit-specify Read GOORA_SPEC_KIT_BRIEF.md sections 6.4–6.6. Build groups and the daily commute (the app's 4-tab shell: Today, Week, Wallet, Trust):

Today, rider: greeting, a dark hero card "Your ride is confirmed · 7:25 AM · route", a legs card (Going: driver, Return: driver, each "Covered"), a map card with the route and "Pickup in 12 min", a driver card (avatar, name, verified badge, car, rating, call button), a timeline (pickup → on the way → arrival), Return time + "You pay per trip" tiles, Share trip + SOS buttons, and "I can't come tomorrow" (with the rule caption).
Today, driver: "Offer a trip" entry (feature 005), a dark hero card "Tomorrow · direction · N passengers" with pickup stops and times and the estimated contribution, Confirm / Undo, Report delay, Can't drive, "Requests on your route" (feature 005), and pickup check-in: "I've arrived at Main Gate", then per passenger "Picked up" / "No-show".
Week: the schedule per working day showing who drives going and return, with backup substitutions labelled.
Attendance, cancellation and backup rules exactly as 6.5 and 6.6, including warning and info banners ("Ahmed can't drive on Tuesday — Mohamed will drive instead…", "You're off tomorrow — no charge").
Trust tab: profile, verification checklist (phone, national ID, work email, + license and vehicle for drivers), reliability % with bar and rule caption, "Switch to driver/rider mode", privacy preference pills (Verified users / Same company / Same compound / Women only).
Live trip: real-time driver location during an active trip, share-trip link, SOS (calls 122 and notifies trusted contacts).
```

### Feature 004: Wallet and subscription

```text
/speckit-specify Read GOORA_SPEC_KIT_BRIEF.md section 6.7. Build the payment model and wallet:

Payment-method screen (shown to riders after "Join this group"; drivers skip it): "Pay cash to the driver (first 10 trips)" or "Use wallet", plus a small "Subscribe and pay no fees" link. There is no mandatory plan step.
Subscription screen (from that link and from the Wallet): Monthly 129 EGP / Yearly 1,290 EGP with "2 months free" chip / Through my company (verify work email), "What's included" list, note that the fuel contribution goes to the driver in full, footer "Cancel anytime. Goora is free for drivers." Subscribers pay no per-trip fee.
Prices everywhere a trip is priced (match result, Today, booking): "40 EGP to the driver + 4 EGP service fee" for non-subscribers, "40 EGP · no fees (subscribed)" for subscribers, "Pay 40 EGP cash to the driver" during the cash trial.
Wallet, rider: plan card (Pay per trip / Subscribed / Company, Change), dark balance card with "Covers about N trips" and Top up (method pills InstaPay / Vodafone Cash / Card, amounts 200/400/800), the cash-trial counter "N cash trips left" while it is active (top-up banner from cash trip 8), the fee-savings banner when this month's fees exceed 129 EGP, "How paying works" rules list, activity list (each trip shows its service fee separately, late-cancel half charge, zero rows for free cancellations, cash trips, top-ups), and "What you pay per trip" breakdown (driver's share / service fee / total).
Wallet, driver: "Recovered this week" balance, "Paid out every Thursday · no fees taken from you", Withdraw to InstaPay, cash received shown separately (recorded only, not withdrawable), activity (trip income, late-cancel and no-show fees), "Your trip cost" breakdown (trip cost / you receive from riders / what you pay yourself / Goora is free for drivers).
Driver Today: after drop-off, for each cash rider, "Received 40 EGP cash" / "Didn't pay".
Domain (pure Dart, unit tests with these exact numbers): PricingService.riderTotal(contribution, isSubscriber, isCashTrial), CashTrialPolicy (10-trip limit, 2 "didn't pay" strikes, banner from trip 8), FeeSavingsCalculator (monthly fees vs 129).
Money is held by a licensed payment partner; the app keeps a ledger only. Use FakePaymentProvider in this feature.
```

### Feature 005: Seat marketplace

```text
/speckit-specify Read GOORA_SPEC_KIT_BRIEF.md section 6.8. Build the four one-off/demand flows that feed daily groups.

Entry points:
- From onboarding, when the user picks "Just one trip" on the frequency screen (feature 001): a rider goes to A, a driver goes to C. Back returns to the frequency screen.
- From inside the app, at any time: a rider who already belongs to a group sees "Need an extra trip? Book a seat" on Today, which opens A. A driver sees "Offer a trip" on Today, which opens C. Back returns to the app.

A) Empty seats today (riders, no subscription needed): Going/Return toggle, route line, list of seats from existing groups (driver avatar, rating, pickup point, time, seats left, price, Book seat), the rule caption about subscriber priority and refunds, and a dashed card "Nothing fits your time? Post your trip".
   - Non-subscribers see "44 EGP · 40 to the driver + 4 service fee" (the same 10% per-trip service fee as section 6.7). The booked confirmation shows a summary plus an upsell card "Liked it? Make it your daily commute", which leads to commute setup with "every day" preselected.
   - Subscribers see "40 EGP · no fees (subscribed)". The booked confirmation shows the summary and "Back to today" with no upsell.
B) Post your trip (rider): From / To / Time, "Just once" or "Every workday", the three rules shown with check icons, Post. Then a posted state ("Sent to N drivers on your route", progress, Cancel) and an accepted state (driver card, pickup, time, contribution; if daily: "You're now a commute group" → payment method).
C) Offer a trip (driver): verification chips, From / To / Time, seats, once/daily, contribution stepper, the three rules, Publish. Then a live state with a seat progress bar, anonymous booked riders list, "Your car is full!" when full, and a daily trip with riders that becomes a group.
D) Find riders (driver browses requests without posting a trip first). Entry points: "Find riders" next to "Offer a trip" on driver Today, and a text link "Or find riders who already posted" on the Offer screen. The screen shows a "Leaving from" area filter (All / Sheikh Zayed / 6th of October / Smart Village…), a Morning/Evening toggle, a "Trips left today" counter (starts at 2), and anonymous request cards (route, verified rider / verified rider (woman), pickup, time, once/daily, rating or New, fixed price).
   - Accept opens an inline confirm: "This creates your trip: <route> · <time>. Trips left after this: N". Confirming creates the driver's trip, the same as Offer a trip.
   - A request on the same route within ±30 min of an existing trip in that direction joins that trip ("This joins your trip at 7:30 AM") and does not use another trip.
   - A request that doesn't fit an existing trip in that direction shows "Doesn't fit your trip" and can't be accepted. Once 2 trips exist, every remaining request shows "Daily limit reached".
   - The price is fixed and there is no bidding.

Driver Today shows "Requests on your route": a demand banner ("12 people want <route> in the morning") and anonymous request cards (verified rider / verified rider (woman), pickup, time, once/daily, rating or New, detour minutes, fixed price, Accept → "Accepted ✓").
```

### Feature 006: Company network (later, do not start yet)

Companies sign up, employees join with their work email, the company pays 75 EGP per registered employee per month, and employees pay no subscription. The company gets an aggregated dashboard showing active groups, carpool rate, estimated savings, CO₂ reduced, parking demand and route gaps. It never shows individual data without consent.

---

## 6. Business rules (decided)

### 6.1 Positioning
- Goora solves **"How do I reliably get to work every day?"**, not "find me a ride once".
- **Launch on one dense corridor**: Sheikh Zayed → Smart Village. Density matters more than user count.
- **The brand must not look like a taxi company.** It should read as modern, friendly, trustworthy and premium but accessible.

### 6.2 Pricing (cost-sharing)
- **Suggested contribution per rider per trip** = (fuel + tolls + reasonable running cost for the route) ÷ (riders + 1). Demo value: trip cost 180 EGP, 3 riders, so the suggested contribution is 40 EGP.
- **The driver can adjust within ±20% of the suggestion** (demo range 32 to 48), in 2 EGP steps. The stepper label shows "Suggested price" or "N EGP above/below suggested".
- **Hard cap:** riders' total payments can never exceed the full trip cost. The driver never profits.
- **The price is fixed per group for the month.** Riders see it before joining. If a backup driver covers a day, the group price applies.
- **Each trip is priced separately**, so going only = 1 × price and both ways = 2 × price.
- **The driver keeps 100% of rider contributions.** Goora takes nothing from drivers.
- **The driver sees their full cost breakdown.** Riders see only what they pay.

### 6.3 Matching
- **Hard constraints:**
  - Pickup distance at most 1 km from home (configurable).
  - Driver detour at most 10 min.
  - Departure difference at most 20 min.
  - Destination within 1.5 km.
  - Seat capacity.
  - At least one shared working day.
  - Privacy preference compatibility (women-only, same company, same compound).
- **Score (0 to 100)**, suggested weights:
  - Destination match 25
  - Departure-time closeness 20
  - Pickup distance 15
  - Return-time closeness 10
  - Shared days 10
  - Same company or community 10
  - Rating and reliability 10
- **"Why this group" reasons** are generated from the top factors, for example "Same destination: Smart Village", "5-minute departure difference", "Pickup 600 m from home" and "Same company · similar return time".
- **Pickup points:** cluster riders to shared pickup points (gate, main street) instead of door-to-door.
- **Going and return are matched independently**, so a rider can go with Ahmed and return with Sara.

### 6.4 Groups and schedule
- **A group** is one route, one time window and recurring days, with drivers and riders in it.
- **Drivers choose Both ways, Going only or Return only.** Each driver drives their own car only.
- **The weekly schedule rotates fairly** between the group's drivers, and the Week tab shows who drives each day.

### 6.5 Cancellation, no-show and reliability
- **Cancel before 9 PM the day before:** free. The seat is offered to the waitlist or to one-off riders.
- **Cancel after 9 PM:** the rider pays half their share, with no Goora fee.
- **No-show:** the driver taps "I've arrived" and riders are notified. The driver waits 5 min, then marks "No-show". The rider pays the full share.
- **Planned absence:** "Not coming next week" is set with one tap.
- **Reliability %** is shown on the profile. Two no-shows in a month triggers a warning, and three removes the person from the group (their seat goes to the waitlist). The same rules apply to drivers.

### 6.6 Backup
When a driver can't drive, Goora searches in this order:
1. Other drivers in the same group
2. Nearby groups
3. Same-company drivers
4. Same-community drivers
5. (Later) partner transport

Riders get a banner telling them who covers the day. If nobody can cover, riders are notified the evening before with options.

### 6.7 Monetization
- **A) Per-trip service fee (default for riders):** the rider pays the driver's contribution + a 10% Goora service fee on each trip, rounded to the nearest whole EGP (40 EGP trip → rider pays 44: 40 to the driver, 4 to Goora). The fee is deducted per completed trip, never at top-up (topping up 200 EGP gives a 200 EGP balance). Late-cancel (half share) and no-show (full share) charges go to the driver only, with no Goora fee.
- **Drivers:** never pay any fee or subscription. They always receive 100% of their contribution.
- **B) Optional subscription (frequent riders):** 129 EGP/month or 1,290 EGP/year. Subscribers pay no per-trip fee: trips and one-off seats cost exactly the driver's contribution. There is no mandatory plan step after "Join this group"; riders go to the payment-method screen instead (C). When a rider's fees this month exceed the subscription price, the Wallet shows "You paid X EGP in fees this month. With a subscription you'd pay 129." with a "Subscribe" button.
- **C) Cash trial (new riders, first 10 trips):** a new rider can pay the driver in cash for their first 10 completed trips (trips, not days), with no Goora fee. After each cash trip the driver confirms "Received 40 EGP cash" or taps "Didn't pay"; both are recorded. Two "Didn't pay" marks turn cash off for that rider immediately, and they must top up. Late-cancel and no-show charges are not collected during cash trips; they affect the reliability score only. The rider sees "N cash trips left", and from cash trip 8 a banner: "Top up your wallet to keep riding — get backup drivers, guaranteed seats and refunds." After 10 cash trips, booking requires a wallet balance (or a company plan). Payment-method screen after joining a group: "Pay cash to the driver (first 10 trips)" or "Use wallet", plus a small "Subscribe and pay no fees" link.
- **D) Company plan (feature 006):** unchanged. 75 EGP per registered employee per month; employees pay no fees.
- **Wallet:** prepaid top-ups through a licensed partner, and the app keeps a ledger. Payouts to drivers run weekly (Thursday) to InstaPay. Cash a driver receives is recorded only and is not withdrawable.
- **Constitution II reading:** the hard cap ("riders' total payments never exceed the full trip cost") applies to what drivers receive. The Goora service fee is not part of trip cost and never reaches the driver, the same reading the earlier 5 EGP booking fee used. To be confirmed by the legal opinion in §8.

### 6.8 Marketplace limits (so it never becomes a taxi)
- **Max 2 offered trips per driver per day**, going and return. A trip is created either by "Offer a trip" or by accepting a request in "Find riders". Riders on the same route within ±30 min of each other count as one trip.
- **Drivers may browse requests freely without posting a trip.** Accepting is what creates the trip, so the daily limit still applies.
- **Requests and offers are shown only to people whose registered route fits**, with a detour under 10 min.
- **No bidding.** Prices are always system-set.
- **Drivers can't pick riders by name or photo.** Riders appear as "Verified rider" or "Verified rider (woman)" with a rating until they board. Filters exist only as settings: women-only, same company.
- **Subscribers get priority on empty seats.** A one-off booking is fully refunded if the seat is reclaimed before 9 PM.
- **One-off trips are available to everyone at any time.** New users reach them from onboarding ("Just one trip"). Group members reach them from the Today tab, and subscribers pay no service fee.
- **A daily request or offer that gets riders automatically becomes a group.**

---

## 7. Key copy (seed the ARB files)

| key | ar (default) | en |
|---|---|---|
| tagline | مشوارك.. سوا. | Go together. Every day. |
| getStarted | يلا نبدأ | Get started |
| login | تسجيل الدخول | Log in |
| howTravel | بتتحرك إزاي؟ | How do you travel? |
| canDrive / needRide | معايا عربية / محتاج توصيلة | I can drive / I need a ride |
| freqTitle | كل يوم ولا مشوار واحد؟ | Every day or just once? |
| fRegular / fOnce | كل يوم / مشوار واحد بس | Every day / Just one trip |
| fTag | الأوفر | Best value |
| extraTrip | عايز مشوار زيادة؟ احجز كرسي | Need an extra trip? Book a seat |
| subNote | ضمن اشتراكك · من غير رسوم | Included in your plan · no fees |
| whereGo | بتروح فين كل يوم؟ | Where do you go every day? |
| dirBoth / dirGoing / dirRet | رايح جاي / رايح بس / راجع بس | Both ways / Going only / Return only |
| findCommute | دوّرلي على مشواري | Find my commute |
| foundGroup | لقينالك مجموعة مشوارك! | We found your commute group! |
| join | انضم للمجموعة | Join this group |
| confirmed | توصيلتك متأكدة | Your ride is confirmed |
| covered | متغطّي | Covered |
| cantCome | مش هقدر آجي بكرة | I can't come tomorrow |
| arrivedBtn | وصلت البوابة الرئيسية | I've arrived at Main Gate |
| pickedUp / noShow | ركب / مجاش | Picked up / No-show |
| planTitle | اشترك ومن غير رسوم | Subscribe and pay no fees |
| postReq | انشر مشوارك | Post your trip |
| offerBtn | اعرض مشوار | Offer a trip |
| reqsOnRoute | طلبات على خطك | Requests on your route |
| browseBtn | دوّر على ركاب | Find riders |
| browseTitle | طلبات قريبة منك | Requests near you |
| tripsLeftA | المشاوير الباقية النهارده | Trips left today |
| tabs | النهارده · الأسبوع · المحفظة · الأمان | Today · Week · Wallet · Trust |
| sos | استغاثة | SOS |
| priceWithFee | {price} ج للسواق + {fee} ج رسوم خدمة | {price} EGP to the driver + {fee} EGP service fee |
| priceSubscribed | {price} ج · من غير رسوم (مشترك) | {price} EGP · no fees (subscribed) |
| priceCash | ادفع {price} ج كاش للسواق | Pay {price} EGP cash to the driver |
| payMethodTitle | هتدفع إزاي؟ | How do you want to pay? |
| payCash | ادفع كاش للسواق (أول 10 مشاوير) | Pay cash to the driver (first 10 trips) |
| payWallet | ادفع من المحفظة | Use wallet |
| subscribeLink | اشترك ومن غير رسوم | Subscribe and pay no fees |
| cashTripsLeft | فاضل {count} مشاوير كاش | {count} cash trips left |
| cashTopUpBanner | اشحن محفظتك عشان تكمّل مشاويرك — سواق بديل وكرسي مضمون وفلوسك ترجعلك. | Top up your wallet to keep riding — get backup drivers, guaranteed seats and refunds. |
| feeSavings | دفعت {fees} ج رسوم الشهر ده. بالاشتراك هتدفع 129 بس. | You paid {fees} EGP in fees this month. With a subscription you'd pay 129. |
| subscribe | اشترك | Subscribe |
| planPayPerTrip | بالمشوار | Pay per trip |
| cashReceived | استلمت {price} ج كاش | Received {price} EGP cash |
| didNotPay | مدفعش | Didn't pay |

**Tone:** warm, short, Egyptian Arabic ("يلا"، "متغطّي"، "مجاش"), never formal MSA. In English, keep it plain and friendly.

---

## 8. Open items (not for Claude Code to decide)

- **Legal opinion:** does a cost-sharing coordination platform with a subscription and a 10% per-trip service fee fall under Law 87/2018? Confirm that the fee sits outside the Constitution II cap (§6.7).
- **Insurance product** for passengers.
- **Payment partner** selection (Paymob or Fawry) and wallet licensing.
- **Final pricing**, to be tested at 99, 129 and 149 with the first 50 riders.

Until these are resolved, keep the related code behind interfaces and feature flags.
