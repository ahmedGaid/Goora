# Contract: Edge Functions, schedule job and shared vectors (deployed later)

## `POST /functions/v1/commute-day`

Auth: Supabase JWT (the caller). Body `{ "action": <name>, ...params }`. The function converts
`now()` to Africa/Cairo wall time (research R2), loads rows under the caller's RLS context where
possible (service role only for waitlist release and notices), runs `_shared/*.ts`, writes rows.

| action | params | caller must be | result |
|---|---|---|---|
| `cancel` | date, legs[] | passenger of those rides | `{ charges: [{rideId, amount, reason}] }` |
| `undo` | date | same person | `{ ok }` or `{ refused: "seatTaken" \| "afterCutoff" }` |
| `notNextWeek` | — | group member | `{ charges: [...] }` |
| `confirm` / `unconfirm` | rideId | ride driver | `{ ok }` + notices |
| `delay` | rideId, minutes (5/10/15) | ride driver | `{ newTimes }` + notices |
| `cantDrive` | date, legs[] | planned driver | `{ cover: {memberId, step} \| null }` + notices |
| `arrive` | rideId, stopId | ride driver | `{ noShowAvailableAt }` + notices |
| `mark` | rideId, personId, outcome | ride driver | `{ ok }` or `{ refused: "tooEarly", secondsLeft }` |
| `start` / `end` | rideId | ride driver | `{ ok }` |
| `sos` | rideId? | the person | `{ alerted: n }` |

Responses never include home points, phone numbers of non-drivers, or names of riders who have not
boarded (to the driver).

## `evening-cutoff` (pg_cron, daily 21:00 Africa/Cairo)

1. For tomorrow's rides: seats freed by free cancels → offered to the corridor waitlist.
2. For tomorrow's legs whose planned driver is absent and uncovered: re-run `backup.ts`;
   still none → `noCover` notices to every passenger (FR-020).
3. Idempotent per (date, step): re-running the same evening changes nothing.

## Shared vectors

`test/fixtures/{attendance,reliability,rotation,backup}_vectors.json` — hand-computed cases.
Dart: `test/unit/daily_vectors_test.dart`. Node: `supabase/functions/_shared/*.test.ts`.
Both must pass; changing one implementation without the other fails the tests.

Minimum cases: 20:59 free / 21:00 late (20 EGP), both legs late = 40; cut-off for a Sunday ride =
Saturday 21:00; no-show at 4:59 refused / 5:00 allowed; standing at 1/2/3; 12.5 of 13 → 96 %;
0 booked → 100 %; rotation of 2 and 3 drivers over 4 weeks (max − min ≤ 1); backup picks same group
before nearby group, nearby before company, company before community; a women-only passenger
rejects a male cover; no candidate → none.
