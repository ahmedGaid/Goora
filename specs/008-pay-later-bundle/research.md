# Research: Pay Later and Trip Bundle (008)

## R0 — Legal
Pending by the founder's choice (profit brief §10.1: pay-later balance for Goora's own fee).
The balance is a small debt to Goora for its own fee, not money held for drivers.

## R1 — The balance is 007's ledger
- **Decision**: no new store for "owed". Owed = max(0, −balance) of the Goora ledger 007 already
  keeps (top-ups, fees, subscriptions, refunds). Settlement is a new `settlement` activity row
  (+amount). Rationale: one money source; 007 FR-009 already reads a negative balance as owed.

## R2 — Due / overdue rule (twinned)
Input: the rider's ledger as end-of-day balances, ascending by day, and today.
1. The unpaid run starts the first day after the last day the balance was ≥ 0 (or the first day).
2. `due150` = first day in the run with owed ≥ 150.
3. `dueMonth` = for each month end after the run starts, in order: if owed at that month end ≥ 30
   → the 1st of the next month; else carry over.
4. due = the earlier of the two; null when owed today is 0.
5. overdue ⇔ due ≠ null and today − due ≥ 3 days.
Month boundaries need calendar months, so the twin takes ISO dates (`yyyy-mm-dd`).

## R3 — Bundle use (twinned)
`useBundle(fee, tripsLeft)` ⇔ fee > 0 ∧ tripsLeft > 0. A used trip records no fee owed and a
`bundleTrip` entry. Trips left = purchases × 20 − trips used (derived, never a stored counter).

## R4 — Bundle purchase and settlement go through the provider
`PaymentProvider.debit(amount)` (existing fake) is the one transaction; failure → nothing written.
A bundle purchase writes a `bundle` row with amount 75 and **no balance delta**.

## R5 — Gate
`BookingGate.check` gains `feeOverdue` (owed amount when overdue, else 0). Order: owes driver →
fee overdue → needs method → ok.

## R6 — Nudge copy
`feeSavings` becomes the brief §8 sentence (149, guaranteed seat, backup driver).
