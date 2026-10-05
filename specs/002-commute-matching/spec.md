# Feature Specification: Commute Profile and Smart Matching

**Feature Branch**: `feature/002-commute-matching`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Read GOORA_SPEC_KIT_BRIEF.md sections 6.1–6.3. Build the commute
profile and matching: Commute setup screen ('Where do you go every day?'): Home and Work (place
search + map pin; store exact coordinates privately, show only area names), departure time, return
time, working days (7 day pills, default Sun–Thu). If driver: empty seats (1–4), which trips they
drive (Both ways / Going only / Return only), and contribution per rider using the stepper (range
and rules in 6.2). Show 'You recover per day = seats × price × trips'. Matching (server-side Edge
Function, pure logic mirrored in Dart for tests): hard constraints and scoring in 6.3. Going and
return are matched independently. Match result screen: '92% match' chip, 'We found your commute
group!', stacked avatars, member count, route, time + days, 4 stats (drivers, riders, fixed/wk,
EGP/trip), the line '40 EGP to the driver · no per-trip fees', a 'Why this group' card listing
reasons with check icons, a 'See other options' toggle listing alternative matches with %, and the
primary CTA 'Join this group'. No-match state: 'You're #7 on the Sheikh Zayed → Smart Village list
— we'll notify you as soon as we have a match', plus a CTA to post a trip request (feature 005)."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` §5 (002), §6.1–6.3; approved prototype copy for
the setup and match screens. Where the prototype and brief differ, the brief wins (e.g. the
prototype's "+ Goora service fee" line is replaced by the brief's "no per-trip fees").

## Clarifications

### Session 2026-10-05

- Q: §6.2 demo says trip cost 180, 3 riders, suggestion 40 — but 180 ÷ (3 + 1) = 45. → A: Keep the
  formula and every "40 / 32–48" in the brief; the demo corridor trip cost is **160 EGP**
  (160 ÷ 4 = 40).
- Q: How is trip cost (fuel + tolls + running) computed? → A: From configurable rates
  (EGP per km × route km + tolls) behind a feature flag; until real rates are set, every route in
  the launch corridor uses the fixed demo cost of 160 EGP. Final rates stay an open item (§8).
- Q: How does each scoring factor earn points? → A: Linearly inside its limit: full weight at a
  perfect fit, zero at the hard limit (e.g. departure 0 min = 20 pts, 10 min = 10, 20 min = 0).
- Q: Backend for 002? → A: The app runs on fake data now (in-app matching with the brief's numbers,
  a fixed list of corridor places, a simple map card). The server code (database schema with
  location support and row-level security, plus the matching function) is written and tested,
  ready to deploy when the founder provides keys.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Set up my daily commute (Priority: P1)

After choosing "Every day", the person tells Goora where they live and work, when they leave and
return, and which days they work. A driver also sets empty seats, which trips they drive and their
contribution per rider, and sees what they recover per day.

**Why this priority**: Matching needs this profile; without it no group can be found.

**Independent Test**: As a rider and as a driver, fill the setup screen and confirm the saved
profile, the default values, and the driver's recovery line.

**Acceptance Scenarios**:

1. **Given** the commute setup screen, **When** it opens, **Then** it shows the title "Where do you
   go every day?", Home and Work pickers, departure (default 7:30 AM) and return (default 5:00 PM)
   times, seven day pills with Sun–Thu selected, progress dots on step 3, and "Find my commute".
2. **Given** the Home or Work picker, **When** the person chooses a place, **Then** only the area
   name is shown (e.g. "Sheikh Zayed"); the exact point is stored privately and never displayed.
3. **Given** a rider, **Then** no driver fields are shown.
4. **Given** a driver, **Then** the screen also shows empty seats (1–4, default 3), "Which trips do
   you drive?" (Both ways default / Going only / Return only) and "Your contribution per rider"
   with a stepper, the suggested-price label, the min / suggested / max range line and the note
   "Based on distance, fuel and tolls. Riders see it before joining, and it stays fixed for the
   month."
5. **Given** a driver with 3 seats on the demo corridor, **Then** the suggested contribution is 40
   EGP, the stepper moves in 2 EGP steps between 32 and 48, the label reads "Suggested price" at 40
   and "N EGP above/below suggested" otherwise, and "You recover per day" shows
   seats × price × trips (3 × 40 × 2 = 240 EGP for both ways).
6. **Given** a driver choosing "Going only" or "Return only", **Then** trips = 1 in the recovery
   line and the note "Riders get the other trip from another driver in the group." appears.
