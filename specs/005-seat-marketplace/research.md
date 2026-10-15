# Phase 0 Research: Seat Marketplace

Every unknown from the plan's Technical Context is resolved here. Each entry: **Decision**,
**Rationale**, **Alternatives**. Entries marked *(founder to confirm)* are implementer readings of
the spec or brief that a founder may want to change; none blocks planning.

---

## R1 — Where the feature lives

- **Decision**: a new feature folder `lib/features/marketplace/{domain,data,presentation}`. It
  reads `commute` (groups, areas, pricing), `daily` (rides, schedule, notices, attendance rules)
  and `wallet` (payment method, plan, ledger). `daily` and `wallet` never import marketplace
  *domain* types. They see the marketplace only through two small seams (R9).
- **Rationale**: the four flows share one model (offers, requests, bookings, driver day) and one
  fake store. Splitting them across `commute`/`daily`/`wallet` would scatter a single rule set,
  the 2-trip limit, across three features.
- **Alternatives**: grow `daily` (it already has the 870-line fake repository and is tied to
  "my group" throughout, R11). Rejected.

## R2 — One price quote for every seat (FR-005, FR-029)

- **Decision**: one value object, `SeatPrice`, in `lib/features/wallet/domain/seat_price.dart`:
  `SeatPrice.of(contribution, tripCost:, riderSeats:, mode:)` → `contribution`, `fee`, `total`,
  `cash` (`int?`). It composes the existing `PricingService.serviceFee` with a new
  `PricingService.cashAmount`. Every price string and every charge in this feature reads a
  `SeatPrice`. The four 004 callers that print or record a cash amount switch to it (FR-029 amends
  004; see [contracts/pricing.md](contracts/pricing.md) "Callers").
- **Rationale**: today the cash price is "the contribution", repeated at four call sites. FR-029
  makes cash a different number from the contribution, so leaving four places to each remember
  to round invites drift. `PricingMode` already lives in `wallet/domain`, so the quote belongs
  next to it. `PricingService` stays a pure arithmetic rule with no plan or mode concepts.
- **Alternatives**: round inside `labels.priceLine` only. Rejected: the driver's "Received N EGP
  cash" and the recorded `CashMark.amount` would still use the unrounded contribution, and
  FR-029 says all three must match.

## R3 — The cash rounding rule (FR-029, founder 2026-10-12)

- **Decision**: `PricingService.cashAmount(c, tripCost:, riderSeats:)` → `int?`:
  1. `down = c − c % 5`, `up = down + 5` (when `c % 5 == 0`, `down == c`).
  2. `nearest = (c % 5 <= 2) ? down : up`. Ties can't happen because money is whole EGP and
     5 is odd.
  3. `r = range(tripCost, riderSeats)` (002's ±20% range, top already capped at or below
     `equalShare`). Start from `nearest`; if it is above `r.max`, use `down`; if the result is
     below `r.min`, use `up`.
  4. If the result is still outside `[r.min, r.max]`, or is `0`, return `null`: cash is not
     offered for that seat (wallet only).
  
  Worked rows (spec Edge Cases): at 160/3 (range 32–48, share 53) 44→45, 42→40, 41→40, 48→45,
  32→35; at 160/4 (range 26–38) 38→35; at 156/4 (range 26–38) 38→35; at 8/4 (range 2–2) 2→`null`.
- **Amended after /speckit-analyze (founder, 2026-10-12)**: steps 3–4 first checked only
  `equalShare`, which let 48 become 50 above the range top 48 (Constitution II: prices stay inside
  ±20%). The founder chose to keep cash inside the range rather than amend the constitution.
- **Twin**: `cashAmount` joins `supabase/functions/_shared/pricing.ts`. Every case in
  `test/fixtures/pricing_vectors.json` gains a `cash` field (number or `null`), plus named
  `cash:` rows for the spec's examples. `gen_pricing_vectors.py` computes them independently.
- **Sweep (SC-002)**: the existing cap sweep (`pricing_cap_sweep_test.dart`, `pricing.test.ts`)
  also asserts, for trip costs 20–1,000, rider seats 1–4 and every allowed contribution, that
  `cash` is `null` or a positive multiple of 5 with `r.min ≤ cash ≤ r.max` and `cash ≤ equalShare`.
- **Rationale**: these are the founder's words turned into integer arithmetic. Step 3 is what
  keeps riders' cash total within the trip cost (at most `riderSeats` riders, each paying at most
  `r.max ≤ equalShare`) and every cash price inside Constitution II's ±20%.
- **Alternatives**: banker's rounding, or always rounding down. Rejected: the founder said
  nearest 5, and down only when the cap requires it.

## R4 — The 2-trip limit and the ±30 min join rule (FR-019, FR-021, SC-003)

- **Decision**: a pure rule, `DriverDayRules.fit(trips, candidate)` →
  `TripFit {join(tripId), full(tripId), limitReached, doesntFit, oneGroupOnly, overlap,
  create(tripsLeftAfter)}`, with `tripsLeft(trips) = max(0, 2 − trips.length)`. Inputs are plain
  data: `DayTrip {id, leg, from, to, departure (minutes), durationMinutes, seats, taken}` and
  `Candidate {leg, from, to, departure, durationMinutes, daily, leadsGroup}`. Checks run in this
  order, and the first one that matches wins:
  1. **join**: some trip has the same leg, `from` and `to`, and `|departure diff| ≤ 30`, and
     `taken < seats`.
  2. **full**: as in 1, but every such trip is full.
  3. **limitReached**: `trips.length ≥ 2`.
  4. **doesntFit**: a trip already exists in that leg (direction).
  5. **oneGroupOnly**: `candidate.daily && leadsGroup` (FR-016, spec clarification).
  6. **overlap**: the candidate's window `[departure, departure + duration)` intersects another
     trip's window (edge case "can't be in two places"; half-open, so back-to-back is fine).
  7. **create**: `tripsLeftAfter = tripsLeft − 1`.
