# Data Model: 013 live parity

New objects (all in new migrations; no applied migration is edited).

## Tables
- `plan_cover_windows (person_id, from_wall, to_wall)` — what an ended company plan made fee-free (010 R8); select own, writes by `wallet_end_company_plan()` only.
- `corridor_legs (origin_area, destination_area, km)` — config for the CO₂ estimate (D11); RLS on,
  select for `authenticated`; seeded in the migration: Cairo↔Ismailia 123, Sheikh Zayed↔Smart
  Village 13 (010 R7, estimates).

## Functions

All `security definer`, `set search_path = public`, `execute` to `authenticated` unless noted. The
caller's identity is `auth.uid()`, never a parameter.

| Function | Returns | Rule source |
|---|---|---|
| `pay_equal_share(cost, seats)` / `pay_cash_amount(contribution, cost, seats)` | int / int or null | `PricingService` |
| `direct_pay_share(contribution, method, cost, seats)` / `direct_pay_fee(contribution, share, cost, seats, fee_free)` | int | `DirectPay` |
| `is_late(date, at timestamptz)` | bool | `AttendanceRules.isLate` |
| `fee_due_date(days jsonb, today date)` | date or null | `FeeBalancePolicy.dueDate` |
| `wallet_state()` | jsonb (D2) | 004 R8, 007 R5/R6, 008 |
| `wallet_assert_open()` | void, or `refused:feeOverdue:<owed>` | 008 FR-005 |
| `wallet_share_rows(p_role)` | rows (ride, other first name, method, amount, outcome, claimed, trip end) | 007, D7 |
| `market_offer_cards()` | open offers + driver first name/rating | D6 |
| `market_requests_for(p_leg)` | posted requests of others + rider `is_woman` | D8 |
| `market_done_one_offs()` | finished seats of the caller + first names | D8 |
| `market_reclaim(p_booking)` | refund int; refuses `notReclaimable` / `reclaimTooLate` | D9 |
| `company_suspensions(p_company)` | `{approvedAt, endedAt, invoices: [{dueOn, paidAt}]}` | D11 |
| `company_dashboard(p_company, p_month)` (replaced) | adds moneySaved, co2Kg, parkingPerDay, routeGaps | D11 |
| `company_reset_mine()` | void | D12 |
| `staff_company_approve`, `staff_invoice_mark_paid`, `staff_company_set_hr`, `staff_company_end` | void; `service_role` only | D12 |
| `market_book/post/accept` (replaced) | + `perform wallet_assert_open()` | D5 |

## Edge function
`commute-day`: actions `ride` and `noCover` (D10).

## Unchanged invariants
Whole EGP; no income kind; every table keeps RLS; profiles owner-only; k = 5.
