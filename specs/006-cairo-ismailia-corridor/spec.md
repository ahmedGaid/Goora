# Feature Specification: Cairo ↔ Ismailia Launch Corridor

**Feature Branch**: `006-cairo-ismailia-corridor`

**Created**: 2026-10-16

**Status**: Draft

**Input**: User description: "Cairo↔Ismailia intercity corridor as Goora's first real launch corridor: seed data, stops, pricing on the longer distance (Constitution II check), demo/test coverage."

## Background

Goora's brief (§6.1) and Constitution IX name **Sheikh Zayed → Smart Village** as the single launch corridor, and every seed, stop, price and test today is built on it. On 2026-10-16 the founder decided the **first real launch corridor is Cairo ↔ Ismailia** instead. This feature makes the product, its demo data and its tests speak that corridor, without breaking the existing one. The corridor is longer than the current one, so the price rules (Constitution II, the legal boundary under Law 87/2018) must be proven again on the new numbers, not assumed.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A rider gets matched on the Cairo ↔ Ismailia corridor (Priority: P1)

A person who lives in a Cairo area and works in Ismailia (or the other way round) signs up, sets home, workplace, times and days, and sees a real-looking match: a group with a driver, pickup point, times, a clear price, and the reasons why this group fits.

**Why this priority**: Without a matchable corridor there is no launch. This is the smallest slice that shows the product working on the real route.

**Independent Test**: Reset demo data, onboard as a rider with a Cairo home and an Ismailia workplace, and reach a match result for a seeded group. Repeat for the opposite direction.

**Acceptance Scenarios**:

1. **Given** a new rider whose home is in a supported Cairo area and whose workplace is in Ismailia, **When** they finish setup, **Then** they see at least one matching group with pickup point, departure time, arrival time, price and "why this group" reasons, all in Arabic and English.
2. **Given** a new rider whose home is in Ismailia and whose workplace is in Cairo, **When** they finish setup, **Then** they see a matching group for that direction.
3. **Given** a rider whose home or workplace is outside the corridor, **When** they finish setup, **Then** they land on the no-match state, which names the corridor they asked for, and can post a trip request.

---

### User Story 2 - The price is fair and legal on the longer distance (Priority: P1)

A rider and a driver both see one clear price per trip. It is the trip cost shared between riders and driver, never more than the full trip cost in total, and the driver never profits.

**Why this priority**: This is the NON-NEGOTIABLE rule (Constitution II). The corridor is longer, so a price that was safe at the old corridor's cost can break the cap. It must be proven before launch.

**Independent Test**: For the corridor's trip cost, check every allowed price and every rider count from 1 to the car's rider seats: riders' total, service fee included, never exceeds the trip cost.

**Acceptance Scenarios**:

1. **Given** the corridor's trip cost and a group with N riders, **When** the suggested price is calculated, **Then** it equals trip cost ÷ (N + 1), rounded to the nearest 2 EGP, and the driver can adjust it only within ±20% in 2 EGP steps.
2. **Given** any allowed price and any rider count, **When** the rider's total (contribution + service fee) is added up for a full car, **Then** the sum of all riders' totals never exceeds the full trip cost.
3. **Given** a cash rider, **When** the cash amount is shown, **Then** it is a multiple of 5 EGP and still inside the allowed range (feature 005 rule).
4. **Given** a rider is shown a price before joining, **When** they join, **Then** they pay exactly that price (no change after joining).

---

### User Story 3 - Both directions and the marketplace work on the corridor (Priority: P2)

People who live in Ismailia and work in Cairo, and people who live in Cairo and work in Ismailia, both find groups. A driver can offer a trip and a rider can post a trip request on the corridor (feature 005), and the daily screens (Today, Week, wallet) show realistic corridor data.

**Why this priority**: A corridor with one direction has half the density. The marketplace and daily screens are what the founder will show on camera, so they must not show the old corridor.

**Independent Test**: Walk the quickstart on the new corridor in both directions: match, join, daily Today, wallet, empty seats, post a trip. No screen shows "Sheikh Zayed" or "Smart Village".

