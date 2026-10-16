# Contract: Pricing on the Cairo ↔ Ismailia corridor

**Feature**: 006 · No change to any pricing formula. This contract fixes the numbers and the proof.

## Inputs

| Name | Value | Status |
|---|---|---|
| Trip cost per leg | 300 EGP | **Demo placeholder, unverified** |
| Rider seats | 3 | Same as the old corridor |
| `ratesEnabled` | false | Real rates blocked by brief §8 |

## Derived values (proven by `cap_sweep.ts`)

| Seats | Range | Suggested | Equal share | Top price + fee | Full car at top |
|---|---|---|---|---|---|
| 1 | 120–180 | 150 | 300 | 198 | 198 |
| 2 | 80–120 | 100 | 150 | 132 | 264 |
| **3** | **62–90** | **76** | **100** | **99** | **297** |
| 4 | 48–72 | 60 | 75 | 75 | 300 |

Result: 80 price/seat combinations at 300 EGP, and 6,588 over costs 100–1000, **0 over the cap**.

## Rows to add to `test/fixtures/pricing_vectors.json` (both Dart and TS read it)

Wallet rider (not subscriber, not cash), `tripCost = 300`:

| Seats | Contribution | Fee | Total | Cash amount |
|---|---|---|---|---|
| 3 | 62 | 6 | 68 | 65 |
| 3 | 76 | 8 | 84 | 75 |
| 3 | 90 | 9 | 99 | 90 |
| 4 | 48 | 5 | 53 | 50 |
| 4 | 60 | 6 | 66 | 60 |
| 4 | 72 | 3 (trimmed from 7) | 75 | 70 |

Also add the subscriber and cash variants for the 3-seat rows (fee 0, total = contribution). The generator `test/fixtures/gen_pricing_vectors.py` is extended so the rows are reproducible. Existing rows stay unchanged.

## Tests required

1. Dart: the existing vector test passes with the new rows.
2. TS: `pricing.test.ts` passes with the same rows.
3. Dart cap sweep for 300 EGP, seats 1–4, every allowed price: rider total ≤ equal share, and full car ≤ 300 (mirror of `cap_sweep.ts`; the 004 sweep helper is reused).
4. Seed invariant: every seeded corridor group has `riders + freeSeats ≤ 3` on both legs and `price ∈ [62, 90]` (extend the 004 `corridor_seed_invariant_test.dart`).

## Changing the number later

Edit one value (the corridor's trip cost) and re-run `node specs/006-cairo-ismailia-corridor/cap_sweep.ts` with the new number. If the proof passes, only the seeded `price` fields and example copy need updating; no rule changes.
