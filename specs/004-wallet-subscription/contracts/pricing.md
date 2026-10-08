# Contract: per-trip rider price (v2.1)

The one pricing rule that exists twice (FR-015, Constitution VIII). Both twins take plain integers
and MUST return the same numbers for every row of `test/fixtures/pricing_vectors.json`.

## Dart — `lib/features/commute/domain/pricing_service.dart`

```dart
abstract final class PricingService {
  static const feeRatePercent = 10;  // the ceiling, not always the fee (FR-017)

  /// ⌊tripCost ÷ riderSeats⌋. Throws ArgumentError when riderSeats < 1.
  static int equalShare(int tripCost, int riderSeats);

  /// 0 for subscribers, company-plan riders and cash trips; else
  /// max(0, min((c × 10 + 50) ~/ 100, equalShare − c)).
  static int serviceFee(int contribution,
      {required int tripCost, required int riderSeats,
       required bool isSubscriber, required bool isCashTrial});

  /// contribution + serviceFee(…). The contribution is never reduced.
  static int riderTotal(int contribution,
      {required int tripCost, required int riderSeats,
       required bool isSubscriber, required bool isCashTrial});
}
```

The doc comment above `feeRatePercent` that cites the v2 "Constitution II reading" is replaced
with the v2.1 rule (spec "Amendment — the service fee sits inside the cap").

## TypeScript — `supabase/functions/_shared/pricing.ts`

```ts
export const FEE_RATE_PERCENT = 10;
export function equalShare(tripCost: number, riderSeats: number): number;   // RangeError if < 1
export function serviceFee(contribution: number, tripCost: number, riderSeats: number,
                           isSubscriber: boolean, isCashTrial: boolean): number;
export function riderTotal(contribution: number, tripCost: number, riderSeats: number,
                           isSubscriber: boolean, isCashTrial: boolean): number;
```

Integer arithmetic only (`Math.floor` on non-negative values), as in v2 (research R6).

## Vectors — `test/fixtures/pricing_vectors.json`

Every case gains `tripCost` and `riderSeats`. The 45 existing cases take `tripCost: 160,
riderSeats: 3` (equal share 53); every existing contribution is ≤ 48, so their `fee`/`total` are
unchanged. Five cases are added — the spec's table, named so a failure points at it:

| name | contribution | tripCost | riderSeats | isSubscriber | isCashTrial | fee | total |
|---|---|---|---|---|---|---|---|
| cap: 160/3 suggested | 40 | 160 | 3 | false | false | 4 | 44 |
| cap: 160/3 top of range | 48 | 160 | 3 | false | false | 5 | 53 |
| cap: 160/4 suggested | 32 | 160 | 4 | false | false | 3 | 35 |
| cap: 160/4 top of range, trimmed | 38 | 160 | 4 | false | false | 2 | 40 |
| cap: 96/4 at the share, no room | 24 | 96 | 4 | false | false | 0 | 24 |

The Dart reader (`test/unit/rider_total_test.dart`) and the TS reader (`pricing.test.ts`) pass the
two new fields through; nothing else in the readers changes.

## Property (FR-016, SC-006) — research R17

Not a vector (it is a sweep): in both twins, for trip cost 20–1,000, rider seats 1–4 and every
contribution in `PricingService.range(tripCost, riderSeats)` in 2 EGP steps,
`riderSeats × riderTotal(c, …, isSubscriber: false, isCashTrial: false) ≤ tripCost`.
The TS sweep needs `range`; it is a small local helper in `pricing.test.ts` mirroring 002's
`PricingService.range` (no server consumer needs `range` yet, so it is not exported).

## Callers (all pass `group.tripCost`, `group.riderSeats`)

| Caller | Today | v2.1 |
|---|---|---|
| `match_result_screen.dart` price line | `serviceFee(g.price, isSubscriber: false, …)` | + basis of `g` |
| `rider_today.dart` `_Tiles` | same | + basis of `view.group` |
| `fake_wallet_repository.dart` `_riderTrips` | `serviceFee(group.price, isSubscriber: feeFree, …)` | + basis of `group` |
| `pay_method_screen.dart` wallet subtitle | `serviceFee(contribution, …)` from `WalletView.legShare` | + `WalletView.groupTripCost`, `riderSeats` (still wallet-mode, not the rider's current mode) |
| `wallet_controller.dart` `WalletView.fee` | `serviceFee(legShare, …)` | + `groupTripCost`, `riderSeats` |