**Acceptance Scenarios**:

1. **Given** the corridor is the active demo, **When** the rider opens Today, Week and Wallet, **Then** every place name, stop, time and price belongs to the new corridor.
2. **Given** a driver who goes Cairo → Ismailia, **When** they offer a trip, **Then** riders on the corridor can book empty seats within the price rules.
3. **Given** a rider on the corridor, **When** they post a trip request, **Then** drivers on the corridor see it as an anonymous card.

---

### User Story 4 - The product's own documents say the same thing (Priority: P3)

The brief, the constitution and the roadmap name the new launch corridor, so no future feature is built against a wrong rule.

**Why this priority**: A stale rule reads as authoritative while wrong. It is cheap to fix and expensive to leave.

**Independent Test**: Search the brief, constitution and roadmap for the old corridor as "the launch corridor": none remain unless marked as the previous demo corridor.

**Acceptance Scenarios**:

1. **Given** the founder approves the change, **When** the documents are amended, **Then** the brief (§6.1 and the no-match copy), Constitution IX's rationale, and the roadmap list Cairo ↔ Ismailia as the launch corridor.
2. **Given** the company-network feature is currently numbered 006, **When** this feature takes that number, **Then** the roadmap shows the new number for the company network.

---

### Edge Cases

- A person lives in a town between Cairo and Ismailia, on the route. Pickup points must be at most 1 km from home; if none fits, they see the no-match state.
- A driver's detour limit (10 min) and departure-time limit (20 min) were set for a short urban route. They are kept unchanged unless the founder decides otherwise.
- A car with 3 rider seats at the corridor's cost must keep its rider total under the cap at every rider count from 1 to 3. The seed must not contain an over-seated car.
- A driver leading a daily group on the corridor already uses their 2 trips per day. They cannot also offer one-off trips that day (feature 005 rule).
- A person who lives on the old corridor (Sheikh Zayed) and works in Ismailia has no match and joins the waitlist.
- Tolls and running costs are an open item (brief §8). Real rates stay behind the existing switch until resolved; the demo uses a founder-set number.
- The 9 PM evening-before cut-off for late cancel and reclaim stays the same, whatever the trip length.
- Arabic and English names for every new area and stop must exist; a missing name must fail a test, not show a blank.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST offer Cairo-side and Ismailia-side areas as selectable home and workplace places during setup. The launch list (founder, 2026-10-16) is: New Cairo, Nasr City and Heliopolis on the Cairo side; Obour and 10th of Ramadan as towns on the road; Ismailia city on the Ismailia side. Which of these lie on the road, and their approximate centres, are checked in the plan; they were recalled, not verified.
- **FR-002**: The system MUST include seeded groups on the corridor in both directions, each with a driver, riders, free seats, a price, going and return times, a pickup point and an arrival point, so a new user always sees a realistic match.
- **FR-003**: The system MUST apply the existing matching rules (pickup ≤ 1 km from home, driver detour ≤ 10 min, departure difference ≤ 20 min, destination within 1.5 km, seat capacity, one shared day, privacy preferences) to the corridor unchanged, unless the founder decides otherwise.
- **FR-004**: The system MUST use one trip cost per leg for the corridor for the demo: **300 EGP per leg, for a car with 3 rider seats** (founder choice, 2026-10-16). This number is an unverified placeholder: it MUST be marked as a demo value in the code and docs, and MUST be reviewed before any public claim about prices. Real per-kilometre and toll rates MUST stay behind the existing switch until the open item (brief §8) is resolved. With these numbers, by the existing pricing rule (checked by hand against the current code, to be re-proven by tests), the suggested price is 76 EGP (300 ÷ 4 = 75, rounded to the nearest 2 EGP), the allowed range is 62–90 EGP, and an equal share is 100 EGP.
- **FR-005**: The system MUST price each trip as trip cost ÷ (riders + 1), rounded to the nearest 2 EGP, with driver adjustment limited to ±20% in 2 EGP steps and capped at an equal share of the trip cost.
- **FR-006**: The system MUST guarantee that riders' total payments, service fee included, never exceed the full trip cost, for every allowed price and every rider count of every seeded group. This MUST be proven by a test that sweeps all allowed prices and rider counts for the corridor's numbers.
- **FR-007**: The system MUST keep the cash rule: cash amounts are multiples of 5 EGP and stay inside the allowed range, or cash is not offered.
- **FR-008**: The system MUST show only pickup points and area names, never home addresses; seeded coordinates are approximate area centres.
- **FR-009**: The system MUST provide Arabic and English names for every new area, stop and arrival point through localization, and every new or changed screen MUST render correctly in RTL (ar) and LTR (en).
- **FR-010**: The system MUST seed marketplace demand and supply on the corridor (empty seats, trip requests) so feature 005 screens are populated on both directions.
- **FR-011**: The system MUST show the corridor's own names in the no-match state ("You're #N on the {origin} → {destination} list").
- **FR-012**: The system MUST keep the existing Sheikh Zayed → Smart Village corridor working so the existing 1,085 Flutter and 148 Node tests do not regress. Cairo ↔ Ismailia is the default corridor; the old one stays as additional demo data (assumed, founder may replace it later).
- **FR-013**: The system MUST set realistic trip duration and arrival times for the corridor's distance in all seeded groups, checked in the plan against a real route check.
- **FR-014**: The documents MUST be amended after founder approval: brief §6.1 and its no-match copy, Constitution IX rationale (with a Sync Impact Report and a version bump), and the roadmap numbering for the company-network feature.

