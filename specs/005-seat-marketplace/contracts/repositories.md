# Contract: repositories and seams (app-internal)

These are app-internal interfaces (Constitution VIII); there is no network API in 005. The fakes
run on shared_preferences. A future Supabase implementation calls the server, and the server's
own ledger and its twins of the rules ([marketplace-rules.md](marketplace-rules.md),
[pricing.md](pricing.md)) decide.

## MarketplaceRepository — `lib/features/marketplace/domain/marketplace_repository.dart`

```dart
abstract interface class MarketplaceRepository {
  // A — Empty seats
  Future<List<SeatOffer>> seatOffers(Leg leg, {required WallTime now});
  /// Re-checks free seats and the gate inside the write; a failure changes nothing (SC-006).
  Future<BookResult> book(SeatOffer offer, {required WallTime now});
  Future<CancelResult> cancelBooking(String bookingId, {required WallTime now});
  Future<List<Booking>> myBookings({required WallTime now});      // booked, not done/ended, oldest first

  // B — Post your trip
  Future<PostResult> post(TripDraft draft, {required WallTime now});
  Future<void> cancelRequest(String requestId);
  Future<TripRequest?> request(String requestId, {required WallTime now}); // expires on read (R13)
  Future<int> driversOnRoute(TripDraft draft);                   // "Sent to N drivers"

  // C — Offer a trip
  Future<PublishResult> publish(OfferDraft draft, {required WallTime now});
  Future<OfferedTrip?> offer(String tripId, {required WallTime now});
  Future<OfferLive> live(String tripId, {required WallTime now}); // seats, AnonymousRider list (names from departure)
  Future<void> cancelOffer(String tripId, {required WallTime now}); // refunds + reliability (FR-017)

  // D — Find riders / driver Today
  Future<DriverDay> driverDay(CalendarDate date);
  Future<List<RequestCard>> requestsForMe({Area? leavingFrom, required PartOfDay part, required WallTime now});
  Future<AcceptResult> accept(String requestId, {required WallTime now});

  // US6
  Future<ReclaimResult> reclaim(String bookingId, {required WallTime now}); // subscriber takes the seat

  // Demo (debug only, FR-028)
  Future<DemoResult> demoDriverAccepts({required WallTime now});
  Future<DemoResult> demoRiderBooks({required WallTime now});
  Future<DemoResult> demoSubscriberTakes({required WallTime now});
}
```

Result types are sealed classes, one case per outcome the UI words differently:

- **`BookResult`**:
  - `booked(Booking)`
  - `needsMethod`
  - `topUp(gap)`
  - `seatTaken`
  - `alreadyRiding`
  - `paymentFailed`
- **`PublishResult`**:
  - `published(OfferedTrip)`
  - `notVerified(List<VerificationKind>)`
  - `limit(TripFit)` (anything but create)
- **`AcceptResult`**:
  - `created(tripsLeft)`
  - `joined(time)`
  - `refused(TripFit)`
  - `riderCantPay` (request withdrawn)
- **`PostResult`**:
  - `posted(TripRequest)`
  - `needsMethod`
  - `topUp(gap)`
  - `dailyNotAllowed`
- **`ReclaimResult`**:
  - `reclaimed(refund)`
  - `tooLate`
  - `notReclaimable`

`RequestCard = {request id, route, AnonymousRider, pickup, time, repeat, price (SeatPrice for the request's rider — fixed), detourMinutes, fit: TripFit}`.
It has no name and no photo (FR-023).

## Seams (research R9)

### NoticeSink — `lib/features/daily/domain/notice.dart`

```dart
abstract interface class NoticeSink {
  Future<void> post(NoticeKind kind, Map<String, String> params);
  /// Appends to 003's reliability events (FR-017). The marketplace calls it with
  /// ReliabilityEventKind.lateCantDrive, rideId 'offer:<tripId>', only for a
  /// driver cancel after the 9 PM cut-off on a trip with ≥ 1 booking (R9).
  Future<void> recordReliability(ReliabilityEvent event);
}
```

`FakeDailyCommuteRepository` implements it. Posted notices reach 003's bell/inbox stream unchanged.
Recorded events feed `ReliabilityRules.compute` like 003's own.

### SeatLedger — `lib/features/wallet/domain/wallet_repository.dart`

```dart
abstract interface class SeatLedger {
  /// Debits total (fee recorded); simulated failure leaves balance/activity untouched.
  Future<PaymentResult> debitSeat(String personId, {required String bookingId, required String rideId,
      required int total, required int fee, required CalendarDate date});
  /// One credit row; amount may be 0 (no row written then).
  Future<void> refundSeat(String personId, {required String bookingId, required String rideId,
      required int amount, required CalendarDate date});
}
```

`FakeWalletRepository implements WalletRepository, SeatLedger`.

### One-off trips into the wallet

`FakeWalletRepository` gains a constructor callback:

```dart
final Future<List<DoneOneOff>> Function() _oneOffs;
// DoneOneOff = {rideId, date, leg, paidBy, contribution, tripCost, riderSeats, riderId, driverId}
```

- **Rider**: cash `DoneOneOff`s are interleaved into the 004 cash-trial fold, ordered by date and
  leg. Wallet and plan ones are already debited, so the fold skips them.
- **One ride, one charge** (R10): the fold counts each rideId once per person. A group trip whose
  rideId has a `seatBooked` debit is skipped. A cash one-off with the same rideId as a group trip
  counts as one cash trip.
- **Driver**: one `tripIncome` row per (trip, non-cash rider), written once, idempotent by id.

## GroupCatalog — `lib/features/commute/data/group_catalog.dart` (research R10)

```dart
final class GroupCatalog {
  GroupCatalog(SharedPreferences prefs, {List<CommuteGroup> seed = CorridorSeed.groups});
  List<CommuteGroup> all();                       // seed + created, extra members merged
  CommuteGroup? byId(String id);
  Future<CommuteGroup> create(CommuteGroup g);    // id must start with 'mk-'
  Future<void> addMember(String groupId, Member m);
  Future<void> clear();                           // reset demo data
}
```

Consumers:
- `FakeCommuteRepository` (`groupsFor`, `join`);
- `FakeDailyCommuteRepository` (replaces the `groups` constructor list);
- `FakeMarketplaceRepository` (create / addMember).

Riverpod: one `groupCatalogProvider`. Invalidating it invalidates the commute and daily
repositories.

## WalletRepository — no signature changes

`getWallet` now includes `seatBooked`/`seatRefund` rows and one-off cash trips. Its interface is
unchanged.
