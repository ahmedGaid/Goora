# Quickstart: Wallet and Payment Model (v2)

Device validation. Run alongside `flutter analyze`, `flutter test` and
`node --test "supabase/functions/_shared/*.test.ts"`.

## Prerequisites

- `flutter pub get` (no new packages). Debug build per `goora-stack` "Device testing".
- Settings → Demo → "Reset demo data" before Scenario 1.
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
3. Let a trip settle: 003 settles a ride once its arrival time passes (or the driver taps End
   trip). Not yet confirmed on device which demo-clock steps make that quick — check and fix
   this step during T077. **Expect** a "Trip" row of 44 EGP with "40 EGP to the driver + 4 EGP service fee",
   balance 156.
4. Plan card → Change → Monthly → Subscribe. **Expect** balance 27, plan card "Subscribed until
   {date}", price lines "40 EGP · no fees (subscribed)".
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
