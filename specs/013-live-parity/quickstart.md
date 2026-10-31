# Quickstart: verifying 013

1. `flutter analyze` → 0 issues.
2. `flutter test --concurrency=1` → all green (≥ 1944, existing tests unchanged).
3. `node --test "supabase/functions/_shared/*.test.ts"` → green (≥ 276).
4. Database (Docker up): README "Running against local Supabase" — `supabase db reset` (applies the
   migrations and `seed.sql`), then `supabase test db` → all green.
5. Live contract run (optional): README, `GOORA_CONTRACT_*` defines; "DB not run" otherwise.
6. App on the local backend: `flutter run --dart-define=BACKEND_LIVE=true ...` (README); sign in with
   a seeded phone; Wallet shows the trial; Marketplace shows driver first names.
