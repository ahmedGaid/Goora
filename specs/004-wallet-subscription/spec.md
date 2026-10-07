# Feature Specification: Wallet and Payment Model

**Feature Branch**: `004-wallet-subscription`

**Created**: 2026-10-08 · **Amended**: 2026-10-08 (payment model v2, see "Amendment" below)

**Status**: Draft

**Input**: User description (v2, replaces the v1 "free month + mandatory plan" model): "Read
GOORA_SPEC_KIT_BRIEF.md section 6.7. Build the payment model and wallet: payment-method screen
after 'Join this group' (cash to the driver for the first 10 trips, or wallet, plus a 'Subscribe
and pay no fees' link); optional subscription (129 EGP/month, 1,290 EGP/year, company plan
unchanged); a 10% per-trip service fee for non-subscribers, deducted per completed trip; price
lines on match result and Today; rider wallet with plan card, cash-trial counter, fee-savings
banner and per-trip fee rows; driver Today 'Received cash' / 'Didn't pay' after drop-off; driver
wallet showing cash received separately; pure-Dart PricingService, CashTrialPolicy and
FeeSavingsCalculator with unit tests using the brief's numbers."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` §5 (004), §6.2, §6.5, §6.7 (rewritten 2026-10-08),
§7. Copy not in §7 is drafted (research R5 + R6, founder review before ship).

**Carried over from 001–003 (decided, not re-asked)**: 40 EGP contribution per rider per trip
(one leg); late cancellation owes half the leg share (20 EGP), a no-show the full share (40 EGP),
both to the driver with no Goora fee; fakes-first backend; Constitution II (drivers never profit).

## Amendment — payment model v2 (2026-10-08)

v1 (US1–US3 built, T001–T045) had a mandatory plan screen with a free month and folded Goora's
cut into the subscription. v2 makes the subscription optional, adds a 10% per-trip service fee for
everyone else, and adds a 10-trip cash trial for new riders. What survives from v1 unchanged: the
wallet ledger, top-up and withdrawal (with their failure paths), the subscription screen's plan
cards and company verification, the driver wallet's recovered balance and breakdown, and the
"read 003's records, don't duplicate them" seam (research R3). What is removed: the free month,
the trialing status, the "Start your free month" copy, and the redirect that forced a plan.

