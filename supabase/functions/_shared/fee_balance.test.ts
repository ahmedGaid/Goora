// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/fee_balance_vectors_test.dart.
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { type DayBalance, dueDate, isOverdue, useBundle } from "./fee_balance.ts";
import { loadVectors } from "./vectors.ts";

interface Vectors {
  due: { name: string; days: DayBalance[]; today: string; expect: string | null }[];
  overdue: { name: string; due: string | null; today: string; expect: boolean }[];
  bundle: { name: string; fee: number; left: number; expect: boolean }[];
}

const v = loadVectors<Vectors>("fee_balance");

for (const c of v.due) {
  test(`due: ${c.name}`, () => strictEqual(dueDate(c.days, c.today), c.expect));
}
for (const c of v.overdue) {
  test(`overdue: ${c.name}`, () => strictEqual(isOverdue(c.due, c.today), c.expect));
}
for (const c of v.bundle) {
  test(`bundle: ${c.name}`, () => strictEqual(useBundle(c.fee, c.left), c.expect));
}
