# Data Model: Real Backend (011)

Money is whole EGP `integer` everywhere (research D8). Times are `timestamptz`; dates `date`
(Cairo calendar day). Every table has RLS on; "server" = written only by `security definer`
functions or the service role. `auth.uid()` = the signed-in person.

## Migration order

| File | Holds |
|---|---|
| `20261030000000_fixes.sql` | D17: API grants for the 002/003/005 tables, nine areas, cost-cap CHECK |
| `20261030000100_profile_trust.sql` | profile extras + trust statuses, privacy trigger, group functions |
| `20261030000200_wallet.sql` | plans, paused plans, payment settings, ledger, share marks/claims, bundles, `wallet_*` functions |
| `20261030000300_company.sql` | companies … hr consents, roster view, dashboard/statement functions |
| `20261030000400_marketplace_rpc.sql` | `market_*` functions on the 005 tables |

## Profile and trust (`profiles` — 002 table, extended)

| Column | Type | Notes / who writes |
|---|---|---|
| `phone` | text, E.164 check | owner (set once at sign-up) |
| `rider_id_status` | text `notVerified`/`pending`/`verified`, default `notVerified` | server (`submit_rider_id`) |
| `driver_docs` | text `notNeeded`/`pending`/`verified`, default `notNeeded` | server (`start_driver_verification`) |
| `work_email` | text, nullable | server (work-email verification, later) |
| `work_email_verified` | boolean default false | server |
| `privacy_preference` | (003) | owner; trigger `profiles_privacy_available` keeps it available |
| `rating`, `reliability` | (002) | server; column grant revoked from `authenticated` |

RLS (002, unchanged): `own profile` for all. Column grants: `authenticated` may insert/update only
`first_name, last_name, gender, role, frequency, company, compound, phone, privacy_preference,
women_only_pref, same_company_only_pref, same_compound_only_pref`.

Trusted contacts and SOS alerts: 003 tables, unchanged (owner-only).

## Wallet

| Table | Key | Columns | RLS |
|---|---|---|---|
| `plans` | `person_id` | `type` (`monthly`/`yearly`/`company`), `status` (`active`/`due`), `price` ≥ 0, `start_at`, `until_date` | owner select; server write |
| `paused_plans` | `person_id` | `type`, `price`, `days_left` ≥ 0 | owner select; server write |
| `payment_settings` | `person_id` | `method` (`cash`/`instapay`), `instapay_handle` (≤ 40, trimmed, null when empty), `since_date`, `no_trial` bool, `no_trial_from` | owner all |
| `wallet_entries` | `id` | `person_id`, `kind` (D9 list), `amount` (signed), `fee` ≥ 0, `ride_id`, `leg`, `booking_id` unique-when-set per kind, `entry_date`, `created_at` | owner select; server insert |
| `share_marks` | (`ride_id`, `rider_id`) | `driver_id`, `outcome` (`received`/`didNotPay`), `amount` ≥ 0 (the share shown, never credited), `ride_date`, `marked_at`, `reversed_once` | driver all on own marks (via `wallet_mark_share`); rider select own |
| `share_claims` | (`ride_id`, `rider_id`) | `claimed_at` | rider insert/select own; driver select claims on their marks |
| `bundles` | `id` | `person_id`, `trips` = 20, `price` = 75, `bought_at` | owner select; server insert |
| `wallet_balances` (view) | — | `person_id`, `balance` = sum(`amount`) | `security_invoker` → owner only |

No driver-income kind, column or function (D9). `methodOf(other rider)` and `instapayHandleOf(driver)`
read through `payment_method_of(rider)` / `instapay_handle_of(driver)` (definer; the first only for
a driver who shares a ride with that rider, the second for anyone who shares a ride with that driver).

## Company network (010 R9)

