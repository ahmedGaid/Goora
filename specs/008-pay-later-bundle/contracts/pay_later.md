# Contract: 008

Twins: `lib/features/wallet/domain/fee_balance.dart` ↔ `supabase/functions/_shared/fee_balance.ts`,
vectors `test/fixtures/fee_balance_vectors.json` — groups `due` ({days: [{date, balance}], today,
expect}), `overdue` ({due, today, expect}), `bundle` ({fee, left, expect}).

Repository additions (WalletRepository):

```
Future<PaymentResult> settle(String riderId, {required String method})   // owed amount, one tx
Future<PaymentResult> buyBundle(String riderId, {required String method}) // 75 → +20 trips
```

Gate: `BookingCheck.feeOverdue(amount)`; results `BookFeeOverdue(amount)`, `PostFeeOverdue(amount)`.

Copy keys (drafted, founder review): feeDueLine, feeOverdueBody, payNow, settleTitle,
settleConfirm, settleFailTitle, methodFawry, fawryCode, fawryPaid, bundleTitle, bundleSub,
bundleLeft, bundleBuy, actSettlement, actBundle, actBundleTrip (texts in the ARB files).
