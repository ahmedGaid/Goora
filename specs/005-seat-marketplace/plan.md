# Implementation Plan: Seat Marketplace

**Branch**: `005-seat-marketplace` | **Date**: 2026-10-12 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-seat-marketplace/spec.md`

## Summary

Four one-off/demand flows feed daily groups: **A** Empty seats (rider books a free seat in an
existing car or a published offer), **B** Post your trip (rider request), **C** Offer a trip
(driver publishes), **D** Find riders (driver accepts requests), plus driver Today's "Requests on
your route" and subscriber reclaim with a full refund.

Two pure rules carry the legal core and get TypeScript twins with shared vectors:
`DriverDayRules.fit` (the 2-trip limit, one trip per direction, the ±30 min join, research R4)
and `PricingService.cashAmount` (FR-029: every cash amount a multiple of 5, never above the equal
share, R3). A third, `BookingRefund.amount`, joins the marketplace twin because it moves money
(R7). One value object, `SeatPrice`, turns contribution + basis + plan into every price line and
charge (R2). The four 004 call sites that print or record cash switch to it, which is the FR-029
amendment to 004.

Cost cap (FR-024): seats are counted against the price basis `riderSeats`, off-duty drivers
included, and every seat price is ≤ the equal share. Riders' total therefore stays ≤ trip cost
by construction (R6), and the extended sweep proves it (SC-002).

State lives in a new fake `MarketplaceRepository` on shared_preferences (`market.*`). Wallet and
subscribed seats are paid at booking through a `SeatLedger` seam into 004's ledger; cash seats
join 004's cash-trial fold through a callback (R7, R9). "Becomes a group" is real: a
`GroupCatalog` persists created groups, so 003's Today/Week read them through `myGroup()` (R10).
One-off trips show in a separate Today section; 003's group machinery is untouched (R11).

## Technical Context

**Language/Version**: Dart 3.12 / Flutter 3.44; TypeScript on Node 24 for the twins

**Primary Dependencies**: none new (flutter_riverpod + riverpod_generator, go_router, intl,
shared_preferences: all already in use)

**Storage**: `shared_preferences`, new keys `market.offers`, `market.requests`,
`market.bookings`, `market.groups`, `market.members.<groupId>`, `market.seedCursor`
(data-model.md). Plus wallet ledger rows of two new kinds. "Reset demo data" clears `market.*`.

**Testing**: `flutter_test` unit tests cover `DriverDayRules`, `cashAmount`/`SeatPrice`,
`BookingGate`, `BookingRefund`, free-seat math, `DriverDay` assembly, `GroupCatalog` JSON round
trip, the one-leg group schedule (R10 risk) and the fake repository flows. Widget tests run in
ar + en for Empty seats, the booked confirmation, Post your trip, Offer a trip, Find riders,
driver Today requests, the one-off Today section and the no-group Today. Goldens cover the new
cards. `node --test` covers `pricing.ts` (+cash) and `marketplace.ts` (new).

**Target Platform**: Android 7+ / iOS 14+. Server: twins + schema only, no deploy.

**Project Type**: mobile-app

**Performance Goals**: every list derives from ≤ 30 seeded items plus local records; < 1 s on
device, like 003/004.

**Constraints**:
- Constitution II: no driver over 2 trips a day; prices only from the system (no field accepts
  a typed price); riders' total ≤ trip cost; ±20% in 2 EGP steps.
- Constitution IV, stricter reading: no rider name or photo on any driver-facing list before
  boarding.
- No real payments or push notifications.

**Scale/Scope**: 4 new screens (Empty seats + booked state, Post your trip, Offer a trip, Find
riders); driver Today requests section; one-off Today section + no-group Today; 4 demo actions;
3 pure rules (2 twinned modules); 1 catalog for created groups; 004 cash amendment at 4 call
sites; about 60 new ARB keys (research R16).

## Constitution Check

*Pre = before research; Post = after design.*

| Principle | Gate | Pre | Post |
|---|---|---|---|
| I Commute-first | One-off flows exist to feed daily groups: the booked confirmation upsells "make it your daily commute", and daily offers/requests become groups (R10) | ✅ | ✅ |
| II Cost-sharing | ≤ 2 trips/day incl. group legs, one per direction, joins free (R4, R5; twin + vectors + scripted sequences, SC-003). Prices only from `PricingService.range`/`SeatPrice`; no input accepts a price (FR-022). Cap holds by construction: seats ≤ `riderSeats`, each price ≤ equal share, cash rounded down when needed (R3, R6; sweep, SC-002). Fee legality still open (brief §8, spec Open) | ✅ | ✅ |
| III Arabic-first | All copy in ARB both locales; brief strings verbatim; drafts listed in R16; directional layout; widget tests ar + en for every screen | ✅ | ✅ |
| IV Privacy | Driver-facing models carry no name/photo (`AnonymousRider`) until departure, the boarding stand-in (R11, R15); pickup points only; SC-004 widget test | ✅ | ✅ |
| V Trust & safety | Publish needs verified ID + license + vehicle (FR-014); Share + SOS on every one-off trip card; driver cancels count on reliability (FR-017) | ✅ | ✅ |
| VI Design system | Reuses GooraCard, GooraRadioCard, GooraStepper, GooraProgressBar, GooraDashedButton, GooraStatusChip, GooraBanner, GooraPill, GooraAvatar; no new tokens expected (if one is needed, it goes into `lib/core/theme` + `contrast_test.dart`) | ✅ | ✅ |
| VII Accessible | Every limit/state is a word, never colour alone ("Daily limit reached", "Doesn't fit…"); ≥ 44 px; semantic labels on Accept/Book/SOS | ✅ | ✅ |
| VIII Testable | Pure rules with the brief's numbers; Dart/TS twins on shared vectors; scripted limit sequences; fakes-first repository behind an interface | ✅ | ✅ |
| IX Simplicity | No new packages. One new feature folder. Once trips are time-driven in the fakes, with no second ride engine (R11). Schema-only migration is droppable (R17) | ✅ | ✅ (see Complexity) |

Workflow note: the constitution names branches `feature/00X-name`; this repo uses speckit's
`00X-name` for 001–005 alike. That is a pre-existing convention and needs no change here.

## Project Structure

### Documentation (this feature)

```text
specs/005-seat-marketplace/
├── spec.md · checklists/requirements.md          (specify)
├── plan.md                                       this file
├── research.md                                   R1–R17
├── data-model.md                                 entities, states, storage keys
├── contracts/
│   ├── pricing.md                                v3: cashAmount + SeatPrice, vectors, 004 callers
│   ├── marketplace-rules.md                      DriverDayRules + BookingRefund twin + vectors
│   ├── repositories.md                           MarketplaceRepository, seams, GroupCatalog
│   └── navigation.md                             routes, entry points, Back, screen states
├── quickstart.md                                 validation scenarios
└── tasks.md                                      (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
lib/features/marketplace/                                          (new)
  domain/  driver_day_rules.dart      R4  (twin: marketplace.ts)
           booking_refund.dart        R7  (twin: marketplace.ts)
           booking_gate.dart          R8
           market_day.dart            R13 next-departure / next-workday resolution
           seat_math.dart             R6  free seats on a leg-date
           offered_trip.dart · trip_request.dart · booking.dart · seat_offer.dart
           driver_day.dart · anonymous_rider.dart
           marketplace_repository.dart (interface)
  data/    fake_marketplace_repository.dart · market_seed.dart · providers.dart
  presentation/
           empty_seats/  empty_seats_screen.dart · seat_card.dart · booked_view.dart
           post_trip/    post_trip_screen.dart (form · posted · accepted · expired)
           offer_trip/   offer_trip_screen.dart (form · live · full)
           find_riders/  find_riders_screen.dart · request_card.dart
           today/        one_off_section.dart · requests_section.dart (driver Today, US5)
           labels.dart · route_form.dart (From / To / Time / Just once–Every workday, shared by B and C)
lib/features/commute/domain/pricing_service.dart    + cashAmount                       (R3)
lib/features/commute/domain/group.dart              + toJson/fromJson (Group, Member, Stop, Vehicle)
lib/features/commute/data/group_catalog.dart        seed + created groups + extra members (new, R10)
lib/features/commute/data/fake_commute_repository.dart   groupsFor/join read the catalog
lib/features/daily/domain/notice.dart               + 5 NoticeKinds; NoticeSink interface (R9)
lib/features/daily/data/fake_daily_commute_repository.dart  groups from catalog; implements NoticeSink
lib/features/daily/presentation/today/              today_screen (no-group state), driver_today
                                                    (Find riders route, requests section),
                                                    rider_today (one-off section), cash_after_trip
                                                    (SeatPrice.cash; row extracted to shared widget)
lib/features/wallet/domain/seat_price.dart          SeatPrice (new, R2)
lib/features/wallet/domain/activity_entry.dart      + seatBooked, seatRefund
lib/features/wallet/domain/wallet_repository.dart   + SeatLedger
lib/features/wallet/data/fake_wallet_repository.dart  ledger rows; one-off cash trips in the fold;
                                                      once-trip income for the driver
lib/features/wallet/presentation/labels.dart · rider_wallet.dart · pay_method_screen.dart
                                                    cash lines via SeatPrice; PayMethod `next`
lib/features/settings/presentation/demo_section.dart  + 4 demo actions (R14)
lib/features/onboarding/presentation/onboarding_routes.dart  relaunch → Today with one-off trips
lib/features/placeholder/                           deleted (FR-002)
lib/app/routes.dart · router.dart                   + findRiders; real screens; placeholders gone
lib/core/l10n/app_ar.arb · app_en.arb (+ generated) ~60 keys (R16)
supabase/functions/_shared/pricing.ts + .test.ts    + cashAmount, sweep extended
supabase/functions/_shared/marketplace.ts + .test.ts   (new)
supabase/migrations/20261012000000_marketplace.sql  schema + RLS + anonymous view (R17)
test/fixtures/pricing_vectors.json · gen_pricing_vectors.py      + cash
test/fixtures/marketplace_vectors.json · gen_marketplace_vectors.py   (new)
test/unit/ · test/widget/ · test/golden/            per Testing above
```

**Structure Decision**: one new feature folder `marketplace` (research R1). The other features
change only at their seams: `commute` gets the catalog and `cashAmount`; `daily` gets notices,
the Today sections and the no-group state; `wallet` gets `SeatPrice`, `SeatLedger` and the fold
input. Their domain layers never import marketplace domain types.

## Phasing (maps to tasks.md)

Riskiest first, thinnest slice early. Each phase is about one session.

- **P1 — rules + twins**: `cashAmount` + `SeatPrice`; pricing vectors gain `cash`; sweep
  extended. `DriverDayRules` + `BookingRefund` + `marketplace.ts` + vectors + scripted
  sequences. `BookingGate`, `MarketDay`, `SeatMath` unit tests.
- **P2 — 004 cash amendment (FR-029)**: the four callers in
  [contracts/pricing.md](contracts/pricing.md); widget tests at 44 → "Pay 45 EGP cash" and
  "Received 45 EGP cash"; recorded `CashMark.amount` = 45. This ships value alone and could
  merge first.
- **P3 — model, store, seams**:
  - entities + `FakeMarketplaceRepository` + `MarketSeed`;
  - `GroupCatalog` + group JSON;
  - **one-leg group schedule test (R10 risk)**;
  - `NoticeSink`, `SeatLedger`, wallet fold input;
  - reset clears `market.*`.
- **P4 — US1 Empty seats (MVP)**:
  - Empty seats screen, booked state and upsell;
  - entry points (onboarding, Today, no-cover card);
  - PayMethod `next`, the gate (needs method / top up), the one-off rider Today section;
  - the no-group Today and relaunch to Today.
- **P5 — US2 Offer a trip**: form (chips, stepper, rules); live/full state; cancel + refunds +
  reliability; daily offer → group on its first booking; "A rider books your seat"; "Verify my
  driver documents"; the once-trip cash step.
- **P6 — US3 Post your trip**: form, posted, accepted (once → seat; daily → group →
  PayMethod), expired, cancel; "A driver accepts your request"; dashed card, no-match and
  no-cover entry points.
- **P7 — US4 Find riders**: filters, counter, request cards with all `TripFit` states, inline
  confirm, join/create, anonymity.
- **P8 — US5 driver Today requests**: banner, cards, Accepted ✓, empty state, "see all".
- **P9 — US6 reclaim**: reclaim rule, full refund, notice, "A subscriber takes this seat",
  refused after the cut-off; cash-trial reclaim moves nothing and does not count toward the 10.
- **P10 — polish + gate**: schema migration (R17, droppable); goldens; brand checklist ar + en;
  copy list to founder; `flutter analyze` 0, `flutter test --concurrency=1`, `node --test`;
  quickstart scenarios on device.

## Complexity Tracking

| Addition | Why needed | Simpler alternative rejected because |
|---|---|---|
| `GroupCatalog` + JSON for groups (R10) | Spec requires a daily offer/request to *become a group* shown on Today/Week like 003's, and 003 reads `myGroup()` from a constant seed | A "group" label on a one-off trip would not appear in Week, rotation or the 003 rules the spec carries over |
| One-off trips outside 003's `Ride` engine (R11) | 003's driver actions re-derive rides from `myGroup()`; a second ride source would touch about 15 methods | Accepted trade-off: no pickup check-in or no-show marks for one-off trips in the fakes (founder to confirm); the server will hold one ride table for both |
