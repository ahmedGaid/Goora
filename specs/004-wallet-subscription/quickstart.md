# Quickstart: Wallet and Payment Model (v2)

Device validation. Run alongside `flutter analyze`, `flutter test` and
`node --test "supabase/functions/_shared/*.test.ts"`.

## Prerequisites

- `flutter pub get` (no new packages). Debug build per `goora-stack` "Device testing".
- Settings → Demo → "Reset demo data" before Scenario 1.
- **Set the clock to a ride-day morning first.** Trips that start before the moment you join never
  settle (`FakeDailyCommuteRepository._catchUp` skips `firstPickup` before `daily.joinedAt`), and
  joining stamps the demo clock's time. Onboard in a real-time evening and none of the demo-clock
  buttons can settle a trip: "After 9 PM" lands on that same evening (whose legs predate the join),
  and "Ride day" jumps back to that morning. Reset keeps the demo clock (`debug.demoNow`), so: while
  still in a group, tap "Ride day · 7:15 AM", *then* "Reset demo data", then onboard. Run this on a
  ride day that is **not the last working day of the week** (Sun–Wed for a Sun–Thu group): "After
  9 PM" lands on the evening before the *next* ride day, so from a Thursday it jumps to Saturday,
  and step 4's subscribe then happens on a later day than the trips — which no longer exercises the
  same-day case (R14). If "Ride day" lands on a Thursday, tap "After 9 PM" then "Ride day" again
  to move on to Sunday before resetting. (Confirmed on a phone 2026-10-08.)
- The top-up/withdraw failure path is test-only (research R4 addendum); it is not part of these
  scenarios.

## Scenario 1 — payment method after joining (US1)

1. Onboard as a rider (Sheikh Zayed → Smart Village), "Join this group".
2. **Expect**: "How do you want to pay?" with "Pay cash to the driver (first 10 trips)", "Use
   wallet", and the "Subscribe and pay no fees" link. No free-month copy anywhere.
3. Pick cash → Continue. **Expect**: Today; the price line reads "Pay 40 EGP cash to the driver".
4. Wallet: **Expect** "10 cash trips left", plan card "Pay per trip", no fee rows.

## Scenario 2 — wallet rider, fees and subscribing (US2, US3)

1. Reset, onboard again, pick "Use wallet". **Expect** on match result and Today:
   "40 EGP to the driver + 4 EGP service fee".
2. Wallet → Top up InstaPay 200. **Expect** balance exactly 200.
3. Let a trip settle: Settings → Demo → "After 9 PM" (or "Before 9 PM") jumps to today's own
   evening — past the return leg's arrival — because `_nextDuty(from: 1)` resolves to tomorrow's
   ride day and backs up one day to get there. "Ride day" instead jumps to *today* at 7:15 AM
   (today still counts as the next ride day before its own legs have run), which moves the clock
   backward, not forward — don't use it for this step. This only settles anything if you joined
   before that day's first pickup (see Prerequisites). Reopen Wallet. **Expect** a "Trip" row of
   44 EGP with "40 EGP to the driver + 4 EGP service fee" for each leg that ran after you joined:
   joined before both legs (the Prerequisites recipe) → two rows, balance 112; joined between the
   legs → one row, balance 156.
4. If the balance is under 129, top up another 200 first (112 → 312). Plan card → Change → Monthly
   → Subscribe, the same evening. **Expect** balance = before − 129 (312 → 183, or 156 → 27), plan
   card "Subscribed until {date}", price lines "40 EGP · no fees (subscribed)", "What you pay per
   trip" now "Service fee: none / Total 40 EGP" —
   and the earlier "Trip" rows **unchanged** at 44 EGP with their 4 EGP fee (R14: before the fix
   they turned into 40 EGP rows and the fee came back, 191 / 31).
5. With less than 129 EGP, subscribing shows "Top up {gap} EGP first" and charges nothing.

## Scenario 3 — driver cash (US5)

1. Reset, onboard as a driver on the Sheikh Zayed group (license + vehicle verified in Trust).
2. On a ride day: arrive at each stop, mark Youssef picked up, start and end the trip.
3. **Expect**: under Youssef, "Received 40 EGP cash" / "Didn't pay". Tap Received → status chip
   "Cash received", buttons gone.
4. Wallet: **Expect** "Cash received" with "Recorded only — not withdrawable", separate from
   "Recovered this week"; Withdraw leaves the cash card unchanged.

## Scenario 4 — the cash trial's end (US4) — test-driven

The 7-trip banner, the 10-trip switch-over and the 2-strike switch-over need trip histories that
can't be produced in minutes on a device; they are covered by `cash_trial_policy_test.dart` and
`rider_wallet_test.dart` (seeded histories), ar + en.

## Done when

Scenarios 1–3 pass in Arabic and English, the gates are green, and the Dart and TS pricing tests
read the same `test/fixtures/pricing_vectors.json`.
