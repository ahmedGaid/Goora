# Phase 0 Research: Wallet and Subscription

All three spec-level clarifications were already resolved in `spec.md`'s Clarifications section
(trips-covered formula, company verification timing, mid-cycle plan change). What's left here is
implementation-level: how to build what the spec already decided.

## R1 — "one calendar month" trial end date

- **Decision**: add `CalendarDate.addMonths(int months)` that keeps the day-of-month when the
  target month has at least that many days, and clamps to the target month's last day otherwise
  (e.g. 31 Jan + 1 month → 28/29 Feb, not an overflow into March).
- **Rationale**: `DateTime.utc(y, m + 1, d)` in Dart silently rolls an out-of-range day into the
  next month (31 Jan → 3 Mar), which would make a trial that starts on the 31st end on the wrong
  date in short months. Clamping is the common "same date next month, or month-end" rule used by
  subscription billing (Stripe, App Store) and matches founder intent ("free month" means a
  month, not sometimes 32 days).
- **Alternatives considered**: let it overflow (rejected — wrong date, and only the last 3 days of
  a 31-day month would ever hit it, making it a rare, confusing bug); always use 30 days flat
  (rejected — "free until {date}" would show a date that visibly isn't "a month" to a user
  checking a calendar).

## R2 — where the plan-required redirect lives

- **Decision**: a redirect check added to the shell's `today`/`week` `GoRoute`s (next to the
  existing `routeForSession` pattern from onboarding), not a new top-level guard. If the session
  is a rider with no `Plan` (or a due/expired one) and no Company verification, redirect to
  `Routes.plan`.
- **Rationale**: `go_router`'s per-route `redirect` is the existing idiom in this codebase (see
  `Routes.otp`'s redirect in `router.dart`); no new dependency or architecture needed. Wallet and
  Trust tabs stay reachable even with a due plan (FR-014 says "prompted... before their next trip
  is confirmed", not "locked out of the app"), so only Today/Week redirect; Wallet shows the due
  state inline instead.
- **Alternatives considered**: a global `GoRouter.redirect` callback (rejected — would need to
  special-case every other route, including settings/gallery, for no benefit); blocking in the
  shell's `build()` instead of routing (rejected — `today`/`week` are independent branches of one
  `StatefulShellRoute`, so a route-level redirect is the only place that catches direct deep
  links too).

## R3 — reusing 003's `Charge` records for the rider's activity list

- **Decision**: `WalletRepository` reads existing `Charge` records (via the daily feature's
  `DailyCommuteRepository`) to build late-cancel/no-show activity rows, and reads a `Ride`'s
  attendance outcome to add the zero-amount free-cancellation rows; it does not duplicate that
  data into its own store.
- **Rationale**: FR-013 makes the wallet's own ledger the source of truth for *balances*, but
  003 already owns the source of truth for *why* a charge happened (`AttendanceRules`,
  `Charge`). Duplicating those records into the wallet feature would create two copies that can
  drift; reading across features (wallet → daily) keeps one writer per fact, the same seam 003
  used when it read `PrivacyPreference` from 002 instead of copying it.
- **Alternatives considered**: have 003 push a `WalletActivity` row whenever it creates a
  `Charge` (rejected — adds a cross-feature write dependency in the wrong direction; 003 already
  shipped and its tests shouldn't need to know wallet exists); copy+transform at seed time only
  (rejected — would go stale the moment a live cancellation happens after the wallet is seeded).

## R4 — top-up/withdrawal failure simulation

- **Decision**: `FakePaymentProvider` takes an optional `shouldFail` hook (defaults to "never"),
  settable from the debug Demo section (same pattern as 003's demo-clock override in Settings),
  so SC-005's failure path is reachable without hand-editing code.
- **Rationale**: 003 already has precedent (research R11) for a debug-only way to force
  demo-relevant edge cases; a widget test can also inject a provider that always fails without
  touching the debug UI.
- **Alternatives considered**: random failure chance (rejected — flaky, not testable
  deterministically); no way to trigger a failure at all outside unit tests (rejected — SC-005's
  "verified by a unit test for each path" still needs the widget-level inline error reachable for
  manual device walkthroughs, same as every other feature's quickstart).
