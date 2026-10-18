# Feature Specification: Direct Driver Payment

**Feature Branch**: `007-direct-driver-payment`

**Created**: 2026-10-18

**Status**: Draft

**Input**: User description: "Direct driver payment — profit change 1 (`GOORA_PROFIT_CHANGES.md` §1,
with §8 for the fee-balance seam). The rider pays the driver's cost share to the driver directly
(cash or InstaPay, outside Goora). Goora's wallet holds only Goora's own money: subscriptions,
bundles and its service fee. The driver confirms receipt after each trip; an unpaid share blocks
the rider from booking until resolved."

**Sources of truth**: `GOORA_PROFIT_CHANGES.md` §1, §8, §9, §10 (profit-change brief, untracked at
repo root) · `GOORA_SPEC_KIT_BRIEF.md` §6.7 · specs `004-wallet-subscription` and
`005-seat-marketplace` (money flow being changed). Copy not in the brief is drafted (founder
review before ship).

**Carried over, decided, not re-asked**: 40 EGP contribution per rider per leg; late cancel owes
half the share (20), no-show the full share (40), both to the driver with no Goora fee; the fee
sits inside the Constitution II cap (004 v2.1); subscribers pay 0 fee (profit brief §9); drivers
pay nothing, ever; subscription 149/1,490 (profit change 2, merged); cash trial is 5 trips
(profit change 3, merged); fakes-first backend; Dart and TypeScript twin rules with shared vectors.

## Clarifications

### Session 2026-10-18 (decided by the implementer from the profit brief, founder to confirm)

