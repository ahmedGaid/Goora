# Data Model: Commute Profile and Smart Matching

Pure Dart in `lib/features/commute/domain/`; mirrored as plain objects in TypeScript.

| Type | Fields | Rules |
|---|---|---|
| `GeoPoint` | lat, lng | `distanceMeters(a, b)` haversine, R = 6 371 000 m |
| `Clock` | minutes since midnight (0–1439) | `diff(a, b)` absolute minutes; formats h:mm + AM/PM |
| `Area` | enum: sheikhZayed, october, smartVillage | display via l10n only |
| `Place` | id, area, point | point is private |
| `Day` | enum sun…sat | default working days sun–thu |
| `DrivenTrips` | both, going, ret | trips per day: 2 / 1 / 1 |
| `DriverOffer` | seats 1–4, trips, contribution EGP | contribution within pricing range |
| `CommuteProfile` | home, work, departure, ret, days, driver? | ret > departure; home–work > 1500 m |
| `Member` | id, firstName, initials, role, isWoman, company?, compound?, rating 0–5, reliability 0–100, legs (going/return) | |
| `CommuteGroup` | id, origin, destination area, destinationPoint, pickupPoints[], going, ret, days, members, price, freeSeatsGoing, freeSeatsReturn, detourMinutes, womenOnly, sameCompanyOnly | |
| `Seeker` | role, home, work, departure, ret, days, legs needed, isWoman, company?, compound?, prefs (womenOnly, sameCompany, sameCompound) | built from profile + commute |
| `FactorScores` | destination, departure, pickup, ret, days, community, rating | unrounded points |
| `GroupMatch` | group, legs, score (int), factors, reasons[] (top 4 by points, > 0) | |
| `MatchResult` | main GroupMatch?, returnMatch? (different group), alternatives[] | main null → no match |
| `Reason` | kind (destination, departure, pickup, companyReturn, company, compound, ret, days, rating) + value | localized in presentation |

Membership (fake): `commute.membership` = group id. Waitlist (fake): seeded count 6 → position 7.