**Constitution II reading**: the cap ("riders' total payments must not exceed the full trip
cost") applies to the contributions drivers receive, which are unchanged. The service fee goes to
Goora, is not trip cost and never reaches the driver — the same reading the brief already used
for the old 5 EGP booking fee. The brief records this for the pending legal opinion (§8). This
feature does not amend the constitution.

## Clarifications

### Session 2026-10-08 (v1)

- Q: "Covers about N trips" — what is a trip? → A: a round-trip day, floor(balance ÷ 2 × leg
  total). In v2 the leg total includes the service fee for non-subscribers (44 EGP, so 88 per day).
- Q: Company verification — immediate or async? → A: immediate, fake verifier; a real check
  belongs to feature 006.
- Q: Mid-cycle plan change? → A: takes effect at the next billing date, no pro-rating.

### Session 2026-10-08 (v2 — decided by the implementer from the brief, founder to confirm)

- Q: Is there still a free month? → A: No. §6.7 B lists no trial; the cash trial is the new
  low-friction start.
- Q: How is a subscription paid? → A: From the wallet balance at the moment of subscribing (the
  ledger stays the one money source). Not enough balance → an inline "top up first" with the gap.
  At the end of the paid period the plan lapses back to pay-per-trip (no auto-renew in the fakes).
- Q: Fee rounding? → A: Nearest whole EGP, halves up: fee = (contribution + 5) ÷ 10, integer.
  40 → 4, 45 → 5, 44 → 4, 48 → 5.
- Q: "From cash trip 8 onwards" — when exactly does the banner show? → A: Once the rider's next
  cash trip is their 8th, i.e. after 7 completed cash trips (3 left), until cash ends.
- Q: Does a "Didn't pay" trip count toward the 10? → A: Yes — it is a completed cash trip.
- Q: Does a "Didn't pay" mark create a wallet debt? → A: No. It is recorded (and counts as a
  strike); collecting it is out of scope.
- Q: Can a rider move between cash and wallet? → A: The choice is made once on the
  payment-method screen. Choosing the wallet gives up the cash trial. Cash ends by policy (10
  trips or 2 strikes); topping up during the cash trial does not end it.
- Q: "After 10 cash trips, booking requires a wallet balance (or a company plan)" — enforced
  where? → A: There is no booking engine yet (005/server). This feature shows a "Top up to keep
  riding" state in the Wallet when cash is not available and the balance is below one trip; a
  company-plan rider never sees it. Blocking a seat is server/005 work.
- Q: Do subscribers and company employees still pay the contribution? → A: Yes. "No fees" means no
  Goora service fee; the driver's contribution is always paid (it is the cost-sharing).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A rider chooses how to pay after joining a group (Priority: P1)

After "Join this group", a rider picks cash (first 10 trips) or wallet, or follows the small
"Subscribe and pay no fees" link. Drivers never see this screen.

**Why this priority**: it replaces v1's mandatory plan screen as the rider's entry into the
business model; without it a new rider has no payment arrangement.

**Independent Test**: join a group as a rider, land on the payment-method screen, choose cash,
and confirm Today opens with the cash price line.

**Acceptance Scenarios**:

1. **Given** a rider has just joined a group, **When** the payment-method screen opens, **Then**
   it shows "How do you want to pay?", the cash option "Pay cash to the driver (first 10 trips)",
   the wallet option "Use wallet", and a small "Subscribe and pay no fees" link — and no free-month
   or mandatory plan copy.
2. **Given** the rider picks cash and continues, **Then** Today opens and every price line reads
   "Pay 40 EGP cash to the driver".
3. **Given** the rider picks wallet and continues, **Then** Today opens and every price line reads
   "40 EGP to the driver + 4 EGP service fee".
4. **Given** the rider taps "Subscribe and pay no fees", **Then** the subscription screen opens
   (Monthly / Yearly / Through my company).
5. **Given** a driver joins a group, **Then** they never see the payment-method screen.
6. **Given** a rider leaves the payment-method screen without choosing, **When** they return,
   **Then** it reappears until a choice is made (subscribing or a company plan also counts).

---

### User Story 2 - A rider pays per trip from the wallet, with the fee shown (Priority: P1)

A wallet rider sees what each trip costs, tops up, sees each trip's fee as its own line, and is
told when a subscription would have been cheaper.

**Why this priority**: this is the default way riders pay and the main revenue line.

**Independent Test**: seed a wallet rider with completed trips this month, open Wallet, and check
balance, fee rows and the savings banner against the numbers below.

**Acceptance Scenarios**:

1. **Given** a non-subscriber rides a 40 EGP trip, **When** the trip completes, **Then** 44 EGP
   leaves the wallet: 40 to the driver, 4 service fee, shown as one trip row with the split.
2. **Given** a rider tops up 200 EGP, **Then** the balance rises by exactly 200 (no fee at top-up).
3. **Given** a late cancellation (20 EGP) or a no-show (40 EGP), **Then** the wallet row shows the
   charge to the driver with no service fee.
4. **Given** a non-subscriber's service fees this calendar month exceed 129 EGP, **Then** the
   Wallet shows "You paid {X} EGP in fees this month. With a subscription you'd pay 129." with a
   "Subscribe" button that opens the subscription screen.
5. **Given** the plan card, **Then** it reads "Pay per trip", "Subscribed" (with the paid-until
   date) or "Company", with a "Change" link to the subscription screen.
6. **Given** the "What you pay per trip" breakdown, **Then** it shows the driver's share (40), the
   service fee (4, or "none" for subscribers, company and cash), and the total.

---

### User Story 3 - A rider subscribes and stops paying fees (Priority: P1)

**Independent Test**: a wallet rider with 200 EGP subscribes Monthly; balance drops to 71, plan
card reads Subscribed, the next trip costs exactly 40.

**Acceptance Scenarios**:

1. **Given** a rider with at least 129 EGP subscribes Monthly (or 1,290 Yearly), **Then** the
   price leaves the wallet as a "Subscription" row and the plan is active for one month (or year).
2. **Given** a subscriber's trip completes, **Then** exactly the contribution leaves the wallet and
   price lines read "40 EGP · no fees (subscribed)".
3. **Given** a rider without enough balance tries to subscribe, **Then** an inline message says
   how much to top up first, and nothing is charged.
4. **Given** "Through my company" is verified, **Then** the plan is Company: no fees, no charge.
5. **Given** a subscription's paid period ends, **Then** the rider is back on pay-per-trip.

---

### User Story 4 - A new rider pays cash for their first 10 trips (Priority: P1)

**Independent Test**: seed a cash rider with N completed trips and M "didn't pay" marks and check
the counter, the banner and the switch-over against CashTrialPolicy's numbers.

**Acceptance Scenarios**:

1. **Given** a cash rider has completed 3 trips, **Then** the Wallet shows "7 cash trips left" and
   no Goora fee is charged on those trips (activity rows read "Paid 40 EGP cash to the driver").
2. **Given** a cash rider has completed 7 cash trips, **Then** the banner "Top up your wallet to
   keep riding — get backup drivers, guaranteed seats and refunds." shows (and stays until cash
   ends).
