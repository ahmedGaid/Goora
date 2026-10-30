# /speckit-analyze — 012 (2026-10-30)

| ID | Severity | Finding | Resolution |
|---|---|---|---|
| A1 | CRITICAL | Constitution tech line says `google_maps_flutter`; feature uses `flutter_map` | Founder already decided (profit change §4, brief §4). Logged in plan Complexity Tracking + D14; PATCH amendment flagged to the conductor. Not a blocker for build. |
| A2 | HIGH | FR-001 (no free picking), FR-008 (44 px, close), FR-012 (swap) had no explicit test task | Fixed: T010 now asserts them |
| A3 | MEDIUM | `AppSizes` edit not in the lane's OWNS list | Additive lines at the end of the class only (tokens must live in `lib/core/theme`); listed in files touched |
| A4 | LOW | FR-003 (no live position) is guaranteed by the input type, not a runtime check | Accepted: `PickupMapScene` has no driver field; covered by the contract |

Coverage: FR-001…FR-014 and SC-001…SC-006 each map to ≥ 1 task. No unmapped tasks. No ambiguity
markers. Terminology consistent (pickup = التجمع, arrival = الوصول, meeting point card).
