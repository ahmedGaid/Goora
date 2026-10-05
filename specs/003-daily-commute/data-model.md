# Data Model: Commute Groups and the Daily Commute

Pure Dart (`lib/core/time`, `lib/features/daily/domain`, additions in `lib/features/commute/domain`);
mirrored as plain objects in TypeScript for the four rule modules. Money = integer EGP (prices are
even, research R3).

## Time (`lib/core/time`)

| Type | Fields | Rules |
|---|---|---|
| `CalendarDate` | year, month, day | `day` → `Day` (sun…sat); `addDays(n)`; `monthKey` "YYYY-MM"; comparable |
| `WallTime` | date: CalendarDate, time: Clock | Cairo wall clock; comparable; `plusMinutes`; `minutesUntil(other)` |

## Additions to 002 types (`commute/domain/group.dart`)

| Type | New fields | Notes |
|---|---|---|
| `Member` | `seats?` (drivers, 1–4), `vehicle?` (make, colour), `phone?` (E.164, fake), `privacy` (default verifiedUsers), `days?` (null = group days) | 002 constructors keep working (all optional) |
| `CommuteGroup` | `stops: List<Stop>`, `arrival: Clock`, `arrivalName`, `rotationStart: CalendarDate` | `pickupPoints` stays for matching; `stops[i].point == pickupPoints[i]` |
| `Stop` | id, name (mainGate, centralSt — l10n), point, time: Clock | going order; last stop time == `going` |
| `Vehicle` | make (proper noun, not translated), colour (enum → l10n) | |

## Daily domain (`daily/domain`)

| Type | Fields | Rules / transitions |
|---|---|---|
| `PrivacyPreference` | enum verifiedUsers, sameCompany, sameCompound, womenOnly | availability per R7 |
| `Duty` | enum drive, ride, off | per person, date, leg |
| `LegAssignment` | leg, planned: memberId, actual: memberId?, isBackup, backupStep? | actual null + uncovered = no cover |
| `ScheduleDay` | date, going: LegAssignment?, ret: LegAssignment?, myDuty(leg) | built by `RotationPlanner` + overrides |
| `Ride` | id, groupId, date, leg, driverId, passengerIds, stops (with delayed times), status, delayMinutes, confirmed, shareToken | status: `scheduled → confirmed ⇄ scheduled` (undo) · `→ delayed` · `→ driverArrived(stopIndex)` · `→ inProgress` · `→ arrived`; `→ cancelled` (no driver, no cover) |
| `Absence` | personId, date, leg, madeAt: WallTime, kind (freeCancel, lateCancel, noCover), seatTaken | undo per R3; `noCover` always free |
| `StopCheckIn` | rideId, stopId, arrivedAt | `noShowAvailableAt = arrivedAt + 5 min` |
| `PassengerOutcome` | rideId, personId, outcome: `Outcome` (waiting, pickedUp, noShow), markedAt | switchable until `inProgress`; last mark counts; noShow only after 5 min |
| `Charge` | id, personId, rideId, reason (lateCancel, noShow), amount, owedTo (driverId) | lateCancel = share ~/ 2; noShow = share; collected in 004 |
| `NoShowStanding` | enum ok, warning, removal | from count in ride's month (2 → warning, ≥3 → removal) |
| `ReliabilityEvent` | personId, rideId, date, kind (kept, noShow, lateCancel, lateCantDrive) | free cancels produce no event |
| `Reliability` | percent (int 0–100), monthLateCancels, monthNoShows | R4 formula |
| `BackupCandidate` | member, relation (sameGroup, nearbyGroup, sameCompany, sameCommunity), seeker (home, work, times, days), freeSeats(leg, date), available(date) | |
| `BackupResult` | covered(cover, step) / none | first passing candidate in step order |
| `Notice` | id, kind, createdAt, params, read | kinds: driverConfirmed, driverUnconfirmed, delay, backupCover, noCover, driverArrived, lateCancelCharged, noShowCharged, noShowWarning, removed, seatOffered, sosSent |
| `VerificationItem` | kind (phone, nationalId, workEmail, license, vehicle), status (verified, notVerified, notNeeded) | license/vehicle = notNeeded for riders |
| `TrustProfile` | firstName, initials, rating, items, company?, compound?, isWoman, privacy | statuses from fake data only (FR-023a) |
| `PersonFacts` | isWoman, company? (only when work email verified), compound? | input to `PrivacyRules`; built from 001 profile + trust data |
| `TrustedContact` | id, name, phone: PhoneNumber | max 3 |
| `SosAlert` | id, rideId?, at, contactIds | fake send = recorded |
| `TripPosition` | rideId, progress 0–1, at | from `LocationSource` |

## Relationships

```text
CommuteGroup 1─* Member ─ RotationPlanner ─▶ ScheduleDay (per date) ─▶ Ride (per leg)
Ride 1─* StopCheckIn 1─* PassengerOutcome ─▶ Charge (noShow) ─▶ ReliabilityEvent
Person 1─* Absence ─▶ Charge (lateCancel) ─▶ ReliabilityEvent
Ride (driver absent) ─▶ BackupService(candidates) ─▶ LegAssignment.actual / Notice(noCover)
Person 1─1 PrivacyPreference ─▶ Seeker (002 matching) and PrivacyRules (backup)
```

## Fake storage keys (shared_preferences, JSON)

`daily.absences`, `daily.checkIns`, `daily.outcomes`, `daily.rideState` (confirm/delay/status per
ride id), `daily.backups`, `daily.charges`, `daily.events`, `daily.notices`, `trust.privacy`,
`trust.contacts`, `trust.sos`, `debug.demoNow`. Membership stays `commute.membership` (002).
Ride ids are deterministic: `<groupId>:<yyyy-mm-dd>:<going|return>`.
