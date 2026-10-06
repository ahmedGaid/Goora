// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/daily_vectors_test.dart (group "attendance").
import { deepStrictEqual } from "node:assert";
import { test } from "node:test";
import {
  canCancel,
  cancelCharge,
  cancelKind,
  canMarkNoShow,
  canUndo,
  cutoffFor,
  driverNoShow,
  isLate,
  noShowAvailableAt,
  noShowCharge,
  standing,
} from "./attendance.ts";
import type { AbsenceKind } from "./attendance.ts";
import { loadCases } from "./vectors.ts";

// deno-lint-ignore no-explicit-any
type Input = Record<string, any>;

function run(fn: string, i: Input): unknown {
  switch (fn) {
    case "cancel": {
      const charges = (i.legs as string[]).map(() => cancelCharge(i.rideDate, i.madeAt, i.share));
      return {
        cutoff: cutoffFor(i.rideDate),
        late: isLate(i.rideDate, i.madeAt),
        kind: cancelKind(i.rideDate, i.madeAt),
        charges,
        total: charges.reduce((a, b) => a + b, 0),
      };
    }
    case "canCancel":
      return canCancel(i.pickup, i.madeAt);
    case "undo":
      return canUndo(i.absence as { date: string; kind: AbsenceKind }, i.now, i.pickup, i.waitlistWaiting);
    case "noShow":
      return { availableAt: noShowAvailableAt(i.arrivedAt), allowed: canMarkNoShow(i.arrivedAt, i.now) };
    case "standing":
      return standing(i.count);
    case "driverNoShow":
      return driverNoShow(i.firstPickup, i.now, i.checkedIn, i.cancelled);
    case "noShowCharge":
      return noShowCharge(i.share);
    default:
      throw new Error(fn);
  }
}

for (const c of loadCases<{ name: string; fn: string; input: Input; expect: unknown }>("attendance")) {
  test(c.name, () => deepStrictEqual(run(c.fn, c.input), c.expect));
}
