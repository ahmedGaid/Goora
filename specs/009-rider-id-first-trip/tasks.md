# Tasks: Rider ID Check Before the First Trip (009)

- [ ] T001 Trust: `RiderIdStatus {notVerified, pending, verified}`, `TrustRepository.riderIdStatus()` / `submitRiderId()`; fake store `trust.riderId`, legacy rule (R1); nationalId item reflects it for riders
- [ ] T002 Gate: `needsId` after owesDriver/feeOverdue, before needsMethod; `BookNeedsId`, `PostNeedsId`; demo accept withdraws
- [ ] T003 Marketplace `_Rider.idOk` from trust; all gate calls pass it
- [ ] T004 ID check screen `/id-check?next=` (front/back capture, brief copy, Submit), router + routes
- [ ] T005 Empty seats, Post, Match result route to the ID check on needsId / unverified
- [ ] T006 ARB keys ar/en
- [ ] T007 Test helper: memberPrefs seeds a verified rider ID by default
- [ ] T008 Unit tests (gate order, trust fake legacy rule) + widget tests (ID screen; Book → ID → back) ar/en
- [ ] T009 Brief §5/§6 note · gates · tasks ticked
- [ ] T010 Device walkthrough (needs emulator)
