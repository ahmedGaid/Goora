# Tasks: Rider ID Check Before the First Trip (009)

- [x] T001 Trust: `RiderIdStatus {notVerified, pending, verified}`, `TrustRepository.riderIdStatus()` / `submitRiderId()`; fake store `trust.riderId`, legacy rule (R1); nationalId item reflects it for riders
- [x] T002 Gate: `needsId` after owesDriver/feeOverdue, before needsMethod; `BookNeedsId`, `PostNeedsId`; demo accept withdraws
- [x] T003 Marketplace `_Rider.idOk` from trust; all gate calls pass it
- [x] T004 ID check screen `/id-check?next=` (front/back capture, brief copy, Submit), router + routes
- [x] T005 Empty seats, Post, Match result route to the ID check on needsId / unverified
- [x] T006 ARB keys ar/en
- [x] T007 Test helper: memberPrefs seeds a verified rider ID by default
- [x] T008 Unit tests (gate order, trust fake legacy rule) + widget tests (ID screen; Book → ID → back) ar/en
- [x] T009 Brief §5/§6 note · gates · tasks ticked
- [ ] T010 Device walkthrough (needs emulator) — NOT RUN 2026-10-19


Notes (2026-10-19): R1 as built — sign-up writes `notVerified` (LocalProfileRepository.save); a missing status = signed up before 009 = verified. The Trust screen shows the ID as not verified but has no "verify now" action yet (the check opens from Book/Post/Join).
