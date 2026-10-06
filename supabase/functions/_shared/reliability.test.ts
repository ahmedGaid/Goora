// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/daily_vectors_test.dart (group "reliability").
import { deepStrictEqual } from "node:assert";
import { test } from "node:test";
import { computeReliability } from "./reliability.ts";
import type { Reliability, ReliabilityEvent } from "./reliability.ts";
import { loadCases } from "./vectors.ts";

interface Case {
  name: string;
  today: string;
  events: ReliabilityEvent[];
  expect: Reliability;
}

for (const c of loadCases<Case>("reliability")) {
  test(c.name, () => deepStrictEqual(computeReliability(c.events, c.today), c.expect));
}