- Q: How does the rider choose between cash and InstaPay? → A: A per-rider default ("Pay the
  driver by": cash / InstaPay) set at first booking and changeable in Settings. It is a label and
  a hint for the driver ("rider will pay by InstaPay"), not a Goora-processed payment. Goora never
  sees a transfer, an account number of the rider, or a receipt.
- Q: How does a rider pay a driver by InstaPay? → A: The driver may add an InstaPay handle to their
  profile. It is shown to a booked rider only after the booking is confirmed (privacy, Constitution
  IV). If the driver has none, only cash is offered for that driver.
- Q: What does the 24-hour default do? → A: If the driver gives no answer for a rider within 24
  hours of the trip's end, the share counts as received and the rider owes nothing.
- Q: Can a rider contest "ماستلمتش"? → A: Yes. The rider can tap "دفعت" (I paid). The dispute then
  shows on both sides, the rider stays blocked only for a share the driver still disputes, and it
  counts toward the two-in-30-days review flag. Goora does not judge it; support reviews flagged
  riders (no support tooling in this feature).
- Q: What does the cash trial mean now? → A: The first 5 trips carry **no Goora service fee and
  need no payment method**. The driver's share is always direct. Founder to confirm (profit brief §3).
- Q: What happens to existing wallet balances? → A: Riders keep a balance and may withdraw it, as
  today. No new trip-share top-up exists. A non-zero balance can still pay Goora's own money
  (service fee, subscription). Nothing else is migrated.
- Q: How is the 4 EGP fee collected before the pay-later spec (profit change 8) exists? → A: This
  spec records it as a **fee owed** line on the rider's account, taken from wallet balance when one
  exists, otherwise left as owed. The balance screen, settlement, overdue block and bundle belong to
  the next spec (008). Until then an owed fee never blocks a booking.

### Open — recorded, not decided here (founder)

- Lawyer answers (CBE licence for holding money, Law 87/2018 per-trip fee, pay-later balance) were
  skipped by the founder's choice. Record in `research.md` that the answers are pending, then plan.
- Whether a driver can be reported as habitually marking riders unpaid (abuse by drivers). Out of
  scope here; the two-disputes rule flags riders only. Flagged for the dispute spec.
- Real InstaPay deep link. This feature only shows the driver's handle for copy; no link out.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A rider pays the driver directly and Goora takes only its own fee (Priority: P1)

A rider books or rides a trip. The price shown is "40 ج للسواق" (to the driver, paid directly by
cash or InstaPay) plus, for a non-subscriber after the cash trial, "+ 4 ج رسوم خدمة لـ Goora". The
trip's 40 EGP never enters the Goora wallet and is never shown as Goora money anywhere.

**Why this priority**: it is the whole point of the change. Without it the gateway fee on the
driver's share keeps eating about half of Goora's revenue, and Goora keeps holding money that may
need a licence.

**Independent Test**: Book and complete a trip as a non-subscriber after the cash trial. The wallet
shows no movement of 40; the activity shows a 4 EGP fee line; the driver's side shows "40 ج من
<rider first name>, بالكاش" as a receivable status, not a wallet credit.

**Acceptance Scenarios**:

1. **Given** a non-subscriber past the cash trial, **When** they complete a 40 EGP trip, **Then**
   exactly 4 EGP is recorded as owed to Goora, and no wallet balance moves by 40.
2. **Given** a subscriber, **When** they complete the same trip, **Then** Goora's fee is 0 and the
   trip's 40 EGP is still direct.
3. **Given** a rider in the cash trial (first 5 trips), **When** they complete a trip, **Then**
   there is no Goora fee at all and no payment method is required.
4. **Given** any price shown (match result, Today, booking, confirmation), **When** the screen is
   rendered in ar or en, **Then** it says the 40 goes to the driver directly and never says
   "charged to your wallet".
5. **Given** a trip whose fee is trimmed by the cap (a full 4-seat car at the top of the range),
   **When** completed, **Then** the trimmed fee (for example 2) is recorded, and the sum of what
   riders pay the driver plus Goora's fees never exceeds the trip cost.

---

### User Story 2 - The driver confirms receipt after each trip (Priority: P1)

After a trip ends, the driver sees each rider with two buttons, "استلمت" and "ماستلمتش". The driver
may leave it. After 24 hours with no answer the share counts as received.

**Why this priority**: this replaces the wallet as the proof of payment. Without it nothing says a
rider paid.

**Independent Test**: End a trip as a driver; tap "استلمت" for one rider and "ماستلمتش" for another;
confirm each rider's status and that a third rider left unanswered becomes "received" after the
demo clock passes 24 hours.

**Acceptance Scenarios**:

1. **Given** a finished trip with three riders, **When** the driver taps "استلمت" for a rider,
   **Then** that share is settled and the rider sees no debt.
2. **Given** the same trip, **When** the driver taps "ماستلمتش" for another rider, **Then** that
   rider sees "عليك 40 ج.م لـ <driver first name>" and a pay-and-tell action.
3. **Given** a rider the driver did not answer for, **When** 24 hours pass, **Then** the share is
   marked received automatically and shows as auto-confirmed.
4. **Given** the driver already answered, **When** they tap the other button, **Then** the answer
   changes (a driver can correct a mistake until the 24 hours end) and the change is logged.
5. **Given** a trip with a late cancel (20) or a no-show (40), **When** the driver confirms, **Then**
   the same two buttons apply with the amount owed, and Goora takes no fee on it (004).

---

### User Story 3 - An unpaid share blocks the rider from booking until resolved (Priority: P1)

A rider whose share the driver marked "ماستلمتش" sees the debt on Today and in Wallet. They cannot
book a seat, join a group or offer-accept a trip until the driver confirms, or until the rider
disputes with "دفعت" and the driver reverses the answer.

**Why this priority**: it is the only protection drivers get now that Goora does not hold the money.

**Independent Test**: As a rider, get a "ماستلمتش" mark, try to book (blocked with the debt line),
then have the driver tap "استلمت" and book again (works).

**Acceptance Scenarios**:

1. **Given** a rider with an open "ماستلمتش", **When** they try to book a seat or join a group,
   **Then** the action is refused with "عليك X ج.م لـ <driver first name>" and no other change.
2. **Given** that rider, **When** the driver later taps "استلمت", **Then** the block lifts at once
   and the rider is told so.
3. **Given** a rider who taps "دفعت", **When** the driver has not answered again, **Then** the
   dispute shows to the driver, the rider stays blocked, and the dispute is counted.
4. **Given** a rider with two disputes in 30 days, **When** the second one is recorded, **Then** the
   rider is flagged for review (a visible internal state; no automatic ban) and sees neutral copy.
5. **Given** a rider with several open shares to different drivers, **When** all are cleared,
   **Then** only then can they book; one cleared share does not unblock the others.

---

### User Story 4 - The wallet holds only Goora's money (Priority: P2)

The rider wallet screen stops describing trip money. It shows the plan, the subscription, any fee
owed to Goora, and the existing balance (withdrawable). The driver wallet stops showing "cash
received" as wallet money and instead shows a payments-received list with confirmation statuses.

**Why this priority**: it removes the licence risk in the product's own words, but only matters
once US1–US3 stop moving money through the wallet.

**Independent Test**: Open the rider and driver wallet screens after a trip; verify no line states
that Goora holds or moved the driver's share.

**Acceptance Scenarios**:

1. **Given** a rider wallet, **When** it is opened, **Then** the "How paying works" list explains
   direct payment to the driver and Goora's separate fee, and the top-up is no longer offered for
   trip shares.
2. **Given** a rider with a balance from before this change, **When** they open Wallet, **Then**
   they can withdraw it and it can pay subscription or Goora fees, nothing else.
3. **Given** a driver wallet, **When** opened, **Then** it lists received/pending/disputed shares per
   trip and shows no "balance" the driver can withdraw from Goora.

---

### User Story 5 - The marketplace, one-off and group flows all use the new flow (Priority: P2)

The seat marketplace (005), one-off trips (003) and group commute billing all stop debiting the
wallet for the driver's share, and keep "one ride, one charge" so a rider never owes a share twice.

**Why this priority**: it finishes the change across the app; US1–US3 define the rules, this makes
every entry point obey them.

**Independent Test**: Book a marketplace seat, a one-off trip and run a group day; each yields one
share record per rider per ride and no wallet movement for the share.

**Acceptance Scenarios**:

1. **Given** a rider who booked a marketplace seat and then joins that car's group, **When** the day
   runs, **Then** one share record exists for that ride (not two).
2. **Given** a cancelled booking before the free-cancel deadline, **When** it is cancelled, **Then**
   no share record exists and any fee is not owed.
3. **Given** a failure while booking, **When** the rider retries, **Then** the state is exactly as
   before (blame-free error, no half records).

---

### Edge Cases

- The driver marks "ماستلمتش" and then the trip is disputed after the 24 hours: the answer can still
  change by the driver; the auto-received state is reversible only by a driver action, once, for
  7 days (proposed; founder to confirm).
- The rider is also a driver on another trip that day: their own receipts and debts are separate.
- Two riders share one account on one phone: not supported (one person, one account).
- A driver with no InstaPay handle: rider sees "كاش فقط" for that driver.
- A rider with an open share and an active subscription: still blocked; subscription does not buy
  out an unpaid share.
- Demo clock jumps over 24 h: the auto-receive runs once per share, never twice.
- A trip with zero riders paying (everyone in cash trial, fee 0): no fee lines at all.
- A balance withdrawal while a fee is owed: the owed fee is taken first, never negative.
- Provider/transfer failures: none exist here, because Goora does not process the driver payment.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The driver's cost share MUST NOT pass through, be held in, or be recorded as a
  movement of the Goora wallet. It is recorded only as a **share record** with a status.
- **FR-002**: Each completed ride with a paying rider MUST create exactly one share record per rider
  per ride with: amount, rider, driver, ride id, method label (cash / InstaPay), and status
  (pending, received, auto-received, disputed, rider-claimed-paid).
- **FR-003**: The driver MUST be able to mark each rider "استلمت" or "ماستلمتش" after a trip, and
  correct it until the correction window ends (24 h after the trip; 7 days to reverse an
  auto-received share, proposed).
- **FR-004**: With no driver answer for 24 hours after the trip ends, the share MUST become
  auto-received.
- **FR-005**: A rider with any open "ماستلمتش" share MUST NOT book a seat, join a group or accept a
  match until it is resolved. The refusal MUST name the amount and the driver's first name.
- **FR-006**: A rider MUST be able to tap "دفعت" on an open share; this records a counter-claim
  visible to the driver and counts as a dispute.
- **FR-007**: Two disputes (driver "ماستلمتش" followed by rider "دفعت", or a driver's mark that
  stays open) for one rider in any 30-day window MUST flag the rider for review. The flag is
  recorded and visible to internal tooling; it MUST NOT auto-ban.
- **FR-008**: Goora's service fee MUST be recorded as a **fee owed** line on the rider, 4 EGP for
  a non-subscriber past the cash trial (trimmed by the 004 cap rule when needed), 0 for subscribers,
  0 during the cash trial. It MUST NOT be added to the driver's share.
- **FR-009**: The fee owed MUST be taken from an existing wallet balance when one covers it;
  otherwise it stays owed. Collecting an owed fee and blocking on it belong to the pay-later spec.
- **FR-010**: The Constitution II invariants MUST hold on the share records and fee lines:
  riders' total (shares plus fees) ≤ trip cost; each contribution within ±20% of the suggested
  price; no bidding; at most 2 offered trips per driver per day. They MUST run on the recorded
  shares, not on wallet movements.
- **FR-011**: Late-cancel (half share) and no-show (full share) amounts MUST be share records to
  the driver with no Goora fee, confirmed by the same two buttons.
- **FR-012**: The wallet MUST NOT offer a top-up to pay trip shares. An existing balance MUST stay
  withdrawable and MAY pay Goora's own money only.
- **FR-013**: The rider MUST choose a pay-the-driver method (cash / InstaPay) once; the driver's
  InstaPay handle MUST be shown only after the booking is confirmed (Constitution IV), copyable,
  never opened as a transfer by Goora.
- **FR-014**: All price lines (match result, Today, booking, confirmation, wallet, activity) MUST
  say the share goes to the driver directly and the fee is Goora's, in ar and en, via ARB, with no
  hard-coded strings or colors and directional layout only.
- **FR-015**: The Dart rules (share status transitions, fee for a trip, the 24-hour rule, the
  booking guard, the two-in-30-days flag) MUST have TypeScript twins in
  `supabase/functions/_shared/` with shared vectors that both run.
- **FR-016**: The "one ride, one charge" dedupe (005) MUST apply to share records: a ride yields
  one share record per rider even if reached by booking and by group membership.
- **FR-017**: The driver Today MUST keep an "unconfirmed payments" prompt until each share is
  answered or auto-received, and never ask twice for the same share once answered.
- **FR-018**: Data shown to the other party MUST be limited to first name and amount (privacy);
  Goora MUST NOT store the rider's or the driver's payment account numbers except the driver's
  optional InstaPay handle.

### Key Entities

- **Share record**: one rider's cost share for one ride, paid to the driver outside Goora. Has
  amount, method label, status, history of status changes with who and when.
- **Fee owed**: Goora's service fee for one ride and one rider. Has amount, ride, state (owed, taken
  from balance). Never mixed with a share record.
