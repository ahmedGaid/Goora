// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/marketplace_vectors_test.dart.
import { deepStrictEqual, strictEqual } from "node:assert";
import { test } from "node:test";
import { type Candidate, type DayTrip, fit, refundAmount, type TripFit } from "./marketplace.ts";
import { loadVectors } from "./vectors.ts";

interface Vectors {
  fit: { name: string; trips: DayTrip[]; candidate: Candidate; expect: TripFit }[];
  refund: { name: string; paidTotal: number; fee: number; owed: number; expect: number }[];
}

const v = loadVectors<Vectors>("marketplace");

for (const c of v.fit) {
  test(c.name, () => deepStrictEqual(fit(c.trips, c.candidate), c.expect));
}

for (const c of v.refund) {
  test(c.name, () => strictEqual(refundAmount(c.paidTotal, c.fee, c.owed), c.expect));
}
