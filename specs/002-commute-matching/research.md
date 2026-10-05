# Research: Commute Profile and Smart Matching

## R1 Scoring (founder: linear)

`points = weight × clamp(1 − value / limit, 0, 1)`

| Factor | Weight | value / limit |
|---|---|---|
| Destination | 25 | metres from work to group destination / 1500 |
| Departure | 20 | minutes difference / 20 |
| Pickup | 15 | metres from home to nearest group pickup point / 1000 |
| Return | 10 | minutes difference / 20 |
| Shared days | 10 | (shared days ÷ my days) — full when all my days are covered |
| Company / community | 10 | 10 if any member shares my company or compound, else 0 |
| Rating & reliability | 10 | 10 × mean(avg rating ÷ 5, avg reliability ÷ 100) |

Total = sum, rounded half-up to an integer. Factor points are kept unrounded until the total.

## R2 Hard constraints (§6.3; limits in one `MatchingLimits` object, defaults below)

pickup ≤ 1000 m · detour ≤ 10 min · departure ≤ 20 min · destination ≤ 1500 m · ≥ 1 shared day ·
capacity (rider: free seat on the leg; driver: group has riders on the leg) · privacy:
women-only groups/seekers only with women; same-company only with same company; same-compound only
with same compound.

## R3 Legs (§6.3 "going and return independently")

- Needed legs: rider → both; driver → per "Which trips do you drive?".
- Going leg passes with departure ≤ 20 min; return leg passes with return ≤ 20 min, each with the
  other constraints. Main group = best group passing every needed leg. If none passes all legs,
  each leg takes its best passing group (main = going group). No leg passes → no match.

## R4 Pricing (§6.2 + founder decisions)

- `tripCost`: `ratesEnabled ? km × egpPerKm + tolls : 160` (demo corridor cost).
- `suggested = roundToStep(cost / (riders + 1), 2)`; 160 / 4 = 40.
- `min = ceilToStep(0.8 × s)`, `max = min(floorToStep(1.2 × s), floorToStep(cost / riders))`.
  For 40: 32–48; cap 160/3 = 53 → no effect.
- Recovery per day = seats × price × (both ? 2 : 1).
- Snap: a chosen price outside a new range moves to the nearest bound.

## R5 Shared test vectors

`test/fixtures/matching_vectors.json` holds seekers, groups and expected scores/exclusions computed
by hand from R1–R3. `test/unit/matching_vectors_test.dart` and
`supabase/functions/_shared/matching.test.ts` both load it, so the two implementations cannot drift.

## R6 TypeScript without Deno installed

Node 24 runs `.ts` with built-in type stripping (`node --test`). The shared module uses only
erasable TypeScript (no enums/namespaces) and explicit `.ts` import extensions, which Deno also
accepts. `index.ts` (Deno.serve + supabase-js) is not executed locally; it is a thin adapter.

## R7 Time input

A `GooraTimeStepper` (− / time / +, 5-minute steps, long-press repeats) instead of the Material
time picker: no new package, Western digits guaranteed, fully labelled. 5-minute steps match the
brief's "5-minute departure difference".

## R8 Map without a key

`GooraRouteMap`: `mapLand` card with a drawn line from a green pickup dot to a `mapDestination` dot
and the two area names; semantic label `mapAria`. Swapped for `google_maps_flutter` once the key
exists.

## R9 Seed data

Launch corridor: homes Sheikh Zayed / 6th of October, work Smart Village. Seeded groups use the
prototype's people (Ahmed, Mohamed, Sara, Youssef) and times (7:20–7:30 AM, return 5:00–5:05 PM),
price 40, so the default rider profile (Sheikh Zayed → Smart Village, 7:30 / 5:00, Sun–Thu) gets a
high match plus 3 alternatives, and one seeded "night shift" profile path yields no match.

## R10 Drafted copy (founder review)

| key | ar | en |
|---|---|---|
| feeLine | {price} ج للسواق · من غير رسوم على المشوار | {price} EGP to the driver · no per-trip fees |
| noMatch | إنت رقم {position} على قايمة {from} ← {to} — هنبلّغك أول ما نلاقيلك مجموعة | You're #{position} on the {from} → {to} list — we'll notify you as soon as we have a match |
| reasonCompany / reasonCompound | نفس الشركة / نفس الكمبوند | Same company / Same compound |
| reasonReturn | ميعاد رجوع قريب | Similar return time |
| reasonDays | {count} أيام شغل مشتركة | {count} shared working days |
| reasonRating | الأعضاء متقيّمين {rating} ★ | Members rated {rating} ★ |
| returnLeg | الرجوع مع مجموعة {time} | Return with the {time} group |
| verifiedRider / verifiedRiderWoman | راكب موثّق / راكبة موثّقة | Verified rider / Verified rider (woman) |
| pickHome / pickWork | البيت فين؟ / الشغل فين؟ | Where's home? / Where's work? |
| sameAreaHint | اختار مكان شغل أبعد من 1.5 كم عن البيت. | Choose a work place more than 1.5 km from home. |
| returnHint | ميعاد الرجوع لازم يكون بعد الذهاب. | Return must be after departure. |
| earlier / later | أبدري 5 دقايق / أتأخر 5 دقايق | 5 minutes earlier / 5 minutes later |
| areaOctober | 6 أكتوبر | 6th of October |
| timeAm / timePm | {time} ص / {time} م | {time} AM / {time} PM |
| planTitle placeholder, today placeholder | reuse `planTitle`, `tabToday` | — |