7. **Given** no working day selected or no Home/Work, **Then** "Find my commute" is unavailable.

---

### User Story 2 - Find my commute group (Priority: P1)

The person taps "Find my commute". Goora applies the hard constraints and the score from §6.3 to
the groups on their corridor and shows the best group with its match percentage, the group
details, the reasons it fits, other options, and "Join this group".

**Why this priority**: This is what the feature proves: we can find compatible people.

**Independent Test**: With the seeded corridor data, find a match as a rider and as a driver and
verify the shown percentage, stats and reasons come from the matching rules.

**Acceptance Scenarios**:

1. **Given** a compatible group exists, **When** the person taps "Find my commute", **Then** the
   result screen shows the "N% match" chip, "We found your commute group!", the subline "People
   going your way, at your time.", stacked member avatars, the member count, the route (home area →
   work area), time and days, four stats (drivers, riders, fixed trips per week, EGP per trip), the
   line "40 EGP to the driver · no per-trip fees", a "Why this group" card with check-icon reasons,
   and "Join this group".
2. **Given** the result screen, **When** the person taps "See other options", **Then** alternative
   groups appear with avatar, name, a short detail line and their match %; the toggle then reads
   "Hide other options".
3. **Given** the person needs both ways and no single group fits both, **Then** going and return are
   matched independently and the result shows the group for each leg.
4. **Given** the viewer is a driver, **Then** riders in the group appear only as "Verified rider" /
   "Verified rider (woman)" without name or photo.
5. **Given** "Join this group", **When** tapped, **Then** the membership is saved and the person
   continues to the next step (rider → plan screen of feature 004; driver → Today of feature 003;
   both are placeholders until those features exist).

---

### User Story 3 - No match yet (Priority: P2)

When no group passes the hard constraints, the person sees their place on the corridor waitlist and
can post a trip request instead.

**Why this priority**: An honest empty state keeps people on the list while density grows.

**Independent Test**: With a profile no seeded group can serve, confirm the waitlist message and the
post-a-trip action.

**Acceptance Scenarios**:

1. **Given** no group passes the hard constraints, **Then** the screen says "You're #N on the
   <home area> → <work area> list — we'll notify you as soon as we have a match", where N is the
   person's waitlist position, and offers "Post your trip".
2. **Given** "Post your trip", **When** tapped, **Then** the person reaches the post-a-trip
   placeholder (feature 005-B).

---

### Edge Cases

- Home and Work in the same area: allowed only if the two points are more than 1.5 km apart;
  otherwise a calm hint asks for a different Work place.
- Return time earlier than or equal to departure: "Find my commute" stays unavailable with a hint.
- A driver lowers seats: the suggested contribution and range recompute; a contribution that falls
  outside the new range snaps to the nearest allowed value.
- The person leaves and comes back: the saved commute profile is shown pre-filled.
- Every candidate fails one hard constraint (e.g. 25-minute departure difference): no-match state,
  never a low-percentage "match".
- Language switch mid-screen keeps all entered values.

## Requirements *(mandatory)*

### Functional Requirements

**Commute setup**

- **FR-001**: The setup screen MUST collect Home, Work, departure time, return time and working days
  (default Sun–Thu) for every person.
- **FR-002**: Home and Work MUST be chosen as places with an exact point; the app MUST display only
  the area name and MUST never show exact coordinates or addresses to anyone.
- **FR-003**: For drivers the screen MUST also collect empty seats (1–4), driven trips (Both ways /
  Going only / Return only) and contribution per rider.
- **FR-004**: The suggested contribution MUST be trip cost ÷ (riders + 1), where riders = the
  driver's empty seats, rounded to the nearest 2 EGP.
- **FR-005**: The driver MUST only be able to choose a contribution within ±20% of the suggestion,
  in 2 EGP steps, and never above trip cost ÷ riders (riders' total MUST NOT exceed the trip
  cost).
- **FR-006**: Trip cost MUST come from configurable rates (EGP per km × route km + tolls); while the
  rates flag is off, every launch-corridor route MUST use the demo cost of 160 EGP.
- **FR-007**: The driver MUST see "You recover per day" = seats × price × trips (trips = 2 for Both
  ways, 1 otherwise).
- **FR-008**: The commute profile MUST be saved and restored across restarts.

**Matching**

- **FR-009**: A group MUST be excluded unless it passes every hard constraint: pickup point ≤ 1 km
  from home (configurable), driver detour ≤ 10 min, departure difference ≤ 20 min, destination
  within 1.5 km, a free seat on the needed leg (riders) or riders on that leg (drivers), at least
  one shared working day, and compatible privacy preferences (women-only, same company, same
  compound).
