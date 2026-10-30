# Contract: server functions (SQL, `security definer`, `set search_path = public`)

All are granted to `authenticated` only (never `anon`), check `auth.uid()` first, and refuse with
`raise exception 'refused:<reason>' using errcode = 'P0001'`. Money in whole EGP.

## Commute (20261030000100)

| Function | Returns | Checks |
|---|---|---|
| `groups_for(p_origin text, p_destination text)` | jsonb list of groups `{id, origin, destination, going, ret, days, price, detourMinutes, womenOnly, sameCompanyOnly, sameCompoundOnly, pickupPoints[{id,label,lat,lng,time}], members[{id, firstName (drivers only, '' for riders), initials (drivers only), role, legs, isWoman, rating, reliability, seats}]}` | no home point, no rider name |
| `join_group(p_group uuid, p_role text, p_legs text[], p_seats int)` | void | group exists (`noSuchGroup`) |
| `join_waitlist(p_origin text, p_destination text)` | int position | — |

## Trust (20261030000100)

| Function | Effect |
|---|---|
| `submit_rider_id()` | `rider_id_status = 'verified'` (fake-equivalent; a real check may set `pending`) |
| `start_driver_verification()` | `driver_docs = 'pending'` |

## Wallet (20261030000200)

| Function | Effect / refusal |
|---|---|
| `wallet_top_up(p_method text, p_amount int)` | +amount `topUp` entry; amount > 0. Trusts the fake payment result until 012 adds the payment webhook — hosted deploy stays blocked until then |
| `wallet_withdraw(p_amount int)` | −amount `withdrawal`; `refused:insufficient` when amount > balance |
| `wallet_subscribe(p_type text, p_price int)` | monthly/yearly: `refused:needsTopUp` when balance < price, else −price `subscription` + plan row; company: plan row, no entry |
| `wallet_change_plan(p_type text, p_price int)` | plan type/price change from next billing date |
| `wallet_settle(p_method text)` | one `settlement` entry = what is owed (−balance when < 0); nothing owed → no row |
| `wallet_buy_bundle(p_method text)` | one `bundles` row (20 trips, 75 EGP) + `bundle` entry of 0 on the balance (paid outside it) |
| `wallet_seat_debit(p_booking text, p_ride text, p_fee int, p_date date)` | one `seatBooked` entry per booking (idempotent) |
| `wallet_seat_refund(p_booking text, p_ride text, p_amount int, p_date date)` | one `seatRefund` entry per booking; 0 → none |
| `wallet_mark_share(p_ride text, p_rider uuid, p_outcome text, p_amount int, p_date date)` | caller = the ride's driver; first answer wins, one reversal allowed (007 R2) |
| `wallet_claim_paid(p_ride text)` | caller's claim on a `didNotPay` mark |
| `payment_method_of(p_rider uuid)` / `instapay_handle_of(p_driver uuid)` | read-only, shared-ride check |

Plan prices: `p_price` comes from the device's `PlanType` price (the brief's numbers) and is
checked against `plan_prices` (a two-row config table seeded with the same numbers) so a client
can't subscribe for less.

## Company (20261030000300)

| Function | Effect / refusal |
|---|---|
| `company_register(p_name, p_domains text[], p_hr_work_email)` | pending company + domains + HR contact; `domainTaken:<d>`, `emailNotOnDomain` |
| `company_for_domain(p_domain)` | `{id, name, status}` or null |
| `company_enroll()` | open enrollment for caller's verified work email; `notEligible` |
| `company_leave()` | close caller's open enrollment (`self`) |
| `company_remove_employee(p_company, p_work_email)` | HR only (`notHrContact`); `removedByHr` |
| `company_add_domain` / `company_remove_domain(p_company, p_domain)` | HR only; removing closes matching enrollments (`domainRemoved`) |
| `company_set_consent(p_on bool)` | caller's `hr_consents` row |
| `company_dashboard(p_company, p_month)` | jsonb counts; any count over < 5 people → null; HR only |
| `company_statement(p_company, p_month)` | rows `{name, date, leg, sharePaid}` for consented employees only; HR only |

## Marketplace (20261030000400)

| Function | Effect / refusal |
|---|---|
| `market_publish(p_leg, p_origin, p_destination, p_date, p_departure, p_seats, p_trip_cost, p_contribution, p_repeat, p_pickup jsonb)` | offered trip; `overLimit` at 2 trips that day; cost cap by CHECK |
| `market_post(...)` | trip request; `dailyNotAllowed` when the caller is in a group and repeat = daily |
| `market_cancel_request(p_request)` | owner, posted only |
| `market_book(p_offer, p_leg, p_date, p_contribution, p_fee, p_paid_by)` | locks the offer, `seatTaken` when full, `alreadyRiding` on the unique key; writes the booking and its `seatBooked` entry in one transaction |
| `market_cancel_booking(p_booking)` | rider's own, booked only; refund entry; `notCancellable` |
| `market_cancel_offer(p_trip)` | driver's own; every booking refunded |
| `market_accept(p_request)` | driver; creates the offered trip from the request (2/day cap) |
| `market_reclaim(p_booking)` | subscriber of the group takes the seat; `tooLate` after 21:00 Cairo the day before; `notReclaimable` |
