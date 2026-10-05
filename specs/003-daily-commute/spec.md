# Feature Specification: Commute Groups and the Daily Commute

**Feature Branch**: `feature/003-daily-commute`

**Created**: 2026-10-05

**Status**: Draft

**Input**: User description: "Read GOORA_SPEC_KIT_BRIEF.md sections 6.4–6.6. Build groups and the
daily commute (the app's 4-tab shell: Today, Week, Wallet, Trust): Today, rider: greeting, a dark
hero card 'Your ride is confirmed · 7:25 AM · route', a legs card (Going: driver, Return: driver,
each 'Covered'), a map card with the route and 'Pickup in 12 min', a driver card (avatar, name,
verified badge, car, rating, call button), a timeline (pickup → on the way → arrival), Return time +
'You pay per trip' tiles, Share trip + SOS buttons, and 'I can't come tomorrow' (with the rule
caption). Today, driver: 'Offer a trip' entry (feature 005), a dark hero card 'Tomorrow · direction
· N passengers' with pickup stops and times and the estimated contribution, Confirm / Undo, Report
delay, Can't drive, 'Requests on your route' (feature 005), and pickup check-in: 'I've arrived at
Main Gate', then per passenger 'Picked up' / 'No-show'. Week: the schedule per working day showing
who drives going and return, with backup substitutions labelled. Attendance, cancellation and
backup rules exactly as 6.5 and 6.6, including warning and info banners ('Ahmed can't drive on
Tuesday — Mohamed will drive instead…', 'You're off tomorrow — no charge'). Trust tab: profile,
verification checklist (phone, national ID, work email, + license and vehicle for drivers),
reliability % with bar and rule caption, 'Switch to driver/rider mode', privacy preference pills
(Verified users / Same company / Same compound / Women only). Live trip: real-time driver location
during an active trip, share-trip link, SOS (calls 122 and notifies trusted contacts)."

**Sources of truth**: `GOORA_SPEC_KIT_BRIEF.md` §5 (003), §6.2, §6.4–6.6, §7; approved prototype
copy for the Today, Week and Trust screens. Where the prototype and brief differ, the brief wins:
the prototype's per-trip "Goora fee" lines are replaced by "no per-trip fees" (as in feature 002),
and its driver trip cost of 180 EGP is replaced by the decided demo cost of 160 EGP.

**Carried over from 001/002 (decided, not re-asked)**: demo trip cost 160 EGP → 40 EGP per rider
per trip; fakes-first backend (the app runs on fake data; server code is written and tested, ready
for keys); the contrast-safe pill and tab colours; riders appear to drivers only as "Verified
rider" / "Verified rider (woman)" until they board.

## Clarifications

### Session 2026-10-06

- Q: Trust verification checklist — statuses only, or submit flows (ID photo, work-email code,
  license and vehicle photos)? → A: Statuses only in this feature, from fake data. Submit flows
  come in a later feature.
- Q: How is the reliability % calculated? → A: Kept trips ÷ booked trips over the last 30 days. A
  no-show counts as one missed trip, a cancel after 9 PM as half a missed trip, a cancel before
  9 PM has no effect.
- Q: On days a driver is not driving (prototype "You ride"), do they ride and pay? → A: Yes. They
  ride with the driver on duty, take a seat, and pay the group price (40 EGP per trip) like any
  rider; rider rules (cancel, no-show) apply to them on those days.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - My ride today, as a rider (Priority: P1)

A rider in a group opens Goora and lands on the Today tab. They see that their ride is confirmed,
who drives each leg, when they are picked up and where, what they pay, and they can call the
driver, share the trip or call for help.

**Why this priority**: This is the feature's promise — groups actually ride together every day. It
is the screen a rider opens every morning.

**Independent Test**: As a seeded rider in a group, open the app and check every element of the
rider Today screen against the seeded schedule, in Arabic and English.

**Acceptance Scenarios**:

