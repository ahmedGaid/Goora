# Contract: marketplace rules (twinned)

Constitution II's daily limit and the refund arithmetic exist twice. Both twins take plain data
and MUST return the same result for every row of `test/fixtures/marketplace_vectors.json`
(written by `test/fixtures/gen_marketplace_vectors.py`, independently of both).

## Dart — `lib/features/marketplace/domain/driver_day_rules.dart`

```dart
enum TripFitKind { join, full, limitReached, doesntFit, oneGroupOnly, overlap, create }

final class DayTrip {          // one trip the driver already has that day
  final String id; final Leg leg; final Area from; final Area to;
  final int departure;         // minutes of day
  final int durationMinutes; final int seats; final int taken;
}

final class Candidate {        // what accepting / publishing would add
  final Leg leg; final Area from; final Area to;
  final int departure; final int durationMinutes;
  final bool daily; final bool leadsGroup;
}

final class TripFit {
  final TripFitKind kind;
  final String? tripId;        // join / full
  final int? tripsLeftAfter;   // create
}

abstract final class DriverDayRules {
  static const maxTrips = 2;
  static const joinWindowMinutes = 30;   // inclusive
  static int tripsLeft(List<DayTrip> trips);           // max(0, 2 − length)
  static TripFit fit(List<DayTrip> trips, Candidate c); // order: research R4
}
```

**Order** (first match wins, research R4):
1. **join**: a trip with the same leg, from and to, `|Δdeparture| ≤ 30`, and `taken < seats`.
   Among several, the nearest departure wins, then the lowest id.
2. **full**: as in 1, but none has a seat.
3. **limitReached**: `trips.length ≥ 2`.
4. **doesntFit**: a trip already exists in `c.leg`.
5. **oneGroupOnly**: `c.daily && c.leadsGroup`.
6. **overlap**: `[c.departure, c.departure + c.durationMinutes)` intersects any trip's window.
7. **create**: `tripsLeftAfter = tripsLeft(trips) − 1`.

## Dart — `lib/features/marketplace/domain/booking_refund.dart`

```dart
abstract final class BookingRefund {
  /// What goes back to the wallet. owed = 003's cancel charge on the
  /// contribution (0 before the cut-off, half after; full share for a no-show);
  /// the fee always comes back (Goora takes no fee on a trip that didn't
  /// happen). Never negative, never above paidTotal. 0 for a cash booking
  /// (paidTotal 0).
  static int amount({required int paidTotal, required int fee, required int owed});
  // = max(0, min(paidTotal, paidTotal − owed))  — fee is inside paidTotal and never part of owed
}
```

Full refunds (reclaim, driver cancel) call it with `owed: 0`.

## TypeScript — `supabase/functions/_shared/marketplace.ts`

```ts
export const MAX_TRIPS = 2;
export const JOIN_WINDOW_MINUTES = 30;
export type Leg = "going" | "return";
export type Area = "sheikhZayed" | "october" | "smartVillage";
export interface DayTrip { id: string; leg: Leg; from: Area; to: Area; departure: number; durationMinutes: number; seats: number; taken: number; }
export interface Candidate { leg: Leg; from: Area; to: Area; departure: number; durationMinutes: number; daily: boolean; leadsGroup: boolean; }
export type TripFit =
  | { kind: "join" | "full"; tripId: string }
  | { kind: "limitReached" | "doesntFit" | "oneGroupOnly" | "overlap" }
  | { kind: "create"; tripsLeftAfter: number };
export function tripsLeft(trips: DayTrip[]): number;
export function fit(trips: DayTrip[], c: Candidate): TripFit;
export function refundAmount(paidTotal: number, fee: number, owed: number): number;
```

## Vectors — `test/fixtures/marketplace_vectors.json`

```json
{ "fit":    [ { "name": "...", "trips": [DayTrip...], "candidate": {...}, "expect": {"kind": "...", "tripId"?: "...", "tripsLeftAfter"?: 0} } ],
  "refund": [ { "name": "...", "paidTotal": 44, "fee": 4, "owed": 20, "expect": 24 } ] }
```

The required rows (names are prefixes, so a failure points at the rule):

| name | setup | expect |
|---|---|---|
| fit: empty day creates | no trips; going SZ→SV 7:30 | create, left 1 |
| fit: join within 30 | going SZ→SV 7:30 (3/1); cand 8:00 | join |
| fit: 31 min is not a join | going 7:30; cand 8:01 going | doesntFit |
| fit: join beats limit | going 7:30 (3/1) + return 17:00; cand going 7:45 | join |
| fit: full | going 7:30 (3/3); cand 7:40 | full |
| fit: other direction creates | going 7:30; cand return 17:00 | create, left 0 |
| fit: two trips → limit | going + return; cand going 9:30 (not joinable) | limitReached |
| fit: group leg counts | trip `g:sz-0725:going` 7:25 (3/3) only; cand return 17:00 | create, left 0 |
| fit: other route same leg | going SZ→SV 7:30; cand going OCT→SV 7:30 | doesntFit |
| fit: one daily group | no trips, leadsGroup; cand daily | oneGroupOnly |
| fit: once ok when leading | no trips, leadsGroup; cand once | create, left 1 |
| fit: overlap other direction | going 7:30 (40 min); cand return 8:00 | overlap |
| fit: back-to-back ok | going 7:30 (40 min); cand return 8:10 | create, left 0 |
| refund: before cut-off | 44/4/0 | 44 |
| refund: after cut-off half share | 44/4/20 | 24 |
| refund: subscriber after cut-off | 40/0/20 | 20 |
| refund: cash | 0/0/0 | 0 |

## Scripted sequences (SC-003) — Dart only

`test/unit/driver_day_rules_test.dart` replays seeded-random sequences of offers, accepts and joins.
Each step applies `fit` and adds the trip on `create` or a seat on `join`. After every step it asserts
`trips.length ≤ 2` and at most one trip per leg. It runs 10,000 sequences with a fixed seed.
