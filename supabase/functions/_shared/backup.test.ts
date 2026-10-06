// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/daily_vectors_test.dart (group "backup").
import { deepStrictEqual } from "node:assert";
import { test } from "node:test";
import { findCover } from "./backup.ts";
import type { BackupCandidate, BackupResult, BackupRide, DailyGroup } from "./backup.ts";
import { loadCases } from "./vectors.ts";

interface Case {
  name: string;
  ride: BackupRide;
  group: DailyGroup;
  candidates: BackupCandidate[];
  expect: BackupResult;
}

for (const c of loadCases<Case>("backup")) {
  test(c.name, () => deepStrictEqual(findCover(c.ride, c.group, c.candidates), c.expect));
}