| Table | Key | Columns | RLS |
|---|---|---|---|
| `companies` | `id` | `name`, `status` (`pending`/`active`/`suspended`/`ended`), `hr_contact_id`, `contract_start`, `contract_end`, `minimum_seats` = 20, `price_per_seat`, `approved_at`, `ended_at` | HR contact select; server write |
| `company_domains` | `domain` (unique, lower) | `company_id` | HR contact select; anyone signed in: only via `company_for_domain(d)` |
| `enrollments` | `id` | `company_id`, `person_id`, `name`, `work_email`, `enrolled_at`, `left_at`, `left_why` (`self`/`removedByHr`/`domainRemoved`/`contractEnded`) | employee select own; server write |
| `invoices` | `id` | `company_id`, `month` (`YYYY-MM`, unique per company), `peak_enrolled`, `billed_seats`, `price_per_seat`, `total`, `issued_on`, `due_on`, `reference`, `paid_at`, `bank_ref` | HR contact select; server write |
| `company_log` | `id` | `company_id`, `at`, `actor` (`hr`/`employee`/`goora`), `kind` (LogKind names), `detail` | HR contact select; server insert |
| `hr_consents` | `person_id` | `on` bool, `changed_at` | owner select/insert/update |
| `company_roster` (view) | — | `company_id`, `name`, `work_email`, `enrolled_at`, `left_at` — 4 roster columns + the company | HR contact of that company only |

Functions: `company_register`, `company_for_domain`, `company_enroll`, `company_leave`,
`company_remove_employee`, `company_add_domain`, `company_remove_domain`, `company_set_consent`,
`company_dashboard(company, month)` (k = 5), `company_statement(company, month)` (consented only).

## Marketplace (005 tables; functions only)

`offered_trips`, `trip_requests`, `bookings` and the `driver_request_cards` view are unchanged
except the cost-cap CHECK and the nine areas (D17). New: `market_*` functions (D16).

## Commute (002 tables; functions only)

`groups_for(origin, destination)` → groups + pickup points + members' public facts;
`join_group(group)`; `join_waitlist(origin, destination)` → position.

## RLS test matrix (each row = at least one pgTAP assertion)

| # | Rule | Test file |
|---|---|---|
| R1 | Every table in `public` has RLS on | `00_rls_everywhere.test.sql` |
| R2 | `anon` reads no row of any table | `00_rls_everywhere.test.sql` |
| R3 | A reads/writes only own profile; cannot set `rider_id_status`/`rating` | `10_profile_trust.test.sql` |
| R4 | Women-only privacy refused for a man | `10_profile_trust.test.sql` |
| R5 | Trusted contacts: owner only; 4th refused | `10_profile_trust.test.sql` |
| R6 | Wallet tables: owner-only reads; no direct insert into the ledger | `20_wallet.test.sql` |
| R7 | Withdraw over balance refused; top-up / subscribe write one entry | `20_wallet.test.sql` |
| R8 | No driver-income kind/column (Law 87) | `20_wallet.test.sql` |
| R9 | Share marks: only the ride's driver marks; rider reads own; others nothing | `20_wallet.test.sql` |
| R10 | HR reads own company, invoices, log; not another company's | `30_company.test.sql` |
| R11 | Roster view = 4 columns, HR's company only | `30_company.test.sql` |
| R12 | Dashboard withholds counts < 5 | `30_company.test.sql` |
| R13 | Statement lists only consented employees | `30_company.test.sql` |
| R14 | Employee reads only own enrollment/consent | `30_company.test.sql` |
| R15 | Domain taken → refused; enroll needs a verified work email on an active company's domain | `30_company.test.sql` |
| R16 | Cost cap CHECK refuses a contribution over ⌊cost / seats⌋ | `40_marketplace.test.sql` |
| R17 | Booking the last seat twice → one wins; double booking same leg-date refused | `40_marketplace.test.sql` |
| R18 | Third trip in a day refused for a driver | `40_marketplace.test.sql` |
| R19 | `groups_for` never returns a home point or a rider's name | `10_profile_trust.test.sql` |
