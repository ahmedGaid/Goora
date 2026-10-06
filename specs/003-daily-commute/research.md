# Research: Commute Groups and the Daily Commute

Decisions carried from 001/002 are not repeated here (demo cost 160 → 40 per trip, fakes-first,
pill/tab colours, riders anonymous to drivers until boarding). Spec clarifications (statuses-only
verification, reliability = kept ÷ booked over 30 days, off-duty drivers ride and pay 40) are
applied as written.

## R1 App shell and routing

- **Decision**: go_router `StatefulShellRoute.indexedStack` with four branches — `/today`,
  `/week`, `/wallet`, `/trust` — rendered by `AppShell` with the existing `GooraBottomNav`. Each
  tab keeps its own scroll/state; switching language rebuilds in place and keeps the tab (spec
  edge case).
- `/today` keeps its path, so 002's driver "Join this group" (`context.go(Routes.today)`) lands in
  the shell unchanged. The rider plan placeholder (004) gains a "Continue" button → `/today`.
- Resume: `routeForSession` returns `/today` when the person has a group (membership key
  `commute.membership`, read synchronously from the already-loaded `SharedPreferences`), else the
  002 flow. A removed person (FR-009) has no membership → back to commute setup/match.
- **Alternatives**: a plain `IndexedStack` inside one route (loses deep links per tab); keeping
  the placeholder and adding `/home` (breaks 002's join route).

## R2 Time: wall-clock Cairo time, no time zones in rules

- **Decision**: rules take `WallTime` = `CalendarDate` (y/m/d) + `Clock` (minutes since midnight,
  from 002). The app builds it from the device's local `DateTime` (`now_provider.dart`); the
  server adapter converts `timestamptz` to Africa/Cairo wall time with
  `Intl.DateTimeFormat(…, {timeZone: 'Africa/Cairo'})`. Rules never see a time zone, so Egypt's
  summer-time shifts cannot break the 9 PM boundary.
- `CalendarDate`: `weekday → Day` (sun…sat from 002), `addDays`, `monthKey` (`2026-10`),
  `isBefore/isAfter`, `daysBetween`.
- `nowProvider` (Riverpod) returns `WallTime Function()`; tests override it with a fixed value;
  debug builds may override it with a demo clock (R11). Countdown widgets use a 1-second
  `Stream.periodic` ticker scoped to the widget, not the tab.

## R3 AttendanceRules (brief §6.5, FR-005 – FR-011) — exact numbers

Build note (P1): `WallTime` carries seconds as well as the minute `Clock`, because the no-show
boundary is 4:59 vs 5:00 after arrival.

All in `attendance_rules.dart`, constants in one `AttendanceLimits` object:
`cutoff = Clock.hm(21, 0)`, `noShowWait = 5 min`, `warnAt = 2`, `removeAt = 3`.

| Function | Rule |
|---|---|
| `cutoffFor(rideDate)` | `WallTime(rideDate − 1 day, 21:00)` — calendar day before, even if not a working day |
| `cancelCharge(rideDate, madeAt, share)` | `madeAt < cutoff` → free (0); `madeAt ≥ cutoff` → `share ~/ 2` per trip. 8:59 PM free, 9:00 PM late |
| `canCancel(ride, madeAt)` | allowed until the leg's scheduled pickup time; after that only the no-show path exists |
| `canUndo(absence, now, seatTaken)` | only while `now < cutoff` and the seat was not given away; otherwise refused with a calm message |
| `noShowAvailableAt(arrivedAt)` | `arrivedAt + 5 min`; `canMarkNoShow(arrivedAt, now)` = `now ≥ that`. 4:59 not yet, 5:00 yes |
| `noShowCharge(share)` | full `share` (40) |
| `standing(noShowsThisMonth)` | `<2` ok · `==2` warning · `≥3` removal. Each trip counts (going + return same day = 2) |
| `driverNoShow(ride, now)` | driver neither checked in nor cancelled by first scheduled pickup + 5 min |
| `driverCantDriveLate(rideDate, madeAt)` | same cut-off; drivers owe no money; only reliability is affected |

- Prices are always even (002 pricing uses 2-EGP steps from an even suggestion), so `share ~/ 2`
  is exact (40 → 20). A unit test pins this.
- **Seat release** (FR-006): a free cancellation marks the seat "offered to the waitlist"; at the
  cut-off the waitlist takes it when anyone is waiting (fake corridor waitlist = 6 → always taken).
  This makes "Undo" possible exactly until 9 PM and gives the spec's "undo refused" edge case a
  concrete trigger. **Founder decision 2026-10-06**: a late (after 9 PM) cancellation *can* be
  undone while its seat is still free — the waitlist only takes seats at the cut-off, so a late
  cancel's seat stays free until pickup; undo removes the charge and the reliability event.
  `canUndo` refuses only `refusedSeatTaken` (free cancel, at/after cut-off, waitlist waiting) or
  `refusedTooLate` (at/after the trip's pickup time).
- "I can't come tomorrow" cancels both legs the person rides by default; the sheet lets them untick
  one leg. "Not coming next week" = one absence per ride day of next week (Sun–Thu after the
  coming Saturday), each charged by `cancelCharge` at the moment of tapping.
- No-show count is per calendar month (`monthKey` of the ride date) and resets on the 1st; the
  reliability % does not reset (spec edge case).

## R4 ReliabilityRules (FR-036)

```text
window   = rides with date in [today − 30 days, today) whose scheduled time has passed
booked   = window rides the person was on (rider seat or driving duty), minus free cancels
missed   = 1 × no-shows + 0.5 × late cancels (riders) / late can't-drive (drivers)
percent  = booked == 0 ? 100 : roundHalfUp((booked − missed) / booked × 100), clamped 0–100
```

Vectors: 12.5 / 13 → 96 %; 0 booked → 100 %; 1 no-show of 4 → 75 %; 1 late cancel of 2 → 75 %;
x.5 rounds up. Caption parts (this calendar month): `lateCancels` and `noShows` counts → "1 late
cancel this month." + the fixed rule "3 no-shows in a month removes you from the group."; no events
→ only the fixed rule.

## R5 RotationPlanner (§6.4, FR-022, FR-022a, SC-005)

- Per leg, independently. Eligible drivers on a date = group drivers who chose that leg and that
  day (`Member.days`, default = group days) and have no absence that day.
- Periods: consecutive 4-week blocks starting from the group's `rotationStart` (a Sunday).
- Greedy per ride day in date order: pick the eligible driver with the fewest drives on that leg
  in the current period; ties → longest since last drive on that leg → lowest member id.
  With equal availability this is round-robin, so in every period max − min ≤ 1 (SC-005); with
  unequal day choices the guarantee holds among drivers sharing the same days (documented in the
  test, not promised beyond the spec).
- The plan is the *planned* driver. Absences and backups are applied on top (`ScheduleDay.going /
  ret` carry `planned`, `actual`, `isBackup`), so a backup never shifts the fairness count.
- Off-duty drivers (FR-022a): on a leg they don't drive that day they are passengers of the
  on-duty car, owe the group price, and rider rules apply. Seats per leg/day:
  `onDuty.seats − riders on leg − offDutyDrivers on leg − absent` (absent riders free their seat).

## R6 BackupService (§6.6, FR-017 – FR-020, SC-004)

- Input: the uncovered `Ride` (group, date, leg, passengers), a `List<BackupCandidate>` each tagged
  with how they relate to the group, `MatchingLimits`.
- Steps in order: `sameGroup` (off-duty group drivers who drive this leg, not absent) →
  `nearbyGroup` (drivers of other groups driving this leg/day whose group passes 002 hard
  constraints vs. this group's route for that leg) → `sameCompany` (any network driver sharing a
  company with a passenger) → `sameCommunity` (sharing a compound). Partner transport: out of scope.
- A candidate passes when: available that day; free seats in their car that leg ≥ passengers
  needing a seat; 002 hard constraints (pickup ≤ 1000 m, detour ≤ 10, time ≤ 20, destination ≤
  1500 m) via `MatchingService.evaluate` with a driver `Seeker` limited to `{leg}` and `{day}`; and
  every passenger's `PrivacyPreference` accepts the cover (R7).
- Within a step: least detour → highest rating → lowest id. First passing candidate wins; result
  `BackupResult.covered(cover, step)` or `BackupResult.none`.
- One cover carries the whole leg; splitting riders across several covers is deferred (IX).
- Price on covered days = group price (FR-019); `Charge` amounts never use the cover's own price.
- No cover: notice with the three options (empty seat → 005-A placeholder, post trip → 005-B
  placeholder, day off free). The search runs at "Can't drive" time; the evening job re-runs it at
  9 PM (cut-off) and sends the no-cover notice then at the latest (FR-020). Choosing "day off"
  creates an absence with reason `noCover`, charge 0, no reliability effect.

## R7 Privacy preference (FR-024 – FR-026)

- `enum PrivacyPreference { verifiedUsers, sameCompany, sameCompound, womenOnly }`, default
  `verifiedUsers`; saved per person.
- Availability: `womenOnly` only for women (gender from 001 profile); `sameCompany` needs a
  verified work email (company from trust data); `sameCompound` needs a compound name. Unavailable
  pills stay visible but disabled with a short hint (except `womenOnly` for men: not shown).
- Matching: `Seeker` flags come from the preference (`womenOnly`, `sameCompanyOnly`,
  `sameCompoundOnly`) — the 002 `_privacyCompatible` logic is reused unchanged.
- Backup: `PrivacyRules.accepts(pref, owner, other)` mirrors the same three checks for a single
  person, applied to every passenger against the cover.
- A change never touches the current group (FR-026); a note says it applies from now on.

## R8 Live trip (FR-028, US7)

- `LocationSource` interface: `Stream<TripPosition> watch(rideId)`; `TripPosition` = progress
  0–1 along the drawn route + timestamp (no coordinates are needed by the UI until maps exist).
- `SimulatedLocationSource` emits every 5 s from the driver's arrival to arrival time, progress
  = elapsed ÷ trip minutes, so the refresh limit (≤ 10 s) holds with margin.
- `GooraRouteMap` gains an optional `driverProgress` marker; swapped for `google_maps_flutter`
  when the key exists.
- Active trip = from driver "I've arrived" at the person's stop until arrival.

## R9 Dialler and share sheet (new packages)

- `url_launcher` → `PhoneDialer.dial(String e164)` with `tel:` URIs ("Call driver", "Call 122").
  Android 11+ needs a `<queries>` entry for `tel` in `AndroidManifest.xml`.
- `share_plus` → `TripSharer.share(String text)`.
- Both behind interfaces in `daily/domain`; widget tests inject recording fakes.
- **Alternatives**: Android intents/iOS URL schemes via hand-written method channels (more code,
  untested platform glue); copying the link to the clipboard only (fails "system share sheet").

## R10 Share link and SOS (FR-030, FR-031)

- Link: `${Env.shareBaseUrl}/t/<token>`; `shareBaseUrl` is a `String.fromEnvironment` with a
  placeholder default until a domain is chosen. Token = random 16-char id stored on the ride
  (fake). The message: route areas, driver first name, car, expected arrival — never a home
  location.
- SOS sheet: one confirm step → "Call 122" (dialler) + "Alert my trusted contacts" (records an
  `SosAlert`; real SMS waits for a provider). With no contacts: only "Call 122" + "Add a trusted
  contact" → Trust tab. Two taps from Today (SOS → Call 122) = SC-006.
- Trusted contacts: up to 3, name + Egyptian mobile validated with 001's `PhoneNumber`.

## R11 Fake data, demo clock and inbox

- `daily_seed.dart` extends the corridor seed for group `sz-0725` (Ahmed + Mohamed drive both
  legs; Sara, Youssef ride): stops "Main Gate" 7:20 and "Central St." 7:25, arrival "Smart Village,
  Gate 2" 8:05, return 5:00 PM (002 group time, unchanged — the prototype's 5:05 is an example);
  cars, ratings, fake phones (+20 10 0000 000x), rotation start, and a 30-day history giving the
  seeded user 96 % with one late cancel this month.
- The current person joins as a member with their own role and legs (002 membership); a driver
  member enters the rotation.
- **Demo section** (debug builds only, in Settings): set demo time (ride-day 7:15 AM, 8:55 PM,
  9:05 PM, real time), "Driver can't drive next Tuesday", "Driver can't drive — no cover",
  "Reset demo data". Release builds use real time only.
- **Notices**: an in-app inbox (bell on Today header → sheet) plus derived banners. Push (FCM)
  arrives with server keys; nothing in this feature depends on it.
- Driver confirmation is informational: an unconfirmed drive still runs.
- Trip lifecycle on the driver side: "I've arrived at <stop>" per stop in order → mark each
  passenger → "Start trip" after the last stop (marks are final from here) → "End trip" (fake also
  ends automatically at simulated arrival). Report delay offers 5 / 10 / 15 minutes.

## R12 Server (FR-032, FR-033)

- Migration `20261006000000_daily_commute.sql`: `rides`, `ride_passengers`, `absences`,
  `pickup_check_ins`, `charges`, `backup_assignments`, `notices`, `trusted_contacts`,
  `sos_alerts`, `privacy_preference` column on `profiles`, `rotation_start` on `groups`. RLS on
  every table: members read their own group's rides/schedule; a person writes only their own
  absences/contacts/alerts; drivers write check-ins for rides they drive; no table exposes
  `commute_profiles.home`.
- `_shared/attendance.ts`, `reliability.ts`, `rotation.ts`, `backup.ts` — erasable TypeScript,
  `.ts` imports (002 R6); each `*.test.ts` loads the same `test/fixtures/*_vectors.json` as the
  Dart `daily_vectors_test.dart`.
- `commute-day/index.ts` (actions: cancel, undo, confirm, delay, cant-drive, arrive, mark, start,
  end, sos) and `evening-cutoff/index.ts` (pg_cron daily 21:00 Africa/Cairo: release freed seats
  to the waitlist, re-run backup for uncovered legs, send no-cover notices). Thin adapters; not
  executed locally.
- Build addendum (T064–T065): three more tables the actions need — `passenger_outcomes` (driver
  marks), `reliability_events` (FR-036 input), `cutoff_runs` (job idempotency). Service-role-only
  SQL functions `backup_input(ride)` (candidates in the `backup.ts` shape, like 002's
  `match_input`) and `nearest_stop(group, user)` (returns a stop id; the home point stays in the
  database). A trigger stamps `absences.made_at` and the free/late kind on direct inserts, and
  limits trusted contacts to 3. DB access shared by both functions is in `_shared/daily_store.ts`.

## R13 New core widgets

`GooraStatTile` (label + value, used for Return time and You pay per trip), `GooraProgressBar`
(value with visible % text and semantics), `GooraStatusChip` (icon + text: covered, waiting,
pickedUp, noShow, backup, off), live marker on `GooraRouteMap`. All token-only, goldens RTL + LTR,
added to the Design gallery.

## R14 Drafted copy (founder review) — not in the prototype dictionary

Everything else is taken from the prototype's ar/en dictionary and brief §7. Brief wins over the
prototype: no "Goora fee" lines; 160 not 180.

| key | ar | en |
|---|---|---|
| notNextWeek | مش جاي الأسبوع الجاي | Not coming next week |
| notNextWeekConfirm | هنعلّم كل أيام الأسبوع الجاي إجازة. الأيام اللي لسه قبل 9 بالليل من غير فلوس. | We'll mark every day next week off. Days still before 9 PM are free. |
| lateCancelPreview | بعد 9 بالليل: هتدفع {amount} ج للسواق | After 9 PM: you'll pay {amount} EGP to the driver |
| freeCancelPreview | قبل 9 بالليل: من غير فلوس | Before 9 PM: free |
| lateOffBanner | إنت إجازة بكرة ({day}) · اعتذرت بعد 9 بالليل — {amount} ج للسواق. | You're off tomorrow ({day}) · Cancelled after 9 PM — {amount} EGP to the driver. |
| undoRefused | الكرسي اتاخد من قايمة الانتظار، فمش هينفع نرجّعه. ممكن تحجز كرسي فاضي لو محتاج. | Your seat went to the waitlist, so we can't undo this. You can book an empty seat if you need one. |
| noShowWarning | مجتش مرتين الشهر ده. المرة التالتة هتخرجك من المجموعة. | You missed 2 pickups this month. A third will remove you from the group. |
| removedNotice | خرجناك من المجموعة عشان مجتش 3 مرات الشهر ده. مشوارك متسجّل، ونقدر ندوّرلك على مجموعة جديدة. | You were removed from the group after 3 no-shows this month. Your commute is saved and we can find you a new group. |
| findNewGroup | دوّرلي على مجموعة جديدة | Find me a new group |
| noCoverTitle | مفيش سواق بكرة ({day}) | No driver for tomorrow ({day}) |
| noCoverBody | {driver} مش هيقدر يسوق، وملقيناش بديل. اختار اللي يناسبك: | {driver} can't drive and we found no cover. Pick what suits you: |
| noCoverDayOff | خد اليوم إجازة — من غير فلوس | Take the day off — free |
| rideWith | راكب {day} مع {driver} | Riding {day} with {driver} |
| nextRide | مشوارك الجاي · {day} | Your next ride · {day} |
| delayTitle / delayMinutes | هتتأخر قد إيه؟ / {minutes} دقايق | How late will you be? / {minutes} min |
| delaySent | بلّغنا الركاب بالميعاد الجديد: {time} | Riders were told the new time: {time} |
| cantDriveConfirm | متأكد؟ هندوّر على سواق بديل لركابك. | Sure? We'll look for a backup driver for your riders. |
| startTrip / endTrip | يلا نتحرك / وصلنا | Start trip / End trip |
| inboxTitle / inboxEmpty | الإشعارات / مفيش إشعارات لسه | Notifications / No notifications yet |
| sosTitle | محتاج مساعدة؟ | Need help? |
| sosCall | اتصل بـ 122 | Call 122 |
| sosAlert | بلّغ الناس اللي بثق فيهم | Alert my trusted contacts |
| sosAlertSent | بعتنالهم لينك المشوار | We sent them your trip link |
| sosNoContacts | ضيف حد بتثق فيه عشان نبلّغه وقت الطوارئ | Add a trusted contact so we can alert them in an emergency |
| trustedTitle / trustedAdd | ناس بثق فيهم / ضيف حد | Trusted contacts / Add contact |
| trustedMax | ممكن تضيف لحد 3 | You can add up to 3 |
| shareMessage | أنا في مشواري مع {driver} ({car}) من {from} لـ {to}، هوصل حوالي {time}. تابعني: {link} | I'm on my commute with {driver} ({car}) from {from} to {to}, arriving around {time}. Follow along: {link} |
| privacyNote | الاختيار ده هيتطبّق على المجموعات الجاية، مش مجموعتك الحالية. | This applies to future groups, not your current one. |
| needWorkEmail | وثّق إيميل الشغل الأول | Verify your work email first |
| needCompound | ضيف اسم الكمبوند الأول | Add your compound first |
| driverNeedsDocs | عشان تسوق، لازم الرخصة والعربية يكونوا موثّقين. | To drive, your license and vehicle need to be verified. |
| walletSoon | المحفظة جاية قريب | Wallet is coming soon |
| verified / notVerified | موثّق / مش موثّق | Verified / Not verified |
| demoSection | تجربة (للمطورين) | Demo (developers) |

### R14 addendum — drafted during the P1 build (founder review)

Not in the prototype dictionary; Arabic in `lib/core/l10n/app_ar.arb`, English in `app_en.arb`:
`goodEvening`, `relToday` / `relTomorrow` / `relTomorrowDay` / `relOn`, `heroToday` / `heroTomorrow`,
`noDriverYet`, `goingLeg`, `callName`, `colour*`, `tlPassengers`, `noReturnTrip`, `offLegTitle`,
`tripGoing` / `tripReturn`, `lateOffBody` (replaces the single `lateOffBanner` line), `undoTooLate`,
`cantComeTitle`, `confirmCancel`, `pickOneTrip`, `cancelAfterPickup`, `notNextWeekDone`, `keepIt`,
`headsUp`, `removedTitle`, `drivingWhen`, `notDrivingSoon`, `heroDriver`, `confirmDriveToday` /
`confirmDriveDay`, `cantDriveYes`, `keepDriving`, `cantDriveDone`, `reqsPlaceholder`, `stNotArrived`,
`noShowAvailableIn`, `tripOnWay`, `tripEndedNote`, `refusedNoShowEarly`, `refusedTripStarted`,
`inboxEmptyBody`, `inboxAria`, `sentToRiders`, `nDriverConfirmed`, `nDriverUnconfirmed`, `nDelay`,
`nDriverArrived`, `nLateCancel`, `nNoShow`, `nSeatOffered`, `noRidesSoon`, `loadingToday`,
`todayError`, `demoNow`, `demoRideDay`, `demo855`, `demo905`, `demoRealTime`, `demoReset`.
`offTitle` / `noCoverTitle` take a `{when}` ("tomorrow (Tue)", "on Sun") instead of a fixed day.

### R14 addendum — drafted during the P2 build and convergence (founder review)

Arabic in `lib/core/l10n/app_ar.arb`, English in `app_en.arb`: `nDriverNoShow` (a driver who never
checked in), `carColour`, `demoNowValue`, `noCoverEmptySeat`, `offNoCoverBody`, `noCoverNote`,
`demoBackup`, `demoNoCover`, `weekRiderLine` (also the Week header times), `weekDriveLine`,
`weekEmpty`, `verificationTitle`, `percentValue`, `trustedCount`, `contactName`, `removeContact`.
"Post your trip" on the no-cover card reuses `postReq`.

### R14 addendum — drafted during the P3 build (founder review)

Arabic in `lib/core/l10n/app_ar.arb`, English in `app_en.arb`:

| key | ar | en |
|---|---|---|
| arrivalInMin | الوصول بعد {minutes} دقيقة (plural forms as `pickupInMin`) | Arriving in {minutes} min |
| mapLiveAria | خريطة المشوار · السواق في الطريق | Route map · your driver is on the way |
| demoDriverArrives (debug only) | السواق وصل محطتي | Driver arrives at my stop |

The SOS sheet's "Add a trusted contact" button reuses `trustedAdd`; "We sent them your trip link"
is `sosAlertSent` from the table above.
