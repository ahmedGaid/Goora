# Contracts: WalletRepository

App-internal interface (no network API in this feature). v2 changes marked **(v2)**. v2.1 does
not change this interface — the fee rule moves inside `PricingService` ([pricing.md](pricing.md)),
and the repository passes the group's price basis to it.

```dart
abstract interface class WalletRepository {
  Future<Plan?> getPlan(String personId);
  Future<Plan> changePlan(String personId, PlanType newType);               // next billing date
  Future<SubscribeResult> subscribe(String personId, PlanType type,         // (v2) replaces
      {required CalendarDate today});                                      //      choosePlan
  Future<PaymentMethod?> getMethod(String personId);                        // (v2)
  Future<void> setMethod(String personId, PaymentMethod method);            // (v2)
  Future<PaymentMethod?> methodOf(String riderId);                          // (v2) others, seeded
  Future<List<CashMark>> cashMarks(String rideId);                          // (v2)
  Future<void> markCash(CashMark mark);                                     // (v2) first wins
  Future<Wallet> getWallet(String ownerId);                                 // (v2) derived
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount});
  Future<PaymentResult> withdraw(String ownerId, {required int amount});
}

enum SubscribeResult { subscribed, needsTopUp }                             // (v2)
```

## Who calls what

| Caller | Method | Notes |
|---|---|---|
| Router guard | `getMethod`, `getPlan` | arrangement = method, or active/company plan (R9) |
| `PayMethodScreen` | `setMethod` | then `Routes.today` |
| `PlanScreen` (subscription) | `subscribe`, `getWallet` | company only after the work-email sheet |
| `ChangePlanSheet` | `changePlan` | unchanged |
| Price lines (match result, Today) | `getMethod`, `getPlan`, `getWallet` | via `riderPricingProvider` |
| `RiderWallet` / `DriverWallet` | `getWallet`, `getPlan` | |
| `PickupCheckIn` (driver) | `methodOf`, `cashMarks`, `markCash` | after the ride has ended |
| Top-up / withdraw sheets | `topUp`, `withdraw` | unchanged; withdraw never touches `cashReceived` |

## Error handling

Unchanged from v1: payment results are values, storage failures throw. `subscribe` returns
`needsTopUp` (nothing charged) rather than throwing. `markCash` on an already-marked
(ride, rider) is a no-op.
