# Feature Specification: Wallet and Subscription

**Feature Branch**: `004-wallet-subscription`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "Read GOORA_SPEC_KIT_BRIEF.md section 6.7. Build the subscription and
wallet: Plan screen (shown to riders after 'Join this group'; drivers skip it): title 'Start your
free month', subline 'You only pay once we find your group — and we did.', three radio cards
(Monthly 129 EGP / Yearly 1,290 EGP with '2 months free' chip / Through my company: free, verify
work email), 'What's included' list, note that the fuel contribution goes to the driver in full,
CTA 'Start free month' / 'Verify work email', footer 'Cancel anytime. Goora is free for drivers.'
Wallet, rider: plan card (name, status 'Free until <date> · then 129 EGP/month', Change), dark
balance card with 'Covers about N trips' and Top up (method pills InstaPay / Vodafone Cash / Card,
amounts 200/400/800), 'How paying works' rules list, activity list (trip deductions, late-cancel
half charge, zero rows for free cancellations, top-ups), and 'What you pay per trip' breakdown
(your share of fuel & tolls / Goora fees: in your plan / total). Wallet, driver: 'Recovered this
week' balance, 'Paid out every Thursday · no fees taken from you', Withdraw to InstaPay, activity
(trip income, late-cancel and no-show fees), 'Your trip cost' breakdown (trip cost / you receive
from riders / what you pay yourself / Goora is free for drivers). Money is held by a licensed
payment partner; the app keeps a ledger only. Use FakePaymentProvider in this feature."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` §5 (004), §6.2, §6.7; approved prototype has no
wallet/plan screens, so all copy here is drafted (research R-series, founder review before ship,
same pattern as 001/002/003).

**Carried over from 001–003 (decided, not re-asked)**: demo trip cost 160 EGP → 40 EGP per rider
per trip per leg; fakes-first backend (fake data now, server code written and tested for later
keys); late cancellation owes half the leg share (`AttendanceRules.cancelCharge`, 20 EGP/leg — 40
EGP across both legs of a day, matching the "40 EGP, both legs" figure already shown live in 003);
a no-show owes the full leg share (40 EGP/leg); "Goora fee" never appears as a separate per-trip
line (brief wins over the prototype) — it is folded into the subscription price instead, so the
per-trip breakdown says "Goora fees: in your plan" rather than a number.

## Clarifications

### Session 2026-10-08