3. **Given** a cash rider has completed 10 cash trips, **Then** cash is no longer available, price
   lines switch to the wallet price, and a wallet balance below one trip shows "Top up to keep
   riding".
4. **Given** drivers have marked a rider "Didn't pay" twice, **Then** cash turns off at once, with
   the same switch-over as scenario 3 and a blame-free note why.
5. **Given** a late cancellation or no-show during the cash trial, **Then** nothing is charged; the
   row reads "Not charged during the cash trial" and reliability still counts it (003).

---

### User Story 5 - A driver records cash and sees it apart from earnings (Priority: P2)

**Independent Test**: as a driver whose car carries a cash rider, end the trip, tap "Received 40
EGP cash", and check the Wallet's cash-received section.

**Acceptance Scenarios**:

1. **Given** a driver ends a trip that carried a cash rider who was picked up, **Then** that
   rider's row shows "Received 40 EGP cash" and "Didn't pay".
2. **Given** the driver taps either, **Then** the choice is recorded and shown as a status; the
   buttons are gone.
3. **Given** the driver's Wallet, **Then** "Cash received" shows the recorded cash total with
   "Recorded only — not withdrawable", separate from "Recovered this week", and withdrawing never
   includes it.
4. **Given** v1's driver wallet (recovered balance, Thursday payout, withdraw, trip-cost
   breakdown ending "Goora is free for drivers"), **Then** it is unchanged.

---

### Edge Cases

- A top-up, withdrawal or subscription payment fails: balance and activity unchanged, inline
  blame-free error with retry (v1 SC-005 carries over).
- The balance goes below zero after trips complete (no top-up yet): the Wallet shows the negative
  balance and the "Top up to keep riding" state; "Covers about N trips" shows 0.
- A cash rider is marked "Didn't pay" on their 10th trip: cash is over either way; one state, not
  two notes.
- Fee on a contribution not divisible by 10 (32–48 range): halves round up (45 → 5).
- A rider subscribes mid-month after paying fees: the savings banner hides once subscribed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After "Join this group", a rider without a payment arrangement (payment method,
  subscription or company plan) MUST see the payment-method screen before Today/Week; drivers MUST
  skip it.
- **FR-002**: The payment-method screen MUST offer cash ("first 10 trips") and wallet, plus a
  "Subscribe and pay no fees" link to the subscription screen.
- **FR-003**: `PricingService.riderTotal(contribution, isSubscriber, isCashTrial)` MUST return
  contribution + fee, where fee = 10% rounded half-up to whole EGP for wallet non-subscribers and 0
  for subscribers, company-plan riders and cash trips.
