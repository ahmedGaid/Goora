# Data Model: Seat Marketplace

Money is whole EGP (`int`). Times are `Clock` (minutes of day) on a `CalendarDate`, so a moment is a
`WallTime`. A "leg" is 002's `Leg {going, ret}`. "Route" = `(from: Area, to: Area)` in that leg's
direction (spec Assumptions). All ids are strings.

## Value objects

### SeatPrice (`wallet/domain/seat_price.dart`, research R2)

| field | type | rule |
|---|---|---|
| contribution | int | goes to the driver in full |
| fee | int | `PricingService.serviceFee(...)`; 0 for subscribed/company/cash |
| total | int | contribution + fee; what a wallet rider is charged |
| cash | int? | `PricingService.cashAmount(...)`; null → cash not offered (wallet only) |
| mode | PricingMode | the rider's mode when quoted |

`SeatPrice.of(contribution, {tripCost, riderSeats, mode})`. **Paid amount** = `cash` when the mode
is cash, else `total`.

### PriceBasis

`(tripCost, riderSeats)`. Every group (004 v2.1) and every offered trip carries one.

### AnonymousRider (`marketplace/domain/anonymous_rider.dart`, research R15)

`{isWoman: bool, rating: double?}`. `rating == null` shows "New". It never carries a name,
initials, photo or member id.

## Entities

### OfferedTrip

A trip a driver publishes (C), or one created by accepting a request (D).

| field | type | notes |
|---|---|---|
| id | String | `of-<n>`; seeded offers `of-seed-*` |
| driverId | String | `me` or a seeded driver |
| leg | Leg | going = home area → work area |
| from, to | Area | |
| date | CalendarDate | resolved by `MarketDay` (R13) |
| departure | Clock | |
| durationMinutes | int | 40 (003 default) |
| seats | int | 1–4, capacity offered; ≤ `riderSeats` |
| riderSeats | int | price basis (R6). Published: = seats. Created from a request: the request's basis (3 on the corridor) with seats = min(driver's car seats, 3), so the request's fixed price stays the basis' suggestion and inside ±20% |
| tripCost | int | `PricingService.tripCost(config)` for the route |
| contribution | int | within `PricingService.range(tripCost, seats)`, 2 EGP steps |
| repeat | Repeat | `once` \| `daily` |
| pickup | Stop | public point, never a home |
| status | OfferStatus | see below |
| groupId | String? | set when a daily trip became a group |
| origin | OfferOrigin | `published` \| `fromRequest` |
| cancelledWithRiders | bool | counts on the driver's day (R5) |

Validation:
- Publishing needs verified ID, license and vehicle (FR-014).
- Contribution is in range.
- `DriverDayRules.fit(...)` is `create`, or for a request, `join` into an existing trip.
- `daily` is not allowed when the driver leads a group (`oneGroupOnly`).

**OfferStatus**: `open → full` (taken == seats) `→ open` (a booking is cancelled or reclaimed) ·
`open|full → departed` (now ≥ departure) `→ done` (now ≥ departure + duration) ·
`open|full → cancelled` (driver; every booking is refunded in full, FR-017) · `open|full → grouped`
(daily, first booking; it then lives as a `CommuteGroup`, R10).

### TripRequest

A rider's posted trip (B).

| field | type | notes |
|---|---|---|
| id | String | `rq-<n>`; seeded `rq-seed-*` |
| riderId | String | `me` or a seeded rider |
| rider | AnonymousRider | what drivers see |
| leg, from, to, date, departure | | as OfferedTrip |
| repeat | Repeat | `daily` not allowed when the rider is already in a group (R10) |
| pickup | Stop | nearest public stop to the rider's home area |
| detourFrom | Map<Area,int> | seeded detour minutes by driver origin area (R14); fit = < 10 |
| price | SeatPrice | quoted for the rider at posting; fixed (FR-022) |
| status | RequestStatus | see below |
| acceptedBy | String? | driver id |
| tripId | String? | the OfferedTrip or group ride it was seated in |

**RequestStatus**: `posted → accepted` (a driver accepts and the rider passes `BookingGate`; a
`Booking` is created) · `posted → withdrawn` (the gate fails at accept; the rider is told to top
up) · `posted → cancelled` (rider; free, FR-012) · `posted → expired` (now ≥ date + departure; no
charge). `accepted` + `daily` → a group is created or joined (R10).

