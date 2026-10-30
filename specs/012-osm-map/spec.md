# Feature Specification: Pickup-point map (OpenStreetMap display)

**Feature Branch**: `feat/osm-map` (spec folder `012-osm-map`)

**Created**: 2026-10-30

**Status**: Draft

**Input**: User description: "012 OSM map display — show a group's fixed pickup points (and arrival point) on a small map on the match result screen and on today's meeting-point card (rider + driver), tap to open a bigger map. Display only (matching stays on PostGIS). flutter_map behind a swappable renderer interface; tile URL template + key from --dart-define; with no tile URL (default, tests, demo) render a calm offline schematic with no network. OSM attribution wherever tiles render. Never a home address, only pickup points; no live driver location; no free map picking."

Source: `GOORA_PROFIT_CHANGES.md` §4 (OpenStreetMap instead of Google Maps), `GOORA_SPEC_KIT_BRIEF.md` §4 (maps line) and §3 (tokens), Constitution IV (privacy) and VII (accessibility).

## Clarifications

### Session 2026-10-30 (autonomous run — answered by the lane, logged in research.md "Decisions")

- Q: Does the new map replace the existing drawn route card on Today? → A: No. The route card (with its trip-progress marker and countdown, 003 US7) stays as is; the meeting-point card is a new, separate card placed after the trip timeline.
- Q: With no tiles, draw the points at their real relative positions or in order? → A: In order, evenly spaced along a soft path (a sketch), labelled "sketch, not to scale". Real positions overlap at corridor scale (200 m stops vs a 100 km leg).
- Q: Is the attribution text translated? → A: Yes — "© مساهمو OpenStreetMap" / "© OpenStreetMap contributors" (OSM's attribution guideline allows translation), plus the provider's own line when configured.
- Q: Can the user pan/zoom? → A: Only on the bigger map with real tiles. The small card is a static preview (one tap target); the sketch never pans.
- Q: Driver on a return-only day? → A: The card shows the work meeting point (the return pickup) only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See where the group meets before joining (Priority: P1)

A rider (or driver) has just been matched to a commute group. Under the group summary they see a
small map card with the group's pickup point (where they will stand) and the arrival point. The
card names each point and its time in words, so the map is never the only way to read it. Tapping
the card opens a bigger map of the same points.

**Why this priority**: the meeting point is the one place a new member has to find on day one;
seeing it before joining builds the trust that makes them press "Join".

**Independent Test**: open the match result in Arabic and English; the map card shows exactly two
named points (pickup, arrival) with their times; tapping it opens the bigger map; no home point is
ever drawn.

**Acceptance Scenarios**:

1. **Given** a fresh match, **When** the match result opens, **Then** a map card shows the pickup point nearest the viewer (by name and time) and the arrival point (by name and time), and nothing else.
2. **Given** the match result, **When** the viewer taps the map card, **Then** a bigger map of the same points opens and can be closed with one tap.
3. **Given** the viewer switches to another candidate group, **When** the result redraws, **Then** the map shows that group's points.

---

### User Story 2 - Find today's meeting point (Priority: P1)

On Today, a rider sees a "meeting point" card for their next trip: their own pickup stop (going) or
the work meeting point (return), plus the arrival point when it is a named point. A driver sees the
stops of the trip they drive, in driving order, then the arrival point. Tapping opens the bigger map.

**Why this priority**: this is the everyday use — "where exactly do I stand at 7:20?".

**Independent Test**: rider and driver Today in both locales show the card with the right named
stops in order; tap opens the bigger map.

**Acceptance Scenarios**:

1. **Given** a rider with a going trip, **When** Today opens, **Then** the meeting-point card shows their pickup stop with its time and the arrival point.
2. **Given** a driver with a going trip, **When** Today opens, **Then** the card shows every pickup stop of that trip numbered in driving order, then the arrival point.
3. **Given** either card, **When** tapped, **Then** the bigger map opens with the same points.
4. **Given** no upcoming trip, **When** Today opens, **Then** no meeting-point card is shown (the existing "no rides soon" state stays).

---

### User Story 3 - Works with no map service configured (Priority: P1)

Until the founder picks a map-tile provider (open question Q4), the app has no tile address. In
that state — and in every test and demo build — the map card shows a calm drawn sketch of the
points in order on the brand's map colour, with the names list, and says it is a sketch, not to
scale. It never shows a broken or grey map and never touches the network.

**Why this priority**: this is the shipped default today; it must look designed, not broken.

**Independent Test**: run with no tile address; every map card renders the sketch; no network
request is made.

**Acceptance Scenarios**:

1. **Given** no tile address configured, **When** any map card renders, **Then** it shows the drawn sketch, the names list and a "sketch, not to scale" note, with no network use.
2. **Given** a tile address configured, **When** a map card renders, **Then** it shows real map tiles with the points on them and the OpenStreetMap attribution visible on the map.

---

### Edge Cases

- **One point only** (e.g. a return trip whose only named point is the work meeting point): the map centres on it; the sketch draws one pin in the middle.
- **Points far apart** (a 100 km Cairo ↔ Ismailia leg) or **very close** (two stops 200 m apart): the real map fits all points with padding and a street-level zoom cap; the sketch spaces pins evenly in order so they never overlap.
- **Tiles fail to load** (no signal, bad key): the map area keeps the brand map colour behind the points and the names list stays readable; nothing grey or blank is shown.
- **Large text (1.3×)**: names list wraps; pin numbers stay inside their pins; no overflow.
- **Right-to-left**: the first point sits on the start side (right in Arabic), matching the existing route card.
- **Screen reader**: the card reads as one button: "Map of meeting points: 1 Main gate 7:20, Arrival Smart Village gate 2 8:05 — open the map".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The map MUST be display only: it shows existing named points and never lets a user drop, drag or pick a free location.
- **FR-002**: The map MUST only ever receive public pickup/arrival points (group stops). A home location MUST NOT be passable to it (Constitution IV).
- **FR-003**: The map MUST NOT show any live driver position. (The existing drawn route card with the trip-progress marker is unchanged and out of scope.)
- **FR-004**: Every point MUST be identified by a number or icon AND its name and time in text next to the map; colour MUST NOT be the only signal (Constitution VII).
- **FR-005**: The match result screen MUST show a map card for the shown group: the viewer's pickup stop and the arrival point.
- **FR-006**: Rider Today MUST show a meeting-point card for the next trip: the rider's stop, plus the arrival point on the going leg.
- **FR-007**: Driver Today MUST show a meeting-point card for the trip being driven: all pickup stops in driving order, plus the arrival point on the going leg; on a return-only day, the work meeting point.
- **FR-008**: Tapping a map card MUST open a bigger map of the same points, closable with one tap; the whole card is one ≥ 44 px target with a spoken label.
- **FR-009**: The tile address and key MUST come from build-time configuration only; no key is ever stored in the repository.
- **FR-010**: With no tile address configured, the app MUST make no map network requests and MUST show the drawn sketch with a "sketch, not to scale" note.
- **FR-011**: Wherever real map tiles render, the OpenStreetMap attribution MUST be visible on the map (plus the tile provider's own attribution when configured).
- **FR-012**: The map provider MUST be replaceable without touching the screens that show the map (one switch point).
- **FR-013**: All new text MUST exist in Arabic (Egyptian colloquial, default) and English, reusing the lexicon (التجمع for pickup, الوصول for arrival).
- **FR-014**: Layout MUST be directional (correct in RTL and LTR) and use design tokens only.

### Key Entities

- **Map point**: a public meeting point shown on the map — position, kind (pickup or arrival), its order number (pickups), name and time text. Built only from a group stop.
- **Map configuration**: the build-time tile address template, key and optional extra attribution; "tiles on" only when the address is set.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the match result and both Today views, a member can name their meeting point and its time from the map card alone, in both languages, in 100% of the widget-test scenarios.
- **SC-002**: With no tile address configured, 0 network requests are made by any map card (asserted in tests).
- **SC-003**: With tiles on, the attribution is visible on 100% of rendered maps (asserted in tests).
- **SC-004**: 0 home locations reach the map (enforced by the map's input type and asserted in tests).
- **SC-005**: All map screens render at 1.3× text in Arabic and English with no overflow (goldens).
- **SC-006**: Swapping the map provider changes one file, not the screens.

## Assumptions

- The tile provider and real key are a founder decision (Q4); this feature stays provider-neutral and ships with the sketch as the default.
- The tile address follows the usual `{z}/{x}/{y}` template; a `{key}` placeholder is filled from the key setting.
- The bigger map is a sheet over the current screen (no new route), so app routing is untouched.
- Group stops are already public meeting points (`Stop.point`), which is all the map needs; no data changes.
- The Android internet permission is owned by the launch-prep lane; this feature only flags it.
