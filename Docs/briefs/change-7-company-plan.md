# Brief — profit change 7 (company plan), for the 006 session

Written 2026-10-19 from `main` (after 007/008/009 merged). Source: `GOORA_PROFIT_CHANGES.md` §7, §10.3
(untracked file in the main checkout). Founder confirmed on 2026-10-19 that every implementer
default in 007/008/009 stands as built.

## TL;DR for the 006 session

1. **Do not put the company plan into the 006 spec.** 006 is the Cairo ↔ Ismailia corridor. The
   company plan is a separate, later feature ("company network"). Adding B2B billing to a corridor
   spec would break "one change per spec".
2. **Fix a number clash before 006 merges.** Your branch renumbered the company network from 006
   to **007** (brief §2 roadmap table, brief "Feature 007: Company network", brief §5 D), constitution
   1.0.1 Development Workflow + Sync Impact Report). Since then `main` merged
   `specs/007-direct-driver-payment`, `008-pay-later-bundle`, `009-rider-id-first-trip`. So 007 is
   taken. Renumber the company network to the **next free feature number** at merge time (010
   today; check `ls specs/` first) — or just "later, unnumbered".
3. **Expect conflicts in `GOORA_SPEC_KIT_BRIEF.md` when 006 merges.** 007/008/009 rewrote brief §5
   (payments: driver paid directly, pay later, bundle, trial = 5) and §6.7. Your branch edited §2,
   §5 D), §6.1. Keep **both** sides; §5 C) on your branch still says "first 10 trips" — main's
   text (5 trips, direct pay) wins there.
4. **Price text in brief §5 D) and the company-network section is stale either way.** Brief says
   75 EGP / registered employee / month; the profit model says 99. Leave the number as "TBD
   (founder, in `/speckit-clarify`)" rather than picking one.

Nothing else in 006 needs to change for change 7.

## What change 7 is (input for the later company-network spec)

- **Company pays Goora** a fixed per-employee monthly fee, one invoice, bank transfer.
- **Covered employees pay no service fee** (no 4 EGP / 10% trip fee) and need no personal
  subscription.
- **Drivers are usually fellow employees.** They still get the cost share **directly from riders**
  (change 1 / feature 007). Goora never holds that money — the company fee pays only Goora.
- **Optional HR statement:** monthly per-employee list of trips and cost shares paid, so the
  company can reimburse commuting through payroll. Goora moves no money for this.
- Law 87/2018 unchanged: drivers never profit, drivers pay nothing.
- Constitution: companies **never** see individual employee data without explicit consent. The HR
  statement is individual data → needs the employee's opt-in, per company.

## Already built (don't rebuild)

- `PlanType.company` (`lib/features/wallet/domain/plan.dart`): price 0, no end date, covers every
  date → trips are fee-free.
- Rider picks "Through my company" on the plan screen → work-email verify sheet
  (`company_verify_sheet.dart`) → fake repository sets the company plan.
- Payment method resolves to `company` when the plan covers today (`payment_method.dart`);
  `direct_pay` treats company as fee-free (twins `direct_pay.dart` / `.ts`).
- Matching already scores "same company" and offers a same-company privacy filter (002/003).

## Not built (the real scope of the later feature)

- Company side: sign-up, verified email domain(s), roster (enrolled employees), seat count.
- Billing: monthly invoice per company, bank-transfer record, unpaid-invoice rule (what happens to
  employees' fee-free status).
- Leaving: employee leaves the company / domain removed → plan ends, rider returns to pay-per-trip
  (with or without trial? — 004 wallet riders already stay out of the trial).
- Aggregated dashboard (brief: active groups, carpool rate, savings, CO₂, parking, route gaps) —
  aggregates only.
- HR statement + consent flow.
- Interaction with 008: does a covered employee ever have a fee balance? (Should be no — but
  one-off seat fees outside the company corridor need a rule.) Bundle bought before joining a
  company: keep, pause, or refund?

## Founder decisions for `/speckit-clarify` (open — not decided here)

1. Price per employee per month (brief 75 vs model 99).
2. Bill all enrolled employees vs active riders only.
3. Minimum seats (suggest 20).
4. Contract length (suggest annual).
5. Do employees' one-off marketplace seats (005) count as covered?
6. HR statement in v1 or later.

## Fit

Spec + clarify + plan: **Opus** (B2B billing, consent, interplay with 007/008). Implementation
later: Sonnet per phase. Start only after 006 merges (both touch the brief and constitution).
