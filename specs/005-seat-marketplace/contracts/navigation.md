# Contract: routes, entry points and screen states (UI)

## Routes (`lib/app/routes.dart`)

| route | screen | query | notes |
|---|---|---|---|
| `/empty-seats` | EmptySeatsScreen | `leg=going\|return`, `seat=<offerKey>` (after PayMethod) | booked confirmation is a state, not a route |
| `/post-trip` | PostTripScreen | `id=<requestId>` → posted/accepted/expired state | |
| `/offer-trip` | OfferTripScreen | `id=<tripId>` → live/full state | |
| `/find-riders` | FindRidersScreen | — | **new** |
| `/pay-method` | PayMethodScreen (004) | `next=<location>` | **new param**: return there instead of Today |

`PlaceholderScreen`, `PlaceholderKind` and the router loop over them are deleted (FR-002).

## Entry points and Back (FR-001, FR-002)

| from | action | opens | Back returns to |
|---|---|---|---|
| Frequency (rider, Just one trip) | Continue | Empty seats (`go`) | Frequency |
| Frequency (driver, Just one trip) | Continue | Offer a trip (`go`) | Frequency |
| Rider Today | "Need an extra trip? Book a seat" | Empty seats (`push`, group's leg) | Today |
| No-cover card | "Book an empty seat" | Empty seats (`push`, that day's leg) | Today |
| No-cover card | "Post your trip" | Post your trip (`push`) | Today |
| No-match screen | "Post your trip" | Post your trip (`push`, was `go`) | No-match |
| Empty seats | dashed "Nothing fits your time? Post your trip" | Post your trip (`push`) | Empty seats |
| Booked state (non-subscriber) | "Liked it? Make it your daily commute" | Commute setup, Every day preselected | Booked state |
| Driver Today | "Offer a trip" | Offer a trip (`push`) | Today |
| Driver Today | "Find riders" / requests "See all" | Find riders (`push`) | Today |
| Offer a trip | "Or find riders who already posted" | Find riders (`push`) | Offer a trip |
| Offer a trip | missing verification chip | Trust (`go` tab) | — |
| Book / Post with no arrangement | — | PayMethod `?next=` (`push`) | the same seat/form |
| Accepted daily request | "Continue" | PayMethod `?next=/today` | — |

Rule: every new screen uses `canPop() ? pop() : go(Routes.frequency)`.

## Screen states (all designed, FR-027)

| screen | states |
|---|---|
| Empty seats | loading · list (Going/Return toggle, route line, cards, caption, dashed card) · empty ("No seats on your route right now" + dashed card) · already riding this leg · error (retry) · booked (summary + upsell or Back to today) · top-up gate · seat just taken (calm banner, refreshed list) · late-booking note before confirm |
| Post your trip | form · daily disabled (reason) · top-up gate · posted (Sent to N, progress, Cancel) · accepted (driver card, pickup, time, price; daily → "You're now a commute group") · expired (Post again / See empty seats) |
| Offer a trip | form · not verified (chips, Publish off) · daily limit / joins-instead / overlap / one daily group (Publish off + words) · live (N of M booked, anonymous list, Cancel trip) · full ("Your car is full!") · departed (names shown) · done (cash rows for cash riders) · cancelled |
| Find riders | loading · list (area filter, Morning/Evening, Trips left today, cards in every TripFit state) · inline confirm (create) · empty (calm + privacy caption) · error |
| Driver Today requests | banner + up to 3 cards + See all · Accepted ✓ · empty (calm + privacy caption) |
| Today (no group yet) | one-off section · entry points · calm empty state |
| Today one-off section | rider: booked seat card (route, day/time, driver, pickup, price line, Cancel booking + rule, Share, SOS) · driver: offered trip card (progress, anonymous riders, Cancel trip; after done: cash rows) |

Every limit, state and price is shown as words, never colour alone (VII). All copy comes from
research R16.
