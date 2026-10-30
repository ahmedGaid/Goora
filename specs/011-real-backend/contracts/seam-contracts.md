# Contract: shared behaviour lists per seam (test/contract/)

Each list is a Dart library `test/contract/<seam>_contract.dart` exposing
`void <seam>Contract(String label, <Seam>Harness Function() harness)`. A harness builds a fresh
implementation for one test, signed in as a given person, and seeds what the case needs **through
that implementation's own storage** (prefs for the fake, rows for the Supabase one). Runners:
`test/contract/<seam>_contract_test.dart` calls the list once with the fake harness and once with
the Supabase-over-`InMemoryGateway` harness (and, opt-in, a live harness — research D20).

Assertions are **relative** (contains / not contains / changed by) so the fakes' seeded demo data
never breaks them. Cases tagged *clockBound* depend on the demo clock and do not run live (D14).

## Onboarding — `onboarding_contract.dart` (AuthRepository + ProfileRepository)

- A1 `verifyCode` with a wrong code throws `InvalidCodeException`; `currentPhone` stays null.
- A2 first correct `verifyCode` → `existingAccount == false`; `currentPhone` is the number.
- A3 `signOut` → `currentPhone == null`; verifying the same number again → `existingAccount == true`.
- A4 `isFake` is true while the code provider is fake.
- P1 `load()` is null before any `save`.
- P2 `save` then `load` returns the same phone, names, gender, role, frequency.
- P3 a second `save` replaces the first; `clear` then `load` is null.

## Commute — `commute_contract.dart`

- C1 `homePlaces`/`workPlaces` are the active corridor's lists.
- C2 `loadProfile` null before save; `saveProfile` → `loadProfile` equal (`toJson`).
- C3 `groupsFor(origin, destination)` contains the harness's group for that route and no group of
  another route.
- C4 `join(unknown id)` throws `ArgumentError`; `join(group)` → `joinedGroupId() == group`.
- C5 `joinWaitlist` returns a position ≥ 1; asking twice returns the same position.

## Trust — `trust_contract.dart`

- T1 `profile()` carries the person's first name and gender; privacy defaults to `verifiedUsers`.
- T2 a man's `setPrivacy(womenOnly)` → `TrustRefused(privacyUnavailable)`; privacy unchanged.
- T3 a woman's `setPrivacy(womenOnly)` → `profile().privacy == womenOnly`.
- T4 contacts start empty; three adds keep order and trim names; a fourth →
  `TrustRefused(contactsFull)`.
- T5 `removeContact(id)` removes only that contact.
- T6 `sendSos(rideId: r)` returns an alert with `rideId == r` and every contact id.
- T7 a new rider reads `notVerified`; `submitRiderId()` → `verified`, and so does the next read.
- T8 a driver always reads `verified`.
- T9 a driver after `startDriverVerification()` sees licence and vehicle `notVerified`.

## Wallet — `wallet_contract.dart` (WalletRepository + SeatLedger)

- W1 `getPlan` is null for a person with no plan.
- W2 `setMethod(instapay)` → `getMethod == instapay`.
- W3 `setInstapayHandle('  abc  ')` → `'abc'`; `''` → null.
- W4 `topUp(100)` succeeds; balance rises by 100; newest activity is a `topUp` of 100.
- W5 `withdraw(40)` after it → balance falls by 40; newest activity is a `withdrawal`.
- W6 `subscribe(monthly)` with a balance under the price → `needsTopUp`, balance unchanged, no
  plan; with enough → `subscribed`, `getPlan.type == monthly`, balance falls by the price.
- W7 `settle` with nothing owed → `success`, activity unchanged.
- W8 `debitSeat` twice for one booking → one `seatBooked` row; `refundSeat(amount: 0)` → no row.

## Company — `company_contract.dart`

- K1 `register` with a fresh domain → `Registered`, status pending; `companyForDomain` finds it.
- K2 the same domain again → `DomainTaken`; a public-mail domain → `PublicDomain`; an HR email on
  none of the domains → `EmailNotOnDomain`.
- K3 `myCompanyAccount(hr)` → home with status pending; another person → null.
- K4 `offerFor(person with no work email)` → `NoWorkEmail`; on a pending company's domain →
  `PendingCompany`.
- K5 `hrConsent` defaults false; `setHrConsent(true)` → true; `false` → false.
- K6 `roster`/`log` by someone who isn't the HR contact → `NotHrContact`.
- K7 `hasEnrolled` is false for someone who never enrolled; `coverageFor` is empty.

## Marketplace — `marketplace_contract.dart`

- M1 a verified driver's `publish` → `Published(trip)`; `offer(trip.id)` returns it.
- M2 a third trip the same day → `OverLimit` (constitution II: two a day).
- M3 a rider's `post` → `Posted(request)`; `myRequests` contains it; `cancelRequest` removes it.
- M4 `request(id)` returns the posted request.
- M5 `cancelOffer` on own trip → `offer(id)` reads cancelled (or null).

## Daily commute — `daily_contract.dart`

- D1 not in a group → `myGroup()` is null.
- D2 a member → `myGroup()` contains `meId`.
- D3 *clockBound* cancel before the 9 PM cut-off → no charges; `absences` holds a `freeCancel` per
  leg.
- D4 *clockBound* cancel at/after the cut-off → one `lateCancel` charge of 20 EGP per leg;
  `chargesOwed` contains them.
- D5 `notices()` emits a list; after `markRead(id)` that notice reads as read.
- D6 `noShowsInMonth` of a month with no trips is 0.
