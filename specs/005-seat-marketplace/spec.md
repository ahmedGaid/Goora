# Feature Specification: Seat Marketplace

**Feature Branch**: `005-seat-marketplace`

**Created**: 2026-10-12

**Status**: Draft

**Input**: User description: "Read GOORA_SPEC_KIT_BRIEF.md section 6.8. Build the four one-off/demand
flows that feed daily groups: A) Empty seats today, B) Post your trip, C) Offer a trip, D) Find
riders, plus driver Today 'Requests on your route'. Carry forward from 004: booking enforcement
(after 10 cash trips, booking needs a wallet balance or a company plan); PricingService service
fee/rider total, with the fee inside the Constitution II cap, is reused for every one-off seat price
(44 / 40 subscribed). Record, don't decide: T078, does an off-duty driver riding in another
driver's car pay the contribution (4 × 44 > 160 cap risk)."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` §5 "Feature 005", §6.2 (pricing), §6.7
(monetization, fee inside the cap), §6.8 (marketplace limits), §7 (copy). Copy not in §7 is
drafted and goes to founder review before ship (same pattern as 003/004).

**Carried over from 001–004 (decided, not re-asked)**: the commute corridor and areas (002); the
group price fixed per group for the month, ±20% of the suggestion in 2 EGP steps (002); rider rules
for cancel, late cancel and no-show, the 9 PM cut-off, and off-duty drivers riding in the car on
duty (003 FR-005 to FR-009, FR-022a); driver verification (license + vehicle) before driving (003);
privacy preferences Verified users / Same company / Same compound / Women only (003 FR-024/025);
the payment-method screen, wallet, cash trial, subscription and company plan (004); the service fee
of up to 10%, trimmed so each rider's contribution + fee stays at or below their equal share of the
trip cost (004 v2.1); fakes-first backend.

## Clarifications

### Session 2026-10-12 (decided by the implementer from the brief, founder to confirm)

- Q: Does the "max 2 trips per driver per day" limit count the trips a driver already drives for
  their own daily group? → A: Yes. A trip is a trip: a driver's group legs today count against the
  2, one per direction they drive. A request or booking that fits a trip the driver already has
  (same direction, same route, within ±30 min) joins that trip and uses no extra trip. "Trips left
  today" starts at 2 only for a driver with no trip yet that day. This is the stricter reading of
  Constitution II and can be relaxed later; the looser one can't be taken back once drivers rely on it.
- Q: When is a one-off seat paid? → A: Wallet and subscribed riders pay when they book (the seat
  price is taken from the wallet), because §6.8 promises a full refund when a seat is reclaimed.
  Cash-trial riders pay the driver in cash at the trip, as in 004. A refund always returns exactly
  what was paid.
- Q: Does "fully refunded if the seat is reclaimed before 9 PM" mean 9 PM the evening before the
  trip? → A: Yes, the same 9 PM cut-off as 003. A one-off booking stays open to a subscriber until
  9 PM the evening before; booked after that (for example a seat for today), it is final the moment
  it is booked.
- Q: Which cancellation rules apply to a one-off booker? → A: The rider rules from 003, unchanged:
  free before 9 PM the evening before, half share after, full share for a no-show (to the driver,
  no Goora fee). A same-day booking is therefore past the free window as soon as it is made; the
  booking confirmation says so before the rider confirms.
- Q: Where does booking enforcement (carried from 004) apply? → A: At the moment a rider books a
  seat (A), posts a request (B), or a request is accepted. A rider who can't pay cash (trial used up
  or turned off) needs a wallet balance of at least the seat price; otherwise they see "Top up N EGP
  first" and nothing is booked. Company-plan riders are not blocked, matching 004. Daily group trips
  keep 004's behavior (the balance may go below zero, the Wallet shows "Top up to keep riding");
  blocking a group member from their own car is left for the server.
- Q: When is a rider's or a requester's identity shown to the driver? → A: Only when they board
  (pickup check-in). Before that, every list a driver sees shows "Verified rider" or "Verified rider
  (woman)", a rating or "New", and a pickup point. §6.8 says "until they board", which is stricter
  than Constitution IV's "accepted or boards"; the stricter one wins.
