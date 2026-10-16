# Quickstart: Cairo ↔ Ismailia corridor

**Feature**: 006 · Validation guide. Run after implementation. Nothing here shows Sheikh Zayed or Smart Village.

## Prerequisites

- Worktree `D:\Company\80-Worktrees\Goora-006`, branch `006-cairo-ismailia-corridor`.
- Emulator booted only with `D:\Company\99-Ops\start-emulator.ps1` (never the founder's phone).
- Demo data reset (Settings → Demo → Reset demo data), so the active corridor is the default (Cairo ↔ Ismailia).

## 0. Gates and the cap proof

```bash
flutter analyze
flutter test --concurrency=1
node --test "supabase/functions/_shared/*.test.ts"
node specs/006-cairo-ismailia-corridor/cap_sweep.ts
```

Expected: analyze 0 issues · all tests green (no drop from 1,085 Flutter / 148 Node, plus the new ones) · cap sweep prints `0 over the cap` twice and exits 0.

## 1. Rider, Cairo → Ismailia (US1, US2)

1. Welcome → Arabic → sign up as a rider.
2. Home: **New Cairo**. Work: **Ismailia**. Leave 06:30, return 16:45, working days.
3. Expect a match result: a group with driver, pickup meeting point, departure 06:30, arrival about 08:15, price **76 EGP**, and "why this group" reasons. Pay line reads **76 + 8** (wallet) with the fee shown as in feature 004.
4. Pay method → cash: the line reads **75 EGP** cash.
5. Join → Today shows the corridor's names, times and price only.

## 2. Rider, Ismailia → Cairo (US1, US3)

Reset, sign up as a rider with home **Ismailia** and work **Nasr City**. Expect a matching group in that direction with its own times and price 76.

## 3. No match

Reset, set home to **Heliopolis** and a leave time with no group. Expect the no-match state naming the user's route ("You're #N on the Heliopolis → Ismailia list") and the post-a-trip-request button.

## 4. Marketplace (US3)

1. Wallet shows 300-based numbers; top up, then open **Empty seats**: the route toggle and cards use Cairo / Ismailia areas only.
2. **Post your trip** from New Cairo to Ismailia: defaults come from the profile, not a fixed route. Back from pay method returns to Today (feature 005 behaviour).
3. As a driver (demo verify), **Offer a trip** Ismailia → Cairo: the trip is on the Ismailia → Cairo side of the route, duration about 105 min, riders can book.
4. **Find riders** area filter lists only the six corridor areas.

## 5. English and RTL

Repeat steps 1 and 3 in English (LTR). Names, times and prices stay readable; no clipped text at 1.3× text size.

## 6. Old corridor still works (regression)

Settings → Demo → switch corridor to the previous one. Re-run the old quickstart §1 of feature 003 or the existing widget tests; expected: unchanged behaviour. Switch back; reset.

## 7. Content-filming check (SC-005)

Walk steps 1–4 once with screen recording. Search the footage and the on-screen text for "Sheikh Zayed" and "Smart Village": expect none.

## Expected failures that are NOT bugs

- Prices are a **demo** (300 EGP placeholder). Do not quote them publicly before the founder replaces the number.
- Real map distances, tolls and fuel are not modelled.
