# Tasks: Direct Driver Payment (007)

**Input**: `specs/007-direct-driver-payment/` — spec, plan, research (R0–R10), data-model,
contracts/direct_pay.md, quickstart

**Tests**: requested (profit brief §1 "Tests"; Constitution VIII) — rule tests come before code.

## Phase 1: Setup

- [ ] T001 Record legal gate as pending in `specs/007-direct-driver-payment/research.md` R0 (done in plan; verify wording before implement)

## Phase 2: Foundational — the twinned rules (blocks every story)

- [ ] T002 [P] Write vectors `test/fixtures/direct_pay_vectors.json` with groups `status`, `canMark`, `flag`, `share`, `fee` per contracts/direct_pay.md (times as integer minutes; `autoReceiveMinutes = 1440`, `reverseAutoMinutes = 10080`, `disputeWindowDays = 30`, `disputeLimit = 2`); include the demo 160/3/40 → share 40 (instapay) / 40 (cash) fee 4, cash 44→45 with fee 4, 4-seat 38 → cash 35 fee 2, 96/4/24 fee 0
- [ ] T003 [P] Write Dart vector test `test/unit/direct_pay_vectors_test.dart` loading the fixture (fails until T005)
- [ ] T004 [P] Write TS twin test `supabase/functions/_shared/direct_pay.test.ts` using `loadVectors` (fails until T006)
- [ ] T005 Implement `lib/features/wallet/domain/direct_pay.dart`: `ShareStatus {pending, received, autoReceived, notReceived, disputed}`, `SharePolicy.status/canMark/isOpenDebt/disputeFlagged`, `DirectPay.share/fee` per research R2–R4 (pure Dart, no Flutter import)
- [ ] T006 Implement `supabase/functions/_shared/direct_pay.ts` mirror of T005
- [ ] T007 Cap sweep `test/unit/direct_pay_cap_sweep_test.dart`: for trip cost 40..400 step 2, riderSeats 1..4, every contribution in `PricingService.range`, both methods: `share + fee ≤ equalShare` and `share ≥ 1` (Constitution II, R4)

**Checkpoint**: both twins green on the same vectors.

## Phase 3: US1 — direct share, Goora takes only its fee (P1) 🎯 MVP

- [ ] T008 [US1] `lib/features/wallet/domain/payment_method.dart`: `PaymentMethod {cash, instapay}` with `parse(String)` mapping legacy `wallet` → `cash`; `PricingMode {trial, perTrip, subscribed, company}`, `isFeeFree` = not `perTrip`; `PricingMode.of(plan, today, trialAvailable)` (method no longer matters, R6)
- [ ] T009 [US1] Fix all callers of the renamed enums (`flutter analyze` driven): `seat_price.dart`, `booking_gate.dart`, `fake_marketplace_repository.dart`, `market_seed.dart`, `offer_trip_screen.dart`, `one_off_section.dart`, `match_result_screen.dart`, `rider_today.dart`, `cash_after_trip.dart`, `cash_received_row.dart`, `pay_method_screen.dart`, `rider_wallet.dart`, `wallet_controller.dart`, `labels.dart`, `wallet_seed.dart`, `providers.dart`
- [ ] T010 [US1] `seat_price.dart`: `SeatPrice.of(contribution, tripCost, riderSeats, mode, method)` → `share = DirectPay.share`, `fee = DirectPay.fee(…, feeFree: mode.isFeeFree)`; `payable` → `feeDue` (what the Goora ledger takes)
- [ ] T011 [US1] `fake_wallet_repository.dart` `_riderTrips`: trial applies to every rider (not only cash), a trip debits **fee only**; `ActivityEntry` gets `shareToDriver` (display only, default 0, in JSON) and `toDriver` reads it
- [ ] T012 [US1] `debitSeat`/`refundSeat`: fee-only, no provider call, idempotent by bookingId; marketplace books with `price.fee`
- [ ] T013 [US1] Unit tests `test/unit/wallet_direct_pay_test.dart`: non-subscriber past trial pays exactly 4, subscriber 0, trial trips 0 and no method needed, balance never moves by the share (SC-001); trimmed fee case
- [ ] T014 [US1] Update existing tests broken by fee-only debits (004/005 wallet + marketplace tests); each changed expectation cites R5 in a comment

## Phase 4: US2 — driver confirms receipt (P1)

