# Contract: server functions added by 013

Refusals: `raise exception 'refused:<reason>[:<detail>]' using errcode = 'P0001'` (011 D7); the
device maps them to the seam's existing result types.

## wallet_state() → jsonb
```
{trialOn, trialDone, strikes, debits, bundleLeft, feeDue ('YYYY-MM-DD' | null), feeOverdue,
 feesThisMonth, entries: [{id, kind, amount, fee, date, rideId, shareToDriver, leg}]}
```
`debits` = Σ fee of `trip` entries. Trial: the first 5 completed trips and fewer than 2 `didNotPay`
marks; none for a rider who is plan- or company-covered, or forfeited it (`no_trial`).

## wallet_assert_open() → void
Raises `refused:feeOverdue:<owed>` when `feeOverdue`.

## wallet_share_rows(p_role text) → rows
`p_role` is `rider` or `driver`. Columns: `ride_id, rider_id, driver_id, other_first_name, method,
amount, trip_end, outcome ('received' | 'didNotPay' | null), claimed, reversed_once`. The other
party's first name only.

## market_offer_cards() → rows
`offered_trips` columns + `driver_first_name, driver_initials, driver_rating`.

## market_requests_for(p_leg text) → rows
`trip_requests` columns + `rider_is_woman`; excludes the caller's own and non-posted requests.

## market_done_one_offs() → rows
`ride_id, trip_date, leg, paid_by, contribution, trip_cost, rider_seats, rider_id, driver_id,
rider_first_name, driver_first_name, trip_end`; only rows where the caller is rider or driver.

## market_reclaim(p_booking uuid) → int
Refund (0 for a cash seat). Refuses `notReclaimable`, `reclaimTooLate`.

## company_suspensions(p_company uuid) → jsonb `{approvedAt, endedAt, invoices: [{dueOn, paidAt | null}]}`
HR contact or enrolled employee of the company; else `refused:notHrContact`.

## company_dashboard(p_company, p_month) → jsonb (replaced)
Existing keys + `moneySaved, co2Kg, parkingPerDay` (int or null) and `routeGaps: [{area, count}]`.

## company_reset_mine() → void
Deletes only rows the caller owns.

## staff_* (service_role only)
`staff_company_approve(p_company)`, `staff_invoice_mark_paid(p_invoice, p_bank_ref)`,
`staff_company_set_hr(p_company, p_person)`, `staff_company_end(p_company)`.

## commute-day (Edge) — new actions
`{action:'ride', date, leg}` → `{rideId}`; `{action:'noCover', date, leg}` → `{}`; refusals as 409
`{refused}`.
