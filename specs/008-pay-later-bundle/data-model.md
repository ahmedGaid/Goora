# Data Model: 008

- **ActivityKind** gains `settlement` (+amount, balance delta +amount), `bundle` (amount 75, no
  delta), `bundleTrip` (amount 0, a paid trip covered by a bundle; `shareToDriver` set).
- **Wallet** gains `bundleTripsLeft: int`, `feeDue: CalendarDate?`, `feeOverdue: bool`, and the
  getter `owed` (= max(0, −balance)).
- **FeeBalancePolicy** (pure, twinned): `dueDate(days, today)`, `isOverdue(due, today)`,
  constants `settleAt = 150`, `monthEndMin = 30`, `graceDays = 3`.
- **TripBundle** (pure, twinned): `price = 75`, `trips = 20`, `useBundle(fee, left)`.