- Q: The brief's wallet balance card says "Covers about N trips" — what counts as a "trip" for
  that estimate, and does it apply to subscribers? → A: Round-trip days (going + return = one
  trip), floor(balance ÷ 2×leg-share). It only matters for the rare top-up a subscriber makes
  ahead of a late-cancel charge or a one-off seat booking; subscribers don't spend from the wallet
  for their daily group trips (that's covered by the subscription), so the tile is most relevant
  to someone between plans or paying as a one-off rider.
- Q: Company verification ("Through my company: free, verify work email") reuses the existing
  `needWorkEmail` copy and flow from onboarding (001) — does accepting it grant the plan
  immediately, or wait for an async check? → A: Immediate in this feature (fake verifier, same
  spirit as other "fakes-first" checks in 001–003). A real email-domain/SSO check is out of scope
  until feature 006 (company network).
- Q: Can a rider change plans (Monthly ↔ Yearly ↔ Company) from the wallet "Change" link, and does
  a mid-cycle change pro-rate? → A: Yes, they can switch any time from "Change"; it takes effect
  at the next billing date, no pro-rating or refund for the current period (simplest fair rule,
  matches "Cancel anytime" — no clawback either way).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A rider starts their free month after joining a group (Priority: P1)

A rider who just joined a group (002/003) sees the plan screen once, picks a plan, and starts
their free month. Drivers never see this screen — Goora is free for drivers.

**Why this priority**: Without this, a rider has a group but no paid relationship with Goora — the
business model (brief §6.7's "people pay") has no entry point at all.

**Independent Test**: Can be fully tested by completing "Join this group" as a rider, landing on
the plan screen, choosing Monthly, and confirming it starts a free month that only begins billing
after the trial.

**Acceptance Scenarios**:

1. **Given** a rider has just joined a group for the first time, **When** they land on the plan
   screen, **Then** they see the title "Start your free month", the subline "You only pay once we
   find your group — and we did.", three plan cards (Monthly 129 EGP, Yearly 1,290 EGP with a "2
   months free" chip, Through my company: free), the "What's included" list, the note that the
   fuel contribution goes to the driver in full, and the footer "Cancel anytime. Goora is free for
   drivers."
2. **Given** the rider selects Monthly or Yearly, **When** they tap "Start free month", **Then**
   their plan shows as active with a free-until date one calendar month out, and no charge is made.
3. **Given** the rider selects "Through my company", **When** they tap "Verify work email" and
   complete the (fake) verification, **Then** their plan is Company, marked free, with no trial
   date (the company pays).
4. **Given** a driver has just been confirmed into the same group, **When** they open the app,
   **Then** they never see the plan screen — only riders see it.
5. **Given** a rider dismisses or backs out of the plan screen without choosing, **When** they
   return to the app, **Then** the plan screen reappears until a plan is chosen (a rider cannot use
   the group without an active plan, even a free-trial one).

---

### User Story 2 - A rider manages their wallet, plan and top-ups (Priority: P1)

A rider on the Wallet tab sees their plan, a balance, a way to top up, a plain-language
explanation of how paying works, and a running activity list of what they were charged and when.

**Why this priority**: This is the tab that answers "did I get charged, and why" — without it,
every attendance rule from 003 (late-cancel charge, no-show charge) is invisible money leaving a
black box.

**Independent Test**: Can be fully tested by opening the Wallet tab as a rider with seeded demo
activity (a top-up, a trip deduction, a late-cancel charge, a free cancellation) and confirming
each row and the balance match.

**Acceptance Scenarios**:

1. **Given** a rider is on a Monthly plan with a free-until date, **When** they open the Wallet
   tab, **Then** the plan card shows "Free until {date} · then 129 EGP/month" and a "Change" link.
2. **Given** the rider has a wallet balance, **When** they view the dark balance card, **Then**
   it shows the balance and "Covers about {N} trips" (round-trip days at 2×leg-share each) plus a
   "Top up" action with method pills (InstaPay / Vodafone Cash / Card) and amount choices (200 /
   400 / 800 EGP).
3. **Given** the rider taps Top up, picks a method and an amount, **When** the (fake) payment
   completes, **Then** the balance increases by that amount and a new "Top-up" row appears at the
   top of the activity list.
4. **Given** the rider was charged for a late cancellation (003), **When** they open the activity
   list, **Then** a row shows the half-share charge for that trip, distinct from a free
   cancellation (which shows as a zero-amount row, not a missing one — the rider can see it was
   recorded, just not charged).
5. **Given** the rider wants to know what they pay per trip, **When** they view the "What you pay
   per trip" breakdown, **Then** it shows their share of fuel & tolls as a number and "Goora fees:
   in your plan" (never a separate fee number), with a total that equals their share.

---

### User Story 3 - A driver sees what they're paid and withdraws it (Priority: P2)

A driver on the Wallet tab sees money recovered this week, when it pays out, a way to withdraw
early, and an activity list of trip income and the rare rider fee that reaches them.

**Why this priority**: Drivers are the supply side; if what they're owed isn't legible, drivers
stop driving. Lower priority than the rider wallet because a driver's number is the same net
figure riders already see confirmed live in 003 — this is presentation and withdrawal, not new
money logic.

**Independent Test**: Can be fully tested by opening the Wallet tab as a driver with seeded demo
trip income and confirming the weekly balance, payout day and activity rows.

**Acceptance Scenarios**:

1. **Given** a driver has driven trips this week, **When** they open the Wallet tab, **Then** they
   see "Recovered this week" with the total and the line "Paid out every Thursday · no fees taken
   from you".
2. **Given** a driver wants their balance sooner, **When** they tap "Withdraw to InstaPay", **Then**
   the (fake) withdrawal completes and the balance resets, with a new "Withdrawal" row in activity.
3. **Given** a driver views "Your trip cost" breakdown for a trip, **When** they expand it,
   **Then** it shows the trip cost, what they receive from riders, what they pay themselves (the
   gap, if riders' total is less than the full cost — e.g. an empty seat), and "Goora is free for
   drivers" with no deduction shown.
4. **Given** a rider was charged a late-cancel or no-show fee tied to one of the driver's trips,
   **When** the driver views activity, **Then** a row shows that fee reaching them, labelled by
   which rider and trip.

---

### Edge Cases

- A rider's free trial ends with no payment method on file (no top-up ever made, company plan not
  chosen): the plan card shows the plan as due, and the rider is prompted to top up or switch to
  Through my company before their next trip is confirmed — they are not silently removed from the
  group (that stays a reliability-rule outcome, not a billing one).
- A top-up or withdrawal fails (FakePaymentProvider simulates this): the balance is unchanged, no
  activity row is added, and an inline error explains it with a retry, matching the rest of the
  app's blame-free error tone.
- A rider switches plans mid-cycle: the new plan takes effect at the next billing date; the
  current free-until or paid-until date is unaffected (Clarification above).
- A rider on a Company plan loses company verification (e.g. leaves the company, out of scope to
  simulate the trigger in this feature, but the state must exist): the plan card shows the plan as
  needing a new choice, same treatment as a trial ending unpaid.
- The "Covers about N trips" estimate when the balance is smaller than one leg-share: shows "0"
  rather than a negative or fractional trip count.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After a rider's first "Join this group" action, the system MUST show the plan
  screen before the rider can use Today/Week for that group, with Monthly, Yearly and Through my
  company options, and MUST skip this screen entirely for drivers.
- **FR-002**: Choosing Monthly or Yearly MUST start a one-calendar-month free trial from that
  moment, with no charge during the trial, and MUST record the plan's future price and billing
  cadence for display.
- **FR-003**: Choosing Through my company MUST route through the existing work-email verification
  flow (reusing `needWorkEmail`/the 001 verification pattern) and, on confirmation, MUST mark the
  plan as Company: free, with no trial date and no future charge recorded for the rider.
- **FR-004**: The system MUST let a rider change plans at any time from the wallet's "Change"
  link, applying the new plan at the next billing date without pro-rating or refunding the current
  period.
- **FR-005**: The rider wallet MUST show the active plan's name and status line ("Free until
  {date} · then {price}/month" during trial, or the Company/paid equivalent), a balance, a
  "Covers about {N} trips" estimate computed from the balance and the per-leg share, and a Top-up
  action offering InstaPay, Vodafone Cash and Card at 200/400/800 EGP.
- **FR-006**: A successful top-up MUST increase the rider's wallet balance by the chosen amount and
  add a dated activity row for it; a failed top-up MUST change neither the balance nor the activity
  list.
- **FR-007**: The rider wallet's activity list MUST include every trip deduction, every late-cancel
  half-charge, a zero-amount row for every free cancellation (never an omitted row), and every
  top-up, each dated and labelled.
- **FR-008**: The rider's "What you pay per trip" breakdown MUST show their fuel & tolls share as a
  number, "Goora fees: in your plan" as a fixed label (never a separate fee amount), and a total
  equal to the share.
- **FR-009**: The driver wallet MUST show a "Recovered this week" total, the fixed line "Paid out
  every Thursday · no fees taken from you", and a Withdraw-to-InstaPay action.
- **FR-010**: A successful withdrawal MUST reset the driver's recoverable balance for the withdrawn
  period and add a dated activity row for it; a failed withdrawal MUST change neither the balance
  nor the activity list.
- **FR-011**: The driver wallet's activity list MUST include every trip's income, and every
  late-cancel or no-show fee that reaches the driver from a rider's charge, each dated and
  labelled with the rider/trip it came from.
- **FR-012**: The driver's "Your trip cost" breakdown for a trip MUST show the trip cost, what the
  driver received from riders, the gap the driver covers themselves (if any — e.g. an empty seat),
  and the fixed line "Goora is free for drivers" with no deduction line.
- **FR-013**: All money movement in this feature MUST go through a `FakePaymentProvider` (no real
  payment partner integration); the app MUST keep its own ledger of every balance change
  independent of that provider, so the ledger is the single source of truth for what the UI shows.
- **FR-014**: A rider whose trial or paid period has ended with no active payment arrangement (no
  top-up, no Company verification) MUST be shown a due-plan state and prompted to resolve it
  before their next trip is confirmed, without being removed from the group by this feature.

### Key Entities

- **Plan**: belongs to one rider; has a type (Monthly, Yearly, Company), a price (0 for Company),
  a status (trialing, active, due), and a relevant date (free-until or paid-until). Drivers do not
  have a Plan.
- **Wallet**: belongs to one rider or one driver; has a balance (rider: prepaid EGP; driver:
  recoverable EGP awaiting the Thursday payout) and an ordered Activity list.
- **Activity entry**: belongs to one Wallet; has a kind (top-up, trip deduction, late-cancel
  charge, free-cancel zero-row, trip income, no-show fee received, withdrawal), an amount
  (possibly zero), a date, and an optional reference to the trip/rider it came from.
- **FakePaymentProvider**: a test double standing in for the licensed payment partner; accepts a
  top-up or withdrawal request and returns success or a simulated failure; never itself the source
  of truth for balances (the app's ledger is).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A rider can go from "just joined a group" to an active free-trial plan in under 30
  seconds (one screen, one choice, one tap).
- **SC-002**: 100% of a rider's attendance-rule charges from feature 003 (late-cancel half charge,
  no-show full charge, free cancellation) appear in the wallet activity list with the correct
  amount, including the zero-amount rows for free cancellations.
- **SC-003**: A driver can see their current week's recovered balance and next payout date without
  navigating past the Wallet tab's first screen.
- **SC-004**: A rider never sees a bare per-trip "Goora fee" number anywhere in the wallet or plan
  screens — only "in your plan" or no fee line at all.
- **SC-005**: A simulated top-up or withdrawal failure leaves the balance and activity list exactly
  as they were before the attempt, verified by a unit test for each path.

## Assumptions

- All money in this feature is simulated (`FakePaymentProvider`); no real InstaPay/Vodafone
  Cash/Card integration is in scope — that is a later, non-speckit integration step once payment
  partner keys exist (same posture as 001–003's fakes-first backend).
- The demo trip cost (160 EGP total, 40 EGP per rider per leg) and the attendance charges it drives
  (20 EGP half-charge, 40 EGP no-show) are reused unchanged from 002/003; this feature does not
  change pricing, only how it is shown and settled.
- Company-plan verification reuses the existing fake work-email check from onboarding (001); a
  real company-domain or SSO check belongs to feature 006 (company network, explicitly deferred by
  the brief).
- "Covers about N trips" is a rough estimate for display only, not a reservation or hold on the
  balance; it recomputes from the live balance each time the wallet is viewed.
- Feature 005 (seat marketplace) will add its own one-off booking fee (40 to the driver + 5 EGP
  booking fee for non-subscribers) as its own wallet activity kind later; this feature's activity
  kinds cover only what 001–003 already produce (subscription trial/billing status, and 003's
  attendance charges) plus top-ups and withdrawals.
