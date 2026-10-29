# Implementation Plan: Company Network (B2B company plan)

**Branch**: `010-company-network` (implementation, off `main` after 006 merged; merged into `main` 2026-10-29,
`30b8181`; spec written on `spec/company-network`) | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-company-network/spec.md`

## Summary

Turn today's "verified work email = company plan forever" into a real company network: a company
registers in-app and is approved by Goora staff; employees on its domain enroll with explicit
consent; coverage (fee 0) holds only while the employee is enrolled and the company is active; one
invoice per company per month (max(minimum, peak enrolled) × price) is issued lazily and marked paid
by staff; an overdue invoice suspends coverage without ever blocking riding; HR sees a roster,
invoices, a log and a k = 5 suppressed dashboard; an opt-in HR statement (US6) is last and
droppable. Technical core: pure `CompanyRules` twin (Dart + TS + vectors) and coverage windows
attached to the existing company `Plan`, so the six existing plan call sites keep working
(research R2).

## Technical Context

**Language/Version**: Dart 3 (Flutter stable) · TypeScript on Node 24 for the twin
**Primary Dependencies**: flutter_riverpod, go_router, intl/ARB, shared_preferences (fakes) — no new package
**Storage**: SharedPreferences JSON under `company.*` (fakes); Supabase tables described in research R9, not built here
**Testing**: `flutter test --concurrency=1` (unit, widget ar+en, golden), `node --test "supabase/functions/_shared/*.test.ts"`
**Target Platform**: Android (min API 24) + iOS (min 14)
**Project Type**: mobile app (+ shared TS rules for the future server)
**Performance Goals**: none beyond normal screen responsiveness (fakes over seeded data; the spec sets no timing target)
**Constraints**: fakes only; money rules twinned; no individual data to HR without consent; legal items behind flags (R0)
**Scale/Scope**: ~8 new screens/sheets (company home, register, roster, invoices, invoice, dashboard, log, statement) + consent sheet + 2 wallet card changes; 155 new ARB keys (139 at P7, 16 more in P8; was estimated ~70)

## Constitution Check

*GATE: checked before research and again after design (both pass, no violations).*

| Principle | Check | Result |
|---|---|---|
| I Commute-first | Makes the commute cheaper for employees; dashboard shows route gaps | Pass |
| II Cost-sharing (non-negotiable) | Company fee pays only Goora; share, ±20%, cap, 2-trips limit untouched; drivers pay nothing (FR-007; vectors keep the 007/008 invariants) | Pass |
| III Arabic-first, RTL | All copy ARB ar/en; widget tests both locales; directional layout | Pass |
| IV Privacy | Enrollment consent lists exactly what HR sees (name, work email, since); HR read models carry nothing else (R6, privacy test); k = 5 suppression; HR statement opt-in per company | Pass — **the reason US6 is last** |
| V Trust & safety | 009 ID check unchanged; SOS/share untouched | Pass |
| VI One design system | Existing tokens and `Goora*` widgets; new pairings added to `contrast_test.dart` | Pass |
| VII Accessible | ≥ 44 px, statuses in words, "fewer than 5" in words | Pass |
| VIII Testable | Pure `CompanyRules` + `CompanyDashboard` with vectors; repository behind interface; widget tests ar/en | Pass |
| IX Simplicity | In-app HR area instead of a web portal; no new role mode; no new package | Pass |
| Payments / legal | No money moves; invoices are records; real issuing/export behind flags until R0 answers | Pass |
| Roadmap / brief | Brief and constitution still say "006 Company network, 75 EGP" (006 branch makes it "later, unnumbered, price TBD") → amend after 006 merges (FR-030, task T001) with founder approval + Sync Impact Report | Pass with an ordered task |

## Project Structure

### Documentation (this feature)

```text
specs/010-company-network/
├── spec.md · plan.md · research.md · data-model.md · quickstart.md
├── contracts/company-rules.md · contracts/repositories-and-navigation.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/features/company/
├── company_flags.dart
├── domain/   company.dart · enrollment.dart · invoice.dart · company_log.dart · company_terms.dart
│             company_rules.dart (twin) · company_dashboard.dart · company_repository.dart
│             hr_views.dart · hr_statement.dart · employee_month_facts.dart
├── data/     fake_company_repository.dart · company_seed.dart · providers.dart
└── presentation/ company_home_screen.dart · register_company_screen.dart · roster_screen.dart
              invoices_screen.dart · invoice_screen.dart · company_dashboard_screen.dart · company_log_screen.dart
              statement_screen.dart (US6) · hr_consent_toggle.dart (US6) · consent_sheet.dart
              company_offer_view.dart · company_controller.dart
lib/features/wallet/      plan.dart (coverage) · fake_wallet_repository.dart (seam, pause/restore)
                          presentation/plan/company_verify_sheet.dart · wallet/rider_wallet.dart (card)
lib/features/marketplace/data/fake_marketplace_repository.dart   (coversTrip at booking)
lib/features/daily/domain/trust.dart · data/fake_trust_repository.dart  (workEmail)
lib/features/daily/domain/notice.dart  (4 notice kinds)
lib/app/router.dart · settings (entry row + demo actions) · lib/core/l10n/app_{ar,en}.arb
supabase/functions/_shared/company.ts · company.test.ts
test/fixtures/company_vectors.json · test/fixtures/gen_company_vectors.py
test/unit/company_*_test.dart · test/widget/company_*_test.dart
```

**Structure Decision**: one new feature folder `lib/features/company/` (constitution VIII), plus
narrow seams into wallet, marketplace, trust and notices. No server code in this feature beyond the
TS twin; the migration (R9) is a later server feature.

## Phases (risk first — each phase ends with all three gates green)

- **P0 Setup**: brief + constitution amendment after 006 merges (founder OK); flags; ARB skeleton.
- **P1 Coverage spike (riskiest)**: coverage windows on `Plan`, all six call sites green with
  `[enrolledAt, ∞)`, marketplace booking on `coversTrip`.
- **P2 Rules + twin**: `CompanyRules` Dart + TS + vectors (coverage, peak, billing, due/suspend,
  active windows, suppress).
- **P3 Model + fake store + seed + seams**: entities, `FakeCompanyRepository`, `CompanySeed`, wallet
  seam (pause/restore, noTrial), trust workEmail, notices, reset.
- **P4 US1 + US2 (MVP)**: register/pending/approve; offer/consent/enroll; not-on-Goora.
- **P5 US3**: invoices, mark paid, suspension, notices.
- **P6 US4**: roster, remove, leave, domains, contract end, log.
- **P7 US5**: dashboard aggregator + screen.
- **P8 US6 (droppable)**: consent toggle + statement.
- **P9 Polish**: goldens, contrast, a11y at 1.3×, copy list in research R11, quickstart walk.

Model fit per phase: P1–P2 **Opus** (money/coverage edge cases); P3–P8 **Sonnet** per phase; P9
Sonnet. One phase per session.

## Complexity Tracking

No constitution violations to justify.
