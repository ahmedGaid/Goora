// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/daily_vectors_test.dart (group "rotation").
import { deepStrictEqual } from "node:assert";
import { test } from "node:test";
import type { Leg } from "./matching.ts";
import { planRotation } from "./rotation.ts";
import type { PlannedDay, RotationGroup } from "./rotation.ts";
import { loadCases } from "./vectors.ts";

interface Case {
  name: string;
  group: RotationGroup;
  from: string;
  to: string;
  unavailable: [string, string, Leg][];
  expect: PlannedDay[];
}

for (const c of loadCases<Case>("rotation")) {
  test(c.name, () => deepStrictEqual(planRotation(c.group, c.from, c.to, c.unavailable), c.expect));
}