1. **Given** a rider who joined a group, **When** they open the app, **Then** they land on the app
   shell with four tabs — Today, Week, Wallet, Trust — with Today selected.
2. **Given** the rider Today screen, **Then** it shows, top to bottom: a greeting with their first
   name and "Here's your commute for today."; a dark hero card "Your ride is confirmed · 7:25 AM ·
   <home area> → <work area>"; a legs card with one row per leg (Going: <driver> · 7:25 AM,
   Return: <driver> · 5:05 PM), each marked "Covered", and the note "Going and return are separate
   trips — they can have different drivers."; a map card with the route and "Pickup in N min"; a
   driver card (avatar, name, verified badge, car and colour, rating, "Call driver"); a timeline
   (Pickup · time · pickup point → On the way · passengers → Arrival · time · work area); a Return
   time tile and a "You pay per trip" tile reading "40 EGP to the driver · no per-trip fees"; "Share
   trip" and "SOS" buttons; and "I can't come tomorrow" with the caption "Free before 9 PM · after
   that you pay half your share".
3. **Given** the rider rides only one leg with this group, **Then** the legs card shows only that
   leg, or shows the other leg's group and driver when another group covers it.
4. **Given** "Call driver", **When** tapped, **Then** the phone dialler opens with the driver's
   number (only for the current or next trip's driver).
5. **Given** today is not a working day (or the rider is off), **Then** the hero card shows the next
   ride day instead, and no pickup countdown is shown.
6. **Given** the rider Today screen, **Then** an "extra trip" entry ("Need an extra trip? Book a
   seat") leads to the Empty seats today placeholder (feature 005-A).

---

### User Story 2 - Can't come: cancellation and no-show rules (Priority: P1)

A rider who can't make tomorrow taps "I can't come tomorrow". Before 9 PM it is free and the seat
goes to the waitlist; after 9 PM they pay half their share. A rider who doesn't show up within 5
minutes of the driver's arrival pays their full share. Repeated no-shows lead to a warning and then
removal from the group.

**Why this priority**: These rules are what make a fixed group dependable for everyone in it; they
are part of the brief's legal and financial core and must be provable.

**Independent Test**: With a fixed clock, cancel before and after 9 PM, record no-shows, and
check every charge, banner, reliability change, warning and removal against §6.5 with exact
numbers.

**Acceptance Scenarios**:

1. **Given** a rider before 9 PM the day before a ride day, **When** they tap "I can't come
   tomorrow" and confirm, **Then** they owe nothing, an info banner reads "You're off tomorrow
   (<day>) · Cancelled before 9 PM — no charge. Your seat was offered to the waitlist." with "Undo,
   I'm coming", and the Week tab shows that day as "You're off · Cancelled before 9 PM · no charge".
2. **Given** a rider after 9 PM the day before, **When** they confirm "I can't come tomorrow",
   **Then** before confirming they are told the charge, and after confirming they owe half their
   share for each cancelled trip (half of 40 = 20 EGP per trip; 40 EGP for both ways), with no
   Goora fee.
3. **Given** "Undo, I'm coming", **When** tapped before 9 PM and the seat has not been given away,
   **Then** the absence is removed with no charge and no reliability effect.
4. **Given** the rider wants a whole week off, **When** they use "Not coming next week" (one tap
   plus confirm), **Then** every ride day of next week is marked off; days still before their 9 PM
   cut-off are free.
5. **Given** a driver marks a rider "No-show" after the 5-minute wait, **Then** the rider owes
   their full share for that trip (40 EGP) and their no-show count for the month rises by one.
6. **Given** a person's second no-show in a month, **Then** they see a warning banner explaining
   that a third no-show this month removes them from the group.
7. **Given** a person's third no-show in a month, **Then** they are removed from the group, told
   why, and their seat goes to the waitlist.
8. **Given** the rule numbers 9 PM, half share, 5 minutes, 2 and 3 no-shows, **Then** unit tests
   prove each one at its exact boundary (8:59 PM free, 9:00 PM half; 4:59 not yet allowed, 5:00
   allowed).

---

### User Story 3 - Tomorrow's drive and pickup check-in, as a driver (Priority: P1)

A driver opens Today and sees tomorrow's drive: direction, passengers, pickup stops and times, and
the estimated contribution. They confirm the drive, can report a delay or say they can't drive. At
pickup they tap "I've arrived at Main Gate"; riders are notified; after 5 minutes they can mark
each passenger "Picked up" or "No-show".

**Why this priority**: The rider's day depends on the driver's actions; check-in is what produces
the no-show facts behind the rules in User Story 2.

**Independent Test**: As a seeded driver, confirm and undo tomorrow's drive, run a pickup
check-in with one picked up and one no-show, and check statuses, timers and the resulting
charges.

**Acceptance Scenarios**:

1. **Given** a driver in a group, **When** they open Today, **Then** they see the greeting, "You're
   driving tomorrow.", an "Offer a trip" entry and a "Find riders" entry (both lead to feature 005
   placeholders), and a dark hero card "Tomorrow · <direction> · N passengers" listing pickup stops
   with times (e.g. Pickup 1 — Main Gate 7:20, Pickup 2 — Central St. 7:25, <work area> 8:05, and
   "Return from <work area> 5:05" for both ways) and "Estimated contribution" = passengers × price
   × trips.
2. **Given** the hero card, **When** the driver taps "Confirm tomorrow's drive", **Then** it shows
   "Confirmed. Your passengers have been notified." and the button becomes "Undo confirmation".
3. **Given** "Report delay", **When** the driver picks a delay, **Then** the group's riders are
   notified of the new pickup time.
4. **Given** "Can't drive", **When** the driver confirms, **Then** backup search starts
   (User Story 4) and the action is recorded under the same 9 PM rule for reliability.
5. **Given** a "Requests on your route" section, **Then** it shows a placeholder entry for feature
   005 and the note "Requests show only if your detour is under 10 minutes. The price is fixed by
   Goora."
6. **Given** pickup check-in, **When** the driver taps "I've arrived at Main Gate", **Then**
   passengers are notified, the note "Passengers get notified. You wait 5 minutes max." shows, and
   each passenger row shows "Notified · waiting" with a 5:00 countdown.
7. **Given** a waiting passenger, **Then** "Picked up" is available at once and "No-show" becomes
   available only after the 5 minutes end; a no-show row reads "No-show · full share charged" and
   the note "No-show after 5 minutes: the rider still pays their full share." appears.
8. **Given** passengers before boarding, **Then** they appear as "Verified rider" / "Verified rider
   (woman)" with rating; name and photo show once they are marked "Picked up".

---

### User Story 4 - Backup when a driver can't drive (Priority: P2)

When a driver can't drive, Goora looks for a cover in the brief's order. Riders see who covers the
day; if nobody can, riders are told the evening before and offered options.

**Why this priority**: Backup is what turns a carpool into a reliable daily service, but the core
daily loop (stories 1–3) is usable without it.

**Independent Test**: With seeded groups, make a driver unavailable and check that the cover is
chosen in the §6.6 order, that riders see the right banner and Week label, and that the
no-cover path notifies riders with options.

**Acceptance Scenarios**:

1. **Given** a driver can't drive a leg, **Then** the cover is searched in this order: other
   drivers in the same group, then drivers of nearby groups, then same-company drivers, then
   same-community drivers; the first with a free car on that leg and day is chosen.
2. **Given** a cover is found, **Then** each affected rider sees the warning banner "<driver> can't
   drive on <day>" with "<cover> will drive instead. Your commute is still covered — nothing for you
   to do." and "Got it", and the Week tab labels that leg "<cover> (backup)".
3. **Given** a backup driver covers a day, **Then** riders pay the group price (40 EGP per trip),
   not the backup driver's own price.
4. **Given** nobody can cover, **Then** riders are notified the evening before (no later than 9 PM)
   with options: book an empty seat (feature 005-A placeholder), post their trip (feature 005-B
   placeholder), or take the day off at no charge.
5. **Given** a cover rule, **Then** unit tests prove the search order and the no-cover outcome.

---

### User Story 5 - My week (Priority: P2)

Any group member opens the Week tab to see who drives going and return on each of their working
days, including backups and their own days off.

**Why this priority**: Planning ahead builds trust in the group, but the daily loop works without
it.

**Independent Test**: With a seeded group and a fixed date, check every row of the Week tab for a
rider and a driver, with a backup and an absence in place.

**Acceptance Scenarios**:

1. **Given** the Week tab, **Then** it shows "Your commute schedule", the route and time, and one
   row per working day with the driving person's avatar and "<name> drives" (or "You drive"), plus
   a detail line — for riders "Going: <driver> · Return: <driver>"; for drivers "<direction> · N
   riders" on their days and "You ride" on others — and the note "Goora rotates drivers fairly and
   fills gaps automatically when someone can't make it."
2. **Given** a backup covers a leg, **Then** that row shows "<cover> (backup)" for that leg.
3. **Given** the person is off that day, **Then** the row reads "You're off · Cancelled before 9 PM
   · no charge" (or the late-cancel text when it was after 9 PM).
4. **Given** a group with several drivers for a leg, **Then** the schedule spreads that leg's days
   across them so no driver has more than one extra day compared with another over each 4-week
   period.
5. **Given** the Week tab, **Then** "Not coming next week" is available (User Story 2, scenario 4).

---

### User Story 6 - Trust: profile, verification, reliability and privacy (Priority: P2)

A person opens the Trust tab to see their profile, what is verified, their reliability, switch
between driver and rider mode, and choose who can ride with them.

**Why this priority**: Trust is a core principle, and the privacy choice feeds matching, but the
daily loop runs without editing these.

**Independent Test**: As a rider and as a driver, open Trust and check the profile, checklist,
reliability bar and caption, the role switch, and that choosing a privacy pill changes which
groups matching returns.

**Acceptance Scenarios**:

1. **Given** the Trust tab, **Then** it shows the person's avatar, name and "Verified member ·
   <rating> ★".
2. **Given** a rider, **Then** the verification checklist shows Phone number, National ID and Work
   email with their status, and Driving license and Vehicle as "Not needed"; **given** a driver,
   all five show their status ("Verified" or "Not verified"). Statuses come from fake data;
   there is no submit flow in this feature.
3. **Given** the reliability card, **Then** it shows "Reliability" with a percentage, a bar filled
   to that percentage, and a caption built from this month's facts (e.g. "1 late cancel this
   month. 3 no-shows in a month removes you from the group."). The % = kept trips ÷ booked trips
   over the last 30 days (FR-036).
4. **Given** "Switch to driver mode", **When** a rider taps it, **Then** they go to commute setup
   in driver mode (seats, trips driven, contribution) and must have license and vehicle verified
   before being matched as a driver; "Switch to rider mode" turns a driver into a rider without
   losing their saved commute.
5. **Given** "Who can ride with me", **Then** four pills show — Verified users (default), Same
   company, Same compound, Women only — one selectable at a time; the choice is saved and used by
   matching and backup searches from then on.
6. **Given** a man, **Then** "Women only" is not offered; **given** no verified work email,
   "Same company" is unavailable with a short hint to verify the work email; **given** no compound
   set, "Same compound" is unavailable with a short hint to add it.

---

### User Story 7 - Live trip, share and SOS (Priority: P3)

During an active trip the rider sees the driver's location move on the map, can share a live trip
link, and can press SOS to call 122 and alert trusted contacts.

**Why this priority**: Safety must always be one tap away (constitution V), but live location needs
the maps and server keys; until then it runs on a simulated driver path.

**Independent Test**: Start a simulated trip and check the moving driver marker, the share action,
and that SOS asks to call 122 and records an alert to trusted contacts.

**Acceptance Scenarios**:

1. **Given** an active trip (from the driver's arrival until arrival at the destination), **Then**
   the map card shows the driver's current position updating at least every 10 seconds and the
   pickup or arrival countdown.
2. **Given** "Share trip", **When** tapped, **Then** the system share sheet opens with a trip link
   and a short message (route, driver first name, car, expected arrival); the link never reveals a
   home location.
3. **Given** "SOS", **When** tapped, **Then** a one-step confirm offers "Call 122" (opens the
   dialler with 122) and sends an alert with the live trip link to the person's trusted contacts.
4. **Given** the person has no trusted contacts, **Then** SOS still offers "Call 122" and invites
   them to add a trusted contact in the Trust tab.
5. **Given** no active trip, **Then** "Share trip" and "SOS" stay visible on Today and SOS still
   offers "Call 122".

---

### Edge Cases

- A rider cancels both legs after 9 PM: half share per trip → 20 + 20 = 40 EGP.
- A rider cancels only the return leg: rules apply to that trip only.
- A rider taps "Undo, I'm coming" after the seat was taken by the waitlist: the undo is refused
  with a calm message; the absence stays.
- Cancel time exactly 9:00 PM counts as after 9 PM (late); 8:59 PM is free.
- The day before a ride is not a working day (e.g. Sunday ride, Saturday evening): the cut-off is
  still 9 PM on the calendar day before the ride.
- A driver taps "No-show" before 5 minutes: not possible; the action stays disabled with the
  remaining time shown.
- A driver marks "Picked up" by mistake: they can switch it to "No-show" (after the 5 minutes)
  until the trip starts; the last mark counts.
- Two no-shows on the same day (going and return) count as two.
- The month boundary resets the no-show count; the reliability % itself is not reset.
- A removed person keeps their commute profile and returns to matching (no-match or new group).
- The only driver of a leg is removed: that leg goes to backup search for every remaining day.
- The person changes privacy to a stricter option: their current group is not changed; the choice
  applies to future matching and backups, and a note says so.
- Language switch on any tab keeps the current tab and state.
- Times use the same format as 002 ("7:25 AM" / "7:25 ص", Western digits).

## Requirements *(mandatory)*

### Functional Requirements

**App shell**

- **FR-001**: Group members MUST land on a four-tab shell — Today, Week, Wallet, Trust — with Today
  selected; it replaces the Today placeholder from 002. Wallet is a placeholder until feature 004.
- **FR-002**: The 002 "Join this group" route for drivers MUST reach the shell; for riders the plan
  placeholder (feature 004) MUST continue to the shell; a returning member who logs in MUST land on
  the shell.

**Rider Today**

- **FR-003**: The rider Today screen MUST show every element listed in User Story 1, scenario 2,
  with values from the person's group, legs and schedule.
- **FR-004**: The "You pay per trip" tile MUST show the group price per trip and "no per-trip
  fees"; it MUST NOT show any Goora fee.

**Attendance and cancellation (pure rules, exact brief numbers)**

- **FR-005**: A cancellation made before 9:00 PM on the calendar day before the ride MUST be free;
  one made at or after 9:00 PM MUST cost half the person's share for each cancelled trip, with no
  Goora fee.
- **FR-006**: A free cancellation MUST offer the seat to the corridor waitlist (or to one-off riders
  once feature 005 exists).
- **FR-007**: "Not coming next week" MUST mark every ride day of next week off in one action, each
  day charged by FR-005.
- **FR-008**: A no-show MUST only be recordable 5 minutes or more after the driver's "I've arrived";
  the rider MUST owe their full share for that trip.
- **FR-009**: A person's second no-show in a calendar month MUST trigger a warning; the third MUST
  remove them from the group and give their seat to the waitlist. The same rules MUST apply to
  drivers.
- **FR-010**: A driver counts a no-show when they neither check in nor cancel by 5 minutes after
  the scheduled pickup time; a driver's "Can't drive" MUST follow the 9 PM rule for reliability
  (drivers owe no money).
- **FR-011**: The attendance rules (FR-005 to FR-010) MUST be pure logic with unit tests at each
  exact boundary.
- **FR-012**: Charges from cancellations and no-shows MUST be recorded as amounts owed to the
  driver; collecting them is feature 004 (wallet).

**Driver Today**

- **FR-013**: The driver Today screen MUST show every element in User Story 3, scenario 1, with
  "Estimated contribution" = passengers × group price × trips driven.
- **FR-014**: Confirm, Undo confirmation, Report delay and Can't drive MUST notify the affected
  riders.
- **FR-015**: Pickup check-in MUST follow User Story 3, scenarios 6–8.
- **FR-016**: Riders MUST appear to drivers only as "Verified rider" / "Verified rider (woman)" with
  rating until marked "Picked up" (constitution IV).

**Backup**

- **FR-017**: When a driver can't drive a leg, the cover MUST be searched in §6.6 order: same
  group → nearby groups → same company → same community; partner transport is out of scope.
- **FR-018**: A cover MUST pass the same hard constraints as matching (002) for that leg and day,
  including the riders' privacy preferences, and MUST have a free car that leg.
- **FR-019**: Riders MUST see the backup banner and Week label of User Story 4; the group price MUST
  apply on covered days.
- **FR-020**: With no cover, riders MUST be notified by 9 PM the evening before with the three
  options in User Story 4, scenario 4; taking the day off then MUST be free.

**Week**

- **FR-021**: The Week tab MUST show each working day's going and return drivers, backups, and the
  person's days off, as in User Story 5.
- **FR-022**: The rotation MUST spread each leg's days across that leg's drivers so, over each
  4-week period, no driver drives more than one day more than another; drivers only take days and
  legs they chose.
- **FR-022a**: On days and legs a driver is not driving, they MUST ride with the driver on duty,
  take a seat in that car, and owe the group price per trip like any rider; the rider rules
  (FR-005 to FR-009) apply to them for those trips. Free seats per leg MUST count these
  off-duty drivers.

**Trust**

- **FR-023**: The Trust tab MUST show the profile, the verification checklist, the reliability card
  and the role switch as in User Story 6.
- **FR-023a**: The verification checklist MUST show statuses only ("Verified", "Not verified",
  "Not needed"); submitting documents is out of scope for this feature.
- **FR-024**: The privacy preference MUST be one of Verified users / Same company / Same compound /
  Women only, saved, and passed to matching and backup as the existing women-only, same-company and
  same-compound constraints.
- **FR-025**: "Women only" MUST be offered only to women; "Same company" MUST require a verified
  work email; "Same compound" MUST require a compound name.
- **FR-026**: Changing the privacy preference MUST NOT change the current group; it applies to
  future matching and backups.
- **FR-027**: The person MUST be able to keep up to 3 trusted contacts (name + Egyptian mobile) in
  the Trust tab.

**Reliability**

- **FR-036**: Reliability % MUST be kept trips ÷ booked trips over the last 30 days, rounded to a
  whole number: a no-show = 1 missed trip, a cancel at or after 9 PM = 0.5 missed trip, a cancel
  before 9 PM = no effect (the trip is not counted as booked). With no booked trips, it MUST show
  100%. It MUST be pure logic with unit tests (e.g. 12.5 kept of 13 booked → 96%).

**Live trip and safety**

- **FR-028**: During an active trip the map MUST show the driver's position, refreshed at least
  every 10 seconds; until keys exist the position follows a simulated path.
- **FR-029**: "Share trip" and "SOS" MUST be one tap away on Today at all times (constitution V).
- **FR-030**: SOS MUST offer a call to 122 and send an alert with the live trip link to the
  trusted contacts; it MUST work with no trusted contacts (call only).
- **FR-031**: A shared trip link MUST NOT reveal any home location; it shows pickup point, route
  and live position only during the trip.

**Backend readiness**

- **FR-032**: Server schema for groups, schedule, attendance, absences, backups, privacy and
  trusted contacts MUST have row-level security on every table; a person can read only their own
  group's schedule and never another person's home point.
- **FR-033**: The scheduled job that sends evening notices and applies the 9 PM cut-off MUST use
  the same rules and the same tests as the app.

**Quality**

- **FR-034**: Every new screen MUST render correctly in Arabic (RTL) and English (LTR), proven by
  widget tests in both languages, with ≥ 44 px targets and labelled icon buttons.
- **FR-035**: Status MUST never be shown by colour alone (e.g. "Picked up" / "No-show" carry text
  and icon).

### Key Entities

- **Group**: from 002 — route, times, days, drivers (legs they drive), riders, price, free seats.
- **Schedule day**: group, date, going driver, return driver, backup flags.
- **Ride (trip)**: group, date, leg, driver, passengers, status (scheduled, confirmed, delayed,
  driver arrived, in progress, arrived, cancelled).
- **Absence**: person, date, leg(s), made at, charge (free or half share).
- **Pickup check-in**: ride, arrived at, per passenger outcome (picked up / no-show) and time.
- **Charge owed**: person, ride, reason (late cancel, no-show), amount, owed to driver.
- **Reliability record**: person, month, late cancels, no-shows, reliability %.
- **Backup assignment**: ride, original driver, cover driver, search step that found them.
- **Privacy preference**: person, one of four options.
- **Trusted contact**: person, name, mobile.
- **SOS alert**: person, ride, time, contacts alerted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A rider can see who picks them up, when and where within 5 seconds of opening the
  app.
- **SC-002**: A rider can cancel tomorrow's ride in 2 taps and always sees the exact charge before
  confirming.
- **SC-003**: Every attendance rule reproduces the brief exactly in tests: 8:59 PM free, 9:00 PM
  half (20 EGP per trip), no-show allowed at 5:00 and not before, full share 40 EGP, warning at 2
  and removal at 3 no-shows in a month.
- **SC-004**: In every seeded "driver can't drive" scenario the chosen cover matches the §6.6 order,
  and riders see who covers before 9 PM the evening before.
- **SC-005**: Over a seeded 4-week schedule, no driver drives more than one day more than another
  on the same leg.
- **SC-006**: SOS reaches the 122 call step in 2 taps from Today.
- **SC-007**: All new screens pass automated rendering tests in Arabic and English; static analysis
  reports zero issues.

## Assumptions

- The fake data reuses 002's corridor groups, people (Ahmed, Mohamed, Sara, Youssef, Omar) and
  times (7:20–7:30 AM going, 5:00–5:05 PM return), with a fixed clock for tests.
- Pickup points: "Main Gate" and "Central St." on the home side; "Smart Village, Gate 2" at work
  (prototype). The check-in button names the stop ("I've arrived at <stop>").
- "Pickup in N min" counts down to the rider's pickup time on a ride day.
- Report delay offers 5, 10 or 15 minutes.
- Driver confirmation is informational; an unconfirmed drive still runs as scheduled.
- A rider's cancellation is per trip (going / return), both by default for "I can't come
  tomorrow".
- The off-day banner, warning banner, removal notice, no-cover notice, undo-refused message,
  trusted-contact strings, share message and the Arabic for any copy not in the prototype are
  drafted in the brief's tone and listed for founder review.
- Notifications are in-app (banners and an in-app inbox list) on fake data; push notifications
  arrive with the server keys.
- "Nearby groups" for backup = groups whose route passes the hard constraints for that leg.
- Charges owed are kept as records only; the Wallet tab (feature 004) will show and collect them.
- Role switching to driver reuses the 002 commute setup screen in driver mode.
- The live position on fake data moves along the drawn route from pickup to work over the trip
  time.
- Trusted-contact alerts are recorded (fake send) until an SMS provider is chosen.