- **FR-004**: Every rider-facing trip price (match result, Today) MUST show
  "{c} EGP to the driver + {fee} EGP service fee", "{c} EGP · no fees (subscribed)",
  "{c} EGP · no fees (company)" (drafted, R13) or "Pay {c} EGP cash to the driver" according to
  the rider's arrangement.
- **FR-005**: On each completed trip (003's settled "kept" outcome for a rider), the wallet MUST
  debit riderTotal for wallet riders, and record a cash trip (no wallet movement) for cash riders.
- **FR-006**: Top-ups MUST credit exactly the amount (no fee).
- **FR-007**: Late-cancel and no-show charges MUST debit only the charge amount (no fee) for
  wallet riders, and MUST NOT be collected while the rider is in the cash trial.
- **FR-008**: `CashTrialPolicy` MUST allow cash for the first 10 completed cash trips, turn cash
  off at 2 "Didn't pay" marks, report trips left, and report the top-up banner once 7 cash trips
  are completed.
- **FR-009**: `FeeSavingsCalculator` MUST sum the service fees paid in a calendar month and report
  the upsell when that sum exceeds 129 EGP, for pay-per-trip riders only.
- **FR-010**: Subscribing MUST debit 129 (Monthly) or 1,290 (Yearly) from the wallet and activate
  the plan for one month or one year; insufficient balance MUST charge nothing and say how much to
  top up. Company verification MUST give a Company plan with no charge.
- **FR-011**: The rider Wallet MUST show the plan card (Pay per trip / Subscribed / Company), the
  balance card with top-up, the cash-trial counter while active, the cash top-up banner, the
  fee-savings banner, "How paying works", the activity list with each trip's fee shown separately,
  and the per-trip breakdown.
- **FR-012**: After a trip ends, driver Today MUST show "Received {c} EGP cash" / "Didn't pay" for
  each picked-up cash rider, and record the choice once.
- **FR-013**: The driver Wallet MUST show recorded cash separately from recovered earnings, as not
  withdrawable; withdrawals MUST never include it.
- **FR-014**: All money movement MUST go through `FakePaymentProvider` and the app's own ledger
  (v1 FR-013 unchanged). Drivers MUST never be charged a fee or subscription.
- **FR-015**: The pricing rule MUST exist twice (Dart and `supabase/functions/_shared`) and pass
  the same vectors (Constitution VIII / twin-implementation rule).

### Key Entities

- **PaymentMethod**: a rider's choice after joining — `cash` or `wallet`.
- **Plan** (optional): `monthly`, `yearly` or `company`; status `active` or `due` (lapsed); paid
  until a date (none for company). No trial.
- **CashMark**: a driver's record for one cash rider on one ride — `received` or `didNotPay`, with
  the amount.
- **Activity entry**: v1 kinds plus `trip` (contribution + fee, both stored), `cashTrip`,
  `subscription` and `cashReceived` (driver).

## Success Criteria *(mandatory)*

- **SC-001**: A rider goes from "Join this group" to Today in one screen and two taps.
- **SC-002**: 100% of completed wallet trips show their fee as its own figure; 40 → 44 everywhere.
- **SC-003**: Unit tests cover PricingService, CashTrialPolicy and FeeSavingsCalculator with the
  brief's numbers (40/44, 10 trips, 2 strikes, trip 8, 129), and the Dart and TS pricing rules pass
  the same vectors.
- **SC-004**: A driver never sees a fee deducted from their contribution, and cash never appears
  in their withdrawable balance.
- **SC-005**: A simulated payment failure leaves balance and activity exactly as before.

## Assumptions

- All money is simulated (`FakePaymentProvider`); no real partner integration.
- Booking enforcement ("needs a wallet balance") belongs to 005/server; this feature shows the
  state only.
- In the fakes, other people's cash status is seeded (`WalletSeed`), and the rider's own
  "Didn't pay" marks can only come from seeded data or tests — drivers are fakes.
- 005 (seat marketplace) will reuse PricingService for one-off seats (44 / 40 subscribed).
