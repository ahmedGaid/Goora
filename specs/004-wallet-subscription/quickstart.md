# Quickstart: Wallet and Subscription

Manual/device validation for the three user stories, once `/speckit-implement` has built them.
Run alongside `flutter analyze` / `flutter test` (see plan.md Constitution Check) — this file
proves the feature *feels* right, those prove it's correct.

## Prerequisites

- `flutter pub get` (no new packages added by this feature).
- A debug build on a device or emulator, same install flow as `goora-stack`'s "Device testing"
  section (`flutter build apk --debug` + `adb install -r ...`).
- Fresh app state (Settings → Demo → "Reset demo data") so Scenario 1 starts from "just joined a
  group, no plan yet".

## Scenario 1 — rider starts the free month (US1)

1. From a fresh reset, walk through onboarding as a rider to "Join this group" (001/002 flow).
2. **Expect**: the Plan screen appears immediately — title "Start your free month", three cards
   (Monthly 129 EGP, Yearly 1,290 EGP with "2 months free", Through my company: free), the
   "What's included" list, the fuel-goes-to-driver note, footer "Cancel anytime. Goora is free
   for drivers."
3. Pick Monthly → "Start free month".
4. **Expect**: lands on Today; Wallet tab's plan card reads "Free until {date one month out} ·
   then 129 EGP/month".
5. Back out to Settings → Demo → switch role to driver (or re-run onboarding as a driver).
6. **Expect**: the Plan screen is never shown for a driver — straight to Today.
7. Force-quit and reopen the app before choosing a plan (use a second fresh rider or reset mid-
   flow). **Expect**: the Plan screen reappears; Today/Week are not reachable until a plan is
   chosen.

## Scenario 2 — rider wallet, top-up, activity (US2)

Prerequisite: seeded demo activity exists (a top-up, a trip deduction, a late-cancel charge, a
free cancellation) — confirm the seed via `WalletSeed` rather than replaying 003's flows live.

1. Open Wallet as the seeded rider.
2. **Expect**: plan card ("Free until {date} · then 129 EGP/month" + Change), dark balance card
   ("Covers about {N} trips" + Top up with InstaPay/Vodafone Cash/Card pills and 200/400/800
   amounts), "How paying works" rules, activity list, "What you pay per trip" breakdown ending in
   "Goora fees: in your plan" (never a number).
3. Tap Top up → InstaPay → 200 → confirm.
4. **Expect**: balance +200; new "Top-up" row at the top of activity.
5. Scroll activity: confirm a late-cancel row shows the half-charge and a free-cancellation shows
   a **zero-amount row**, not a missing one.
6. Tap Change → switch Monthly → Yearly.
7. **Expect**: plan card is unchanged until the next billing date (no immediate price/date jump).
8. In Settings → Demo, force the next top-up to fail, then repeat step 3.
9. **Expect**: balance and activity list unchanged from before the attempt; an inline error with
   retry appears.

## Scenario 3 — driver wallet, withdraw (US3)

Prerequisite: seeded demo trip income for the driver this week.

1. Open Wallet as the seeded driver.
2. **Expect**: "Recovered this week" total, "Paid out every Thursday · no fees taken from you",
   Withdraw to InstaPay, activity list (trip income + any rider fee that reached the driver,
   labelled by rider/trip), "Your trip cost" breakdown ending "Goora is free for drivers" with no
   deduction line.
3. Tap Withdraw to InstaPay.
4. **Expect**: balance resets to 0; new "Withdrawal" row in activity.
5. In Settings → Demo, force the next withdrawal to fail, then repeat with a non-zero balance.
6. **Expect**: balance and activity list unchanged; inline error with retry.

## Done when

All three scenarios pass in both Arabic (RTL) and English (LTR), and `flutter analyze` / `flutter
test` are green (plan.md's Constitution Check gate).
