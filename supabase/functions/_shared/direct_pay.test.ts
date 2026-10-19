// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/direct_pay_vectors_test.dart.
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { canMark, disputeFlagged, fee, type Method, type Outcome, share, type ShareStatus, status } from "./direct_pay.ts";
import { loadVectors } from "./vectors.ts";

interface Vectors {
  status: {
    name: string;
    mark: Outcome | null;
    markedAt: number | null;
    claimAt: number | null;
    tripEnd: number;
    now: number;
    expect: ShareStatus;
  }[];
  canMark: {
    name: string;
    current: ShareStatus;
    outcome: Outcome;
    tripEnd: number;
    now: number;
    reversedOnce: boolean;
    expect: boolean;
  }[];
  flag: { name: string; days: number[]; today: number; expect: boolean }[];
  share: { name: string; contribution: number; method: Method; tripCost: number; riderSeats: number; expect: number }[];
  fee: {
    name: string;
    contribution: number;
    share: number;
    tripCost: number;
    riderSeats: number;
    feeFree: boolean;
    expect: number;
  }[];
}

const v = loadVectors<Vectors>("direct_pay");

for (const c of v.status) {
  test(`status: ${c.name}`, () => strictEqual(status(c.mark, c.markedAt, c.claimAt, c.tripEnd, c.now), c.expect));
}
for (const c of v.canMark) {
  test(`canMark: ${c.name}`, () => strictEqual(canMark(c.current, c.outcome, c.tripEnd, c.now, c.reversedOnce), c.expect));
}
for (const c of v.flag) {
  test(`flag: ${c.name}`, () => strictEqual(disputeFlagged(c.days, c.today), c.expect));
}
for (const c of v.share) {
  test(`share: ${c.name}`, () => strictEqual(share(c.contribution, c.method, c.tripCost, c.riderSeats), c.expect));
}
for (const c of v.fee) {
  test(`fee: ${c.name}`, () => strictEqual(fee(c.contribution, c.share, c.tripCost, c.riderSeats, c.feeFree), c.expect));
}