- **FR-010**: Each passing group MUST get a score from 0 to 100: destination 25, departure-time
  closeness 20, pickup distance 15, return-time closeness 10, shared days 10, same company or
  community 10, rating and reliability 10 — each factor scaled linearly from full weight (perfect
  fit) to zero (at its limit); the total rounded to a whole number.
- **FR-011**: Going and return MUST be matched independently: when the best group cannot serve the
  person's return (or going) leg, the best group for that leg alone is used.
- **FR-012**: "Why this group" MUST list up to four reasons generated from the highest-scoring
  factors (e.g. "Same destination: Smart Village", "5-minute departure difference", "Pickup 600 m
  from home", "Same company · similar return time").
- **FR-013**: Other options MUST list the next-best passing groups, best first, with their score.
- **FR-014**: The matching rules MUST be implemented once as pure logic used by the app and
  mirrored by the server matching function, with the same tests passing on both.
- **FR-015**: Riders MUST appear to drivers only as "Verified rider" or "Verified rider (woman)"
  (constitution IV).

**Results**

- **FR-016**: The result screen MUST show every element listed in User Story 2, scenario 1.
- **FR-017**: "Join this group" MUST save the membership and route riders to the plan placeholder
  (feature 004) and drivers to the Today placeholder (feature 003).
- **FR-018**: The no-match screen MUST show the waitlist position and corridor and offer "Post your
  trip" (feature 005-B placeholder).

**Backend readiness**

- **FR-019**: The server schema MUST store locations with geographic types, enable row-level
  security on every table, and never expose another person's home point.
- **FR-020**: Server URL and keys MUST come only from the git-ignored environment file; with no keys
  the app MUST run fully on fake data.

**Quality**

- **FR-021**: Every new screen MUST render correctly in Arabic (RTL) and English (LTR), proven by
  widget tests in both languages, with ≥ 44 px targets and labelled icon buttons.
- **FR-022**: Matching and pricing rules MUST have unit tests that use the exact numbers from the
  brief (160 EGP, 3 riders → 40; range 32–48; 1 km; 10 min; 20 min; 1.5 km; weights).

### Key Entities

- **Place**: area name (shown), exact point (private).
- **Commute profile**: person, home place, work place, departure time, return time, working days;
  for drivers: empty seats, driven trips, contribution per rider.
- **Group**: route (origin area → destination area), destination point, pickup points, going and
  return times, working days, drivers (with the legs they drive), riders, price per trip, free seats
  per leg.
- **Match**: group, leg(s) covered, score, factor breakdown, reasons.
- **Waitlist entry**: person, corridor, position.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A person completes commute setup and sees a result in under 1 minute.
- **SC-002**: For every seeded scenario, the shown match % equals the score computed from §6.3
  rules by hand (verified by tests).
- **SC-003**: 0 groups that break a hard constraint are ever shown as a match.
- **SC-004**: The pricing rules reproduce the brief's demo exactly: 160 EGP and 3 riders → 40,
  range 32–48, 3 seats × 40 × 2 trips = 240 per day.
- **SC-005**: All new screens pass automated rendering tests in Arabic and English; static analysis
  reports zero issues.

## Assumptions

- The fixed corridor places for fake data are: Home — Sheikh Zayed, 6th of October; Work — Smart
  Village (each with a representative point). Live place search replaces this list once the maps
  key exists.
- The map card shows home → work as a simple drawn route; a live map arrives with the maps key.
- Detour minutes per group come from the data (computed server-side from directions later).
- Group rating and reliability = members' average rating (out of 5) and average reliability %;
  points = 10 × average of (rating ÷ 5, reliability ÷ 100).
- Shared days points = 10 × shared days ÷ the person's working days.
- Return-time closeness uses the same 20-minute scale as departure but is not a hard limit on its
  own; a return difference over 20 minutes means the return leg is matched to another group.
- Same company or community = 10 points if any member shares the person's company or compound, else 0.
  (Company and compound are set in later features; until then this factor is usually 0.)
- The overall match % shown is the score of the main group; when legs come from different groups,
  each leg shows its own %.
- Privacy preferences default to "Verified users" (no restriction) until the Trust tab (feature 003)
  lets people change them.
- Waitlist position comes from the waitlist data (fake: the number of people already waiting on the
  corridor + 1).
- Reason and detail lines not in the brief or prototype (e.g. "Same compound", "N shared working
  days", "Return: <group>") are drafted in the brief's tone and listed for founder review.
- Times are shown as "7:30 AM" / "7:30 ص" with Western digits.
