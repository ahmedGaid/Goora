# Contracts: WalletRepository

An app-internal interface (not a network API — this feature has no server component). Documented
here because it's the seam every screen and test depends on, same purpose 003's
`contracts/repositories.md` served.

```dart
abstract interface class WalletRepository {
  Future<Plan?> getPlan(String personId);
  Future<Plan> choosePlan(String personId, PlanType type, {required CalendarDate today});
  Future<Plan> changePlan(String personId, PlanType newType); // takes effect next billing date
  Future<Wallet> getWallet(String ownerId);
  Future<PaymentResult> topUp(String ownerId, {required String method, required int amount});
  Future<PaymentResult> withdraw(String ownerId, {required int amount});
}
```

## Who calls what

| Caller | Method | Notes |
|---|---|---|
| `PlanScreen` / `PlanController` | `getPlan`, `choosePlan` | `choosePlan(company)` only after the work-email verify sheet confirms |
| `ChangePlanSheet` | `changePlan` | footer link from the Wallet plan card |
| `RiderWallet` / `WalletController` | `getPlan`, `getWallet` | activity rows beyond this feature's own kinds come from `DailyCommuteRepository`/`TrustRepository` reads (research R3), not from this interface |
| `TopUpSheet` | `topUp` | failure leaves balance/activity untouched (FR-006) |
| `DriverWallet` | `getWallet` | |
| `WithdrawSheet` | `withdraw` | failure leaves balance/activity untouched (FR-010) |
| Router redirect guard | `getPlan` | decides whether a rider is sent to `Routes.plan` instead of `today`/`week` |

## Error handling

`topUp`/`withdraw` return `PaymentResult.failure` rather than throwing — a failed payment is an
expected, designed outcome (inline retry, FR-006/FR-010), not an exceptional one. Any other
method failing (e.g. storage read error) throws, same as every other fake repository in this
codebase.