- **Why this order** *(founder to confirm the reading)*:
  - Brief §6.8 allows at most one trip per direction: a request "that doesn't fit an existing
    trip in that direction shows *Doesn't fit your trip*". So 2 trips means one going and one
    return.
  - Join comes before the limit because joining "does not use another trip" (brief, FR-019).
  - At 2 trips, every non-joinable request reads "Daily limit reached" rather than "Doesn't
    fit", as the brief words it ("Once 2 trips exist, every remaining request shows…").
  - `oneGroupOnly` gets its own outcome because "Doesn't fit your trip" would be false for a
    driver with no trip in that direction. New copy, R16.
- **Twin**: `supabase/functions/_shared/marketplace.ts` with the same inputs and outputs, plus
  `test/fixtures/marketplace_vectors.json` from a new `gen_marketplace_vectors.py`. That gives
  three readers on one file: the Dart vectors test, `marketplace.test.ts`, and the scripted
  sequences in `driver_day_rules_test.dart` (SC-003: random offer/accept/join sequences never
  exceed 2).
- **Alternatives**: count "offered trips" only and leave group legs out. Rejected by the
  founder's confirmation in the spec ("group legs count").

## R5 — Which trips count on a driver's day (FR-021)

- **Decision**: `DriverDay.of(date)` collects:
  - each group leg on that date where the person is the **actual** driver in the schedule (a
    leg covered by a backup, or with no driver, doesn't count; spec Edge Cases);
  - each of their offered trips on that date that is open, full, done, or **cancelled after a
    rider had booked** (spec US2 AC8);
  - each trip created by accepting a request.
  
  An offered trip cancelled with no bookings is dropped, so the trip is freed *(founder to
  confirm)*. A group leg becomes a `DayTrip` with the group's route, time, `riderSeats` as seats
  and the derived ride's passengers plus one-off bookings as taken.
- **Rationale**: "Max 2 offered trips per driver per day" protects against running a taxi. A
  published trip nobody booked carried no one, while a cancelled trip with riders did displace
  them. This is the least surprising reading of the two.
- **Alternatives**: always count cancelled offers. Rejected: a typo'd offer would then burn a
  trip for the day.

## R6 — Free seats and the cost cap (FR-004, FR-024)

- **Decision**: free seats on a leg-date = `riderSeats − riding − activeBookings`, floored at 0.
  "Riding" comes from 003's derived `Ride.passengers` for the person's own group (riders and
  off-duty drivers, absences excluded). For any other seeded group it is
  `riderSeats − group.freeSeats(leg)`. That is the seeded count, already net of its members,
  because 003 derives rides only for the person's group. Offered trips use their own seats and
  bookings. Seats are counted against **`riderSeats`, the price basis, not the car's physical
  seats**.
  - A booking whose rider already appears in that ride's passengers (they also became a member,
    R10 "One ride, one charge") is counted once, not twice.
  - **Subscriber view (US6 AC1, FR-004)**: for a subscriber, a one-off booking with
    `reclaimable(now)` counts as free, so a full car still lists. Booking it runs the reclaim
    (T093/T095). Non-subscribers never see it.
- **Rationale (the FR-024 proof)**:
  - Every seat price is ≤ `equalShare = ⌊tripCost ÷ riderSeats⌋`. That holds for the wallet
    total (004 v2.1), for subscribers (the contribution is within the range cap) and for cash
    (R3).
  - At most `riderSeats` seats are ever sold.
  - So riders' total ≤ `riderSeats × ⌊tripCost ÷ riderSeats⌋` ≤ `tripCost`.
  
  Counting the off-duty driver means 005 never sells the 4th place in a 160/3 car (T078 stays
  open, spec "Open").