- **Dispute flag**: a count of disputed shares per rider in a rolling 30 days, plus the review state.
- **Pay-method preference**: a rider's default label (cash / InstaPay) and a driver's optional
  InstaPay handle.
- **Wallet (rider/driver)**: Goora's own money view only (balance from before, fees, subscription).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of completed rides, the wallet balance change caused by a trip equals the
  fee (0 or ≤ 4 EGP) and never includes the driver's share.
- **SC-002**: A driver can confirm all riders of a trip in under 15 seconds on one screen.
- **SC-003**: A rider with an unpaid share is blocked in 100% of booking attempts and unblocked
  within one screen refresh after the driver confirms.
- **SC-004**: Zero screens in ar or en state or imply that Goora holds, receives or moves the
  driver's share.
- **SC-005**: Riders' total (shares plus fees) never exceeds the trip cost across the shared vectors
  and the property tests, in Dart and in TypeScript.
- **SC-006**: Payment-provider costs on a trip drop from about half of Goora's revenue to the
  subscription gateway fee only (measured by the model, not by the app).

## Assumptions

- The Goora wallet stays for Goora's own money and for the balances riders already have.
- Fakes first: no real InstaPay, no real push; the demo clock drives the 24 h and 30-day rules.
- Support and review tooling for flagged riders is not built here; the flag is data.
- The fee balance screen, settlement, overdue block and 20-trip bundle are the next spec (008).
- A real company plan (006) later waives fees and does not change this flow.
- A driver is trusted to answer honestly; the abuse path is recorded as open, not solved here.