### Booking

One rider in one seat on one leg-date.

| field | type | notes |
|---|---|---|
| id | String | `bk-<n>` |
| riderId | String | |
| riderName | String | shown to the driver only from departure (R15) |
| rider | AnonymousRider | |
| source | BookingSource | `groupSeat(groupId)` \| `offer(tripId)` \| `request(requestId)` |
| date, leg | | |
| rideId | String | group seat: 003's `Ride.idFor`; offer: `offer:<tripId>` |
| price | SeatPrice | quote at booking |
| paidBy | PaidBy | `wallet` \| `cash` \| `plan` (subscribed/company) |
| paid | int | ledger debit at booking; 0 for cash |
| bookedAt | WallTime | |
| isSubscriber | bool | subscribers can't be reclaimed |
| status | BookingStatus | see below |

Validation:
- One booking per rider per leg-date (spec Edge Cases).
- Not in the rider's own car on a leg they already ride.
- A driver can't book their own trip.
- Free seats > 0 at the moment of writing (SC-006: re-checked inside the write).

**BookingStatus**: `booked → done` (trip end passed) · `booked → cancelled` (rider; refund =
`BookingRefund.amount`, owed → driver `Charge`) · `booked → reclaimed` (subscriber before the cut-off;
full refund; a cash booking moves nothing and doesn't count toward the 10) · `booked → refunded`
(driver cancelled; full refund).

**Reclaimable** = `!isSubscriber && !AttendanceRules.isLate(date, bookedAt) && !AttendanceRules.isLate(date, now)` (R13).

### SeatOffer (derived, rider-facing; never stored)

`{source, driver (name, avatar, rating — riders may see drivers), pickup, date, leg, departure, freeSeats, price: SeatPrice}`.
It comes from seeded and created groups' next departures plus open offers. Filters:
- route fit (same from/to, detour < 10);
- the rider's privacy preference (003);
- not departed;
- free > 0 (`SeatMath`, R6);
- not the rider's own leg.

### DriverDay (derived)

`{date, trips: List<DayTrip>, leadsGroup}`. `DayTrip = {id, leg, from, to, departure, durationMinutes, seats, taken}`.
It is assembled from:
- 003 schedule legs the person actually drives;
- their offered trips that count (R5).

It feeds `DriverDayRules.fit` and `tripsLeft`.

### CommuteGroup additions (R10)

No new fields. Groups created by the marketplace are ordinary `CommuteGroup`s:
- id `mk-<sourceId>`;
- one stop;
- every member's `legs` = `{that leg}`;
- `riderSeats` = the offer's seats, `tripCost`/`price` from the offer.

New: `toJson`/`fromJson` on `CommuteGroup`, `Member`, `Stop`, `Vehicle`.

### Wallet additions (004)

`ActivityKind` gains:
- `seatBooked`: amount = paid, fee = fee, `rideId`;
- `seatRefund`: a credit; amount = refunded, `rideId`.

Both are written by the `SeatLedger` seam. The cash-trial fold reads one-off cash trips that are
`done` (R9). The driver's `tripIncome` for their done once-trips is posted once per (trip, rider)
for non-cash riders.

### NoticeKind additions (003)

- `seatBooked` (driver);
- `seatReclaimed` (rider: `day`, `amount`);
- `requestAccepted` (rider: `driver`, `time`);
- `requestExpired` (rider);
- `tripCancelledByDriver` (rider: `driver`, `amount`).

## Fake storage keys

| key | holds |
|---|---|
| `market.offers` | `List<OfferedTrip>`: the person's own plus any seeded ones touched (seeded otherwise come from `MarketSeed`) |
| `market.requests` | `List<TripRequest>`: the person's posts plus seeded requests' status changes |
| `market.bookings` | `List<Booking>` |
| `market.groups` | `List<CommuteGroup>` created by the marketplace |
| `market.members.<groupId>` | `List<Member>` added to an existing group by accepting a daily request |
| `market.seedCursor` | next index into the fake rider / driver pools for demo actions |

"Reset demo data" removes every `market.*` key (with 003/004's keys).