- [ ] T015 [US2] `cash_mark.dart`: add `markedAt` (WallTime?, JSON optional; legacy null = ride date 00:00)
- [ ] T016 [US2] `share.dart`: `Share` view (rideId, riderId, driverId, driverFirstName, amount, method, tripEnd, status) and `PaidClaim` (rideId, riderId, claimedAt)
- [ ] T017 [US2] Repository: `markShare` replaces `markCash` (latest mark wins while `SharePolicy.canMark`), `shareMarks(rideId)` current marks; `driverShares(driverId)` derived with dedupe by (rideId, riderId) (R9)
- [ ] T018 [US2] `cash_after_trip.dart` + `cash_received_row.dart`: list **every** boarded paying rider (not only trial), buttons "استلمت"/"ماستلمتش", status chip incl. "اتأكد تلقائي", tap the other button to correct while allowed
- [ ] T019 [US2] Widget tests ar/en `test/widget/share_after_trip_test.dart`: mark, correct, auto-receive after +24 h on the demo clock; late-cancel/no-show share uses the charge amount, no fee (FR-011)

## Phase 5: US3 — unpaid share blocks booking (P1)

- [ ] T020 [US3] Repository: `claimPaid`, `openShares(riderId)`, `disputeFlagged(riderId)` (storage key `wallet.paidClaims`)
- [ ] T021 [US3] `booking_gate.dart`: `BookingCheck.blockedByDebt(amount, driverFirstName)` first, then `needsMethod`, else `ok`; remove `topUp` (R5); callers at Book, Post, accept and group join
- [ ] T022 [US3] Rider debt banner on Today (`rider_today.dart`) and Wallet: "عليك {amount} ج.م لـ {name}" + "دفعت"; disputed state copy
- [ ] T023 [US3] Unit + widget tests: blocked on open debt with amount and name; unblocked after driver "استلمت"; several debts need all cleared; two `didNotPay` in 30 days flags; claim before the mark doesn't count

## Phase 6: US4 — wallet holds only Goora money (P2)

- [ ] T024 [US4] Rider wallet copy: "How paying works" rewritten for direct pay; top-up framed as paying Goora fees/subscription; negative balance reads as fee owed
- [ ] T025 [US4] Driver wallet: payments list from `driverShares` (received/pending/not received/disputed), `receivedThisMonth`; stop `_creditOneOffIncome` and seeded `tripIncome`/`feeReceived` for fresh installs (R8)
- [ ] T026 [US4] InstaPay handle: `instapayHandleOf`/`setInstapayHandle` ("≤ 40 chars, trimmed; empty → null"); driver edits in Wallet; rider sees it with "انسخ" only for a confirmed booking / own group driver (FR-013)
- [ ] T027 [US4] Pay-method screen: "هتدفع للسواق إزاي؟" cash / InstaPay; no wallet option
- [ ] T028 [US4] Widget tests ar/en for wallet (rider, driver) and pay-method screen; goldens regenerated on Windows for changed screens

## Phase 7: US5 — every flow uses direct pay (P2)

- [ ] T029 [US5] Price lines on match result, Today, booking sheet, confirmation: `shareToDriverLine` + `feeToGooraLine`; never "from your wallet"
- [ ] T030 [US5] One-ride-one-share test: booked seat then group membership → one share, one fee (FR-016); cancel before deadline → no share, no fee

## Phase 8: Polish

- [ ] T031 ARB keys (contracts/direct_pay.md table) in `lib/core/l10n/app_ar.arb` + `app_en.arb`, `flutter gen-l10n`, parity test green; goora-brand checklist on new copy
- [ ] T032 Update `GOORA_SPEC_KIT_BRIEF.md` §6.7 money-flow text to direct pay (canon)
- [ ] T033 Gates: `flutter analyze` 0 · `flutter test --concurrency=1` · `node --test "supabase/functions/_shared/*.test.ts"`
- [ ] T034 Quickstart device walkthrough (needs emulator; skip and record if none)

## Dependencies

Phase 2 → all. US1 (T008–T014) → US2, US3 (they reuse the renamed enums and fee-only ledger).
US2 T017 → US3 T020. US4, US5 after US1; US4 T025 after US2 T017. Polish last.

## Parallel examples

- T002, T003, T004 together (different files).
- After US1: US4 T024/T027 (copy, screen) in parallel with US2 T015–T017.

## Implementation strategy

MVP = Phase 2 + US1: rules twinned and the ledger stops moving the share. Then US2 + US3 (trust
loop), then US4/US5 (copy and entry points). Commit after each phase.
