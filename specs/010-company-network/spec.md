# Feature Specification: Company Network (B2B company plan)

**Feature Branch**: `010-company-network` (implementation; the spec was written on
`spec/company-network`, docs only. 006 has merged; P1–P9 are built against the defaults below, T001 and the
T054 emulator walk are open. Merged into `main` 2026-10-29, `30b8181`)

**Created**: 2026-10-19

**Status**: Draft — 11 founder questions open (below). Nothing here is decided for the founder.

**Input**: User description: "Company network — profit change 7 (`GOORA_PROFIT_CHANGES.md` §7,
§10.3; brief `Docs/briefs/change-7-company-plan.md`). A company pays Goora a fixed per-employee
monthly fee on one invoice by bank transfer. Covered employees pay no Goora service fee and need no
personal subscription. Drivers (usually fellow employees) still get the cost share directly from
riders; Goora never holds that money. Optional HR statement so the company can reimburse commuting
through payroll. Rider-side company plan already exists. Missing: company sign-up, roster, invoice,
leaving rule, aggregated dashboard, HR statement + consent."

**Sources of truth**: constitution II (drivers never profit, pay nothing) and IV ("Companies MUST
NEVER see individual employee data without explicit consent") · brief §2 roadmap, §5 D, "Feature 006:
Company network" (stale number and price — see FR-030) · profit changes §7, §10.3 · specs 004
(plans), 005 (one-off seats, subscriber reclaim), 007 (driver paid directly, "ماستلمتش"), 008 (pay
later, bundle), 009 (rider ID before first trip).

## Open founder questions *(read first)*

Each question carries the implementer's **recommended default**. The spec below is written against
these defaults so it stays testable; any answer that differs changes only the requirements named in
the "Touches" column. Ask in Egyptian Arabic.

| # | Question | Options | Recommended default (why) | Touches |
|---|---|---|---|---|
| Q1 | Price per employee per month | 75 EGP (brief §5 D) · 99 EGP (profit model) · other | **99 EGP**. The revenue model is built on it; still a clear volume discount on the 149 EGP personal monthly plan. Stored as one config value, so changing it later costs nothing. | FR-011 |
| Q2 | Bill all enrolled employees or active riders only | enrolled · active (≥ 1 trip that month) · a seat count the company buys | **Enrolled**, counted as the highest number enrolled on any day of the month, no pro-rating; drivers count too. Predictable for the company's finance; billing on "active" would tell the company who rode, which is individual data (constitution IV). Brief says "per registered employee". | FR-010, FR-011 |
| Q3 | Minimum seats | none · 20 · other | **20** billed seats as a floor, even with fewer enrolled. | FR-011 |
| Q4 | Contract length | monthly · annual · other | **Annual**, invoiced monthly, 30 days' notice to end. The paper contract is signed outside the app; the app stores start and end dates only. | FR-004, FR-019 |
| Q5 | Do an employee's one-off seats (005) count as covered? | yes, every Goora fee · only group commute trips | **Yes**, every Goora fee, as for a personal subscriber. Today's code already does this (a company rider is treated as a subscriber, including the right to take a reclaimable one-off seat). | FR-008 |
| Q6 | HR statement in v1 or later | v1 · later | **In this spec as the last story (US6, P3), below the cut line**: ship US1–US5 first; US6 can be dropped without touching them. | US6, FR-024–FR-028 |
| Q7 | Driver abuse of "ماستلمتش" between colleagues (blocking a colleague, or faking marks so payroll reimburses trips that were not paid) | ignore here · exclude disputed shares from the HR statement · add a driver-side flag here | **Exclude disputed shares** from the HR statement (only "استلمت" and auto-received shares count); the company never sees disputes. A driver-side abuse flag stays in the separate dispute spec 007 deferred. | FR-026 |
| Q8 | Lawyer / accountant answers | — | **Pending.** Build against fakes; keep real invoice issuing and real HR export behind a feature flag until answered. Questions: (a) is a per-employee monthly fee to Goora fine under Law 87/2018; (b) does Personal Data Protection Law 151/2020 accept the enrollment consent and the HR-statement opt-in as written; (c) must the invoice be an ETA e-invoice, and is the price before or after 14% VAT; (d) the change-1 questions still pending. | FR-012, FR-029 |
| Q9 | Where does the company side live | a company-account area in the same app · a separate web portal · Goora staff run it by hand (email + PDF) | **In-app company-account area** for the company's HR contact, same app and login (phone OTP). A web portal is a new stack (constitution IX); a by-hand flow gives the company no dashboard. | US1, US4, US5, FR-001 |
| Q10 | Unpaid invoice: what happens to employees | keep covering · suspend coverage after a grace period · block riding | **Due 15 days after issue, 7-day grace, then coverage is suspended**: employees go back to pay per trip (fee on their balance, 008). Riding is never blocked by the company's debt. Paying restores coverage from that moment. | FR-013–FR-015 |
| Q11 | Money the employee already paid Goora before joining; trial after leaving | — | **Personal subscription**: its remaining paid days pause on joining and resume on leaving (founder rule: riders never lose what they paid). **Bundle**: untouched (fee is 0 while covered, so no bundle trip is used). **Owed balance**: stays owed and settles as usual. **After leaving**: no new trial (same as 004 wallet riders). | FR-009, FR-020 |

[NEEDS CLARIFICATION: Q1 price per employee per month — default 99 EGP]
[NEEDS CLARIFICATION: Q2 billing basis — default peak enrolled in the month, no pro-rating, drivers count]
[NEEDS CLARIFICATION: Q3 minimum seats — default 20]
[NEEDS CLARIFICATION: Q4 contract length — default annual, invoiced monthly, 30 days' notice]
[NEEDS CLARIFICATION: Q5 one-off seats covered — default yes, as a subscriber]
[NEEDS CLARIFICATION: Q6 HR statement v1 or later — default this spec, P3, below the cut line]
[NEEDS CLARIFICATION: Q7 driver abuse of "ماستلمتش" — default exclude disputed shares from the statement]
[NEEDS CLARIFICATION: Q8 lawyer/accountant answers — default pending, real invoice/export behind a flag]
[NEEDS CLARIFICATION: Q9 where the company side lives — default in-app company-account area]
[NEEDS CLARIFICATION: Q10 unpaid invoice rule — default due +15 days, 7-day grace, then suspend coverage]
[NEEDS CLARIFICATION: Q11 prior subscription/bundle/balance and trial after leaving — default pause/untouched/owed/no trial]

## Clarifications

### Session 2026-10-19 (decided by the implementer from the constitution and existing specs — founder to confirm)

- Q: What may the company see about one employee without the HR-statement opt-in? → A: Only what
  enrollment needs for billing: name, work email, enrolled since. Never trips, groups, pickup points,
  times, reliability, payments or role. The employee sees this list before enrolling and agrees to it
  (constitution IV: explicit consent).
- Q: How is a company proven to own its email domain? → A: The HR contact verifies a work email on
  that domain (same check as 001's work email). Public mail domains (gmail.com, yahoo.com,
  outlook.com, hotmail.com, icloud.com and similar) are refused. One domain belongs to one company.
- Q: Who approves a new company? → A: Goora staff, after the paper contract is signed. In the fakes
  this is a demo action, as other features do.
- Q: Who marks an invoice paid? → A: Goora staff, when the bank transfer arrives, with the bank
  reference. Demo action in the fakes. The app moves no money.
- Q: Does the company fee ever reach a driver, or change the cost share? → A: No. The fee pays only
  Goora. The cost share, its ±20% range, the cap and "drivers pay nothing" are unchanged.
- Q: Smallest group the dashboard will show a number for? → A: 5 employees. Any figure built from
  fewer than 5 employees shows "fewer than 5" instead of a number, so one person can't be singled out.
- Q: How many HR contacts may a company have? → A: One in v1. Goora staff change it (demo action).
- Q: Which leavers does the roster show? → A: Current employees plus anyone who left this calendar
  month, marked "left on <date>", so HR can check the invoice; earlier leavers drop off the roster.
  Invoices keep counts only, never names.
- Q: Is there a record of who changed what? → A: Yes. Every company-side change (approve, domain
  added/removed, employee removed, invoice issued/paid, suspension, contract end, HR contact changed)
  is logged with who did it and when. HR sees their company's log; Goora staff appear as "Goora".
  Employee self-leave shows as "left" with no reason.
- Q: Which months does the dashboard show? → A: The current month so far (labelled "so far") and every
  closed month since the contract start. No week or day view: small slices single people out.
- Q: What does "share with your HR" send? → A: A fixed text with the app link and one line on the
  company plan. No employee data, and Goora does not track who shared.

### Session 2026-10-29 (decided by the implementer, most conservative reading — founder to confirm)

- Q: A work email moves to a domain no company holds, or the email is removed — does the employee stay
  enrolled? → A: Yes. Only a move to another company's domain ends the enrollment (it counts as the
  employee's own leave, at the moment the app first sees the move); the spec says nothing else, and HR can
  still remove the person. A move to another domain of the same company changes nothing.
- Q: Does the HR statement say "Goora's fee 0" even for a trip taken while the company was suspended
  (FR-013)? → A: Open for the founder (research "P8/P9 notes", A1). Today the rows carry no fee at all and one
  header line says 0; deleting that line is the most conservative reading.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A company signs up and is approved (Priority: P1)

An HR contact opens the company-account area, enters the company name and its work email domain(s),
verifies their own work email on that domain and sends the request. Goora staff approve it once the
contract is signed. The company is now active and its employees can join.

**Why this priority**: nothing else in the feature exists without an active company.

**Independent Test**: As a signed-in user, register "Valeo" with domain `valeo.com`, verify a
`@valeo.com` email, submit: the company shows "waiting for Goora"; run the approve demo action: the
company shows active with its seats and price.

**Acceptance Scenarios**:

1. **Given** a signed-in user, **When** they register a company with a domain and verify a work email
   on it, **Then** the company is saved as pending and they are its HR contact.
2. **Given** a domain like `gmail.com`, **When** it is entered, **Then** it is refused with a reason.
3. **Given** a domain another company already holds, **When** it is entered, **Then** it is refused.
4. **Given** a pending company, **When** Goora approves it, **Then** it is active from that moment,
   with contract start/end dates, minimum seats and price per employee shown.
5. **Given** a pending company, **When** an employee tries to join, **Then** they see "your company
   isn't on Goora yet" and get no company plan.

---

### User Story 2 - An employee joins through their company (Priority: P1)

An employee with a verified work email on an active company's domain picks "Through my company". A
consent step lists exactly what the company will see (name, work email, since when) and what it will
never see. On agreeing they are enrolled: no Goora fee on any trip, no personal subscription
needed. The driver's cost share is still paid directly to the driver.

**Why this priority**: this is the value the company pays for and the part riders feel.

**Independent Test**: As a rider with a `@valeo.com` email and Valeo active, choose "Through my
company", agree, ride a trip: the fee is 0, the cost share is still due to the driver.

**Acceptance Scenarios**:

1. **Given** a verified work email on an active company's domain, **When** the rider picks "Through
   my company" and agrees, **Then** they are enrolled and their plan reads Company.
2. **Given** the consent step, **When** the rider declines, **Then** nothing is enrolled and the
   company sees nothing.
3. **Given** an enrolled rider, **When** a group trip or a one-off seat completes, **Then** Goora's
   fee is 0 and the driver's share is unchanged (Q5 default).
4. **Given** a verified work email whose domain has no active company, **When** the rider picks
   "Through my company", **Then** they see "your company isn't on Goora yet" with a way to share Goora
   with their HR, and no plan is granted.
5. **Given** an enrolled rider with an open "ماستلمتش" or an overdue Goora balance from before
   joining, **When** they try to book, **Then** the existing 007/008 blocks still apply.
6. **Given** a rider with a personal monthly plan and 10 paid days left, **When** they enroll,
   **Then** those 10 days pause and are shown as "paused, back if you leave your company" (Q11).

---

### User Story 3 - Monthly invoice, bank transfer and unpaid rule (Priority: P1)

On the 1st of each month the company gets one invoice for the month before: billed seats, price per
employee, total, due date and Goora's bank details with a payment reference. Goora staff mark it paid
when the transfer arrives. If it stays unpaid past the grace period, employees' coverage is
suspended (they ride on pay per trip) until it is paid.

**Why this priority**: it is how Goora earns from the feature; without it the plan is free forever.

**Independent Test**: With Valeo active and 12 employees enrolled in October, move the demo clock to
1 November: an invoice shows 20 seats (minimum) × 99 = 1,980 EGP, due 16 November. Move to 24
November unpaid: employees' trips carry the fee again. Mark paid: the next trip is fee-free.

**Acceptance Scenarios**:

1. **Given** a month with a peak of 12 enrolled and a minimum of 20, **When** the invoice is made,
   **Then** it bills 20 seats.
2. **Given** a month with a peak of 34 enrolled, **When** the invoice is made, **Then** it bills 34.
3. **Given** an employee who enrolled on the 3rd and left on the 20th, **When** that month is
   invoiced, **Then** they count in that month's peak if the peak included them (no pro-rating).
4. **Given** an issued invoice, **When** Goora marks it paid with a bank reference, **Then** it reads
   paid with the date and reference.
5. **Given** an invoice unpaid 7 days past its due date, **When** the next employee trip settles,
   **Then** Goora's normal fee applies and the employee sees a neutral notice that their company plan
   is paused (no blame, no mention of debt amounts).
6. **Given** a suspended company, **When** its overdue invoice is marked paid, **Then** coverage
   returns from that moment; trips settled while suspended keep their fee.
7. **Given** any state of the company's invoices, **When** an employee wants to ride, **Then** they
   are never blocked because of the company's debt.

---

### User Story 4 - Roster and leaving the company (Priority: P2)

The HR contact sees the roster: who is enrolled and since when, and can remove someone who left the
company. An employee can also leave the company plan themselves. When a contract ends, every
employee leaves. A leaver goes back to pay per trip at once.

**Why this priority**: billing is only fair if people who left stop being covered and billed.

**Independent Test**: As HR, remove one employee: their next trip carries the fee, their paused
personal plan days resume, and they are still counted in this month's invoice peak.

**Acceptance Scenarios**:

1. **Given** an active company, **When** HR opens the roster, **Then** it lists name, work email and
   enrolled-since for each employee, plus this month's leavers marked "left on <date>" — nothing
   else.
2. **Given** HR removes an employee, **When** their next trip settles, **Then** the normal fee applies;
   trips settled before stay fee-free.
3. **Given** an employee leaves by themselves, **Then** the same happens and HR sees them gone.
4. **Given** a contract end date passes, **Then** every employee leaves at that moment and the
   company reads "ended"; a final invoice covers the last month.
5. **Given** a leaver, **Then** they get no new cash trial; a paused personal plan resumes its
   remaining days; bundle trips are untouched; an inbox notice explains the change (Q11).
6. **Given** HR removes a domain, **Then** employees enrolled through that domain leave.
7. **Given** a removed employee re-joins in the same month, **Then** they count once in that month.

---

### User Story 5 - Aggregated dashboard (Priority: P2)

The HR contact sees how commuting goes at the company, in totals only: employees enrolled, active
this month, carpool rate, commute groups with employees in them, trips shared, estimated money
saved, estimated CO₂ avoided, parking spaces freed per workday, and route gaps (areas where
employees wait with no group).

**Why this priority**: it is the company's proof of value at renewal; it must never leak a person.

**Independent Test**: With 12 employees enrolled and 8 active, the dashboard shows totals; set
active to 3: every figure built on active employees shows "fewer than 5" instead of a number.

**Acceptance Scenarios**:

1. **Given** an active company, **When** HR opens the dashboard, **Then** each figure is a total for
   the chosen month, labelled in words, with the method of any estimate in one plain line.
2. **Given** any figure built from fewer than 5 employees, **Then** it shows "fewer than 5" and no
   number; a route-gap area with fewer than 5 employees waiting is not listed at all.
3. **Given** the dashboard, **Then** no name, email, pickup point, time, group name or driver appears
   anywhere on it, and it can't be filtered down to one person.
4. **Given** an employee who did not agree to the HR statement, **Then** they still count in the
   totals (totals are not individual data).

---

### User Story 6 - HR statement with the employee's consent (Priority: P3, below the cut line — Q6)

An employee can agree, per company, that their company receives a monthly statement of their
trips and the cost shares they paid, so HR can reimburse commuting through payroll. Goora moves no
money for this. The employee can withdraw consent at any time.

**Why this priority**: valuable for sales, but it is the only part that hands individual data to a
company; it can ship later without touching US1–US5.

**Independent Test**: As an enrolled employee, turn the statement on; as HR, open October's
statement: it lists that employee's trips and paid shares. Turn it off: November's statement leaves
them out; October's already-issued statement is unchanged.

**Acceptance Scenarios**:

1. **Given** an enrolled employee, **When** they open the statement setting, **Then** it is off by
   default and says exactly what the company will see.
2. **Given** consent on, **When** the month's statement is made, **Then** it lists, for that employee
   only: date, leg (going/return), and the cost share paid for each trip whose share was "استلمت" or
   auto-received; Goora fees are shown as 0.
3. **Given** a share marked "ماستلمتش" or disputed, **Then** it is not on the statement (Q7).
4. **Given** consent withdrawn, **Then** later statements leave the employee out; statements already
   issued are not changed and the employee is told so before withdrawing.
5. **Given** an employee without consent, **Then** HR sees nothing of them on the statement — not
   even their name with "not shared".
6. **Given** the employee was a driver on some trips, **Then** those trips are not on their statement
   (a driver pays no share).

### Edge Cases

- HR contact is also an employee who rides: both roles work; HR sees themself on the roster like
  anyone else and nothing more.
- HR contact leaves the company: another verified employee on the domain must be named HR contact by
  Goora staff (demo action); until then the company stays active but has no HR contact.
- Employee changes work email to another domain of the same company: stays enrolled. To another
  company's domain: leaves the first, may join the second.
- Employee is a driver only: may enroll (counts for billing and dashboard; Q2 default); fees don't
  apply to drivers anyway.
- Trip settles in the same minute as suspension/leaving: judged by settle time against the exact
  moment, as 004 R14 does for subscriptions.
- Demo clock jumps over a whole month: one invoice per month, never twice, never skipped.
- Demo reset: clears every company, enrollment, invoice and consent key.
- Company with zero enrolled for a month: still billed the minimum (Q3 default).
- Price changes mid-contract (Q1 later): applies from the next invoice; issued invoices never change.
- Rider ID not yet checked (009): enrolling doesn't skip the ID check before the first trip.
- Same-company privacy filter (002/003): uses the enrolled company when there is one, the verified
  work-email company otherwise — unchanged behaviour for non-enrolled riders.

## Requirements *(mandatory)*

### Functional Requirements

**Company account**
- **FR-001**: A signed-in user MUST be able to register a company (name, one or more email domains)
  from a company-account area in the app, after verifying their own work email on one of those
  domains; they become its one HR contact (Q9). Only Goora staff can change the HR contact.
- **FR-002**: The system MUST refuse public mail domains and any domain already held by another
  company, each with a reason in words.
- **FR-003**: A company MUST have one status at a time: pending, active, suspended, ended. Only Goora
  staff move pending → active.
- **FR-004**: An active company MUST store contract start and end dates, minimum seats and price per
  employee per month (Q1, Q3, Q4); the HR contact sees them, read-only.

**Enrollment and coverage**
- **FR-005**: A rider MUST be offered company enrollment only when their verified work email's domain
  belongs to an active company; otherwise they see that their company isn't on Goora yet, with a
  share action (a fixed text + app link, no employee data, not tracked), and no plan.
- **FR-006**: Enrollment MUST require explicit consent on a screen that lists what the company sees
  (name, work email, enrolled since) and what it never sees; declining enrolls nothing.
- **FR-007**: While enrolled and the company is active, Goora's service fee MUST be 0 on every trip
  the employee rides; the driver's cost share, the ±20% range, the cap and the 2-trips-a-day limit
  MUST be unchanged.
- **FR-008**: Covered employees MUST be treated as subscribers for one-off seats (005): fee 0 and the
  same reclaim right (Q5).
- **FR-009**: Enrolling MUST pause a personal subscription's remaining paid days; bundle trips and any
  owed balance MUST be left as they are (Q11).

**Invoice and unpaid rule**
- **FR-010**: Enrollment counts MUST be kept per day so a month's peak enrolled can be known; an
  employee counts once per month however often they leave and re-join.
- **FR-011**: On the 1st of each month the system MUST issue one invoice per active, suspended or
  just-ended company for the month before: billed seats = max(minimum seats, peak enrolled), price
  per employee, total = billed seats × price, issue date, due date = issue + 15 days, Goora's bank
  details and a unique payment reference (Q1–Q3, Q10). No pro-rating, including the first and last
  month.
- **FR-012**: Goora staff MUST be able to mark an invoice paid with a date and bank reference; the app
  moves no money and stores no bank card data. Real invoice issuing (e-invoice, VAT) stays behind a
  flag until Q8 is answered.
- **FR-013**: An invoice still unpaid after 7 full days past its due date (so from 00:00 on the 8th day) MUST
  suspend the company; while suspended
  enrolled employees MUST pay Goora's normal fee (pay later, 008) and see a neutral notice (Q10).
- **FR-014**: Marking every overdue invoice paid MUST make the company active again from that moment;
  fees on trips settled while suspended stay.
- **FR-015**: An employee MUST never be blocked from booking, joining or riding because of their
  company's invoice.

**Roster and leaving**
- **FR-016**: The HR contact MUST see a roster of enrolled employees with name, work email and
  enrolled-since only, plus this calendar month's leavers marked "left on <date>"; earlier leavers
  MUST drop off the roster.
- **FR-017**: The HR contact MUST be able to remove an employee and remove a domain; an employee MUST
  be able to leave the company plan themselves.
- **FR-018**: Leaving (any cause) MUST end coverage at that exact moment; trips settled before stay
  fee-free.
- **FR-019**: When the contract end date passes, every employee MUST leave and the company MUST read
  ended (Q4).
- **FR-020**: A leaver MUST get no new cash trial; a paused personal subscription MUST resume with its
  remaining days; an inbox notice MUST explain the change (Q11).

**Dashboard**
- **FR-021**: The HR contact MUST see, for the current month so far and each closed month since the
  contract start (no week or day view): employees enrolled, active this month (≥ 1 completed
  trip as rider or driver), carpool rate (active ÷ enrolled), commute groups with ≥ 1 employee,
  trips shared, estimated money saved, estimated CO₂ avoided, parking spaces freed per workday, and
  route-gap areas — totals only.
- **FR-022**: Any figure built from fewer than 5 employees MUST show "fewer than 5" instead of a
  number; a route-gap area with fewer than 5 waiting employees MUST NOT be listed.
- **FR-023**: The dashboard MUST NOT show or allow filtering to any individual (no names, emails,
  pickup points, times, group names or drivers). Every estimate MUST state its method in one line.

**HR statement (US6, P3 — Q6)**
- **FR-024**: An enrolled employee MUST be able to turn the HR statement on or off for their company;
  it is off by default.
- **FR-025**: The monthly statement MUST include only employees whose consent was on at the end of
  that month,
  and for each: date, leg and cost share paid per trip they rode as a rider. Goora fees show as 0.
- **FR-026**: Shares marked "ماستلمتش", disputed, or still pending MUST NOT appear (Q7).
- **FR-027**: Withdrawing consent MUST leave the employee out of every later statement; statements
  already issued MUST NOT change, and the employee is told so before confirming.
- **FR-028**: An employee without consent MUST be absent from the statement entirely.

**Cross-cutting**
- **FR-029**: Fee-free decisions (coverage at a moment, billed seats, suspension) are money rules and
  MUST be twin-implemented (app + server) and pass the same vectors, like 007/008.
- **FR-030**: The brief (§2 roadmap row, §5 D, "Feature 006: Company network") and the constitution's
  roadmap line MUST be amended to the final number (010) and the founder's price, through the
  founder's approval and a Sync Impact Report, after 006 merges.
- **FR-031**: Every company-side change (approve, domain added/removed, employee removed, invoice
  issued/paid, suspension, contract end, HR contact changed) MUST be logged with actor and moment; the
  HR contact sees their company's log, with Goora staff shown as "Goora" and self-leave shown as
  "left" with no reason.
- **FR-032**: All copy MUST be in ARB ar/en, Egyptian colloquial, with the Goora lexicon (مشوار,
  السواق, كرسي); ≥ 44 px targets; statuses in words, never colour alone; RTL/LTR correct.

### Key Entities

- **Company**: name, domains, status (pending · active · suspended · ended), contract start/end,
  minimum seats, price per employee, HR contact.
- **Company domain**: one email domain, held by exactly one company.
- **Enrollment**: one employee in one company — work email, enrolled at, left at (and why: self,
  removed by HR, domain removed, contract ended), consent given at.
- **Invoice**: company, month, peak enrolled, billed seats, price, total, issue date, due date,
  payment reference, status (issued · paid · overdue), paid date, bank reference.
- **HR-statement consent**: employee, company, on/off with the moments it changed.
- **Company dashboard month**: totals only, each with a "fewer than 5" state.
- **Paused subscription days**: the remaining paid days of a personal plan held while enrolled.
- **Company log entry**: company, what changed, actor (HR contact · employee · Goora), moment.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An HR contact can register a company in under 3 minutes in the fakes.
- **SC-002**: An employee can go from "Through my company" to enrolled in under 1 minute, with the
  consent step read in full on one screen.
- **SC-003**: 0 Goora fees charged to a covered employee, and 0 changes to any driver's cost share,
  across all tests and vectors.
- **SC-004**: Every invoice in the test months equals max(minimum, peak enrolled) × price exactly,
  one per company per month, none skipped or doubled across demo-clock jumps.
- **SC-005**: 0 individual data items (name, email, trip, pickup, time) reach the dashboard in any
  test, and every figure from fewer than 5 employees is suppressed.
- **SC-006**: 0 employees blocked from riding by their company's unpaid invoice.
- **SC-007**: A leaver's next trip carries the normal fee in 100% of leave paths (self, HR, domain,
  contract end, work email moved to another company's domain, suspension).
- **SC-008** (US6): 0 statement lines for an employee without consent, and 0 disputed shares on any
  statement.

## Assumptions

- Fakes first (constitution): no real email sending, no real bank feed, no real e-invoice; Goora
  staff actions are demo actions in Settings, as in 004–009.
- The paper contract, price negotiation and VAT handling happen outside the app (Q4, Q8).
- "Month" = calendar month in Cairo time; invoices are issued at 00:00 on the 1st.
- The estimates' constants (fuel cost per km, CO₂ per km, one car = one parking space) are set and
  sourced in `research.md`, not here; they are labelled "estimate" in the app.
- The existing "Through my company" sheet, `PlanType.company`, the company payment method and the
  fee-free rule in `direct_pay` are kept and narrowed (coverage now depends on an active company and
  an enrollment), not rebuilt.
- Only riders' Goora fees are affected; drivers pay nothing, before and after.
