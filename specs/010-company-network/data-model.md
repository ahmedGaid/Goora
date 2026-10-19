# Data Model: Company Network (010)

Fakes store JSON in SharedPreferences under `company.*` (cleared by Settings → Reset, like
`market.*`). Times are `WallTime` (Cairo); money is whole EGP. The server shape is in research R9.

## Company
| Field | Type | Rule |
|---|---|---|
| id | String | `co-<n>` |
| name | String | 2–60 chars |
| domains | List<String> | ≥ 1, lower-case, no public mail domain, each unique across companies |
| status | `pending · active · suspended · ended` | stored: pending/active/ended; `suspended` is derived from invoices (R3) |
| hrContactId | String? | one person; null after the HR contact leaves until staff name another |
| contractStart, contractEnd | CalendarDate? | set on approval (Q4: start + 1 year) |
| minimumSeats | int | Q3 default 20 |
| pricePerSeat | int | Q1 default 99; changes apply from the next invoice |
| approvedAt, endedAt | WallTime? | |

Transitions: pending →(staff approve) active →(invoice overdue, derived) suspended →(paid) active;
active/suspended →(contract end passes or staff end) ended. Ended is final.

Key: `company.companies` (list) · `company.domain.<domain>` → companyId.

## Enrollment
| Field | Type | Rule |
|---|---|---|
| personId | String | |
| companyId | String | |
| workEmail | String | domain ∈ company.domains |
| enrolledAt | WallTime | consent moment |
| leftAt | WallTime? | null while enrolled |
| leftWhy | `self · removedByHr · domainRemoved · contractEnded`? | |

A person has at most one open enrollment. Re-joining adds a new row. Key:
`company.enrollments.<companyId>` (list).

## Coverage windows (derived, never stored)
`List<(fromMinute, toMinute?)>` = enrollment windows ∩ company active windows (active minus
suspended, ended closes). Attached to a company `Plan` on read (research R2).

## Paused plan
`company.paused.<personId>` = `{plan: Plan JSON, daysLeft: int}`; written on enroll if a personal
plan was active, removed on restore.

## Invoice
| Field | Type | Rule |
|---|---|---|
| id | String | `inv-<companyId>-<yyyy-mm>` |
| companyId, month | String, `yyyy-mm` | one per company per month |
| peakEnrolled | int | R3 |
| billedSeats | int | max(minimum, peak) |
| pricePerSeat, total | int | total = billedSeats × price |
| issuedOn, dueOn | CalendarDate | due = issued + 15 |
| reference | String | `GR-<companyShortId>-<yyyymm>` |
| paidOn, bankRef | CalendarDate?, String? | set by staff |
| status | `issued · paid · overdue` | overdue derived: unpaid after dueOn |

Key: `company.invoice.<companyId>.<yyyy-mm>`.

## Company log entry
`{companyId, at, actor: hr · employee · goora, kind, detail}` — kinds: approved, domainAdded,
domainRemoved, employeeRemoved, employeeLeft, invoiceIssued, invoicePaid, suspended, resumed,
contractEnded, hrContactChanged. `detail` holds a roster name only for employeeRemoved/employeeLeft.
Key: `company.log.<companyId>` (list, newest first).

## HR-statement consent (US6)
`company.hrConsent.<companyId>.<personId>` = list of `{on: bool, at: WallTime}`; a month's statement
includes the person if consent was on at the moment the statement is made for that month.

## HR-facing read models (the only shapes HR gets — research R6)
- `RosterRow {name, workEmail, enrolledAt, leftAt?}`
- `DashboardMonth {month, soFar: bool, enrolled, active, carpoolRatePct, groups, tripsShared,
  moneySaved, co2Kg, parkingPerDay, routeGaps: List<(Area, int)>}` — every number nullable =
  "fewer than 5".
- `StatementLine {name, date, leg, sharePaid}` (US6; consenting employees only; rider trips only;
  shares received/auto-received only).

## Per-person activity facts (input to the aggregator, never shown to HR)
`EmployeeMonthFacts {personId, riderTrips, riderGoingTrips, driverTrips, savedEgp, km, homeArea,
hasProfile, hasGroup, groupIds}` — built by the repository from 003/005/007 data (seeded for seed
employees).
