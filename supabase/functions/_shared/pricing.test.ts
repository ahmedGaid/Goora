// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/rider_total_test.dart.
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { riderTotal, serviceFee } from "./pricing.ts";
import { loadCases } from "./vectors.ts";

interface Case {
  name: string;
  contribution: number;
  isSubscriber: boolean;
  isCashTrial: boolean;
  fee: number;
  total: number;
}

for (const c of loadCases<Case>("pricing")) {
  test(c.name, () => {
    strictEqual(serviceFee(c.contribution, c.isSubscriber, c.isCashTrial), c.fee);
    strictEqual(riderTotal(c.contribution, c.isSubscriber, c.isCashTrial), c.total);
  });
}

test("brief example: 40 EGP trip → 44 (40 to the driver, 4 to Goora)", () => {
  strictEqual(serviceFee(40, false, false), 4);
  strictEqual(riderTotal(40, false, false), 44);
});
