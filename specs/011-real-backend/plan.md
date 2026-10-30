# Implementation Plan: Real Backend Behind the Repository Seams

**Branch**: `011-real-backend` | **Date**: 2026-10-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/011-real-backend/spec.md`

## Summary

Every feature runs today on prefs-backed fakes behind seven repository seams. This lane adds a
Supabase implementation of each seam, chosen once at start-up by `Env.backendLive`
(`--dart-define=BACKEND_LIVE=true` **and** `Env.hasSupabase`; default off). Off = the providers
build exactly today's fakes, so no existing test or behaviour moves.

Approach (research.md D1–D20):

- **One thin port**, `BackendGateway` in `lib/core/backend/`: table reads/writes with simple
  filters, `rpc`, `invoke` (Edge Functions), the session's user id, and an auth bridge. The real
  adapter wraps `SupabaseClient`; tests use `InMemoryGateway` (`test/contract/support/`). Repositories
  never touch `SupabaseClient` directly, so they can be tested without a network.
- **The database decides what a client may see**: new migrations for profile/trust, wallet, company
  and the missing pieces of the three existing ones (API grants, the six new corridor areas, missing
  write rules). RLS on every table; cross-person and money writes go through `security definer`
  functions that re-check inside the transaction; HR reads only through a four-column roster view
  and functions that apply consent and k ≥ 5. No column or ledger kind can hold driver income.
- **Rules stay where they are**: the Dart/TS rule twins are not touched. SQL holds invariants
  (checks, uniqueness, ownership, the k ≥ 5 floor, the cost cap as a CHECK) and state transitions,
  never a second copy of pricing/matching/attendance maths.
- **Same behaviour proof**: one contract suite per seam in `test/contract/<seam>_contract.dart`,
  written first and passing on the fake; then the Supabase implementation passes it over
  `InMemoryGateway`. The same suites can run against the local database (`--dart-define`
  `GOORA_CONTRACT_DB_URL` + keys, opt-in) where a case does not depend on the demo clock.
- **SQL proof**: pgTAP tests in `supabase/tests/` for every RLS rule, run with `supabase test db`
  against a local stack on shifted ports (another project's stack holds the default ones).

## Technical Context

**Language/Version**: Dart ^3.12 (Flutter stable); SQL for Postgres 17 (Supabase local image
17.11); TypeScript (Deno, Node 24 tests) unchanged.

**Primary Dependencies**: new `supabase_flutter` ^2.18.3 (pulls `supabase` 2.16.x). Reason
(constitution IX): the official client for the constitution's chosen backend — auth session,
PostgREST, Edge Function calls; nothing smaller covers the three. No other new package.

**Storage**: Supabase Postgres + PostGIS (existing), RLS on every table. Device: shared_preferences
for the fakes (unchanged) and for the Supabase session (supabase_flutter's own store).

**Testing**: `flutter test --concurrency=1` (unit, contract, widget, golden); pgTAP via
`supabase test db` (local only); `node --test "supabase/functions/_shared/*.test.ts"` unchanged.

**Target Platform**: Android (min API 24) + iOS 14; local Supabase stack in Docker for development.

**Project Type**: mobile app + backend-as-a-service schema.

**Performance Goals**: no new screen; a seam call ≤ one round trip where the fake made one write
(batched RPC instead of N writes for money moves).

**Constraints**: no hosted deploy; no secrets committed; OTP + payments stay fake (012);
`companyInvoicesLive` / `hrStatementExport` stay off; no edit of existing fakes' behaviour, ARB
values, Lane F/M/L files; rule twins unchanged.

**Scale/Scope**: 7 seams (~120 interface methods), 4 new migrations, ~7 contract suites.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|---|---|---|
| I Commute-first | Real persistence makes the commute survive device loss — direct commute value. | ✅ |
| II Never a taxi | No driver-income column/kind/RPC (D9); `offered_trips` keeps the cost cap CHECK; prices stay system-computed by the twins; 2 trips/day re-checked server-side. | ✅ |
| III Arabic-first | No new screen; new copy avoided (failures map to existing refusals, D7). | ✅ |
| IV Privacy | RLS on every table; homes never leave the DB (existing); HR roster view = 4 columns; dashboard/statement via definer functions with k ≥ 5 + consent (D12). | ✅ |
| V Trust | ID/licence/vehicle statuses move to the server, owner-read, server-write (D11). | ✅ |
| VI Design system | No UI. | ✅ |
| VII Accessible | No UI. | ✅ |
| VIII Testable | Repositories behind the existing interfaces; one contract suite per seam on both implementations. | ✅ |
| IX Simplicity | One new package with a stated reason; one port, no ORM, no codegen. | ✅ |
| Secrets | Keys only via `--dart-define`; `.env.example` gains `BACKEND_LIVE=` only; local demo keys printed by `supabase status`, never committed. | ✅ |
| Payments | `FakePaymentProvider` stays; ledger only; card data never stored. | ✅ |

Post-design re-check (after data-model.md and contracts/): still ✅. One recorded tension, not a
violation: the auth bridge (D5) trusts the fake code exactly as `FakeAuthRepository` does, so it
refuses to run unless the backend URL is local. 012 replaces it.

## Project Structure

### Documentation (this feature)

```text
specs/011-real-backend/
├── plan.md            # this file
├── research.md        # Decisions D1–D20 (clarify answers included)
├── data-model.md      # tables, columns, RLS matrix
├── quickstart.md      # run against local Supabase; run the SQL and contract tests
├── contracts/
│   ├── backend-gateway.md   # the port, failure mapping, auth bridge
│   ├── server-functions.md  # RPC / view list with caller and checks
│   └── seam-contracts.md    # per-seam behaviour lists (what each contract suite asserts)
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
lib/core/config/env.dart                     # + backendLive
lib/core/backend/
├── backend_gateway.dart                     # port + Row, filters
├── backend_failure.dart                     # failure types + mapping
├── supabase_gateway.dart                    # adapter over SupabaseClient
├── backend.dart                             # init (Supabase.initialize), mode, start-up fallback
└── backend_providers.dart                   # backendGatewayProvider, backendLiveProvider
lib/features/onboarding/data/supabase_auth_repository.dart
lib/features/onboarding/data/supabase_profile_repository.dart
lib/features/commute/data/supabase_commute_repository.dart
lib/features/daily/data/supabase_daily_commute_repository.dart
lib/features/daily/data/supabase_trust_repository.dart
lib/features/wallet/data/supabase_wallet_repository.dart
lib/features/marketplace/data/supabase_marketplace_repository.dart
lib/features/company/data/supabase_company_repository.dart
lib/features/*/data/providers.dart           # flag switch (fake | supabase)
lib/main.dart                                 # await Backend.init() before runApp (one line)

supabase/migrations/2026103000000{0..4}_*.sql # fixes, profile+trust, wallet, company, marketplace RPCs
supabase/tests/*.test.sql                     # pgTAP, one file per migration
supabase/seed.sql                             # local demo corridor (no people)

test/contract/support/in_memory_gateway.dart  # the mocked client
test/contract/<seam>_contract.dart            # shared behaviour lists
test/contract/<seam>_contract_test.dart       # runs the list on fake + supabase
test/unit/backend/*_test.dart                 # flag, failure mapping, gateway adapter, money
```

**Structure Decision**: feature-first as today (Constitution VIII). The only new shared folder is
`lib/core/backend/`. Contract suites are libraries (`*_contract.dart`) with a `*_contract_test.dart`
runner, so the live runner can reuse them.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `BackendGateway` port between repositories and `SupabaseClient` | Contract tests must run in `flutter test` with no network, and the same suites against a live DB | Mocking `SupabaseClient`'s fluent builders is brittle and needs a mocking package (IX); an HTTP-level PostgREST fake is larger than the port |
