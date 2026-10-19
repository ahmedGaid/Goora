# Feature Specification: Pay Later and Trip Bundle

**Feature Branch**: `008-pay-later-bundle` (stacked on `007-direct-driver-payment`, not yet merged)

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "Pay later + 20-trip bundle — profit change 8 (`GOORA_PROFIT_CHANGES.md`
§8). Riding needs no card and no subscription. After a paid trip Goora's 4 EGP fee goes on the
rider's balance; the rider settles it in one payment at 150 EGP, or at month end when it is ≥ 30
EGP (below 30 it carries over), by mobile wallet, InstaPay, Fawry code or card — never a required
card. After a 3-day grace an unpaid balance blocks new bookings until paid. Optional bundle: 20
trips for 75 EGP that never expire; bundle trips cover Goora's fee only; when they run out the
rider falls back to the balance. Subscription is an upgrade nudge, never a gate."

**Sources of truth**: `GOORA_PROFIT_CHANGES.md` §8, §9, §10.5 · `GOORA_SPEC_KIT_BRIEF.md` §6.7 (as
rewritten by 007) · spec 007 (direct pay; fee owed = balance below zero, FR-009).

**Carried over, decided, not re-asked**: the driver's share is paid directly (007); Goora's fee is
up to 10%, trimmed by the cap, 0 for subscribers, company and the 5-trip trial; subscription
149/1,490; drivers pay nothing; bundle trips never expire (founder decision); bundle price never
below 75.

## Clarifications

### Session 2026-10-19 (decided by the implementer from the profit brief's suggestions, founder to confirm)

- Q: Settlement threshold and grace? → A: The brief's suggestions: settle at **150 EGP** owed,
  or at month end when **≥ 30 EGP** is owed; **3 days** of grace after a balance falls due.
- Q: Which payment methods? → A: Vodafone Cash (and other mobile wallets as one choice),
  InstaPay, Fawry / Aman reference code, card. All fakes; one settlement = one transaction.
- Q: How does a Fawry code work in the fakes? → A: The sheet shows a reference code and a
  "I paid at Fawry" button; the fake provider settles at once. A real integration confirms by
  callback (out of scope).
- Q: Is the bundle paid from the balance? → A: No. It is paid once, like a settlement, by any of
  the methods; it adds 20 trips and never touches the balance. Buying while fees are owed is
  allowed and does not settle them.
- Q: Does a bundle trip get used when the fee is 0 (trial, subscriber, cap trimmed to 0)? → A: No.
  A bundle trip is used only when the trip would carry a fee above 0.
- Q: Does top-up stay? → A: Yes, as an optional prepayment: a positive balance pays fees first.
  Settling is paying the owed amount; nothing else changes.
- Q: When exactly is a month-end balance due? → A: On the 1st of the next month, if the amount
  owed at the end of the month is ≥ 30 EGP; otherwise it carries over to the next month end.

### Open — recorded, not decided here (founder)

- Lawyer: is a pay-later balance for Goora's own fee fine without a licence? (profit brief §10.1)
- Real providers (wallet, InstaPay, Fawry, card gateway) and their fees.
- Bad-debt write-off: the model assumes 3% never paid; tracking the real number needs a backend.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ride now, pay Goora later (Priority: P1)

A non-subscriber past the trial books and finishes trips with no card and no balance. Each trip's
4 EGP goes on their Goora balance. Wallet shows "عليك X ج.م لـ Goora" with a Pay button.

**Why this priority**: it removes the last "add a card first" step; the rest builds on it.

**Independent Test**: As a rider with no payment method on file and balance 0, finish 3 paid trips:
the balance reads −12, booking still works, nothing was charged.

**Acceptance Scenarios**:

1. **Given** a rider with no card or wallet, **When** they book and finish a paid trip, **Then**
   the trip completes and 4 EGP is owed.
2. **Given** 12 EGP owed, **When** they open Wallet, **Then** they see the owed amount and a Pay
   button, and no "top up before booking" message anywhere.
3. **Given** a positive top-up balance, **When** a fee is due, **Then** it comes out of the
   balance first, and only the rest is owed.

---

### User Story 2 - Settle in one payment (Priority: P1)

The rider pays everything owed at once by wallet, InstaPay, Fawry code or card.

**Why this priority**: without settling, the fees are never collected.

**Independent Test**: With 40 EGP owed, open Pay, choose InstaPay, confirm: owed is 0, one
settlement row reads +40.

**Acceptance Scenarios**:

1. **Given** X owed, **When** the rider settles by any method, **Then** exactly X is collected in
   one transaction and the balance is 0.
2. **Given** a payment failure, **When** the rider tries to settle, **Then** nothing changes and a
   blame-free error offers retry.
3. **Given** the Fawry method, **When** chosen, **Then** a reference code shows with "I paid at
   Fawry"; confirming settles in the fakes.
4. **Given** nothing owed, **When** Wallet is opened, **Then** there is no Pay button.

---

### User Story 3 - An overdue balance blocks new bookings (Priority: P2)

When 150 EGP is owed, or a month ends with ≥ 30 owed, the balance falls due. After 3 days unpaid,
the rider can't book, post or join until they pay. Trips already booked still run.

**Why this priority**: it is what makes pay-later collectable; it matters only after US1/US2.

**Independent Test**: Owe 152 EGP; move the clock 3 days; booking is refused with the amount and a
Pay action; paying unblocks at once.

**Acceptance Scenarios**:

