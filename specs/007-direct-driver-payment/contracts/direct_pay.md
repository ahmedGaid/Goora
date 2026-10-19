# Contract: Direct-pay rules and seams (007)

## Twinned pure rules

Dart: `lib/features/wallet/domain/direct_pay.dart` · TS: `supabase/functions/_shared/direct_pay.ts`.
Both run `test/fixtures/direct_pay_vectors.json`.

```
SharePolicy.status(markOutcome?, markedAtMin?, claimAtMin?, tripEndMin, nowMin) -> ShareStatus
SharePolicy.canMark(currentStatus, tripEndMin, nowMin, reversedOnce) -> bool
SharePolicy.isOpenDebt(status) -> bool
SharePolicy.disputeFlagged(didNotPayDays: int[], todayDay: int) -> bool   // days = epoch days
DirectPay.share(contribution, method, tripCost, riderSeats) -> int
DirectPay.fee(contribution, share, tripCost, riderSeats, feeFree) -> int
```

Times in the twin are integer minutes since epoch (demo clock), so both sides compare the same
numbers; Dart converts from `WallTime`.

Constants: `autoReceiveMinutes = 1440`, `reverseAutoMinutes = 10080`, `disputeWindowDays = 30`,
`disputeLimit = 2`.

Vector shape:

```json
{ "status": [{ "mark": "didNotPay", "markedAt": 100, "claimAt": 200, "tripEnd": 0, "now": 300, "expect": "disputed" }],
  "canMark": [...], "flag": [...], "share": [...], "fee": [...] }
```

## Repository seams (app-internal)

`WalletRepository` (changed):

```
Future<void> markShare(CashMark mark)                  // replaces markCash; honours canMark
Future<List<CashMark>> shareMarks(String rideId)       // replaces cashMarks; current marks only
Future<void> claimPaid(String rideId, String riderId)  // rider "دفعت"
Future<List<Share>> openShares(String riderId)         // open debts, for banner + guard
Future<List<Share>> driverShares(String driverId)      // payments list
Future<bool> disputeFlagged(String riderId)
Future<String?> instapayHandleOf(String driverId)
Future<void> setInstapayHandle(String driverId, String? handle)
```

`SeatLedger.debitSeat(total → fee)`: debits the fee only, no provider call; idempotent by bookingId.
`refundSeat` refunds the fee only.

`BookingGate.check` (changed): `blockedByDebt(amount, driverFirstName)` first, then `needsMethod`,
else `ok`. `topUp` removed.

## UI contract (copy keys, ar first — drafted, founder review)

| Key | ar | en |
|---|---|---|
| shareToDriverLine | {amount} ج للسواق، كاش أو InstaPay | {amount} EGP to the driver, cash or InstaPay |
| feeToGooraLine | + {fee} ج رسوم خدمة لـ Goora | + {fee} EGP Goora service fee |
| shareReceived | استلمت | Received |
| shareNotReceived | ماستلمتش | Didn't get it |
| youOweDriver | عليك {amount} ج.م لـ {name} | You owe {name} {amount} EGP |
| iPaid | دفعت | I paid |
| debtBlocksBooking | ادفع لـ {name} الأول، وبعدها تقدر تحجز | Pay {name} first, then you can book |
| shareAutoReceived | اتأكد تلقائي | Confirmed automatically |
| shareDisputed | {name} بيقول إنه دفع | {name} says they paid |
| payDriverBy | هتدفع للسواق إزاي؟ | How will you pay the driver? |
| instapayHandleLabel | حساب InstaPay بتاعك | Your InstaPay handle |
| copyHandle | انسخ | Copy |
| cashOnly | كاش بس | Cash only |

## As built (2026-10-19)

- Added `Future<Share?> driverShareOn(String rideId, String riderId)` (driver Today row).
- Providers: `driverShareProvider(rideId, riderId)`, `myOpenSharesProvider`,
  `riderPayMethodProvider`, `driverInstapayProvider(driverId)`.
- Guards on open debt: Book, Post, demo accept (`BookOwesDriver` / `PostOwesDriver` /
  withdrawn request) and "Join this group" on match result (snackbar with the debt).
- Copy keys as built also include `sharePending`, `paymentsTitle`, `paymentsEmpty`, `feeOwed`,
  `feeOwedBody`, `instapayHandleHint`, `instapaySave`, `copiedHandle`, `priceInstapay`,
  `payInstapaySub`; existing 004 keys were re-worded for direct pay (see the ARB diff).
