# Goora Constitution

Goora ("Go together. Every day." · "مشوارك.. سوا.") is a daily-commute coordination app for
Egypt. It matches people who live near each other, work in the same place and travel at similar
times, then runs their recurring commute as a trusted group. `GOORA_SPEC_KIT_BRIEF.md` at the repo
root is the single source of truth for every product decision, price, rule, color, font, component
and piece of copy.

## Core Principles

### I. Commute-First

Every feature MUST make the daily commute easier, more reliable, cheaper, safer or more
predictable. A feature that does none of these is out of scope and MUST NOT be built.

Rationale: Goora answers "How do I reliably get to work every day?", not "find me a ride once".

### II. Cost-Sharing, Never a Taxi (NON-NEGOTIABLE)

- Drivers recover fuel and toll costs. They MUST NEVER profit: riders' total payments MUST NOT
  exceed the full trip cost.
- Prices MUST be system-calculated within a capped range (±20% of the suggested contribution).
- There MUST be no bidding and no negotiation.
- A driver MUST NOT exceed 2 offered trips per day.

Rationale: this is a legal boundary (Egypt Law 87/2018), not a style preference. Any change that
weakens it requires a constitution amendment and a legal opinion.

### III. Arabic-First, RTL-Correct

- Egyptian Arabic is the default locale; English is secondary.
- Every screen MUST render correctly in both RTL (ar) and LTR (en).
- No hard-coded strings: all user-facing copy MUST go through ARB localization.
- Layout MUST use directional widgets only (`EdgeInsetsDirectional`, `AlignmentDirectional`,
  start/end). `left`/`right` MUST NOT be used. Directional icons MUST mirror in RTL.

Rationale: the launch market is Egyptian; an RTL bug is a broken screen, not a cosmetic issue.

### IV. Privacy by Design

- Home addresses MUST NEVER be exposed; only pickup points are shown.
- A rider's name and photo MUST be hidden from drivers until a request is accepted or the rider
  boards.
- Companies MUST NEVER see individual employee data without explicit consent.

Rationale: users share where they live and when they leave home; that trust is the product.

### V. Trust and Safety Are Features

- Phone OTP plus ID verification are REQUIRED for every user.
- Drivers additionally REQUIRE a verified license and a verified vehicle.
- SOS and trip sharing MUST always be one tap away during a trip.

Rationale: people ride with strangers daily only when safety is built in, not bolted on.

### VI. One Design System

All UI MUST use the Goora tokens defined in the brief (`AppColors`, `AppTypography`, `AppRadii`,
`AppSpacing`) and the shared components in `lib/core/widgets/`. Feature code MUST NOT contain
ad-hoc colors, font sizes or radii; those values live only in `lib/core/theme`.

Rationale: one consistent, premium-but-accessible look that never reads as a taxi company.

### VII. Accessible by Default

- Touch targets MUST be at least 44 px (logical pixels).
- Text contrast MUST be at least 4.5:1.
- Every icon-only button MUST have a semantic label.
- Information MUST NEVER be conveyed by color alone.

Rationale: a daily tool used in a hurry, outdoors and on the move must work for everyone.

### VIII. Testable Architecture

- Feature-first folders: `lib/features/<feature>/{data,domain,presentation}`.
- State with Riverpod; data access through a repository pattern behind abstract interfaces.
- Domain logic (matching, pricing, attendance/cancellation rules, marketplace limits) MUST be
  pure Dart with unit tests that use the exact numbers from the brief.
- Each feature MUST ship with widget tests for its main screens in both locales (ar and en).

Rationale: the business rules are the product's legal and financial core; they must be provable.

### IX. Simplicity Over Cleverness

Build the smallest thing that proves the network. Anything not in the current feature spec MUST
be deferred. New packages MUST NOT be added without a stated reason.

Rationale: density on one corridor (Sheikh Zayed → Smart Village) matters more than features.

## Technology, Secrets and Legal Constraints

- **Stack:** Flutter (latest stable), Dart 3, Android (min API 24) + iOS (min 14);
  flutter_riverpod, go_router, flutter_localizations + intl (ARB: `app_ar.arb` default,
  `app_en.arb`); Cairo and Plus Jakarta Sans bundled as assets, never fetched at runtime;
  light mode only for the MVP.
- **Backend:** Supabase (Postgres + PostGIS, phone-OTP Auth, Row Level Security on every table,
  Edge Functions for matching, pricing and scheduled jobs).
- **Maps:** google_maps_flutter for display only; Directions/Distance Matrix are called from Edge
  Functions only, never from the client.
- **Secrets:** real keys MUST NEVER be committed. Keys live in a git-ignored `.env`, with a
  committed `.env.example`. Until keys are provided, the app MUST run against fake repositories.
- **Payments:** a `PaymentProvider` interface with `FakePaymentProvider` only. No real payment
  integration. Card data MUST NEVER be stored. The app keeps a ledger only.
- **Open legal/commercial items** (Law 87/2018 opinion, passenger insurance, payment partner,
  final pricing): related code MUST stay behind interfaces and feature flags until resolved.

## Development Workflow and Quality Gates

- Features are built in roadmap order (001 → 005; 006 is deferred), each through
  specify → (clarify) → plan → tasks → (analyze) → implement → converge, repeating
  implement → converge until Converged.
- Each feature lives on its own branch `feature/00X-name` and is committed there.
- A feature is done only when ALL of these pass:
  - `flutter analyze` reports zero issues.
  - `flutter test` passes.
  - Every new screen renders in Arabic (RTL) and English (LTR), proven by widget tests for both.
  - No hard-coded strings, colors, font sizes or radii outside `lib/core/theme` and the ARB files.
- When the brief is unclear or contradicts itself, work stops and the founder is asked.
  Nothing is guessed.

## Governance

- This constitution and `GOORA_SPEC_KIT_BRIEF.md` supersede all other practices. Where they
  conflict, work stops and the founder decides.
- Amendments require the founder's approval, an updated Sync Impact Report and a version bump:
  MAJOR for removing or redefining a principle, MINOR for a new principle or materially expanded
  guidance, PATCH for clarifications.
- Every plan MUST pass the Constitution Check before research and again after design. Any
  violation MUST be listed in the plan's Complexity Tracking table with a justification, or
  removed.

**Version**: 1.0.0 | **Ratified**: 2026-10-05 | **Last Amended**: 2026-10-05
