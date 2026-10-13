---
description: "Task list for feature 005: Seat Marketplace"
---

# Tasks: Seat Marketplace

**Input**: `specs/005-seat-marketplace/` (plan, spec, research R1–R17, data-model, contracts, quickstart)

**Tests**: REQUIRED — constitution VIII + plan "Testing": pure rules tested with the brief's
numbers; `cashAmount`, `DriverDayRules` and `BookingRefund` twinned in TypeScript on shared vectors
written by an independent Python generator; scripted limit sequences (SC-003); extended cap sweep
(SC-002); widget tests ar + en for every new screen and state; goldens RTL + LTR for new cards.

**Order**: Setup → Rules + twins (plan P1) → 004 cash amendment (P2) → Model, store, seams (P3) →
US1 (P4, MVP) → US2 (P5) → US3 (P6) → US4 (P7) → US5 (P8) → US6 (P9) → Polish + gate (P10).
Riskiest first: the legal rules and the one-leg group schedule are proven before any screen.
Each phase ≈ one session and ends with a green checkpoint that can be committed on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task)
- **[Story]**: US1–US6 from spec.md
- "R#" = research.md section; "FR-###"/"SC-###" = spec requirement/success criterion
- Gate commands (goora-stack): `flutter analyze` · `flutter test --concurrency=1` (this PC runs out
  of memory otherwise; re-run any file reported "did not complete" on its own) ·
  `node --test "supabase/functions/_shared/*.test.ts"`

---

## Phase 1: Setup