- **Alternatives**: use `Ride.freeSeats`, which is the car's seats. Rejected: in `sz-0725`
  (Ahmed's car has 4 seats, `riderSeats` 3) that would sell a seat past the price basis.
- **Request basis**: a posted request is priced when it is posted. It uses the route's trip cost
  and the corridor's standard 3 rider seats, so its contribution is the suggestion (40) and the
  price is fixed (FR-022). A trip created by accepting it keeps that basis. Its capacity is
  min(driver's car seats, 3), so the price stays inside ±20% for the basis and the cap argument
  above holds.

## R7 — When a one-off seat is paid, and refunds (FR-006, FR-017, FR-025, SC-005)

- **Decision**:
  - **Wallet, subscribed and company riders** pay at booking: the wallet ledger posts a
    `seatBooked` debit of `SeatPrice.total` (fee recorded separately).
  - **Cash riders** pay nothing at booking. When the trip is done, it enters 004's cash-trial
    fold as a cash trip (FR-010, via the R9 seam).
  - **Refunds** post one `seatRefund` credit:
    - reclaim, driver cancel or expired accept: everything paid;
    - rider cancel: paid − owed. Owed is `AttendanceRules.cancelCharge(date, madeAt,
      contribution)`, the 003 rule on the contribution only. The fee is always refunded in full
      (spec Edge Cases). Owed goes to the driver as a 003-style `Charge`, with no Goora fee.
  - The rule `BookingRefund.amount(paidTotal:, fee:, owed:)` is a pure function, twinned in
    `marketplace.ts` with vectors (money).
  - **Company riders** are never blocked and may go below zero (FR-009, matching 004's group
    behaviour).
- **Rationale**: the spec clarification ("paid at booking, refunds return exactly what was paid")
  is a deliberate departure from 004 R7, which derives a charge at completion. A refund only
  makes sense if something was taken. One debit and at most one credit per booking is what
  SC-005 counts.
- **Alternatives**: derive one-off debits at completion like group trips. Rejected: a reclaimed
  booking would then show no money moving at all, which breaks "fully refunded".

## R8 — Booking enforcement (FR-008, FR-009)

- **Decision**: a pure rule, `BookingGate.check({hasArrangement, mode, cashOffered, balance,
  price})` → `ok | needsMethod | topUp(gap)`:
  1. No method and no plan → `needsMethod` (push 004's payment-method screen, then come back to
     the same seat, US1 AC6).
  2. `mode == company` → `ok`.
  3. `mode == cash && cashOffered` → `ok`.
  4. `balance ≥ price.total` → `ok`.
  5. Otherwise `topUp(price.total − balance)`.
  
  Checked at Book, at Post (against the price of the requested route), and again when a request
  is accepted. A failed check at accept turns the accept into "request withdrawn" (the rider is
  told to top up, and nothing is charged).
- **Rationale**: one rule for all three moments named in FR-009. The rule stays Dart-only for now
  (spec: "blocking a group member … is left for the server"). The server will write its own
  check against its own ledger.
- **Alternatives**: put it inside `WalletRepository`. Rejected: it then can't be unit-tested
  with the brief's numbers without a fake store.

## R9 — Seams so the features don't import each other in a cycle

- **Decision**: three narrow interfaces, each implemented by an existing fake:
  - **`NoticeSink`** (`daily/domain`): `post(NoticeKind, params)`, implemented by
    `FakeDailyCommuteRepository`. The marketplace posts `seatBooked`, `seatReclaimed`,
    `requestAccepted`, `requestExpired` and `tripCancelledByDriver`. The bell/inbox and Today
    alerts from 003 show them unchanged (in-app only, spec Assumptions).
    It also has `recordReliability(ReliabilityEvent)` (added after /speckit-analyze), which writes to
    003's reliability event list, so a driver's cancel counts on reliability (FR-017). The marketplace
    records one `ReliabilityEventKind.lateCantDrive` for the trip (rideId `offer:<tripId>`) only
    when the cancel is after the 9 PM cut-off (`AttendanceRules.isLate(date, now)`) and the trip had
    at least one booking. This matches 003, which records `lateCantDrive` only for a late can't-drive.
    Same implementer, same store, so there is no second seam.
  - **`SeatLedger`** (`wallet/domain`): `debitSeat(personId, bookingId, total, fee)` and
    `refundSeat(personId, bookingId, amount)`, both returning `PaymentResult`, implemented by
    `FakeWalletRepository`. A simulated failure leaves the ledger unchanged (004 R4 debug
    switch), which gives SC-006.
  - **`OneOffTrips` callback** passed into `FakeWalletRepository`: the person's done one-off
    trips (`rideId`, date, leg, paidBy, contribution, basis). The cash-trial fold counts the cash
    ones, and the driver wallet credits `tripIncome` for non-cash riders on the person's own
    finished once-trips.
- **Rationale**: the marketplace needs to write money and notices. The wallet needs to read
  marketplace trips for the cash trial. A callback and two interfaces keep both directions
  testable without an import cycle, the same pattern as 004's `_role` callback.
- **Alternatives**: one shared store class. Rejected: it would merge three features' storage.

## R10 — "Becomes a commute group" (US2 AC7, US3 AC4, FR-013, FR-016)

- **Decision**: a `GroupCatalog` in `commute/data` that reads `CorridorSeed.groups`, plus groups
  the marketplace created (`market.groups`, JSON), plus extra members added to existing groups
  (`market.members.<groupId>`). `FakeCommuteRepository.groupsFor` and
  `FakeDailyCommuteRepository` read the catalog instead of the constant list. This needs JSON
  for `CommuteGroup`, `Member`, `Stop` and `Vehicle`, which is new code with round-trip tests.
  A created group has:
  - id `mk-<offerOrRequestId>`, the offer's or request's route, and `days` = Sun–Thu;
  - `price` = the published contribution, `tripCost` and `riderSeats` = the offer's basis, and
    `freeSeats` derived;
  - one stop at the pickup point and time, and `rotationStart` = that week's Sunday;
  - **only the one leg** that was offered or requested, on every member.
  
  The person joins through `CommuteRepository.join(groupId)`. A driver's daily offer joins on its
  first booking, and a rider's daily request joins on acceptance, which then goes to the
  payment-method screen.
- **One ride, one charge** (added after /speckit-analyze, FR-016): a daily offer's first booker
  paid at booking and then becomes a member of the new group, whose schedule covers that same
  ride. Without a rule, 004's fold would bill that ride again and Today would show it twice. The
  rule:
  - when an offer becomes a group, its bookings are re-keyed to `Ride.idFor(mk-<id>, date, leg)`
    (group-seat bookings already carry 003's ride id);
  - the 004 fold counts each rideId once per person. A group trip whose rideId has a `seatBooked`
    debit is skipped, because it was paid at booking. A cash one-off with the same rideId as a
    group trip counts as one cash trip, not two;
  - Today shows that ride on the group card only, and the one-off section hides a booking whose
    rideId is the person's group ride;
  - free seats count that rider once (R6).
  A daily request accepted into a group charges nothing at accept. Its trips are 004 group trips
  from the start (spec US3 AC4, FR-013), so it needs no dedupe.
- **Risk to check first in tasks**: a one-leg group must yield **no** schedule assignment for
  the other leg. `RotationPlanner` must not plan a "no driver" return leg, or 003 would post a
  no-cover notice. This needs a unit test before any UI work.
- **Who may go daily** *(founder to confirm)*:
  - A driver who leads a daily group can't publish "Every workday" (spec, `oneGroupOnly`).
  - By the same one-group rule, a rider already in a group has "Every workday" turned off on Post
    your trip, with the reason shown. They can still post "Just once".
  - A daily request accepted into a trip that is one of a driver's group legs **adds the rider
    to that group**; a once request just books that day's seat.
- **Alternatives**: keep groups immutable and treat "becomes a group" as a label. Rejected: the
  spec requires Today and Week to show it "like any group from 003", and those read
  `myGroup()`.

## R11 — Today: where one-off trips show up (US1 AC8, US2 AC6, US5, FR-006)

- **Decision**:
  - `TodayController`/`TodayView` (003) stay as they are for group legs.
  - A separate `oneOffTodayProvider` (marketplace presentation) feeds a **"One-off trips"
    section** on both Todays:
    - the rider sees booked seats: route, day and time, driver card, pickup, `SeatPrice` line,
      "Cancel booking" with the 003 rule caption, Share and SOS;
    - the driver sees offered trips: seat progress, anonymous riders, Cancel trip, and after the
      trip the cash step.
  - 003's `TodayView.removed` splits in two: **removed** (had a group and lost it, 003) and **no
    group yet** (once users). The no-group state shows the one-off section, entry points and a
    calm empty state.
  - Driver Today's "Requests on your route" placeholder becomes the US5 section. "Find riders"
    points to the new route.
- **Lifecycle of a once trip in the fakes**:
  - It is time-driven: `open/full` → departed at its departure time → `done` at departure +
    duration (40 min, the 003 default).
  - There are **no pickup check-in or no-show marks for one-off trips in 005** *(founder to
    confirm)*. 003's check-in, marks and settle code is keyed to `myGroup()` (every driver
    action re-derives the ride from it), so reusing it means building a second ride source. In
    the fakes, the other side of a one-off trip is always a fake that shows up.
  - Departure stands in for boarding: from then on the driver sees booked riders' first names
    (FR-023, R15).
  - After `done`, cash riders get the same "Received N EGP cash" / "Didn't pay" rows. The 004
    `_CashRow` is extracted to a shared widget fed by a `SeatPrice`, and its marks go to the same
    `CashMark` store with `rideId` = the once trip's id.
- **Alternatives**: model each once trip as a 003 `Ride` inside `FakeDailyCommuteRepository`.
  Rejected for 005: about 15 methods re-derive rides from `myGroup()`, so the blast radius is
  large for a fakes-only demo. The server will own one ride table for both kinds.

## R12 — Navigation and entry points (FR-001, FR-002)

- **Decision**:
  - **Routes**: `emptySeats`, `postTrip` and `offerTrip` become real screens; `findRiders`
    (`/find-riders`) is new. Live states are re-entered with `?id=<offerOrRequestId>`, and the
    booked confirmation is a state of Empty seats, not a route.
  - **Back**: every new screen pops when it can (pushed from inside the app, so Back returns to
    where the user came from) and otherwise goes to `Routes.frequency` (the onboarding entry).
    The no-match screen and the no-cover card `push` Post your trip instead of `go`.
  - **Remove**: `PlaceholderScreen`, `PlaceholderKind` and their router loop.
  - **Payment method first** (US1 AC6): `PayMethodScreen` takes an optional `next` location.
    After choosing, it returns there instead of Today, so the rider confirms the same seat (the
    seat id stays in the Empty seats URL).
  - **Relaunch**: `routeForSession` sends a once user who has any one-off trip or open
    offer/request to Today instead of back to their onboarding destination *(implementer
    choice; FR-001 only covers the first visit)*.
- **Rationale**: this is go_router's existing redirect/`push` idiom, needs no new packages, and
  every Back path in FR-002 is testable with one widget test per entry point.

## R13 — Which day a "Just once" trip is for; listing times (FR-003, FR-012, US6)

- **Decision**:
  - **Empty seats**: lists each car leg's **next departure that hasn't left yet**. That is today
    if its time is still ahead, otherwise its next running day within 7 days. Each card is
    labelled "Today", "Tomorrow" or the weekday.
  - **Post / Offer**: the chosen time resolves to its next workday occurrence (Sun–Thu), today
    included if the time is still ahead. The screen shows the resolved day ("Tomorrow · 7:30
    AM"). There is **no date picker** *(founder to confirm; the brief shows none)*.
  - **Expiry**: a request expires uncharged when now ≥ its date + time. Offers and seats stop
    listing at departure.
  - **Reclaim** (FR-025): `AttendanceRules.isLate(tripDate, at)` decides it, the same 9 PM
    evening-before cut-off as 003. "Reclaimable" = booked before the cut-off **and** now before
    the cut-off.
- **Rationale**: the brief calls A "Empty seats today", yet US6 needs a seat for tomorrow before
  9 PM. "Next departure" covers both without a date picker.

## R14 — Seeds and demo actions (FR-028; standing blocker "pre-verified demo driver")

- **Decision**: a `MarketSeed` holds:
  - **12 open morning requests**, SZ→SV going, 7:00–8:00, mixed: women, once/daily, rating or
    "New". Each carries `detourFrom: {Area → minutes}`, and fit = detour from the driver's area
    < 10. This yields the brief's "12 people want Sheikh Zayed → Smart Village in the morning".
  - **4 evening requests**.
  - **Two fake offers**: Tarek, "Just once" SZ→SV 7:30, 3 seats at **44**, so wallet riders see
    44 + 4 = 48 and cash riders see **45**, which makes FR-029 visible on the demo corridor; and
    Heba, "Every workday" return 17:10, 3 seats at 40.
  - A **pool of fake riders** for "A rider books your seat" and a **pool of fake drivers** for "A
    driver accepts your request".
  
  Settings → Demo gains:
  - "A driver accepts your request" (the latest open request; daily → group).
  - "A rider books your seat" (the latest open offer; the first booking on a daily offer creates
    the group).
  - "A subscriber takes this seat" (the latest reclaimable booking; after the cut-off it shows
    a calm "Too late to reclaim").
  - **"Verify my driver documents"** *(implementer addition)*: sets license + vehicle to verified
    in `FakeTrustRepository`. This clears the standing blocker for live driver scenarios (004
    Scenario 3 and every 005 driver flow) on the founder's phone.
- **Rationale**: fakes-first, like 003/004. Each demo action stands in for exactly one other
  person.
- **Founder confirmation**: the verify action is a debug-only demo switch, like the demo clock.
  It never ships in release builds (`kDebugMode`, as `DemoSection` already is).

## R15 — Privacy on driver-facing lists (FR-023, SC-004)

- **Decision**: driver-facing presentation models carry an `AnonymousRider {isWoman, rating?}`
  and **never** a name, initials or avatar. The name lives only in the `Booking` record and is
  exposed to the driver's view model only once the trip has departed (R11's boarding stand-in).
  - **Women-only**:
    - a rider whose 003 privacy preference is Women only sees only cars driven by women;
    - her requests are offered only to women drivers;
    - a driver's own preference filters the requests they see, via 003's `privacy.dart` rule;
    - there are no other filters.
  - **SC-004 tests**: a widget test asserts, in both locales, that request and booked-rider cards
    contain none of the seeded first names before departure.
- **Note**: brief §6.8 copy says "Verified rider". The goora-brand lexicon prefers "passenger"
  for head-counts in English. Here "rider" is the brief's verbatim label for a person, not a
  count, so it stays. Seat counts use 003's existing "passengers" strings.

## R16 — Drafted copy (founder review, FR-026)

These strings come from the brief verbatim (§5, §6.8, §7) or reuse existing keys:

- `emptySeatsTitle`, `postReq`, `offerTitle`, `offerBtn`, `browseBtn`, `browseTitle`,
  `tripsLeftA`, `reqsOnRoute`, `extraTrip`, `noCoverEmptySeat`, `priceWithFee`,
  `priceSubscribed`, `priceCash`, `cashReceived`.
- "Liked it? Make it your daily commute", "Nothing fits your time? Post your trip", "Sent to N
  drivers on your route", "You're now a commute group", "Your car is full!", "This creates your
  trip: … Trips left after this: N", "This joins your trip at …", "Doesn't fit your trip", "Daily
  limit reached", "Verified rider", "Verified rider (woman)", "Accepted ✓", "N people want <route>
  in the <morning>".

The Arabic for the brief-verbatim English lines above is drafted here too, because the brief
gives English only for them. Drafted for review (Egyptian register, lexicon: مشوار · السواق ·
كرسي · موثّق):

| key | en | ar (draft) |
|---|---|---|
| seatsLeft | {count} seats left | فاضي {count} كراسي |
| bookSeat | Book seat | احجز الكرسي |
| seatRule | Subscribers get priority on empty seats. If a subscriber takes your seat before 9 PM the evening before, you get back everything you paid. | المشتركين ليهم الأولوية في الكراسي الفاضية. لو مشترك أخد كرسيك قبل ٩ بالليل اليوم اللي قبله، فلوسك كلها بترجعلك. |
| nothingFits | Nothing fits your time? Post your trip | مفيش حاجة على ميعادك؟ انشر مشوارك |
| alreadyRiding | You already have a ride on this trip. | إنت عندك توصيلة في المشوار ده خلاص. |
| seatBookedTitle | Seat booked | الكرسي اتحجز |
| upsellDaily | Liked it? Make it your daily commute | عجبك؟ خليه مشوارك كل يوم |
| backToToday | Back to today | ارجع للنهارده |
| lateBookingNote | It's past 9 PM the evening before, so cancelling now means paying half your share. | عدّت ٩ بالليل اليوم اللي قبله، فلو لغيت دلوقتي هتدفع نص نصيبك. |
| topUpFirst | Top up {gap} EGP first | اشحن {gap} ج الأول |
| seatJustTaken | That seat was just taken. Here's the updated list. | الكرسي ده لسه محجوز حالًا. دي القايمة بعد التحديث. |
| justOnce / everyWorkday | Just once / Every workday | مرة واحدة / كل يوم شغل |
| ruleNoBidding | The price is set by Goora — no bargaining | السعر بتحدده جورا — مفيش فصال |
| ruleCostShare | Drivers share costs, they don't profit | السواق بيشارك في التكلفة، مش بيكسب |
| ruleRoute | Only people on your route see it | اللي على خطك بس هيشوفوه |
| post | Post | انشر |
| sentToDrivers | {count, plural, =1{Sent to 1 driver on your route} other{Sent to {count} drivers on your route}} | اتبعت لـ{count} سواق على خطك |
| waitingDriver | Waiting for a driver to accept | مستنيين سواق يوافق |
| cancelRequest | Cancel request | الغي الطلب |
| requestAccepted | A driver accepted your trip | سواق وافق على مشوارك |
| nowGroup | You're now a commute group | بقيتوا مجموعة مشوار |
| requestExpired | No driver took this trip in time. Nothing was charged. | مفيش سواق أخد المشوار في ميعاده. محدش خصم منك حاجة. |
| postAgain / seeEmptySeats | Post again / See empty seats | انشر تاني / شوف الكراسي الفاضية |
| dailyNeedsNoGroup | You're already in a daily group | إنت في مجموعة يومية خلاص |
| verifyChip | {item} not verified — verify | {item} مش موثّق — وثّقه |
| suggestedPrice / aboveSuggested / belowSuggested | (reuse 002's stepper keys) | (as 002) |
| publish | Publish | انشر المشوار |
| dailyLimitReached | Daily limit reached | خلصت مشاوير النهارده |
| joinsTripInstead | This joins your trip at {time} | ده هيدخل على مشوارك الساعة {time} |
| seatsBooked | {booked} of {seats} seats booked | {booked} من {seats} كراسي اتحجزوا |
| carFull | Your car is full! | عربيتك اتملت! |
| verifiedRider / verifiedRiderWoman | Verified rider / Verified rider (woman) | راكب موثّق / راكبة موثّقة |
| newRider | New | جديد |
| cancelTrip | Cancel trip | الغي المشوار |
| tripCancelledRefund | {driver} cancelled the trip. You got back everything you paid. | {driver} لغى المشوار. فلوسك كلها رجعتلك. |
| leavingFrom / allAreas | Leaving from / All | طالع من / الكل |
| morning / evening | Morning / Evening | الصبح / بالليل |
| createsTrip | This creates your trip: {route} · {time}. Trips left after this: {count} | ده هيعمل مشوار جديد: {route} · {time}. هيفضلك بعده {count} |
| doesntFit | Doesn't fit your trip | مش على مشوارك |
| yourCarFull | Your car is full | عربيتك مليانة |
| oneGroupOnly | You already drive a daily group | إنت سايق مجموعة يومية خلاص |
| overlapTrip | You have another trip at that time | عندك مشوار تاني في نفس الوقت |
| accept / accepted | Accept / Accepted ✓ | وافق / اتوافق ✓ |
| demandBanner | {count} people want {route} in the {part} | {count} عايزين {route} {part} |
| detourMin | +{min} min detour | +{min} دقيقة لفّة |
| noRequests | No requests on your route right now. We'll show them here as they come in. | مفيش طلبات على خطك دلوقتي. هنعرضها هنا أول ما توصل. |
| privacyCaption | You'll see names when riders board. | هتشوف الأسامي لما الركاب يركبوا. |
| seatReclaimed | A subscriber took your seat on {day}. You got back {amount} EGP. | مشترك أخد كرسيك يوم {day}. رجعلك {amount} ج. |
| reclaimTooLate | Too late to reclaim — this booking is final. | فات الميعاد — الحجز ده نهائي. |
| oneOffTrips | One-off trips | مشاوير مرة واحدة |
| cancelBooking | Cancel booking | الغي الحجز |
| noGroupYet | No daily group yet | لسه مفيش مجموعة يومية |
| demoAcceptRequest / demoBookSeat / demoReclaim / demoVerifyDriver | A driver accepts your request / A rider books your seat / A subscriber takes this seat / Verify my driver documents | (debug only) سواق يوافق على طلبك / راكب يحجز كرسي / مشترك ياخد الكرسي ده / وثّق أوراق السواقة |

The `ruleNoBidding` Arabic uses "فصال" (bargaining), the everyday Egyptian word. It reads as
"no haggling", which is the Constitution II point. **Not** "مزايدة" (auction).

## R16 addendum — every 005 ARB key actually shipped (founder review)

Written at the end of the build, 2026-10-14, from the ARB files against `main`. The Arabic is Egyptian
colloquial and drafted; the wording is the founder's to approve or change. Keys from R16's table that
changed on the way: `riderPaysLine`, `dailyOfferNote`, `cancelTripConfirm`, `keepTrip`, `acceptConfirm`,
`requestWithdrawn`, `requestGone`, `findRidersLink`, `seeAll` and the Offer-a-trip labels were added; the
rest are the R16 draft.

| key | en | ar |
|---|---|---|
| seatsLeft | {count, plural, =1{1 seat left} other{{count} seats left}} | {count, plural, =1{فاضي كرسي واحد} =2{فاضي كرسيين} few{فاضي {count} كراسي} other{فاضي {count} كرسي}} |
| bookSeat | Book seat | احجز الكرسي |
| seatRule | Subscribers get priority on empty seats. If a subscriber takes your seat before 9 PM the evening before, you get back everything you paid. | المشتركين ليهم الأولوية في الكراسي الفاضية. لو مشترك أخد كرسيك قبل ٩ بالليل اليوم اللي قبله، فلوسك كلها بترجعلك. |
| nothingFits | Nothing fits your time? Post your trip | مفيش حاجة على ميعادك؟ انشر مشوارك |
| alreadyRiding | You already have a ride on this trip. | إنت عندك توصيلة في المشوار ده خلاص. |
| seatBookedTitle | Seat booked | الكرسي اتحجز |
| upsellDaily | Liked it? Make it your daily commute | عجبك؟ خليه مشوارك كل يوم |
| backToToday | Back to today | ارجع للنهارده |
| lateBookingNote | It's past 9 PM the evening before, so cancelling now means paying half your share. | عدّت ٩ بالليل اليوم اللي قبله، فلو لغيت دلوقتي هتدفع نص نصيبك. |
| topUpFirst | Top up {gap} EGP first | اشحن {gap} ج الأول |
| seatJustTaken | That seat was just taken. Here's the updated list. | الكرسي ده لسه محجوز حالًا. دي القايمة بعد التحديث. |
| justOnce | Just once | مرة واحدة |
| everyWorkday | Every workday | كل يوم شغل |
| ruleNoBidding | The price is set by Goora — no bargaining | السعر بتحدده جورة — مفيش فصال |
| ruleCostShare | Drivers share costs, they don't profit | السواق بيشارك في التكلفة، مش بيكسب |
| ruleRoute | Only people on your route see it | اللي على خطك بس هيشوفوه |
| post | Post | انشر |
| sentToDrivers | {count, plural, =1{Sent to 1 driver on your route} other{Sent to {count} drivers on your route}} | {count, plural, =1{اتبعت لسواق واحد على خطك} =2{اتبعت لسواقين على خطك} few{اتبعت لـ{count} سواقين على خطك} other{اتبعت لـ{count} سواق على خطك}} |
| waitingDriver | Waiting for a driver to accept | مستنيين سواق يوافق |
| cancelRequest | Cancel request | الغي الطلب |
| requestAccepted | A driver accepted your trip | سواق وافق على مشوارك |
| nowGroup | You're now a commute group | بقيتوا مجموعة مشوار |
| requestExpired | No driver took this trip in time. Nothing was charged. | مفيش سواق أخد المشوار في ميعاده. محدش خصم منك حاجة. |
| postAgain | Post again | انشر تاني |
| seeEmptySeats | See empty seats | شوف الكراسي الفاضية |
| dailyNeedsNoGroup | You're already in a daily group | إنت في مجموعة يومية خلاص |
| verifyChip | {item} not verified — verify | {item} مش موثّق — وثّقه |
| publish | Publish | انشر المشوار |
| dailyLimitReached | Daily limit reached | خلصت مشاوير النهارده |
| joinsTripInstead | This joins your trip at {time} | ده هيدخل على مشوارك الساعة {time} |
| seatsBooked | {booked} of {seats} seats booked | {booked} من {seats} كراسي اتحجزوا |
| carFull | Your car is full! | عربيتك اتملت! |
| newRider | New | جديد |
| cancelTrip | Cancel trip | الغي المشوار |
| tripCancelledRefund | {driver} cancelled the trip. You got back everything you paid. | {driver} لغى المشوار. فلوسك كلها رجعتلك. |
| leavingFrom | Leaving from | طالع من |
| allAreas | All | الكل |
| morning | Morning | الصبح |
| evening | Evening | بالليل |
| createsTrip | This creates your trip: {route} · {time}. Trips left after this: {count} | ده هيعمل مشوار جديد: {route} · {time}. {count, plural, =0{مش هيفضلك مشاوير بعده} =1{هيفضلك مشوار واحد بعده} other{هيفضلك {count} مشاوير بعده}} |
| doesntFit | Doesn't fit your trip | مش على مشوارك |
| yourCarFull | Your car is full | عربيتك مليانة |
| oneGroupOnly | You already drive a daily group | إنت سايق مجموعة يومية خلاص |
| overlapTrip | You have another trip at that time | عندك مشوار تاني في نفس الوقت |
| accept | Accept | وافق |
| accepted | Accepted ✓ | اتوافق ✓ |
| demandBanner | {count} people want {route} {part, select, morning{in the morning} evening{in the evening} other{}} | {count} واحد عايزين {route} {part, select, morning{الصبح} evening{بالليل} other{}} |
| detourMin | +{min} min detour | {min, plural, =1{+دقيقة لفّة} =2{+دقيقتين لفّة} few{+{min} دقايق لفّة} other{+{min} دقيقة لفّة}} |
| noRequests | No requests on your route right now. We'll show them here as they come in. | مفيش طلبات على خطك دلوقتي. هنعرضها هنا أول ما توصل. |
| privacyCaption | You'll see names when riders board. | هتشوف الأسامي لما الركاب يركبوا. |
| seatReclaimed | A subscriber took your seat on {day}. You got back {amount} EGP. | مشترك أخد كرسيك يوم {day}. رجعلك {amount} ج. |
| reclaimTooLate | Too late to reclaim — this booking is final. | فات الميعاد — الحجز ده نهائي. |
| oneOffTrips | One-off trips | مشاوير مرة واحدة |
| cancelBooking | Cancel booking | الغي الحجز |
| noGroupYet | No daily group yet | لسه مفيش مجموعة يومية |
| demoAcceptRequest | A driver accepts your request | سواق يوافق على طلبك |
| demoBookSeat | A rider books your seat | راكب يحجز كرسي |
| demoReclaim | A subscriber takes this seat | مشترك ياخد الكرسي ده |
| demoVerifyDriver | Verify my driver documents | وثّق أوراق السواقة |
| nSeatBooked | A rider booked a seat on your trip. | راكب حجز كرسي في مشوارك. |
| nRequestAccepted | {driver} accepted your trip at {time}. | {driver} وافق على مشوارك الساعة {time}. |
| actSeatBooked | Seat | كرسي |
| actSeatRefund | Refund | مرتجع |
| noSeatsOnRoute | No seats on your route right now | مفيش كراسي فاضية على طريقك دلوقتي |
| seatPayFailed | The payment didn't go through. Nothing was charged. | الدفع ماتمّش. ومخدناش منك حاجة. |
| seatChosen | Your pick | اختيارك |
| cancelFreeNote | Cancel free until 9 PM the evening before. After that you pay half your share. | الإلغاء ببلاش لحد ٩ بالليل اليوم اللي قبله. بعدها بتدفع نص حصتك. |
| offerFromLabel | Leaving from | طالع من |
| offerToLabel | Heading to | رايح |
| offerTimeLabel | Leaving at | ميعاد الخروج |
| riderPaysLine | Riders pay {amount} EGP | الراكب بيدفع {amount} ج |
| dailyOfferNote | Once someone books, this becomes your daily commute group. | أول ما حد يحجز، المشوار ده بيبقى مجموعة يومية. |
| noRidersYet | No one has booked yet. Riders appear here as they book. | لسه محدش حجز. الركاب هيظهروا هنا أول ما يحجزوا. |
| tripDepartedState | On the way. Rider names show now. | المشوار ماشي. أسامي الركاب ظاهرة دلوقتي. |
| tripDoneState | Trip finished. | المشوار خلص. |
| tripCancelledState | You cancelled this trip. Every rider got back everything they paid. | إنت لغيت المشوار. كل راكب فلوسه كلها رجعتله. |
| cancelTripConfirm | Cancel this trip? Every rider gets back everything they paid. | تلغي المشوار؟ كل راكب فلوسه كلها هترجعله. |
| keepTrip | Keep the trip | سيب المشوار |
| demoNothingToDo | Nothing to do yet. Publish a trip first. | مفيش حاجة تتعمل لسه. انشر مشوار الأول. |
| seeAll | See all | شوف الكل |
| acceptConfirm | Yes, accept | أيوه، وافق |
| requestWithdrawn | Your balance was too low when a driver accepted, so the request was withdrawn. Nothing was charged. | رصيدك كان قليل لما سواق وافق، فالطلب اتلغى. ومخدناش منك حاجة. |
| requestGone | That request is no longer open. Here's the updated list. | الطلب ده مبقاش مفتوح. دي القايمة بعد التحديث. |
| dailyBlockedNote | Every workday is off while you ride in a daily group. | كل يوم شغل مقفول وإنت راكب في مجموعة يومية. |
| findRidersLink | Or find riders who already posted | أو دوّر على ركاب نشروا مشاويرهم |

---

## R17 — Server side (schema only, not deployed)

- **Decision**: `supabase/migrations/20261012000000_marketplace.sql` adds `offered_trips`,
  `trip_requests` and `bookings`, with RLS on each (Constitution: RLS on every table). It also
  adds a `driver_request_cards` view that exposes `is_woman` and `rating` but never name or photo
  (FR-023). It is not deployed, and no Edge Function changes beyond the two `_shared` twins.
- **Rationale**: same as 002/003. The server's shape is fixed while the rules are fresh. 004 added
  no tables because its ledger is a partner concern.
- **Alternatives**: skip the migration. Possible, and it is the first item to drop if the
  feature runs long (P10).

## T104 — device walk, partial (2026-10-14, phone R5CNC0NK6ZT, Arabic, debug APK from main 1b5ae86)

Walked: quickstart §1 steps 1–5 (rider books an empty seat, wallet). **Stopped** at the start of §2: a person took the
phone (call screen, WhatsApp). Not walked: §1 step 6 (upsell), §2–§8, the whole English pass.

Confirmed on device: payment-method screen after "Book seat" with no method; "Top up 44 EGP first" with the chosen
seat marked "Your pick"; booked summary with "Make it your daily commute"; one-off card on Today with Share, SOS and
Cancel; Wallet row "Seat −44 (40 + 4 fee)", balance 156; list prices 40+4 (group cars) and 44+4 (Tarek).

Findings (F2 fixed; the rest open):
- **F1 (bug, blocks the main US1 path)** — a rider who picks "Just one trip" at onboarding has no saved route, so
  `FakeMarketplaceRepository._route` returns null and Empty seats is empty ("no seats on your route"). quickstart §1
  step 2 and spec US1 expect the Sheikh Zayed → Smart Village default and a route line. The route line is also not
  shown when a route exists. Needs a founder/implementer call: default route vs. ask for the route first.
- **F2 (bug)** — top-up sheet opened from the Empty seats gate hangs: money is credited, the sheet stays busy.
  Log: `Cannot use the Ref of walletControllerProvider after it has been disposed` at
  `WalletController._refresh` (wallet_controller.dart). The autoDispose controller has no listener on that screen.
  **Fixed (2026-10-15):** `TopUpSheet` watches the controller while open, so it lives through the top-up. Same hole
  on Post your trip (it opens the same sheet). Regression test in `top_up_sheet_test.dart` (sheet opened over Today,
  ar + en): red with the same `UnmountedRefException` before, green after. Not re-walked on a device yet.
- **F3 (copy/logic)** — Wallet plan card for a no-group wallet rider reads "Per trip · no service fee on your trips"
  while a 4 EGP fee was charged; breakdown shows "Driver's share 0 / Total 0". Cause: no group → riderSeats 0 → fee 0 guard.
- **F4 (quickstart)** — the demo clock survives "Reset demo data"; set "Ride day 7:15" first or every seeded car
  has already left (it was 8 PM). Quickstart names sz-0740; the seed lists cars at 7:20, 7:25, 7:30, 7:40.
- "First month free" still shown on the frequency screen (already known).
- **Process incident** — during the §2 macro the phone was taken by its owner. Guarded taps were refused, but the
  macro's `input text` calls were not guarded and may have typed digits/names into another app. Reported to the founder.
