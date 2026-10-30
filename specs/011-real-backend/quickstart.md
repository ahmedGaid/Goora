# Quickstart: 011 real backend (local only)

Prerequisites: Flutter stable, Docker running, Supabase CLI ≥ 2.110 (`supabase --version`).

## 1. Nothing changes without the flag

```bash
flutter analyze
flutter test --concurrency=1
node --test "supabase/functions/_shared/*.test.ts"
flutter run            # demo data, code 123456, as before
```

## 2. Start the local backend

```bash
supabase start -x studio,imgproxy,inbucket,mailpit,vector,logflare,storage-api,realtime,supavisor,postgres-meta
supabase status        # prints API URL + anon key (local demo keys, never commit them)
supabase db reset      # re-applies every migration + supabase/seed.sql
```

Default ports: API 54321, DB 54322. If another project's stack holds them, copy `supabase/` to a
scratch folder, shift the ports in its `config.toml`, and run the CLI with `--workdir` there
(research D19).

## 3. Database tests (every RLS rule)

```bash
supabase test db       # pgTAP: supabase/tests/*.test.sql
```

Expected: every file `ok`. Not running Docker → write "DB not run" in research.md Results log.

## 4. Run the app on the local backend

```bash
flutter run --dart-define=BACKEND_LIVE=true \
  --dart-define=SUPABASE_URL=http://10.0.2.2:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon key from supabase status>
```

`10.0.2.2` is the Android emulator's address for the host; use `127.0.0.1` on Windows desktop or
iOS simulator. Sign in with any Egyptian mobile and `123456`, finish onboarding, close the app,
reopen: the profile comes back from the database (check `select * from profiles` in the DB).
Backend unreachable → the app starts on demo data (research D6).

## 5. Contract suites

```bash
flutter test test/contract          # fake + Supabase-over-InMemoryGateway
flutter test test/contract --dart-define=GOORA_CONTRACT_DB_URL=http://127.0.0.1:54321 \
  --dart-define=GOORA_CONTRACT_ANON_KEY=<anon> --dart-define=GOORA_CONTRACT_SERVICE_KEY=<service_role>
```

The second run adds the live group (clock-bound cases skipped). Without the defines it prints
"DB not run".
