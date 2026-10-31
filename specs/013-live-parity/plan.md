# Implementation Plan: Live-Mode Parity for the Real Backend

**Branch**: `013-live-parity` | **Date**: 2026-10-31 | **Spec**: [spec.md](spec.md)

## Summary

Close every "Known gap" 011 left in live mode so the app on `backendLive` behaves like the fakes:
run the never-run database tests and fix what fails, add the demo seed, decide the wallet's fee
state in the database, expose first names through narrow functions, give the daily and company seams
the missing reads/actions, and pay two small test debts. `backendLive` stays OFF by default; the
fakes and every existing test are untouched.

## Technical Context

- **Language/stack**: Dart 3.12 / Flutter 3.44, Riverpod, Supabase (Postgres 17 + PostGIS, Deno edge
  functions), Node 24 for the TS twins (`node --test`).
- **Storage**: new migrations only (after `20261030000400`); `supabase/seed.sql`.
- **Testing**: `flutter test --concurrency=1` (contracts over `InMemoryGateway` + emulated server),
  `node --test "supabase/functions/_shared/*.test.ts"`, pgTAP (`supabase/tests/*.test.sql`).
- **Constraints**: no presentation/ARB/android/ios/.github changes; no secrets; local only; whole EGP.
- **Environment risk**: Docker unresponsive at start (D15) — DB phases have a recorded fallback.

## Constitution Check

| Principle | Status |
|---|---|
| II Drivers never profit (Law 87) | No new income column/kind; shares stay statuses; pgTAP scan re-run |
| IV Privacy by design | First-name-only functions (D6, D7); aggregates k ≥ 5 (D11); profiles stay owner-only |
| VIII Repositories behind interfaces | No interface changes except a new field where a seam needs it (test first) |
| IX Tests / no new mocking package | Existing `InMemoryGateway`; pgTAP for SQL |
| Secrets | None committed; keys only via `--dart-define` |

## Project structure (touched)

```text
specs/013-live-parity/          spec, research, plan, data-model, contracts/, quickstart, tasks
supabase/migrations/2026103100* new: fixes, wallet_state, marketplace_live, company_live
supabase/seed.sql               new
supabase/tests/                 new pgTAP files 50–80, gen_vector_tests.mjs, 60_vectors.test.sql
supabase/functions/commute-day/ + actions `ride`, `noCover`
supabase/functions/_shared/     + vector-guard test
supabase/scratch/               fallback harness (only if Docker stays down)
lib/features/*/data/            supabase_* repos, fake_trust_repository.dart (F1)
test/contract/                  extended contracts + test/contract/support/server.dart emulation
README.md                       "Running against local Supabase"
```

## Phases (one commit + push per phase)

| Phase | Content | Needs DB? |
|---|---|---|
| P0 | speckit set + analyze | no |
| P6 | F1 fix (quick, independent) | no |
| P1 | run pgTAP, fix, seed, reset clean | **yes** (real, or D15 fallback) |
| P2 | wallet: SQL + Dart + contract | SQL validated in the P1 harness |
| P3 | marketplace | same |
| P4 | daily | same |
| P5 | company | same |
| P-last | README, status skill, gates, hand-off message | pgTAP line of the gates needs a DB |

Order note: P6 goes right after P0 because it needs nothing and shrinks the trust contract diff.

## Risks and answers

1. **SQL not executable if Docker stays down** → D15 harness; honest labelling in the results log.
2. **Third copy of pricing/fee maths** → generated vectors + node guard (D3).
3. **The contract's "supabase" half runs over an emulated server** → the emulation reuses domain
   code, so it proves the Dart mapping only; the SQL itself is proven by pgTAP and the opt-in live run
   (011 D20).
4. **Existing tests must not change** → every new behaviour is a new case or a new test file; the
   fakes change only in F1 (id counter) and the existing fake tests stay green unedited.