1. **Given** 152 owed since today, **When** 2 days pass, **Then** booking still works and Wallet
   shows "due" with the days left.
2. **Given** the same, **When** 3 days pass, **Then** booking is refused with "عليك X ج.م لـ
   Goora" and Pay.
3. **Given** 28 owed at month end, **When** the month turns, **Then** nothing is due (it carries).
4. **Given** 30 owed at month end, **When** the month turns, **Then** it is due from the 1st and
   overdue from the 4th.
5. **Given** an overdue rider, **When** they settle, **Then** the block lifts immediately.

---

### User Story 4 - The 20-trip bundle (Priority: P2)

A rider buys 20 trips for 75 EGP. Each paid trip uses one bundle trip instead of a 4 EGP fee. The
trips never expire; buying again adds 20. When none are left, fees go on the balance again.

**Why this priority**: a cheaper, no-commitment way to prepay; optional.

**Independent Test**: Buy a bundle, finish 2 paid trips: 18 left, nothing owed. Buy another: 38.

**Acceptance Scenarios**:

1. **Given** a bundle with 20 left, **When** a paid trip finishes, **Then** 19 are left and
   nothing is added to the balance.
2. **Given** 0 left, **When** a paid trip finishes, **Then** the fee goes on the balance.
3. **Given** a trip with fee 0 (trial, subscriber, trimmed), **When** it finishes, **Then** no
   bundle trip is used.
4. **Given** months pass, **When** the rider opens Wallet, **Then** the bundle trips are all
   still there (never expire).
5. **Given** a payment failure buying a bundle, **Then** nothing changes.

---

### User Story 5 - Subscription as an upgrade (Priority: P3)

When a rider's fees this month pass 149, Wallet shows "دفعت X ج.م رسوم الشهر ده، الاشتراك بـ 149
ومعاه مكان مضمون وبديل لو السواق غاب." No screen blocks a ride behind a subscription or a card.

**Acceptance Scenarios**:

1. **Given** 152 EGP of fees this month, **When** Wallet opens, **Then** the nudge shows with
   Subscribe.
2. **Given** any booking path, **When** the rider has no card and no subscription, **Then** it is
   never blocked for that reason.

### Edge Cases

- Owed crosses 150 mid-day by a seat fee at booking: due that day.
- A refund (cancelled seat) brings owed under 150 before the grace ends: still due (the due date
  stays until the owed amount reaches 0), but the amount shown is the new one.
- Settling while a trip is in progress: allowed.
- A subscriber with an old owed balance: still has to settle; no new fees accrue.
- Bundle bought during the trial: trips are kept for after the trial.
- Rider deletes the app data (demo reset): everything clears (fakes).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A paid trip's Goora fee MUST be taken from a positive balance first; the rest MUST
  be owed (balance below zero). No booking path MAY require a card, a top-up or a subscription.
- **FR-002**: Wallet MUST show the owed amount as "عليك X ج.م لـ Goora" with a Pay action when
  owed > 0.
- **FR-003**: Settling MUST collect exactly the owed amount in one transaction by mobile wallet,
  InstaPay, Fawry code or card; a failure MUST leave balance and activity unchanged.
- **FR-004**: The balance MUST fall due on the first day the owed amount reaches 150, or on the
  1st of a month when ≥ 30 was owed at the end of the previous month, whichever is first; below
  30 at month end it carries over. The due date clears only when owed reaches 0.
- **FR-005**: 3 days after the due date (due + 3 days, on the demo clock), an unpaid balance MUST
  block Book, Post, accept and Join, naming the amount with a Pay action; paying lifts it at once.
  Trips already booked are not cancelled.
- **FR-006**: The rule set in FR-004/FR-005 and the bundle-use rule MUST be pure Dart with a
  TypeScript twin and shared vectors.
- **FR-007**: A bundle MUST cost 75 EGP for 20 trips, be paid in one transaction by any method, add
  to the trips left, never expire, and never touch the balance.
- **FR-008**: A paid trip with a fee above 0 MUST use one bundle trip when any are left, recording
  0 fee owed; otherwise the fee goes on the balance. A fee-free trip never uses one.
- **FR-009**: The subscription nudge MUST show when this month's fees exceed 149, with the brief's
  copy; nothing MAY gate a ride behind a subscription or a card.
- **FR-010**: All new copy MUST be ARB ar/en, Egyptian colloquial, directional layout, tokens only.
- **FR-011**: Constitution II is unchanged: bundles and balances concern Goora's fee only.

### Key Entities

- **Fee balance**: the Goora ledger seen as owed / due date / overdue.
- **Settlement**: one payment of the owed amount (method, amount, date).
- **Trip bundle**: trips left (int, ≥ 0), purchases (date, 20 trips, 75 EGP); never expires.

## Success Criteria *(mandatory)*

- **SC-001**: 100% of booking paths work for a rider with no card, no subscription and no balance,
  until a balance is overdue.
- **SC-002**: A settlement clears the owed amount in one transaction in 100% of fake runs.
- **SC-003**: The due/overdue rule gives identical answers in Dart and TypeScript on all vectors.
- **SC-004**: Bundle trips are never lost: trips left only decreases by trips taken.
- **SC-005**: A rider can settle in under 30 seconds from Wallet.

## Assumptions

- Fakes only; providers simulated by the existing fake payment provider.
- The overdue block is enforced in the app fakes; the server enforces its own copy later.
- Bad debt is not written off here; it stays owed.
