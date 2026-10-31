/goal Goora — Lane M: OpenStreetMap display for pickup points (profit change 4), behind a swappable map interface, built spec-driven as feature 012-osm-map. Long autonomous run: you will NOT be asked anything and must NOT ask — pick the defensible option, record it in specs/012-osm-map/research.md "Decisions" with the rejected alternative, continue.

RULES (hold even if no skill loads):
- Recall first: goora-resume (live git), goora-stack, goora-brand, ag-ui-standard, impeccable, multi-agent-git, speckit-* skills. Fit: Opus (design judgment + new dependency) — Sonnet acceptable after P0. Est: 5–6 h.
- Other sessions share this repo (4 lanes this round: F, 011, M, L). One session = one task = one branch = one worktree. Pre-flight: git status / branch --show-current / worktree list / stash list. Never `git add .` — stage exact paths, `git diff --cached --name-only` before every commit. Never revert/reset/clean or `dart format` files you did not edit.
- Branch + worktree BEFORE the first edit: in D:\Company\10-Products\Goora `git fetch --all --prune && git pull --ff-only`, confirm main ≥ b19efec, `ls specs/` (012 must be free — if taken, use the next free number and say so), then `git worktree add D:/Company/80-Worktrees/Goora-map -b feat/osm-map main`.
- Commit + push YOUR branch after every phase. Never merge or push main — the conductor (session "managere") does. When managere says "merge main", run `git merge main` (additive ARB/pubspec conflicts keep BOTH sides, then `flutter pub get`).
- Tests first, confirmed failing. No secrets in the repo: tile key via --dart-define only. New ARB keys only at the END of app_ar.arb / app_en.arb. Copy: goora-brand checklist, Egyptian colloquial, 1.3× text, 44 px targets, RTL. One emulator per session.
- End: append your own dated block at the top of the goora-status skill (never rewrite others'), then SendMessage managere "Lane M done" with gate numbers + files touched + goldens changed.

PUBSPEC BOTTLENECK (Lane 011 also edits pubspec): your FIRST commit is ONLY pubspec.yaml + pubspec.lock adding flutter_map + latlong2 (current stable, pinned). Push it, then SendMessage managere "Lane M deps pushed <sha>" — the conductor merges that one commit to main so 011 picks it up. Do not touch pubspec again after that; if you must, ask managere via SendMessage first (the only allowed message).

WHAT (from GOORA_PROFIT_CHANGES.md §4 + GOORA_SPEC_KIT_BRIEF.md §4): matching already runs on PostGIS; the map is DISPLAY ONLY. Use flutter_map; public OSM tiles forbid production use, so the tile URL template + key come from config (.env.example already has MAP_TILE_URL_TEMPLATE / MAP_TILE_API_KEY). Read them in a NEW lib/core/map/map_config.dart via String.fromEnvironment — do NOT edit lib/core/config/env.dart (Lane 011 owns it). Tile provider is a founder decision (Q4) — stay provider-neutral.
- No tile URL configured (default, tests, demo) → no network at all: render a calm offline pickup-point view (points on a plain brand-token canvas, or the existing pickup list) — never a broken grey map.
- Map behind an interface (e.g. GooraMapView / MapProvider) so the provider can change; flutter_map is one implementation.
- Show OSM attribution wherever tiles render, as the licence requires.
- Privacy (constitution): never show home addresses, only pickup points; no live driver location.
- Prefer fixed pickup points over a free map; the map only shows/selects among existing points.

PHASES (commit + push after each):
P0 deps commit (above). P1 speckit: /speckit-specify "012 OSM map display" → clarify (answer yourself, log) → plan → tasks → analyze; fix criticals.
P2 lib/core/map/** (config, interface, flutter_map impl, offline fallback) + lib/core/widgets/goora_pickup_map.dart, with unit + widget tests (fallback when no URL; attribution present when tiles on; no home address ever passed in).
P3 surfaces: commute match_result_screen.dart (the group's pickup point) and daily today/rider_today.dart + driver_today.dart (today's meeting point card, tap → bigger map). Add the design_gallery entry if goora-stack says galleries list widgets.
P4 goldens ar + en at 1.3× for the new widget (offline mode — goldens must not hit the network); regenerate only the screen goldens you changed; README "Map tiles" section (how to pass the tile URL/key via --dart-define, no real key); research decisions; goora-status block; gates.

OWNS: specs/012-osm-map/** · pubspec.yaml/.lock (P0 commit only) · lib/core/map/** · lib/core/widgets/goora_pickup_map.dart · lib/features/commute/presentation/match_result_screen.dart · lib/features/daily/presentation/today/rider_today.dart · lib/features/daily/presentation/today/driver_today.dart · design_gallery entry for the map widget · test/**/map/** + the goldens of the screens above · README "Map tiles" section · new ARB keys at the end.
MUST NOT TOUCH:
- Lane F (walk-6 fixes, branch fix/010-walk6): lib/features/company/** · lib/features/wallet/presentation/** · onboarding_flow.dart · lib/app/router.dart · lib/app/routes.dart · lib/features/marketplace/presentation/** · lib/features/settings/** · specs/010-company-network/**.
- Lane 011 (real backend, branch 011-real-backend): lib/core/config/env.dart · lib/core/backend/** · any lib/features/*/data/ file · supabase/** · test/contract/** · pubspec after your P0 commit.
- Lane L (launch prep, branch chore/launch-prep): android/** · ios/** · .github/** · flutter_launcher_icons.yaml · flutter_native_splash.yaml · Docs/release/**. (If flutter_map needs an Android INTERNET permission, note it in research and SendMessage managere — Lane L owns the manifest.)
- Docs/NEXT_GOAL.md (conductor writes it). Domain rules + Dart↔TS twins: unchanged.

DONE = specs/012 full speckit set + analyze clean · map behind an interface, offline fallback is the default, attribution when tiles render · pickup map on match result + today screens, ar + en, RTL, 1.3× · no network in tests · gates in your worktree: `flutter analyze` 0 · `flutter test --concurrency=1` green (≥ 1769, existing tests unchanged except goldens you list) · `node --test "supabase/functions/_shared/*.test.ts"` green (276) · goora-status block · branch pushed · "Lane M done" sent to managere.
READ FIRST: GOORA_PROFIT_CHANGES.md §4 · GOORA_SPEC_KIT_BRIEF.md §4 + §3 (tokens) · .specify/memory/constitution.md (privacy) · lib/features/commute/data/corridor_seed.dart (pickup points) · goora-brand.
BLOCKED, don't re-ask: tile provider + real key = founder (Q4) · Google Maps is NOT used · no live tracking.