- Q: Can a driver who already leads a daily group publish a daily offer? → A: No. A driver leads at
  most one daily group; "Every workday" is turned off for them with the reason shown. They can still
  offer "Just once" trips within the daily limit.
- Q: How does a posted request get accepted in the demo? → A: By a driver accepting it (a real
  driver session using D or driver Today), or by a Settings → Demo action "A driver accepts your
  request". Drivers are fakes, as in 003/004.
- Q: How does an offered trip get booked in the demo? → A: By a real rider session using A, or by a
  Settings → Demo action "A rider books your seat".

### Open — recorded, not decided here (founder)

- **T078 (carried from 004):** does an off-duty driver riding in another driver's car pay the
  contribution? 003 FR-022a says they owe the group price like any rider; 004's wallet bills only
  the rider role. In the seeded 160 EGP / 3-rider-seat cars an off-duty driver rides as a 4th
  passenger, so 4 × 44 = 176 > 160 breaks the cap if they pay. This feature does not change who pays.
  It only makes sure a one-off seat is never sold into that 4th place: free seats always count
  off-duty drivers (FR-004), so the marketplace never makes the problem worse.
- **Legal (brief §8):** whether a per-trip service fee is allowed at all. Unchanged by this feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A rider books an empty seat in an existing car (Priority: P1)

A rider who needs one trip (a new user who picked "Just one trip" at onboarding, or a group member
who needs an extra trip or has no driver for a day) opens "Empty seats", picks Going or Return,
sees free seats in existing groups' cars on their route with the price they will pay, and books one.
The confirmation shows a summary; a non-subscriber also sees an invitation to make it their daily
commute.

**Why this priority**: It is the simplest way into Goora and fills seats that already exist. It
needs no new driver and no new trip, so it delivers value on day one with the seeded groups.

**Independent Test**: With the seeded groups, a new rider onboarded with "Just one trip", and a
group member, book a seat, see the right price (44 for a wallet or new rider, 40 for a subscriber,
40 cash for a cash-trial rider), see the seat count drop and the booking appear on Today.

**Acceptance Scenarios**:

1. **Given** a rider who picked "Just one trip" at onboarding, **When** they continue, **Then** they
   land on Empty seats; Back returns to the frequency screen.
2. **Given** a group member on Today, **When** they tap "Need an extra trip? Book a seat", **Then**
   Empty seats opens with their group's route; Back returns to Today. **Given** the no-cover card
   (003 FR-020), **When** they tap "Book an empty seat", **Then** Empty seats opens for that day.
3. **Given** Empty seats, **Then** it shows a Going/Return toggle, the route line, and one card per
   free seat offer: driver avatar, name and rating, pickup point, time, seats left, the price for
   this rider, and "Book seat"; a caption with the subscriber-priority and refund rule; and a dashed
   card "Nothing fits your time? Post your trip" that opens Post your trip (US3).
4. **Given** a non-subscriber paying from the wallet (or with no payment method yet), **Then** each
   card reads "44 EGP · 40 to the driver + 4 service fee" on the demo corridor; **given** a
   subscriber, "40 EGP · no fees (subscribed)"; **given** a cash-trial rider, "Pay 40 EGP cash to the
   driver". Every price comes from the same pricing rule as 004, cap included.
5. **Given** a non-subscriber, **When** they book, **Then** the confirmation shows the summary
   (driver, pickup, time, price) and an upsell card "Liked it? Make it your daily commute" that opens
   commute setup with "Every day" already chosen. **Given** a subscriber, **Then** the confirmation
   shows the summary and "Back to today", with no upsell.
6. **Given** a rider with no payment method (new user), **When** they tap Book seat, **Then** they
   choose how to pay on 004's payment-method screen first, then return to confirm the same seat.
7. **Given** a rider who can't pay cash and whose wallet balance is below the seat price, **When**
   they tap Book seat, **Then** they see "Top up N EGP first" (N = the gap) with a way to top up,
   and nothing is booked; a company-plan rider is not blocked.
