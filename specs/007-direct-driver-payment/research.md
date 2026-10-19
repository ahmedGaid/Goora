# Research: Direct Driver Payment (007)

## R0 — Legal gate (recorded, not answered)

- **Decision**: Plan proceeds with the lawyer's answers **pending**, by the founder's choice
  (NEXT_GOAL 2026-10-18: "lawyer answer was skipped by the founder's choice").
- **Questions still open** (profit brief §10.1): CBE licence for holding riders' money; is a
  per-trip service fee allowed under Law 87/2018; is a pay-later balance for Goora's own fee fine
  without a licence.
- **Why proceeding is safe**: this feature *removes* the riskiest part (Goora holding the driver's
  share). Nothing here adds a new way to hold third-party money. The fee question is unchanged from
  004. Ship is still gated on the lawyer (brief §8), not this build.

## R1 — Share record = the existing driver mark, widened

- **Decision**: Keep `CashMark` (004) as the driver's mark on one rider's share, for **every**
  paying rider, not only cash-trial riders. Add `markedAt` and let a later mark replace an earlier
  one inside the correction window (spec FR-003). The share record itself is **derived at read
  time** from 003's ride outcomes + the marks + rider claims (the read-don't-duplicate seam, 004 R3).
- **Rationale**: 004 already has the "Received cash / Didn't pay" buttons, storage and widget tests.
  Deriving avoids a second ledger that could disagree with 003.
- **Alternatives**: a stored `ShareRecord` table written at trip end — rejected for the fakes (two
  sources of truth); revisit when a real backend lands (the server writes rows, same rules).

## R2 — Status rule (twinned)

`SharePolicy.status(mark, claim, tripEnd, now)`:

| Driver mark | Rider claim | now − tripEnd | Status |
|---|---|---|---|
| none | — | < 24 h | `pending` |
| none | — | ≥ 24 h | `autoReceived` |
| received | any | any | `received` |
| didNotPay | none | any | `notReceived` |
| didNotPay | claimed after the mark | any | `disputed` |

- Open debt = `notReceived` or `disputed`. Booking guard blocks on any open debt (FR-005).
- Driver may change a mark while `now < tripEnd + 24 h`; an `autoReceived` share may be turned
  into `didNotPay` once until `tripEnd + 7 d` (spec edge case, founder to confirm). After that,
  marks are frozen.
- A rider claim only counts when made after the latest `didNotPay` mark.

## R3 — Dispute flag (twinned)

- **Decision**: count `didNotPay` marks for a rider whose trip end falls in the last 30 days
  (rolling, by demo clock date); ≥ 2 → flagged. A share later marked `received` does not count.
- **Rationale**: profit brief "two disputes in 30 days"; counting the driver's mark (not the rider's
  claim) means a rider can't avoid the flag by not answering.

## R4 — Fee under direct pay (twinned)

- **Decision**: `DirectPay.fee(contribution, share, tripCost, riderSeats, feeFree)`
  = 0 if feeFree; else `min(PricingService.serviceFee(contribution, …, false, false), equalShare − share)`,
  floored at 0. `share` is what the rider actually hands the driver: the 5-EGP cash amount when the
  method is cash and one fits (FR-029, 005), otherwise the exact contribution.
- **Rationale**: cash rounding up (44 → 45) must not push contribution + fee over the cap. Taking
  10% of the *contribution* keeps the demo at 40 → 4.
- **Invariant**: share + fee ≤ ⌊tripCost ÷ riderSeats⌋ for every allowed price, so riders' total ≤
  trip cost (Constitution II). A sweep test like 004 R17 proves it.

## R5 — Where the fee goes (pre-008)

- **Decision**: the fee is a debit on the rider's Goora ledger at trip completion (group trips,
  read-time) or at booking (marketplace seat, as today, but fee only). A negative balance **is** the
  "fee owed" (FR-009). No provider call: it is an internal ledger line, so a fee can't "fail".
- **Rationale**: 008 (pay later) turns the negative balance into the settle/overdue flow; this keeps
  the seam. Top-up stays available (it pays Goora's own money), but copy stops linking it to trips.
- **Consequence**: `BookingGate.topUp` goes away; 005's "payment fails while booking" path no longer
  exists for seats (tests updated, not deleted silently).

## R6 — Fee-free trial replaces the cash trial

- **Decision**: `CashTrialPolicy` keeps its numbers (5 trips, 2 strikes, banner from trip 4) but
  applies to **every** new rider regardless of method: trial = no Goora fee. A `didNotPay` mark still
  counts as a strike (ends the trial). Founder to confirm (profit brief §3).
- `PricingMode` becomes `trial | perTrip | subscribed | company`; `PaymentMethod` becomes
  `cash | instapay` (how the rider pays the *driver*). A stored legacy `wallet` value reads as `cash`.

## R7 — InstaPay handle

- **Decision**: drivers get an optional `instapayHandle` (string, ≤ 40 chars, trimmed) in the wallet
  fakes. Shown to a rider only for a confirmed booking / their own group's driver, with a copy button.
  No deep link, no validation beyond length (no real integration).

## R8 — Driver wallet

- **Decision**: drop `_creditOneOffIncome` and the seeded `tripIncome`/`feeReceived` rows for new
  installs; the driver wallet shows a **payments list** derived from share records (received /
  pending / not received / disputed) and the existing withdrawable balance only for legacy rows.
  `cashReceived` becomes "received directly this month".

## R9 — One ride, one charge

- **Decision**: the derived share list dedupes by `(rideId, riderId)`, using the same
  `paidAtBooking`/`cashOneOffs` precedence 005 R10 uses, so a seat booked then folded into a group
  yields one share.

## R10 — Migrations

- **Decision**: none in this feature. 004/005 had no wallet tables; the server side stays the twin
  rules + vectors. A `share_marks` table is listed for the backend feature.

## Addenda from implementation (2026-10-19)

- **R4a — fee base is untrimmed.** `PricingService.serviceFee` already trims against the
  contribution, so `DirectPay.fee` takes the plain 10% (half up) and trims only against the share
  actually paid. Cash 38 → 35 in a 160/4 car pays 35 + 4 = 39 ≤ 40; InstaPay 38 pays 38 + 2.
  Sweep test (`direct_pay_cap_sweep_test.dart`): every allowed price, both methods, cap holds.
- **R6a — 004 wallet riders keep out of the trial.** A stored legacy `wallet` method (or the
  `wallet.noTrial.<id>` flag set when such a rider picks a new method) means the rider already
  gave up the cash trial in 004, so they pay the fee from trip 1 and see no trial card.
- **R5a — refunds are Goora's fee only.** A cancelled or reclaimed seat refunds what Goora took
  (the fee); a late-cancel share is the driver's, paid directly. 005 rows that still hold the
  share keep the old "owed is kept back" rule.
- **R7a — seeded InstaPay handle.** `WalletSeed.instapayHandles` gives Ahmed a handle so a rider
  sees one to copy in the demo; a driver's own saved handle wins.
- **R8a — seeded mark still shows.** A driver's mark on a ride neither side knows (the seeded
  Youssef share) is listed in the driver's payments with its seeded first name.
- **Seam added:** `WalletRepository.driverShareOn(rideId, riderId)` for the driver Today row;
  `riderPayMethodProvider` so price lines read cash vs InstaPay.
- **Not built here:** quickstart device walkthrough (no emulator run this session); support
  tooling for flagged riders; real InstaPay link.