### Key Entities

- **Area**: A named place people choose as home or workplace (Cairo side, Ismailia side, road towns). Shown by name only, never as points.
- **Corridor**: The set of areas, stops and groups that belong to one route, with one trip cost per leg.
- **Group**: One route, one time window, recurring days, drivers and riders, a fixed monthly price (existing concept, new data).
- **Stop / Arrival point**: A named pickup or drop-off point with a time, shared by riders.
- **Trip cost configuration**: The trip cost for the corridor and whether real per-kilometre and toll rates are switched on.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new rider on either direction of the corridor goes from the welcome screen to a match result in under 2 minutes in the demo.
- **SC-002**: For the corridor's trip cost, 100% of allowed price and rider-count combinations keep riders' total at or below the trip cost, with zero exceptions.
- **SC-003**: 100% of new user-facing text exists in both Arabic and English, with zero hard-coded strings.
- **SC-004**: The full existing test suite still passes after the change with zero regressions.
- **SC-005**: A full demo walk (match, join, Today, Wallet, empty seats, post a trip) in both directions shows no mention of Sheikh Zayed or Smart Village, so it can be filmed for public content.
- **SC-006**: The brief, constitution and roadmap contain no unmarked statement that the launch corridor is Sheikh Zayed → Smart Village.

## Assumptions

- The founder has confirmed (2026-10-16) that Cairo ↔ Ismailia is the first real launch corridor, and that the content plan (`D:\Company\30-Ideas\PersonalBrand\PERSONAL_BRAND_PLAN.md`) is built on it.
- Goora stays on fake repositories and a fake payment provider; no real backend, maps or payments are added by this feature.
- The service fee (up to 10%, trimmed to the cap) stays as built in feature 004; its legality (Law 87/2018, brief §8) remains an open item and is not decided here.
- The existing matching thresholds are kept for the longer route unless the founder says otherwise.
- The corridor is added as data and rules on top of the current structure; no new packages are added (Constitution IX).
- This feature takes number 006. The company-network feature (currently 006 in the brief) moves to a later number; this needs the founder's approval with the document amendments in FR-014.
- This is a commute product (Constitution I). The founder (2026-10-16) wants fixed-day work commuting plus occasional travel. Occasional travel is served only through the existing one-off features of 005 (empty seats, post a trip request); this feature builds no separate travel product. If occasional travel becomes a goal in its own right, Constitution I needs an amendment first.