8. **Given** a booking is made, **Then** the seat count on that car drops by one for everyone, the
   wallet is charged the seat price (wallet/subscriber), and the trip shows on the rider's Today
   like any other trip, with the same Share and SOS.
9. **Given** a booking is made after 9 PM the evening before the trip, **Then** the confirmation
   tells the rider that cancelling now owes half the share (003 rules), before they confirm.

---

### User Story 2 - A driver offers a trip and riders book it (Priority: P2)

A verified driver offers a trip on their route: From, To, time, seats, "Just once" or "Every
workday", and a contribution within the allowed range. Riders whose route fits can book it. The
driver watches seats fill; a daily trip that gets riders becomes a commute group.

**Why this priority**: It adds new seats to the market (A only sells seats that already exist) and
is the driver's way into Goora. It depends on A's booking to be useful, so it follows US1.

**Independent Test**: As a verified driver with no trips today, publish a once trip with 3 seats at
the suggested price; use the demo action to book seats; see the progress bar, the anonymous booked
list and "Your car is full!". Publish a daily trip, book one seat, see it become a group.

**Acceptance Scenarios**:

1. **Given** a driver who picked "Just one trip" at onboarding, **When** they continue, **Then** they
   land on Offer a trip; Back returns to the frequency screen. **Given** driver Today, **When** they
   tap "Offer a trip", **Then** Offer a trip opens; Back returns to Today.
2. **Given** Offer a trip, **Then** it shows verification chips (ID, license, vehicle), From / To /
   Time, seats, "Just once" / "Every workday", a contribution stepper, the three rules with check
   icons, Publish, and a text link "Or find riders who already posted" that opens Find riders (US4).
3. **Given** the contribution stepper, **Then** it starts at the suggested contribution, moves in
   2 EGP steps, stops at ±20%, and its label reads "Suggested price" or "N EGP above/below suggested";
   the rider price (contribution + fee, fee trimmed by the cap) is shown under it.
4. **Given** a driver whose license or vehicle is not verified, **Then** the missing chip says so,
   Publish is off, and a tap on the chip opens Trust to verify.
5. **Given** a driver already at their daily limit in that direction, **Then** Publish is off and
   the screen says "Daily limit reached"; **given** an offer within ±30 min of a trip they already
   have in that direction, **Then** they are told it joins that trip instead of creating a new one.
