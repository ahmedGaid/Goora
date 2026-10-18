# Feature Specification: Rider ID Check Before the First Trip

**Feature Branch**: `009-rider-id-first-trip` (stacked on 007 → 008, not yet merged)

**Created**: 2026-10-19

**Status**: Draft

**Input**: User description: "Rider ID verification before the first trip — profit change 5
(`GOORA_PROFIT_CHANGES.md` §5). Drivers unchanged (full ID + licence + vehicle at onboarding).
Riders: onboarding asks only for phone OTP and profile; the ID check runs when the rider first
books or joins a trip, and that trip is not confirmed until the check passes. No one rides
unverified. Copy: 'محتاجين نتأكد من بطاقتك قبل أول مشوار، عشان أمان الكل.'"

**Sources of truth**: profit brief §5 · constitution V (phone OTP + ID required for every user) ·
spec 003 trust screen · spec 005 publish checks (drivers).

## Clarifications

### Session 2026-10-19 (decided by the implementer, founder to confirm)

- Q: What counts as "first books or joins"? → A: Book a seat, post a trip request (it becomes a
  confirmed seat when a driver accepts), and "Join this group". Each is held until the ID check
  passes; nothing is booked, posted or joined before that.
- Q: Is the check instant? → A: In the fakes, yes: capture front and back, submit, verified. A real
  provider may take time; the screen already says "checking" and the action stays held until it
  passes (status `pending`).
- Q: What about riders who signed up before this change? → A: Their ID was checked at signup, so
  they stay verified. Only new riders start unverified.
- Q: Where does the rider land after passing? → A: Back where they were (the seat, the post form
  or the match result) to tap the action again; nothing is booked behind their back.

### Open (founder)

- Real ID provider (manual review vs automated) and how long a pending check may take.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A new rider is asked for their ID at the first booking (Priority: P1)

A new rider browses seats freely. When they tap Book (or Post, or Join) for the first time, the
app opens the ID check with the brief's copy. They capture the front and back of their ID and
submit; once verified they return and book.

**Independent Test**: As a new rider, tap Book on a seat: the ID screen opens and nothing is
booked; complete it; tap Book again: booked.

**Acceptance Scenarios**:

1. **Given** an unverified rider, **When** they tap Book, **Then** the ID check opens and no
   booking exists.
2. **Given** the ID screen, **When** both sides are captured and submitted, **Then** the rider is
   verified and returned to where they were.
3. **Given** a verified rider, **When** they book, **Then** no ID step appears.
4. **Given** an unverified rider, **When** they post a trip or join a group, **Then** the same ID
   step comes first.
5. **Given** the ID screen, **When** only one side is captured, **Then** Submit stays disabled.

### User Story 2 - Onboarding stays short for riders; drivers unchanged (Priority: P2)

Riders reach their first screen with phone OTP and profile only. Drivers still need ID, licence
and vehicle before publishing a trip (005).

**Acceptance Scenarios**:

1. **Given** a new rider, **When** onboarding finishes, **Then** no ID step was shown.
2. **Given** a driver, **When** they publish, **Then** the 005 checks apply unchanged.
3. **Given** the Trust screen, **When** an unverified rider opens it, **Then** the ID item reads
   "not verified" (words, not colour alone).

### Edge Cases

- A rider who owes a driver or Goora: those blocks come first (007/008); the ID step after.
- A rider switches to driver: driver checks apply (ID included).
- A pending check: actions stay held with "we're checking your ID".
- Demo reset: the ID status clears with the trust keys.

## Requirements *(mandatory)*

- **FR-001**: Riders MUST NOT be asked for ID during onboarding.
- **FR-002**: An unverified or pending rider MUST NOT get a booked seat, a posted request or a
  group membership; the action MUST open the ID check instead (or say it is pending).
- **FR-003**: The ID check MUST ask for the front and the back of the national ID and show the
  brief's copy; Submit is enabled only when both are captured.
- **FR-004**: Passing MUST mark the rider's national ID verified and return them to where they
  were, without performing the held action.
- **FR-005**: Drivers' onboarding and publish checks MUST be unchanged.
- **FR-006**: Riders onboarded before this change MUST stay verified.
- **FR-007**: All copy via ARB ar/en, Egyptian colloquial; ≥ 44 px targets; status in words.
- **FR-008**: The gate order MUST be: owes a driver → Goora fees overdue → ID not verified →
  no payment method → ok.

### Key Entities

- **Rider ID status**: notVerified · pending · verified (per person).

## Success Criteria *(mandatory)*

- **SC-001**: 0 bookings, posts or joins by an unverified rider across all tests.
- **SC-002**: A new rider completes the ID step in under 1 minute in the fakes.
- **SC-003**: Rider onboarding has one step fewer than a driver's (no ID step).

## Assumptions

- Fake capture (no camera plugin); a real camera/ID provider is a later feature.
- "Legacy rider" = anyone who signed up before this change: sign-up now writes "not verified",
  so a missing status means an older account, read as verified.
