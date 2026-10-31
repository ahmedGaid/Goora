// Run: node --test "supabase/functions/_shared/*.test.ts"
// 013 research D3: the SQL twins' pgTAP file is generated from the same JSON
// vectors the Dart and TypeScript twins run. This fails when the committed
// supabase/tests/60_vectors.test.sql no longer matches them — no database needed.
import { strictEqual } from "node:assert";
import { readFileSync } from "node:fs";
import { test } from "node:test";
// @ts-ignore: plain ES module, no types
import { generate, OUTPUT } from "../../tests/gen_vector_tests.mjs";

test("60_vectors.test.sql is up to date with test/fixtures/*.json", () => {
  const committed = (() => {
    try {
      return readFileSync(OUTPUT, "utf8");
    } catch {
      return "<missing>";
    }
  })();
  strictEqual(committed, generate(), "run: node supabase/tests/gen_vector_tests.mjs");
});

test("the generated file covers every rule family", () => {
  const text: string = generate();
  for (const fn of ["pay_cash_amount", "direct_pay_share", "direct_pay_fee", "fee_due_date", "fee_is_overdue", "fee_use_bundle", "is_late"]) {
    strictEqual(text.includes(`public.${fn}(`), true, `${fn} has vectors`);
  }
});
