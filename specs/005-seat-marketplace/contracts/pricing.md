# Contract: seat price and cash amount (v3, 005)

This extends 004's [contracts/pricing.md](../../004-wallet-subscription/contracts/pricing.md)
(v2.1). Nothing in v2.1 changes; v3 adds a cash amount (FR-029) and one quote object.

## Dart — `lib/features/commute/domain/pricing_service.dart` (addition)

```dart
/// FR-029 (founder 2026-10-12, range rule after /speckit-analyze): the
/// contribution rounded to the nearest 5 EGP, kept inside range(tripCost,
/// riderSeats) — down when the nearest passes r.max, up when the result is
/// below r.min; null when no multiple of 5 above 0 fits (cash not offered).
/// r.max ≤ equalShare, so the cap holds too.
static int? cashAmount(int contribution, {required int tripCost, required int riderSeats});
```

Research R3 gives the exact steps.

## TypeScript — `supabase/functions/_shared/pricing.ts` (addition)

```ts
export function suggested(tripCost: number, riders: number): number;
export function range(tripCost: number, riders: number): { min: number; suggested: number; max: number };
export function cashAmount(contribution: number, tripCost: number, riderSeats: number): number | null;
```

`suggested`/`range` move from the private helpers in `pricing.test.ts` into `pricing.ts`, exported
(same formula as Dart `PricingService.range`, cap included). The test then imports them.

Integer arithmetic only (`%`, `Math.floor` on non-negative values).

## Dart — `lib/features/wallet/domain/seat_price.dart` (new, no twin)

```dart
final class SeatPrice {
  const SeatPrice({required this.contribution, required this.fee, required this.cash, required this.mode});
  factory SeatPrice.of(int contribution, {required int tripCost, required int riderSeats, required PricingMode mode});
  final int contribution;
  final int fee;      // serviceFee(..., isSubscriber: mode.isFeeFree && mode != cash, isCashTrial: mode == cash)
  final int? cash;    // cashAmount(...)
  final PricingMode mode;
  int get total => contribution + fee;
  bool get cashOffered => cash != null;
  /// What actually moves: cash (cash mode) or total.
  int get payable;
}
```

`SeatPrice` composes the two twinned functions, so it needs no twin of its own. If the mode is
cash but `cash == null`, the quote falls back to the wallet price and the screen shows the wallet
line.

## Vectors — `test/fixtures/pricing_vectors.json`

- Every case gains `cash` (number or `null`), computed by `gen_pricing_vectors.py` with Python
  integers, independently of both twins.
- New named rows (the spec's Edge Cases):

| name | contribution | tripCost | riderSeats | cash |
|---|---|---|---|---|
| cash: 44 up to 45 | 44 | 160 | 3 | 45 |
| cash: 42 down to 40 | 42 | 160 | 3 | 40 |
| cash: 48 down, 50 passes range top 48 | 48 | 160 | 3 | 45 |
| cash: 32 up, 30 below range floor 32 | 32 | 160 | 3 | 35 |
| cash: 41 down to 40 | 41 | 160 | 3 | 40 |
| cash: 38 down, 40 passes range top 38 | 38 | 160 | 4 | 35 |
| cash: 38 down at 156/4, range top 38 | 38 | 156 | 4 | 35 |
| cash: no multiple of 5 in range 2–2 | 2 | 8 | 4 | null |

The readers (`test/unit/rider_total_test.dart`, `pricing.test.ts`) also assert `cash`.

## Sweep (SC-002)

`pricing_cap_sweep_test.dart` and the sweep in `pricing.test.ts` add, for trip cost 20–1,000,
rider seats 1–4, every contribution in `range` (2 EGP steps):

`cash == null || (cash > 0 && cash % 5 == 0 && r.min <= cash && cash <= r.max && cash <= equalShare(tripCost, riderSeats))`.

The existing assertion `riderSeats × riderTotal ≤ tripCost` stays.

## Callers that change (FR-029 amends 004)

| Caller | Today | v3 |
|---|---|---|
| `wallet/presentation/labels.dart` `priceLine` cash branch | `priceCash(contribution)` | takes a `SeatPrice`; cash → `priceCash(price.cash!)`; cash null → wallet line |
| `daily/presentation/today/cash_after_trip.dart` label + recorded `CashMark.amount` | `group.price` | `SeatPrice.of(group.price, …basis, mode: cash).cash` |
| `wallet/presentation/wallet/rider_wallet.dart` plan card (cash) | `priceCash(view.legShare)` | `priceCash(cash of legShare + basis)` |
| `match_result_screen.dart`, `rider_today.dart`, `pay_method_screen.dart` price lines | `priceLine(price, mode, fee:)` | `priceLine(SeatPrice.of(...))` |

On the demo corridor (40 at 160/3) every cash line still reads 40. The widget tests use a 44
contribution to prove the rounding.
