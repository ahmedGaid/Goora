# Specification Quality Checklist: Wallet and Subscription

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-10-08
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

- `FakePaymentProvider` is named because the user's own feature description specified it as a
  constraint on scope ("Use FakePaymentProvider in this feature"), not as an implementation choice
  made by this spec — the same treatment 002/003 gave their own fakes-first backend constraint.
- All three clarification questions were resolved in-session (see spec.md's Clarifications); none
  were left open.

## v2.1 re-validation (2026-10-08 — the service fee sits inside the cap)

- [x] No [NEEDS CLARIFICATION] markers: the rule is the founder's; the details (which rider count,
  round-then-trim order, zero-fee wording, savings banner, booking reach) are recorded in the
  "v2.1" clarification session.
- [x] Testable: FR-003's formula and FR-016's bound are checked against the five-row table and
  every allowed price for 1–4 seats (SC-006).
- [x] Bound holds by construction: each rider's contribution is already at most
  ⌊trip cost ÷ seats⌋ (the range's own cap), the fee only fills the room left, so seats × rider
  total ≤ seats × ⌊trip cost ÷ seats⌋ ≤ trip cost.
- [x] Constitution II is met as written — no amendment needed; brief §6.7 and §8 updated to match.
- Note: `PricingService.riderTotal`/`serviceFee` are named in FR-003, as v2 already did — the pure
  domain rule is a Constitution VIII deliverable, not an implementation choice made here.
- Drafted copy to add to research R13 at plan time: "{c} EGP to the driver · no service fee",
  "a service fee of up to 10%", breakdown label without "(10%)" — founder review before ship.
