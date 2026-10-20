// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/company_vectors_test.dart.
import { deepStrictEqual, strictEqual } from "node:assert";
import { test } from "node:test";
import {
  activeWindows,
  billedSeats,
  coverage,
  covered,
  dueDay,
  invoiceTotal,
  peakEnrolled,
  suppress,
  suspendFromDay,
  type Window,
} from "./company.ts";
import { loadVectors } from "./vectors.ts";

type Overdue = { suspendFrom: number; paidAt: number | null };

interface Vectors {
  coverage: { name: string; enrolled: Window[]; companyActive: Window[]; expect: Window[] }[];
  covered: { name: string; windows: Window[]; minute: number; expect: boolean }[];
  peakEnrolled: {
    name: string;
    byPerson: Record<string, Window[]>;
    monthFromDay: number;
    monthToDay: number;
    expect: number;
  }[];
  billing: { name: string; peak: number; minimumSeats: number; pricePerSeat: number; billedSeats: number; total: number }[];
  due: { name: string; issueDay: number; dueDay: number; suspendFromDay: number }[];
  activeWindows: { name: string; approvedAt: number; endedAt: number | null; overdue: Overdue[]; expect: Window[] }[];
  suppress: { name: string; count: number; expect: number | null }[];
}

const v = loadVectors<Vectors>("company");

for (const c of v.coverage) {
  test(c.name, () => deepStrictEqual(coverage(c.enrolled, c.companyActive), c.expect));
}

for (const c of v.covered) {
  test(c.name, () => strictEqual(covered(c.windows, c.minute), c.expect));
}

for (const c of v.peakEnrolled) {
  test(c.name, () => strictEqual(peakEnrolled(c.byPerson, c.monthFromDay, c.monthToDay), c.expect));
}

for (const c of v.billing) {
  test(c.name, () => {
    const seats = billedSeats(c.peak, c.minimumSeats);
    strictEqual(seats, c.billedSeats);
    strictEqual(invoiceTotal(seats, c.pricePerSeat), c.total);
  });
}

for (const c of v.due) {
  test(c.name, () => {
    const due = dueDay(c.issueDay);
    strictEqual(due, c.dueDay);
    strictEqual(suspendFromDay(due), c.suspendFromDay);
  });
}

for (const c of v.activeWindows) {
  test(c.name, () =>
    deepStrictEqual(activeWindows({ approvedAt: c.approvedAt, endedAt: c.endedAt, overdue: c.overdue }), c.expect));
}

for (const c of v.suppress) {
  test(c.name, () => strictEqual(suppress(c.count), c.expect));
}