6. **Given** a published trip, **Then** a live state shows a seat progress bar ("N of M seats
   booked"), the booked riders as "Verified rider" / "Verified rider (woman)" with a rating or "New",
   and Cancel trip; when every seat is booked it shows "Your car is full!".
7. **Given** a daily trip, **When** its first rider books, **Then** it becomes a commute group with
   the driver as its driver and the booked riders as members, at the published contribution, and the
   driver's Today and Week show it like any group from 003.
8. **Given** the driver cancels a published trip with booked riders, **Then** every booked rider is
   refunded in full and told calmly; the trip counts as one of the driver's trips that day, and the
   cancellation counts on the driver's reliability as in 003.

---

### User Story 3 - A rider posts their trip when no seat fits (Priority: P2)

A rider who finds no seat that fits posts their trip: From, To, time, "Just once" or "Every
workday". Drivers on the route see the request anonymously. When a driver accepts, the rider sees
who and when; a daily request that's accepted becomes a commute group.

**Why this priority**: It turns "no match" into demand drivers can see, and it is the path from the
no-match screen (002) and the no-cover card (003). It needs drivers to accept (US4/US5) to complete.

**Independent Test**: Post a request from Empty seats' dashed card; see "Sent to N drivers on your
route"; use the demo action to accept; see the accepted state; for a daily request, land on the
payment-method screen as a group member.

**Acceptance Scenarios**:

1. **Given** Post your trip, **Then** it shows From / To / Time (prefilled from the rider's route
   when they have one), "Just once" / "Every workday", the three rules with check icons, and Post.
2. **Given** a posted request, **Then** the rider sees "Sent to N drivers on your route" (N = drivers
   whose route fits with a detour under 10 min), a progress indicator, and Cancel; Cancel removes the
   request at no cost.
3. **Given** a driver accepts, **Then** the rider sees the accepted state: driver card, pickup point,
   time and contribution (with the fee line for their plan); the booking is paid as in US1.
4. **Given** a daily request is accepted, **Then** the rider sees "You're now a commute group" and
   goes to 004's payment-method screen, then Today, as a member of the new group.
5. **Given** no driver accepts before the requested time, **Then** the request expires, the rider
   is told calmly and offered to post again or look at empty seats; nothing is charged.
6. **Given** a rider who can't pay (US1 AC7), **When** they tap Post, **Then** they see "Top up N EGP
   first" and nothing is posted.

---

### User Story 4 - A driver finds riders who already posted (Priority: P2)

A driver browses requests on their route without posting a trip first. Accepting a request creates
their trip, or joins a trip they already have in that direction, within the daily limit. Prices are
fixed; there is no bidding.

**Why this priority**: It is the supply side of US3 and enforces the core legal limit (max 2 trips a
day, no bidding, no picking by name or photo).

**Independent Test**: As a driver with no trips today, open Find riders; filter by area and
morning/evening; accept one request (trip created, "Trips left today" 2 → 1); accept a second on
the same route within ±30 min (joins, stays 1); accept one in the other direction (0); see every
remaining request show "Daily limit reached".

**Acceptance Scenarios**:

1. **Given** driver Today, **When** the driver taps "Find riders", **Then** Find riders opens
   ("Requests near you"); the same screen opens from Offer a trip's text link.
2. **Given** Find riders, **Then** it shows a "Leaving from" area filter (All plus each corridor
   area), a Morning/Evening toggle, a "Trips left today" counter, and request cards: route, "Verified
   rider" or "Verified rider (woman)", pickup point, time, Just once / Every workday, rating or "New",
   and the fixed price. Only requests whose route fits the driver's registered route with a detour
   under 10 min are listed.
3. **Given** a request that would create a new trip, **When** the driver taps Accept, **Then** an
   inline confirm reads "This creates your trip: <route> · <time>. Trips left after this: N";
   confirming creates the trip (as Offer a trip would) and seats the rider.
4. **Given** a request on the same route within ±30 min of a trip the driver already has in that
   direction, **Then** its card reads "This joins your trip at <time>"; accepting seats the rider in
   that trip and uses no extra trip.
5. **Given** a request that fits no existing trip in a direction where the driver already has a
   trip, **Then** its card reads "Doesn't fit your trip" and can't be accepted; **given** 2 trips
   already exist, **Then** every remaining request reads "Daily limit reached" and can't be accepted.
6. **Given** a trip that is full, **Then** requests that would join it read "Your car is full" and
   can't be accepted.
7. **Given** any request card, **Then** it never shows the rider's name or photo, and there is no
   way to change the price.

---

### User Story 5 - Driver Today shows requests on the driver's route (Priority: P3)

Driver Today replaces the "Requests on your route" placeholder with live demand: a banner ("12
people want <route> in the morning") and request cards with detour minutes and Accept.

**Why this priority**: It puts US4's demand where drivers look every day. It reuses US4's rules, so
it comes last among the driver flows.

**Independent Test**: As a driver on Today, see the demand banner and request cards; accept one and
see "Accepted ✓"; check the trip and the daily counter changed exactly as in US4.

**Acceptance Scenarios**:

1. **Given** driver Today with matching requests, **Then** "Requests on your route" shows a demand
   banner with the count, route and part of day, and up to a few request cards (anonymous rider,
   pickup, time, once/daily, rating or New, detour minutes, fixed price, Accept), plus a link to see
   all in Find riders.
2. **When** the driver taps Accept on a card, **Then** the same rules as US4 apply (create / join /
   doesn't fit / daily limit / full) and an accepted card reads "Accepted ✓".
3. **Given** no matching requests, **Then** the section shows a calm empty state and the privacy
   caption, not the old placeholder.

---

### User Story 6 - Subscribers get priority; reclaimed seats are refunded in full (Priority: P3)

A subscriber can take a seat that a non-subscriber booked one-off, up to 9 PM the evening before the
trip. The one-off booker gets everything they paid back and a calm notice with other options.

**Why this priority**: It keeps the subscription worth paying for (§6.8) but touches only edge
timing; the marketplace works without it.

**Independent Test**: Book a one-off seat (wallet, 44) for tomorrow before 9 PM; use a Settings →
Demo action "A subscriber takes this seat"; see the booking removed, 44 back in the wallet as one
"Refund" row, and a notice offering Empty seats or Post your trip. After 9 PM the same action is
refused.

**Acceptance Scenarios**:

1. **Given** a car with no free seat and a one-off booking made before the 9 PM cut-off, **When** a
   subscriber books that car, **Then** the subscriber gets the seat and the one-off booker is
   refunded in full.
2. **Given** the refunded rider, **Then** their wallet shows the full amount back as one activity
   row, Today no longer shows the trip, and a notice offers "Empty seats" and "Post your trip".
3. **Given** the booking is past 9 PM the evening before (or was made after it), **Then** it can't
   be reclaimed.
4. **Given** a cash-trial booking, **When** it is reclaimed, **Then** nothing moves in the wallet and
   the trip does not count toward the 10 cash trips.

---

### Edge Cases

- A seat count reaches 0 while a rider is looking at Empty seats: their Book seat tap fails calmly
  ("That seat was just taken") and the list refreshes; nothing is charged.
- The rider is already in a car for that leg (their own group): Empty seats hides that leg's seats
  and says they already have a ride.
- A rider tries to book two seats on the same leg: refused; one person, one seat per leg.
- An off-duty driver rides in their group's car that leg (003 FR-022a): they take a seat, so the
  car's free seats drop; Empty seats never sells a seat that isn't free (T078 stays open).
- A driver tries to book a seat in their own offered trip: not listed to them.
- A driver offers a trip at a time that overlaps another trip of theirs in the other direction (for
  example going at 7:30 AM and return at 8:00 AM): refused, a driver can't be in two places.
- The driver's group trip is cancelled or covered by a backup that day: that trip no longer counts
  against the driver's limit (it is not theirs to drive).
- A woman with the "Women only" preference: Empty seats shows only cars that meet it, and her
  requests are offered only to drivers whose car meets it; a driver's own privacy preference filters
  the requests they see. No other filter exists.
- A request's requested time passes with no driver: it expires (US3 AC5).
- A rider cancels a one-off booking: 003 rules; a wallet rider's refund is the seat price minus what
  they owe (nothing before 9 PM the evening before, half the share after); the fee is refunded in
  full in every case (Goora takes no fee on a trip that didn't happen).
- A payment fails while booking: the booking is not made, the balance and activity are exactly as
  before, and the rider sees a blame-free error with retry (004 SC-005 carries over).
- The demo clock moves past a trip's departure: Empty seats and Find riders stop listing it.
- A full 4-rider-seat car at the top of the price range: the seat shows "38 + 2", not "38 + 4" (004
  v2.1 trimming applies to one-off seats).

## Requirements *(mandatory)*

### Functional Requirements

**Entry points**

- **FR-001**: Choosing "Just one trip" at onboarding MUST lead a rider to Empty seats and a driver to
  Offer a trip; Back MUST return to the frequency screen.
- **FR-002**: Inside the app, the rider's "Need an extra trip? Book a seat" (Today) and "Book an empty
  seat" (no-cover card) MUST open Empty seats; "Post your trip" (no-cover card, no-match screen,
  Empty seats' dashed card) MUST open Post your trip; the driver's "Offer a trip" MUST open Offer a
  trip, and "Find riders" MUST open Find riders. Back MUST return to where the user came from. The
  current placeholder screens for these routes MUST be removed.

**Empty seats (A)**

- **FR-003**: Empty seats MUST list, per direction (Going/Return), the free seats on legs that have
  not yet departed, in groups' cars and published offers whose route fits the rider's route with a
  driver detour under 10 min, filtered by the rider's privacy preference.
- **FR-004**: A leg's free seats MUST equal the car's rider seats minus everyone riding that leg
  (members, off-duty drivers, one-off bookers); a leg with 0 free seats MUST NOT be listed.
- **FR-005**: The price shown and charged for a seat MUST come from the existing pricing rule: the
  group's (or offer's) contribution plus the service fee for the rider's plan, the fee trimmed so
  contribution + fee never exceeds the equal share of the trip cost. Subscribers and company-plan
  riders MUST pay no fee; cash-trial riders MUST pay no fee and pay the driver in cash.
- **FR-006**: Booking MUST take one seat for one leg, charge the wallet the seat price at booking for
  wallet and subscribed riders, and show the trip on the rider's Today and Week.
- **FR-007**: The booked confirmation MUST show the summary; for non-subscribers it MUST also show
  "Liked it? Make it your daily commute", which opens commute setup with "Every day" preselected;
  for subscribers it MUST show "Back to today" and no upsell.

**Booking enforcement (carried from 004)**

- **FR-008**: A rider with no payment method MUST choose one on 004's payment-method screen before
  booking or posting.
- **FR-009**: A rider who can't pay cash (trial used up, or turned off after 2 "Didn't pay") and
  whose wallet balance is below the seat price MUST be stopped with "Top up N EGP first" when they
  book, post, or have a request accepted; nothing MUST be booked or charged. Company-plan riders MUST
  NOT be stopped.
- **FR-010**: A cash one-off trip MUST count toward the 10 cash trips and get the driver's "Received
  cash" / "Didn't pay" step after drop-off, as in 004.

**Post your trip (B)**

- **FR-011**: A rider MUST be able to post From / To / Time and "Just once" / "Every workday"; the
  request MUST be shown only to drivers whose registered route fits with a detour under 10 min and
  whose privacy preference allows the rider.
- **FR-012**: A posted request MUST show "Sent to N drivers on your route" and be cancellable at no
  cost until accepted; it MUST expire, uncharged, when its time passes with no driver.
- **FR-013**: An accepted request MUST show the driver card, pickup point, time and price, and be
  paid as in FR-006; an accepted daily request MUST create a commute group and send the rider to the
  payment-method screen.

**Offer a trip (C)**

- **FR-014**: Only a driver with verified ID, license and vehicle MUST be able to publish; missing
  checks MUST be shown as chips that open Trust.
- **FR-015**: The contribution MUST start at the system suggestion for the route and seats, move in
  2 EGP steps, and stay within ±20%; the rider price shown MUST include the trimmed fee. There MUST
  be no way to set any other price.
- **FR-016**: A published trip MUST show booked seats as a progress bar and anonymous booked riders,
  and "Your car is full!" when full. A daily trip MUST become a commute group when its first rider
  books; a driver who already leads a daily group MUST NOT publish a daily offer.
- **FR-017**: A driver who cancels a published trip MUST refund every booked rider in full; the
  cancellation MUST count on the driver's reliability as in 003.

**Find riders (D) and driver Today requests**

- **FR-018**: Find riders MUST list requests that fit the driver's route (detour under 10 min), with a
  "Leaving from" area filter, a Morning/Evening toggle and a "Trips left today" counter.
- **FR-019**: Accepting a request MUST either join a trip the driver already has (same direction,
  same route, within ±30 min, a free seat left) using no extra trip, or create a new trip after an
  inline confirm that states the trips left after it. A request that fits neither MUST read "Doesn't
  fit your trip"; with 2 trips existing, every remaining request MUST read "Daily limit reached"; a
  request that would join a full trip MUST read "Your car is full". These requests MUST NOT be acceptable.
- **FR-020**: Driver Today's "Requests on your route" MUST show a demand banner and request cards
  with detour minutes and Accept, with the same rules as FR-019, and "Accepted ✓" once accepted.

**Marketplace limits (Constitution II, brief §6.8)**

- **FR-021**: A driver MUST NOT have more than 2 trips in a day, counting their own group legs,
  offered trips and trips created by accepting; trips in the same direction on the same route within
  ±30 min MUST count as one.
- **FR-022**: Prices MUST always be system-set; there MUST be no bidding, counter-offer or tip field
  anywhere in this feature.
- **FR-023**: Driver-facing lists MUST NOT show a rider's name or photo before that rider boards;
  riders MUST appear as "Verified rider" or "Verified rider (woman)" with a rating or "New". Drivers
  MUST NOT be able to filter by anything except the existing privacy preference.
- **FR-024**: Riders' total payments for any trip created or filled by this feature, fees included,
  MUST NOT exceed that trip's full cost.

**Subscriber priority (§6.8)**

- **FR-025**: Until 9 PM the evening before a trip, a subscriber MUST be able to take a seat held by
  a one-off (non-subscriber) booking when the car has no free seat; the one-off booker MUST be
  refunded in full (wallet) and notified with "Empty seats" and "Post your trip" options. After the
  cut-off, a one-off booking MUST be final.

**Cross-cutting**

- **FR-026**: Every screen and state in this feature MUST work in Arabic (RTL, default) and English
  (LTR), with all copy localized; new copy MUST be listed for founder review.
- **FR-027**: Every list in this feature MUST have designed empty, loading and error states.
- **FR-028**: Settings → Demo MUST offer "A driver accepts your request", "A rider books your seat"
  and "A subscriber takes this seat", and the demo seed MUST include requests on the corridor so
  Find riders and driver Today have content.

### Key Entities

- **Seat offer**: one leg of an existing car with free seats, as a rider sees it: driver, pickup
  point, time, free seats, contribution, rider price for this rider.
- **Offered trip**: a trip a driver publishes: route, time, direction, seats, contribution, Just once
  / Every workday, status (open, full, cancelled, done), booked riders.
- **Trip request**: a rider's posted trip: route, time, direction, Just once / Every workday, status
  (posted, accepted, cancelled, expired), the accepting driver.
- **Booking**: one rider in one seat on one leg, from a seat offer, an offered trip or an accepted
  request: price paid, how it was paid (wallet, cash, plan), whether it can still be reclaimed (before
  the 9 PM cut-off), status (booked, reclaimed, cancelled, done).
- **Driver day**: a driver's trips on one date (group legs + offered + accepted), used for the 2-trip
  limit and the ±30 min join rule.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A group member can go from Today to a booked seat in 3 taps or fewer when their
  payment method is set and their balance covers the seat.
- **SC-002**: Across every trip cost from 20 to 1,000 EGP, 1 to 4 rider seats and every allowed
  contribution, no seat price (any plan) makes riders' total exceed the trip cost: 0 cases.
- **SC-003**: No sequence of offers, accepts and joins gives a driver more than 2 trips in one day:
  0 cases across the scripted sequences in the tests.
- **SC-004**: 100% of driver-facing request and booked-rider cards in this feature show no name or
  photo before boarding, in both languages.
- **SC-005**: Every refund (reclaim, driver cancel, request expiry) returns exactly what was paid:
  the wallet balance after equals the balance before booking, with one activity row each way.
- **SC-006**: A failed payment or a seat taken mid-booking leaves balance, seats and activity exactly
  as before.
- **SC-007**: Every main state of every screen in this feature passes the brand checklist in Arabic
  and English.

## Assumptions

- Fakes-first, like 001–004: seeded groups provide empty seats; seeded requests and Settings → Demo
  actions stand in for other people. No server, no real-time push, no real payment partner.
- Trip cost and suggested contribution for a new offer come from the same route pricing as 002; the
  offer's rider seats are the seats the driver offers.
- Areas in the "Leaving from" filter are the corridor areas already seeded in 002.
- "Same route" means the same From area and To area in the same direction.
- Detour minutes come from the seeded data, as in 002; real directions come with the server.
- The demand banner count ("12 people want…") is the number of open requests on the driver's route
  in that part of the day, from the seed.
- Notifications are in-app (Today notices and the bell from 003); push comes later.
- The cap, the ±20% range and the 2-trip limit are the same rules the app and the future server both
  enforce, kept in step as in 002–004.