- [X] T001 Add every 005 ARB key to `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_ar.arb`: the
  research R16 table verbatim (en + drafted ar: `seatsLeft`, `bookSeat`, `seatRule`, `nothingFits`,
  `alreadyRiding`, `seatBookedTitle`, `upsellDaily`, `backToToday`, `lateBookingNote`, `topUpFirst`,
  `seatJustTaken`, `justOnce`, `everyWorkday`, `ruleNoBidding`, `ruleCostShare`, `ruleRoute`, `post`,
  `sentToDrivers` (ICU plural), `waitingDriver`, `cancelRequest`, `requestAccepted`, `nowGroup`,
  `requestExpired`, `postAgain`, `seeEmptySeats`, `dailyNeedsNoGroup`, `verifyChip`, `publish`,
  `dailyLimitReached`, `joinsTripInstead`, `seatsBooked`, `carFull`, `verifiedRider`,
  `verifiedRiderWoman`, `newRider`, `cancelTrip`, `tripCancelledRefund`, `leavingFrom`, `allAreas`,
  `morning`, `evening`, `createsTrip`, `doesntFit`, `yourCarFull`, `oneGroupOnly`, `overlapTrip`,
  `accept`, `accepted`, `demandBanner`, `detourMin`, `noRequests`, `privacyCaption`, `seatReclaimed`,
  `reclaimTooLate`, `oneOffTrips`, `cancelBooking`, `noGroupYet`, `demoAcceptRequest`, `demoBookSeat`,
  `demoReclaim`, `demoVerifyDriver`) plus the notice texts for the five new NoticeKinds (T040) and
  the activity labels `seatBooked`/`seatRefund` (T039). Reuse existing keys where R16 says so
  (`emptySeatsTitle`, `postReq`, `offerTitle`, `offerBtn`, `browseBtn`, `browseTitle`, `tripsLeftA`,
  `reqsOnRoute`, `extraTrip`, `noCoverEmptySeat`, `priceWithFee`, `priceSubscribed`, `priceCash`,
  `cashReceived`, 002's stepper keys) — check each exists before adding. Arabic lexicon: مشوار ·
  السواق · كرسي · موثّق; "فصال", never "مزايدة". Run `flutter gen-l10n`

---

## Phase 2: Rules + twins (plan P1 — blocks everything)

**Cash amount (FR-029, R3)**

- [X] T002 [P] `test/fixtures/gen_pricing_vectors.py`: add a `cash` field (int or `None` → JSON
  `null`) to every case, computed with Python integers per R3 (down = c − c % 5; nearest = down if
  c % 5 ≤ 2 else down + 5; r = 002's range(tripCost, riderSeats), written in Python independently;
  if nearest > r.max use down; if the result < r.min use up; outside [r.min, r.max] or 0 → null),
  plus the eight named rows from contracts/pricing.md ("cash: 44 up to 45" … "cash: no multiple of 5
  in range 2–2"). Regenerate `test/fixtures/pricing_vectors.json`
- [X] T003 `lib/features/commute/domain/pricing_service.dart`: add
  `static int? cashAmount(int contribution, {required int tripCost, required int riderSeats})`
  exactly per R3, reusing `range`; doc comment cites FR-029 (founder 2026-10-12, range rule)
- [X] T004 [P] `supabase/functions/_shared/pricing.ts`: move `suggested`/`range` out of
  `pricing.test.ts` into `pricing.ts` and export them (test imports them); export
  `cashAmount(contribution, tripCost, riderSeats): number | null` per R3, integer arithmetic only
  (`%`, `Math.floor` on non-negative values)
- [X] T005 `test/unit/rider_total_test.dart`: assert `cashAmount` against every vector's `cash`
  (null included)
- [X] T006 [P] `supabase/functions/_shared/pricing.test.ts`: assert `cashAmount` against every
  vector's `cash`; extend the sweep (trip cost 20–1,000 step 20, rider seats 1–4, every allowed
  contribution in 2 EGP steps): `cash === null || (cash > 0 && cash % 5 === 0 && r.min <= cash &&
  cash <= r.max && cash <= equalShare)`; 0 exceptions
- [X] T007 [P] `test/unit/pricing_cap_sweep_test.dart`: same cash assertion as T006 alongside the
  existing `riderSeats × riderTotal ≤ tripCost` check (SC-002)

**SeatPrice (R2)**

- [X] T008 [P] `test/unit/seat_price_test.dart`: `SeatPrice.of` at 160/3 — wallet 40 → fee 4,
  total 44, payable 44; subscribed and company 40 → fee 0, payable 40; cash 40 → fee 0, cash 40,
  payable 40; cash at contribution 44 → cash 45, payable 45; cash at 48 → 45 and at 32 → 35 (range
  32–48); wallet 44 → 48; 160/4 at 38 → fee 2 ("38 + 2", 004 v2.1 trim) and cash 35; cash at 2 / 8 / 4
  (range 2–2) → `cash == null`, `cashOffered` false, payable falls back to total
- [X] T009 `lib/features/wallet/domain/seat_price.dart`: `SeatPrice` per contracts/pricing.md
  (`contribution`, `fee`, `cash`, `mode`, `total`, `cashOffered`, `payable`); `fee` =
  `PricingService.serviceFee(...)` with `isSubscriber: mode.isFeeFree && mode != cash`,
  `isCashTrial: mode == cash`; `cash` = `PricingService.cashAmount(...)`

**Driver day rules + refund (R4, R7) — twinned**

- [X] T010 [P] `test/fixtures/gen_marketplace_vectors.py` (new, independent of both twins): write
  `test/fixtures/marketplace_vectors.json` with `fit` and `refund` arrays; every required row in
  contracts/marketplace-rules.md (13 `fit:` rows, 4 `refund:` rows) plus edge rows: join tie → nearest
  departure then lowest id; join exactly 30 min (inclusive); limitReached when 2 trips and candidate
  joinable but full → `full` (join/full come first); overlap half-open boundary
- [X] T011 `lib/features/marketplace/domain/driver_day_rules.dart`: `TripFitKind`, `DayTrip`,
  `Candidate`, `TripFit`, `DriverDayRules` (`maxTrips = 2`, `joinWindowMinutes = 30` inclusive,
  `tripsLeft = max(0, 2 − trips.length)`, `fit` in R4's order: join → full → limitReached →
  doesntFit → oneGroupOnly → overlap → create). Pure Dart, no Flutter imports
- [X] T012 [P] `lib/features/marketplace/domain/booking_refund.dart`:
  `BookingRefund.amount({paidTotal, fee, owed}) = max(0, min(paidTotal, paidTotal − owed))`
- [X] T013 [P] `supabase/functions/_shared/marketplace.ts`: `MAX_TRIPS`, `JOIN_WINDOW_MINUTES`,
  types and `tripsLeft`/`fit`/`refundAmount` exactly per contracts/marketplace-rules.md
- [X] T014 [P] `supabase/functions/_shared/marketplace.test.ts`: load
  `test/fixtures/marketplace_vectors.json` (via `vectors.ts`), assert every `fit` and `refund` row
- [X] T015 `test/unit/marketplace_vectors_test.dart`: Dart reader of the same file, every row
  (failure message = row name)
- [X] T016 `test/unit/driver_day_rules_test.dart`: hand cases for each `TripFitKind` with the brief's
  times, plus SC-003 scripted sequences — 10,000 sequences, fixed seed, random offers/accepts/joins
  (both legs, both routes, times 6:00–20:00, daily/once, leadsGroup on/off); apply `fit`, add a trip
  on `create` and a seat on `join`; after every step assert `trips.length ≤ 2` and ≤ 1 trip per leg

**Gate, day, seats (R8, R13, R6)**

- [X] T017 [P] `lib/features/marketplace/domain/booking_gate.dart` + `test/unit/booking_gate_test.dart`:
  `BookingGate.check({hasArrangement, mode, cashOffered, balance, price})` → `ok | needsMethod |
  topUp(gap)` in R8's order; tests: no method → needsMethod; company at balance −50 → ok; cash with
  cash offered → ok; cash with `cash == null` and balance 0 → topUp(total); wallet 44 at balance 0 →
  topUp(44), at 30 → topUp(14), at 44 → ok; subscribed 40 at 39 → topUp(1)
- [X] T018 [P] `lib/features/marketplace/domain/market_day.dart` + `test/unit/market_day_test.dart`:
  R13 — `nextDeparture(days, departure, now)` (today if still ahead, else next running day within 7
  days); `nextWorkday(departure, now)` (Sun–Thu, today included if ahead); day label kind
  (today/tomorrow/weekday); `isExpired(date, departure, now)` (now ≥ date+time). Tests at Thu 21:00 →
  Sun, Fri/Sat skipped, exactly-at-departure counts as passed
- [X] T019 [P] `lib/features/marketplace/domain/seat_math.dart` + `test/unit/seat_math_test.dart`:
  R6 — free = `riderSeats − riding − activeBookings`, floored at 0; own group: riding from 003
  `Ride.passengers` (riders + off-duty drivers, absences excluded); other seeded group:
  `riderSeats − group.freeSeats(leg)`; offered trip: `seats − bookings`; a booking whose rider is
  already in the ride's passengers counts once; for a subscriber viewer, reclaimable one-off
  bookings count as free (US6 AC1). Tests: sz-0725 160/3 with its off-duty driver riding → 0 free
  (never the 4th place, T078); never counted against the car's physical seats; booker-who-is-member
  counted once; full car with one reclaimable booking → 1 free for a subscriber, 0 for a
  non-subscriber
- [X] T020 Checkpoint P1: `flutter analyze` 0; `flutter test --concurrency=1 test/unit`;
  `node --test "supabase/functions/_shared/*.test.ts"`; `python test/fixtures/gen_pricing_vectors.py
  && python test/fixtures/gen_marketplace_vectors.py && git diff --exit-code test/fixtures`

---

## Phase 3: 004 cash amendment — FR-029 (plan P2; ships value alone, could merge first)

- [X] T021 `lib/features/wallet/presentation/labels.dart`: `priceLine` takes a `SeatPrice`; cash
  mode → `priceCash(price.cash!)`; cash mode with `cash == null` → the wallet line; other modes
  unchanged (fee 0 → `priceNoFee`)
- [X] T022 Switch the price-line callers to `priceLine(SeatPrice.of(contribution, tripCost:,
  riderSeats:, mode:))` using the group's basis: `lib/features/commute/presentation/match_result_screen.dart`,
  `lib/features/daily/presentation/today/rider_today.dart`,
  `lib/features/wallet/presentation/pay_method/pay_method_screen.dart` (keep its loading-frame guard:
  no quote while `view == null || view.riderSeats < 1`)
- [X] T023 `lib/features/wallet/presentation/wallet/rider_wallet.dart`: cash plan card uses
  `priceCash` of `SeatPrice.of(view.legShare, …basis, mode: cash).cash`
- [X] T024 `lib/features/daily/presentation/today/cash_after_trip.dart`: extract the cash row into
  `lib/features/daily/presentation/today/cash_received_row.dart` (fed by a `SeatPrice` + rideId +
  rider), label "Received N EGP cash" and recorded `CashMark.amount` both = `SeatPrice.cash`
- [X] T025 Widget tests at contribution 44 (160/3), ar + en: `test/widget/commute_screens_test.dart`
  ("Pay 45 EGP cash" on the match result), `test/widget/driver_cash_test.dart` ("Received 45 EGP
  cash" and stored `CashMark.amount == 45`), `test/widget/rider_wallet_test.dart` (cash plan card
  45); the demo corridor (40) still reads 40 everywhere
- [X] T026 Checkpoint P2: gates green; regenerate only goldens whose image actually changed (check
  `git status` after `--update-goldens`)
  - Found while building: the cash activity row (`labels.dart` `cashPaidLine(contribution)`, a
    `cashTrip` entry's breakdown) still prints the contribution, not the cash amount — not one of
    contracts/pricing.md's four callers. Same on the demo corridor (40 = 40); diverges only off it.
    Pick up when Phase 4+ gives cash trips a `SeatPrice` (or `CashMark.amount`) to read.

---

## Phase 4: Model, store, seams (plan P3 — blocks all stories)

**Groups become data (R10)**

- [x] T027 [P] `lib/features/commute/domain/group.dart`: `toJson`/`fromJson` on `CommuteGroup`,
  `Member`, `Stop`, `Vehicle` (every field, incl. `tripCost`, `riderSeats`, per-member `legs`);
  `test/unit/group_json_test.dart` round-trips all seeded groups in `CorridorSeed.groups` (equality
  field by field)
- [x] T028 `lib/features/commute/data/group_catalog.dart` + `test/unit/group_catalog_test.dart`:
  `GroupCatalog(prefs, {seed = CorridorSeed.groups})` with `all()` (seed + `market.groups` + extra
  members from `market.members.<groupId>` merged), `byId`, `create` (id MUST start with `mk-`, else
  throws), `addMember`, `clear`; survives a new instance on the same prefs
- [x] T029 **R10 risk, before any UI** — `test/unit/one_leg_group_schedule_test.dart`: a created
  `mk-` group whose members all have `legs = {going}` only → `RotationPlanner.plan` (and
  `FakeDailyCommuteRepository.schedule`/`ride`) yield **no** return-leg assignment, no "no driver"
  day and no `noCover` notice over a full 28-day period; same for return-only. If red, fix
  `lib/features/daily/domain/rotation_planner.dart` / `schedule.dart` so a leg nobody rides is not
  planned, and re-run `test/unit/rotation_planner_test.dart` + `test/unit/daily_vectors_test.dart`
  (the TS `rotation.ts` twin MUST stay in step — update it and its vectors in the same task if the
  rule changes)
  - **Done 2026-10-13**: red, but not in the planner — `RotationPlanner` already returns no
    assignment for a leg no driver drives (Dart and TS agree; `rotation.ts` + vectors unchanged).
    The hole was `FakeDailyCommuteRepository._me`: the joining person got legs from their own
    profile (a driver of both legs, or a rider whose return time fits), so a one-leg group planned
    a second leg with no car. Fix: the person's legs stay inside `CommuteGroup.legs` (legs any
    member rides or drives).
- [x] T030 Wire the catalog: `lib/features/commute/data/fake_commute_repository.dart` (`groupsFor`,
  `join` read `GroupCatalog`), `lib/features/daily/data/fake_daily_commute_repository.dart` (replace
  the `groups` constructor list), one `groupCatalogProvider` in
  `lib/features/commute/data/providers.dart` whose invalidation invalidates the commute and daily
  repositories (`lib/features/daily/data/providers.dart`); update `test/helpers/daily_fakes.dart`;
  existing 003/004 suites stay green

**Marketplace domain (data-model.md)**

- [X] T031 [P] `lib/features/marketplace/domain/anonymous_rider.dart` (`isWoman`, `rating?`; no name,
  initials, photo or member id) and `offered_trip.dart` (`OfferedTrip` all data-model fields; enums
  `Repeat {once, daily}`, `OfferStatus {open, full, departed, done, cancelled, grouped}`,
  `OfferOrigin {published, fromRequest}`; `seats` 1–4 and ≤ `riderSeats`; JSON)
- [X] T032 [P] `lib/features/marketplace/domain/trip_request.dart` (`TripRequest`, `RequestStatus
  {posted, accepted, withdrawn, cancelled, expired}`, `detourFrom: Map<Area,int>`, fixed `SeatPrice`;
  JSON) and `booking.dart` (`Booking`, `BookingSource {groupSeat, offer, request}` with ids,
  `PaidBy {wallet, cash, plan}`, `BookingStatus {booked, done, cancelled, reclaimed, refunded}`,
  `rideId` = 003 `Ride.idFor` for group seats / `offer:<tripId>`; `reclaimable(now)` =
  `!isSubscriber && !AttendanceRules.isLate(date, bookedAt) && !AttendanceRules.isLate(date, now)`;
  JSON)
- [X] T033 [P] `lib/features/marketplace/domain/seat_offer.dart` (derived, never stored) and
  `driver_day.dart` (`DriverDay {date, trips: List<DayTrip>, leadsGroup}`)
- [X] T034 `test/unit/marketplace_models_test.dart`: JSON round trip for `OfferedTrip`,
  `TripRequest`, `Booking`; `reclaimable` at 20:59 / 21:00 / 21:01 the evening before and for a
  same-day booking; subscriber never reclaimable
- [X] T035 `lib/features/marketplace/domain/marketplace_repository.dart`: the interface exactly as
  contracts/repositories.md, sealed results `BookResult`, `PublishResult`, `AcceptResult`,
  `PostResult`, `ReclaimResult`, `CancelResult`, `DemoResult`; `TripDraft`, `OfferDraft`,
  `OfferLive`, `RequestCard` (no name, no photo — FR-023), `PartOfDay {morning, evening}`
  - Built with choices the contract left open: `reclaimable` also needs `status == booked` (a
    cancelled/done booking holds no seat); `CancelResult` = `BookingCancelled(refund)` |
    `NotCancellable`; `DemoResult` = `DemoDone` | `DemoNothing` | `DemoTooLate` (US6 "Too late to
    reclaim"); `TripDraft`/`OfferDraft` carry leg, from, to, time, repeat (+ seats, contribution) —
    no day (R13) and no free price (FR-022); `OfferLive.riders` = `LiveRider {AnonymousRider,
    firstName?}`; `SeatOffer.driver` = `SeatDriver {id, firstName, initials, rating}`. `SeatPrice`
    gained `toJson`/`fromJson` + value equality (stored quotes are fixed).

**Seams (R9)**

- [X] T036 [P] `lib/features/wallet/domain/activity_entry.dart`: `ActivityKind.seatBooked` (amount =
  paid, fee, `rideId`) and `seatRefund` (credit, `rideId`); `lib/features/wallet/domain/wallet_repository.dart`:
  `SeatLedger` interface per contracts/repositories.md
- [X] T037 `lib/features/wallet/data/fake_wallet_repository.dart` implements `SeatLedger`:
  `debitSeat` writes one `seatBooked` row (fee recorded); a simulated `FakePaymentProvider` failure
  leaves balance and activity untouched; `refundSeat` writes one `seatRefund` row, none when amount
  is 0. Tests in `test/unit/fake_wallet_repository_test.dart` (44 debit → balance −44; refund 44 →
  balance back, one row each way — SC-005; failure → unchanged — SC-006)
- [X] T038 `lib/features/wallet/data/fake_wallet_repository.dart`: constructor callback
  `Future<List<DoneOneOff>> Function() oneOffs` (`DoneOneOff = {rideId, date, leg, paidBy,
  contribution, tripCost, riderSeats, riderId, driverId}`); rider: cash ones interleaved into the 004
  cash-trial fold by date then leg (count toward the 10, banner after 7, "Didn't pay" strikes);
  wallet/plan ones skipped (already debited); one ride, one charge (R10): a group trip whose rideId
  has a `seatBooked` debit for that person is not billed again, and a cash one-off sharing a group
  trip's rideId counts as one cash trip; driver: one `tripIncome` row per (trip, non-cash rider),
  idempotent by id. Default `() async => []` so existing tests are untouched; new tests in
  `test/unit/fake_wallet_repository_test.dart` (incl. seatBooked 44 + kept group trip on the same
  rideId → balance −44 once)
  - Built with choices the contract left open: `PaidBy` moved to `wallet/domain/done_one_off.dart`
    (beside `DoneOneOff`; `booking.dart` re-exports it) so the wallet never imports the marketplace
    (R9); `PaymentProvider` gained `debit({amount})` so a seat debit can fail like a top-up (SC-006);
    `debitSeat`/`refundSeat` are idempotent by `bookingId`; a 003 `Charge` on a ride paid at booking
    is skipped too (same one-ride rule; the booking refund already nets what is owed — R7); a cash
    one-off past the trial is a wallet trip at its own basis, fee-free only if a plan started before
    that day (a one-off has no group time; avoids 004 R14 re-pricing); a once user with no group
    gets cash one-offs folded (003 charges/absences still need a group).
  - Gap, not in T036–T039: `FeeSavingsCalculator.feesInMonth` counts `trip` rows only, so seat fees
    don't feed the "you paid X in fees" upsell yet (refunds return the fee in full — R7).
- [X] T039 [P] `lib/features/wallet/presentation/labels.dart` (`activityLabel`): rows for
  `seatBooked` ("seat", 40 + 4 fee breakdown) and `seatRefund` ("Refund")
- [ ] T040 `lib/features/daily/domain/notice.dart`: add `NoticeKind.seatBooked`, `seatReclaimed`,
  `requestAccepted`, `requestExpired`, `tripCancelledByDriver` and `abstract interface class
  NoticeSink { Future<void> post(NoticeKind kind, Map<String, String> params); Future<void>
  recordReliability(ReliabilityEvent e); }` per contracts/repositories.md (FR-017, R9: existing
  `ReliabilityEventKind.lateCantDrive`, appended to 003's event list so `ReliabilityRules.compute`
  counts it); `FakeDailyCommuteRepository` implements it, posted notices reach 003's
  bell/inbox stream unchanged; copy for the five kinds in `lib/features/daily/presentation/labels.dart`;
  `seatReclaimed` notice renders "Empty seats" / "Post your trip" actions like the no-cover notice;
  tests in `test/unit/fake_daily_repository_test.dart`

**Store**

- [ ] T041 `lib/features/marketplace/data/market_seed.dart` (R14): 12 open morning requests SZ→SV
  going 7:00–8:00 (mixed women/men, once/daily, rating or `null` = New, `detourFrom` per area); 4
  evening requests; offers `of-seed-tarek` (once, SZ→SV going 7:30, 3 seats, contribution **44**) and
  `of-seed-heba` (daily, return 17:10, 3 seats, 40); a fake rider pool and a fake driver pool for the
  demo actions
- [ ] T042 `lib/features/marketplace/data/fake_marketplace_repository.dart`: constructor takes
  prefs, `GroupCatalog`, `DailyCommuteRepository`, `NoticeSink`, `SeatLedger`, wallet/plan reader,
  `TrustRepository`, session/person id; storage keys `market.offers`, `market.requests`,
  `market.bookings`, `market.groups`, `market.members.<groupId>`, `market.seedCursor`; seeded items
  read from `MarketSeed` and overlaid with stored status changes; `driverDay(date)` per R5 (group legs
  the person actually drives — backup-covered or driverless legs excluded; offered trips open / full /
  done / cancelled-with-riders; trips created by accepting; `leadsGroup`); `doneOneOffs()` for T038;
  `clear()` removes every `market.*` key. Story methods throw `UnimplementedError` until their phase
- [ ] T043 `test/unit/fake_marketplace_repository_test.dart` (driver day): group leg counts; a leg
  covered by a backup doesn't; offer cancelled with no bookings is dropped (R5), cancelled with a
  booking counts; `leadsGroup` true for sz-0725's driver
- [ ] T044 `lib/features/marketplace/data/providers.dart`: `marketplaceRepositoryProvider` wiring
  the seams; pass `FakeMarketplaceRepository.doneOneOffs` into the wallet repository provider's
  `oneOffs`; `lib/features/settings/presentation/demo_section.dart` `_reset` also clears `market.*`
  and `GroupCatalog.clear()` (test in `test/unit/fake_marketplace_repository_test.dart`: reset leaves
  no `market.*` key)
- [ ] T045 Checkpoint P3: gates green (all 003/004 tests untouched and passing)

---

## Phase 5: User Story 1 — Rider books an empty seat (P1, plan P4) 🎯 MVP

**Goal**: a once rider or group member books a free seat at the right price; Today shows it.
**Independent test**: quickstart §1 + §2 — prices 44 / 40 subscribed / Pay 40 cash; Tarek's 48 /
45; seat count drops; wallet −44; one-off card on Today.

### Tests (write first, see them fail)

- [ ] T046 [P] [US1] `test/unit/fake_marketplace_repository_test.dart` (US1 group): `seatOffers` —
  route fit (same from/to, detour < 10), women-only preference lists only women-driven cars/offers,
  departed legs gone, free 0 not listed, the rider's own leg hidden (`alreadyRiding`), a driver's own
  offer not listed, a full car with a reclaimable one-off booking listed to a subscriber only (FR-004,
  US6 AC1); `book` — wallet 44 debited once, seat drops by one, one booking per rider per
  leg-date, `seatTaken` when the last seat goes between list and book (balance/seats/activity
  unchanged — SC-006), `paymentFailed` unchanged, `needsMethod`, `topUp(44)` at balance 0, company
  at negative balance not blocked, cash debits nothing; `cancelBooking` — before cut-off refund 44,
  after cut-off 24 (owed 20 → driver `Charge`, fee back); `myBookings` oldest first
- [ ] T047 [P] [US1] `test/widget/empty_seats_test.dart`, ar + en: loading; list (Going/Return
  toggle, route line, card: avatar, name, rating, pickup, time + day label, seats left, price line,
  Book seat); price per mode ("44 EGP · 40 to the driver + 4 service fee", "40 EGP · no fees
  (subscribed)", "Pay 40 EGP cash to the driver", Tarek "48 … 44 + 4" / "Pay 45 EGP cash"); caption
  `seatRule`; dashed `nothingFits` card; empty state; already riding; error + retry; booked summary
  with upsell (non-subscriber) / "Back to today" (subscriber); top-up gate "Top up 44 EGP first";
  seat just taken banner + refreshed list; late-booking note shown before confirm after 9 PM
- [ ] T048 [P] [US1] `test/widget/marketplace_navigation_test.dart`: rider Just one trip → Empty
  seats, Back → frequency; Today "Need an extra trip? Book a seat" → Empty seats on the group's leg,
  Back → Today; no-cover "Book an empty seat" → that day's leg; Book with no method → PayMethod →
  back to the same seat (`seat=` kept); upsell → commute setup with Every day preselected;
  **SC-001**: a group member with a method and enough balance goes Today → booked in ≤ 3 taps
  (count the taps in the test)

### Implementation

- [ ] T049 [US1] `fake_marketplace_repository.dart`: `seatOffers`, `book` (re-check free seats +
  `BookingGate` inside the write; `SeatLedger.debitSeat` for wallet/subscribed/company; notice
  `seatBooked` to the driver), `cancelBooking` (`BookingRefund.amount`, owed via
  `AttendanceRules.cancelCharge` on the contribution only → driver `Charge`), `myBookings`; women-only
  via `lib/features/daily/domain/privacy.dart`
- [ ] T050 [P] [US1] `lib/features/marketplace/presentation/labels.dart`: day label
  (Today/Tomorrow/weekday), route line, price line delegating to `WalletLabels.priceLine(SeatPrice)`
- [ ] T051 [US1] `lib/features/marketplace/presentation/empty_seats/empty_seats_controller.dart`
  (Riverpod, `@riverpod`): leg, offers, book → result state; run `dart run build_runner build`
- [ ] T052 [P] [US1] `lib/features/marketplace/presentation/empty_seats/seat_card.dart`
  (GooraCard/GooraAvatar/GooraPill; Book seat ≥ 44 px with a semantic label)
- [ ] T053 [P] [US1] `lib/features/marketplace/presentation/empty_seats/booked_view.dart` (summary;
  upsell card for non-subscribers, "Back to today" for subscribers)
- [ ] T054 [US1] `lib/features/marketplace/presentation/empty_seats/empty_seats_screen.dart`: every
  state in contracts/navigation.md "Empty seats"; Back = `canPop() ? pop() : go(Routes.frequency)`
- [ ] T055 [US1] `lib/app/routes.dart` + `lib/app/router.dart`: real `/empty-seats` route with
  `leg` and `seat` query params (drop `PlaceholderKind.emptySeats` from the placeholder loop)
- [ ] T056 [US1] `lib/features/wallet/presentation/pay_method/pay_method_screen.dart` + router:
  optional `next` location; after choosing, `go(next)` instead of Today; test in
  `test/widget/pay_method_screen_test.dart`
- [ ] T057 [US1] Entry points: `lib/features/daily/presentation/today/rider_today.dart` ("Need an
  extra trip?" pushes Empty seats with the group's next leg), `today_widgets.dart` no-cover card
  ("Book an empty seat" pushes Empty seats for that day's leg)
- [ ] T058 [US1] `lib/features/commute/presentation/commute_setup_screen.dart`: accept a preset
  frequency so the upsell opens it with "Every day" chosen
- [ ] T059 [US1] `lib/features/marketplace/presentation/today/one_off_section.dart` (rider side) +
  `oneOffTodayProvider`: booked seat card (route, day/time, driver card, pickup, `SeatPrice` line,
  Cancel booking with the 003 rule caption, Share, SOS); a booking whose rideId is the person's own
  group ride is not shown here (the group card shows it, R10); add the section to `rider_today.dart`
- [ ] T060 [US1] No-group Today: split 003's `TodayView.removed` in
  `lib/features/daily/presentation/today/today_controller.dart` into `removed` (lost a group, 003
  copy unchanged) and `noGroupYet`; `today_screen.dart` shows the one-off section, entry points and a
  calm `noGroupYet` empty state; while a one-off trip is running, Share and SOS stay one tap away in
  the no-group state too (Constitution V); tests in `test/widget/today_rider_test.dart`
- [ ] T061 [US1] `lib/features/onboarding/presentation/onboarding_routes.dart`: `routeForSession`
  sends a once user with any one-off booking / open offer / open request to Today (R12); test in
  `test/unit/onboarding_flow_test.dart`
- [ ] T062 [US1] Checkpoint P4: gates green; quickstart §1–§2 reachable on the demo seed

---

## Phase 6: User Story 2 — Driver offers a trip (P2, plan P5)

**Goal**: a verified driver publishes once/daily; seats fill; daily becomes a group; cancel refunds.
**Independent test**: quickstart §3.

### Tests

- [ ] T063 [P] [US2] `test/unit/fake_marketplace_repository_test.dart` (US2 group): `publish` —
  `notVerified([license, vehicle])`, `limit(TripFit)` for every non-create kind, contribution
  outside `PricingService.range` rejected; `live` — anonymous riders before departure, first names
  from departure; status open → full → (cancel booking) open → departed → done by the clock; daily
  offer's first booking → `mk-of-…` group in `GroupCatalog` (driver = me, one leg, price = contribution,
  basis = offer) and status `grouped`, its bookings re-keyed to `Ride.idFor(mk-of-…, date, leg)`,
  and the first booker charged once for that ride (one `seatBooked`, no group-trip debit on the same
  rideId, R10); `cancelOffer` — every booking refunded in full (SC-005), each rider gets
  `tripCancelledByDriver`, one `lateCantDrive` reliability event recorded via
  `NoticeSink.recordReliability` **only** when cancelled after the 9 PM cut-off with ≥ 1 booking
  (before the cut-off → none; no bookings → none), the trip still counts in `driverDay`;
  `demoRiderBooks` books the latest open offer from the rider pool
- [ ] T064 [P] [US2] `test/widget/offer_trip_test.dart`, ar + en: chips (missing → "License not
  verified — verify", tap → Trust), From/To/Time + resolved day, seats, Just once/Every workday,
  stepper starts at 40, 2 EGP steps, stops at 32 and 48, label "Suggested price" / "2 EGP above
  suggested", rider price "44 EGP" under it; three rules with check icons; Publish off with
  `dailyLimitReached` / `joinsTripInstead` / `overlapTrip` / `oneGroupOnly` words; live state "0 of 3
  seats booked" + GooraProgressBar + anonymous rows; full "Your car is full!"; live-state loading and
  error + retry (FR-027); no price input field anywhere (FR-022)
- [ ] T065 [P] [US2] `test/widget/today_driver_test.dart`: driver one-off section shows the offered
  trip card (progress, anonymous riders, Cancel trip; Share + SOS one tap away from departure to
  done, Constitution V) and, after `done`, "Received 40 EGP cash" / "Didn't pay" rows for cash riders
  writing `CashMark` with `rideId = offer:<id>`; a driver with no group and only a once trip still
  sees Share + SOS during it

### Implementation

- [ ] T066 [US2] `fake_marketplace_repository.dart`: `publish`, `offer`, `live`, `cancelOffer`,
  `demoRiderBooks` (daily first booking → `GroupCatalog.create` + `CommuteRepository.join` for the
  driver, bookings re-keyed to the group's ride ids, R10 one ride one charge); `book` on an offered
  trip uses the offer's basis; `cancelOffer` records reliability per R9 (late only)
- [ ] T067 [P] [US2] `lib/features/daily/data/fake_trust_repository.dart`: `demoVerifyDriver()`
  sets ID, license and vehicle verified (debug only); test in `test/widget/trust_test.dart` or
  `test/unit/` alongside
- [ ] T068 [P] [US2] `lib/features/marketplace/presentation/route_form.dart`: shared From / To /
  Time / Just once–Every workday form with the resolved-day line (R13), used by C and B
- [ ] T069 [US2] `lib/features/marketplace/presentation/offer_trip/offer_trip_controller.dart` +
  `offer_trip_screen.dart`: form (GooraStepper on `PricingService.range`, 002 stepper keys, rider
  price via `SeatPrice.of`), Publish disabled reasons from `DriverDayRules.fit`, live / full /
  departed / done / cancelled states (contracts/navigation.md "Offer a trip"); `?id=` re-enters the
  live state; Back rule
- [ ] T070 [US2] `lib/app/routes.dart` + `router.dart`: real `/offer-trip` (+ `id`), drop
  `PlaceholderKind.offerTrip`; driver Just one trip → Offer a trip, Back → frequency; driver Today
  "Offer a trip" pushes, Back → Today
- [ ] T071 [US2] `lib/features/marketplace/presentation/today/one_off_section.dart` (driver side):
  offered trip card with Share + SOS (fed by the once trip, `rideId = offer:<id>`, not by 003's
  `TodayView`) + after `done` the cash rows via `cash_received_row.dart`; add to
  `lib/features/daily/presentation/today/driver_today.dart`
- [ ] T072 [US2] `lib/features/settings/presentation/demo_section.dart`: "Verify my driver
  documents" and "A rider books your seat" (debug only, `kDebugMode`, snackbar result like the
  other demo buttons)
- [ ] T073 [US2] Checkpoint P5: gates green; quickstart §3 reachable

---

## Phase 7: User Story 3 — Rider posts a trip (P2, plan P6)

**Goal**: post → sent to N drivers → accepted (once seat / daily group) or expired, never charged
unless booked. **Independent test**: quickstart §4.

### Tests

- [ ] T074 [P] [US3] `test/unit/fake_marketplace_repository_test.dart` (US3 group): `post` —
  `needsMethod`, `topUp(gap)` against the route's price, `dailyNotAllowed` for a rider already in a
  group, `posted` with a fixed `SeatPrice` (contribution = suggestion 40 at the 3-seat basis);
  `driversOnRoute` counts drivers whose area detour < 10 and whose privacy allows the rider;
  `cancelRequest` free; `request` expires on read at date+time (no charge, `requestExpired` notice);
  `demoDriverAccepts` — once → `Booking` paid at accept (wallet −44), `requestAccepted` notice; daily →
  `mk-rq-…` group created (or member added to a driver's group leg), rider joined, **nothing charged
  at accept** (trips billed as 004 group trips, FR-013); gate fails at accept → `withdrawn`, nothing
  charged; expired request → balance and activity unchanged, no row (SC-005)
- [ ] T075 [P] [US3] `test/widget/post_trip_test.dart`, ar + en: form prefilled from the rider's
  route, three rules, Post; daily disabled with "You're already in a daily group"; top-up gate;
  posted "Sent to N drivers on your route" + progress + Cancel request; accepted (driver card,
  pickup, time, price line); daily accepted "You're now a commute group" → PayMethod `next=/today`;
  expired "No driver took this trip in time. Nothing was charged." + Post again / See empty seats;
  posted-state loading and error + retry (FR-027)
- [ ] T076 [P] [US3] `test/widget/marketplace_navigation_test.dart`: Empty seats dashed card → Post
  your trip, Back → Empty seats; no-match "Post your trip" now `push`, Back → no-match; no-cover
  "Post your trip" → Back → Today

### Implementation

- [ ] T077 [US3] `fake_marketplace_repository.dart`: `post`, `cancelRequest`, `request`,
  `driversOnRoute`, `demoDriverAccepts` (shares the accept path T085 builds on)
- [ ] T078 [US3] `lib/features/marketplace/presentation/post_trip/post_trip_controller.dart` +
  `post_trip_screen.dart`: form · daily disabled · top-up gate · posted · accepted · expired
  (contracts/navigation.md "Post your trip"); `?id=` re-entry; Back rule
- [ ] T079 [US3] Entry points: `lib/features/commute/presentation/no_match_screen.dart` `go` → `push`;
  Empty seats dashed card; no-cover card already pushes
- [ ] T080 [US3] Remove placeholders (FR-002): real `/post-trip` (+ `id`) in `lib/app/router.dart`;
  delete `lib/features/placeholder/`, `PlaceholderKind`, `_placeholderPaths` and the router loop; fix
  any test that referenced them
- [ ] T081 [US3] `demo_section.dart`: "A driver accepts your request"
- [ ] T082 [US3] Checkpoint P6: gates green; quickstart §4 reachable

---

## Phase 8: User Story 4 — Driver finds riders (P2, plan P7)

**Goal**: browse anonymous requests; accept creates or joins a trip within the 2-trip limit.
**Independent test**: quickstart §5 (Trips left 2 → 1 → 1 → 0, then "Daily limit reached").

### Tests

- [ ] T083 [P] [US4] `test/unit/fake_marketplace_repository_test.dart` (US4 group):
  `requestsForMe` — only detour < 10 from the driver's area, driver's own privacy preference applied,
  women-only requests only to women drivers, `leavingFrom` and part-of-day filters, each card's `fit`
  from `DriverDayRules`; `accept` — create (`OfferedTrip` origin `fromRequest`, basis riderSeats 3,
  seats = min(car seats, 3), contribution = request price) → `created(1)`; join within ±30 →
  `joined(7:30)`, tripsLeft unchanged; other direction → `created(0)`; `refused(doesntFit | full |
  limitReached)`; `riderCantPay` → request withdrawn; the quickstart §5 sequence as one test
- [ ] T084 [P] [US4] `test/widget/find_riders_test.dart`, ar + en: "Leaving from" filter (All + each
  corridor area), Morning/Evening, "Trips left today 2"; card (route, Verified rider / (woman),
  pickup, time, once/daily, rating or New, fixed price) in every state — inline confirm "This
  creates your trip: … · 7:30 AM. Trips left after this: 1", "This joins your trip at 7:30 AM",
  "Doesn't fit your trip", "Your car is full", "Daily limit reached" (not acceptable); empty +
  privacy caption; error; **SC-004**: no seeded first name and no avatar anywhere on the screen
  before departure; no price input (FR-022)

### Implementation

- [ ] T085 [US4] `fake_marketplace_repository.dart`: `requestsForMe`, `accept` (gate re-check;
  create/join; daily request joining one of the driver's group legs → `GroupCatalog.addMember`;
  `requestAccepted` notice to the rider)
- [ ] T086 [P] [US4] `lib/features/marketplace/presentation/find_riders/request_card.dart`: every
  `TripFit` state as words (never colour alone), Accept ≥ 44 px with a semantic label, inline confirm
  for `create`; takes `RequestCard` only (no name/photo reachable)
- [ ] T087 [US4] `lib/features/marketplace/presentation/find_riders/find_riders_controller.dart` +
  `find_riders_screen.dart` ("Requests near you"; loading/list/empty/error)
- [ ] T088 [US4] `lib/app/routes.dart` + `router.dart`: new `Routes.findRiders = '/find-riders'`;
  driver Today "Find riders" pushes it (today it pushes `offerTrip`); Offer a trip gains the text link
  "Or find riders who already posted" (`offer_trip_screen.dart`)
- [ ] T089 [US4] Checkpoint P7: gates green; quickstart §5 reachable

---

## Phase 9: User Story 5 — Driver Today requests (P3, plan P8)

**Goal**: driver Today's placeholder becomes live demand with US4's rules.
**Independent test**: quickstart §6.

- [ ] T090 [P] [US5] `test/widget/today_driver_test.dart`, ar + en: banner "12 people want Sheikh
  Zayed → Smart Village in the morning"; up to 3 cards with "+N min detour" and Accept; "See all" →
  Find riders; sz-0725's driver on a day driving both legs → cards near 7:25 read "Your car is full",
  the rest "Daily limit reached", no Accept; off-duty day → Accept → "Accepted ✓", counter drops;
  no matching requests → `noRequests` + privacy caption, not the old placeholder; SC-004 names check
- [ ] T091 [US5] `lib/features/marketplace/presentation/today/requests_section.dart`: banner
  (`demandBanner`, count = open requests on the driver's route in that part of day), cards via
  `request_card.dart` + detour, Accepted ✓, See all, empty state; replace the `reqsOnRoute`
  placeholder in `lib/features/daily/presentation/today/driver_today.dart`
- [ ] T092 [US5] Checkpoint P8: gates green; quickstart §6 reachable

---

## Phase 10: User Story 6 — Subscriber priority + full refund (P3, plan P9)

**Goal**: a subscriber takes a one-off seat before the 9 PM cut-off; the booker gets everything back.
**Independent test**: quickstart §7.

- [ ] T093 [P] [US6] `test/unit/fake_marketplace_repository_test.dart` (US6 group): `reclaim`
  before cut-off → booking `reclaimed`, one `seatRefund` of 44, balance = pre-booking value (SC-005),
  `seatReclaimed` notice with day + amount; at/after 21:00 → `tooLate`; booking made after the
  cut-off → `notReclaimable`; subscriber booking → `notReclaimable`; cash booking → nothing moves and
  it never appears in `doneOneOffs` (does not count toward the 10); a subscriber `book` on a full car
  takes the newest reclaimable seat (US6 AC1); `demoSubscriberTakes` picks the latest reclaimable
  booking
- [ ] T094 [P] [US6] `test/widget/empty_seats_test.dart` + `test/widget/rider_wallet_test.dart`: the
  refunded rider's Today no longer shows the trip, Wallet shows one "Refund" row, the notice offers
  Empty seats / Post your trip (both navigate); demo after 9 PM shows "Too late to reclaim — this
  booking is final."
- [ ] T095 [US6] `fake_marketplace_repository.dart`: `reclaim`, subscriber take-over inside `book`,
  `demoSubscriberTakes`
- [ ] T096 [US6] `demo_section.dart`: "A subscriber takes this seat"
- [ ] T097 [US6] Checkpoint P9: gates green; quickstart §7 reachable

---

## Phase 11: Polish + gate (plan P10)

- [ ] T098 [P] `supabase/migrations/20261012000000_marketplace.sql` (R17, droppable if the feature
  runs long): `offered_trips`, `trip_requests`, `bookings` with RLS on each; view
  `driver_request_cards` exposing `is_woman` and `rating`, never name or photo; not deployed
- [ ] T099 [P] `test/golden/marketplace_golden_test.dart`, RTL + LTR: seat card, booked view, request
  card (create/join/limit), offered-trip live card, one-off Today card, requests banner
- [ ] T100 [P] `test/widget/daily_accessibility_test.dart` (or a new
  `test/widget/marketplace_accessibility_test.dart`): Book seat / Accept / Publish / SOS have
  semantic labels and ≥ 44 px; every limit state readable as text; if any new colour token was added,
  pair it in `test/unit/contrast_test.dart`
- [ ] T101 [P] Confirm `test/architecture/no_hardcoded_values_test.dart` covers
  `lib/features/marketplace` (it scans `lib/features` recursively); fix any hit
- [ ] T102 [P] `specs/005-seat-marketplace/research.md` R16: list every 005 ARB key actually shipped
  (en + ar) for founder review; README section "Seat marketplace (feature 005)"
- [ ] T103 Gate: `flutter analyze` 0 issues · `flutter test --concurrency=1` all green ·
  `node --test "supabase/functions/_shared/*.test.ts"` · both vector generators re-run with no
  `git diff` in `test/fixtures`; `goora-brand` review checklist on every main state, ar + en (SC-007)
- [ ] T104 Quickstart §1–§8 on a device (`R5CNC0NK6ZT` or an emulator), Arabic and English — on the
  founder's personal phone check `mCurrentFocus` and no systemui before every tap
  (`flutter-lessons` #15); record results in research.md; no device connected → say so, don't block

---

## Dependencies & execution order

```text
Setup (T001)
  └─ Phase 2 rules + twins (T002–T020)
       ├─ Phase 3 004 cash amendment (T021–T026)   ← needs SeatPrice (T009); independent of Phase 4
       └─ Phase 4 model/store/seams (T027–T045)    ← T029 (one-leg risk) before any UI
            └─ US1 (T046–T062)  MVP
                 ├─ US2 (T063–T073)
                 │    └─ US4 (T083–T089)  ← needs offered trips + driverDay
                 │         └─ US5 (T090–T092)  ← reuses request_card + accept
                 ├─ US3 (T074–T082)  ← accept path shared with US4 (T077 ↔ T085)
                 └─ US6 (T093–T097)  ← needs US1 bookings only
Polish (T098–T104) last
```

- Story independence: US1 stands alone. US2 and US3 each need only US1's booking path. US4 needs
  US2's offered trips. US5 is US4's card + accept on Today. US6 needs only US1.
- Inside each story: tests → repository methods → controller → widgets → screen → routes → demo
  action → checkpoint.
- Shared files touched by several stories (do them in order, never in parallel):
  `fake_marketplace_repository.dart`, `lib/app/router.dart`, `demo_section.dart`, `driver_today.dart`,
  `one_off_section.dart`, `test/unit/fake_marketplace_repository_test.dart`.

## Parallel examples

- **Phase 2**: T002 + T004 + T008 + T010 + T012 + T013 + T014 + T017 + T018 + T019 (all different
  files); then T003 → T005/T006/T007; T011 → T015/T016.
- **Phase 4**: T027, T031, T032, T033, T036, T039 together; T028 → T029 → T030.
- **US1**: T046 + T047 + T048 (tests) together; T050 + T052 + T053 together once T049 lands.
- **US2**: T063 + T064 + T065 + T067 + T068 together.
- **US4**: T083 + T084 + T086 together.

## Implementation strategy

1. **MVP** = Setup → Phase 2 → Phase 3 → Phase 4 → US1. That alone sells existing empty seats at the
   right price with the cap and the cash rule proven, and amends 004's cash lines.
2. **Phase 3 can ship first**: it is the FR-029 fix to 004 and needs only T002–T009.
3. Then US2 → US3 → US4 → US5 → US6, one phase per session, each ending green and committed.
4. Drop order if time runs short: T098 (migration) first, then US6 (marketplace works without it).
5. Never push without the founder's OK.
