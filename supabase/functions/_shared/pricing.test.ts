// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/rider_total_test.dart.
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { cashAmount, equalShare, range, riderTotal, serviceFee } from "./pricing.ts";
import { loadCases } from "./vectors.ts";

interface Case {
  name: string;
  contribution: number;
  tripCost: number;
  riderSeats: number;
  isSubscriber: boolean;
  isCashTrial: boolean;
  fee: number;
  total: number;
  cash: number | null;
}

for (const c of loadCases<Case>("pricing")) {
  test(c.name, () => {
    strictEqual(serviceFee(c.contribution, c.tripCost, c.riderSeats, c.isSubscriber, c.isCashTrial), c.fee);
    strictEqual(riderTotal(c.contribution, c.tripCost, c.riderSeats, c.isSubscriber, c.isCashTrial), c.total);
    strictEqual(cashAmount(c.contribution, c.tripCost, c.riderSeats), c.cash);
  });
}

test("brief example: 40 EGP trip → 44 (40 to the driver, 4 to Goora)", () => {
  strictEqual(serviceFee(40, 160, 3, false, false), 4);
  strictEqual(riderTotal(40, 160, 3, false, false), 44);
});

// 004 v2.1 research R17 — Constitution II's cap (FR-016, spec SC-006), proved by
// sweep rather than inspection; 005 adds the cash amount (FR-029, SC-002).
// Mirrors test/unit/pricing_cap_sweep_test.dart.
test("every allowed price keeps riders' total within the trip cost", () => {
  let checked = 0;
  for (let tripCost = 20; tripCost <= 1000; tripCost += 20) {
    for (let riderSeats = 1; riderSeats <= 4; riderSeats++) {
      const { min, max } = range(tripCost, riderSeats);
      for (let c = min; c <= max; c += 2) {
        const total = riderTotal(c, tripCost, riderSeats, false, false);
        if (riderSeats * total > tripCost) {
          throw new Error(
            `tripCost=${tripCost} riderSeats=${riderSeats} contribution=${c} total=${total}`,
          );
        }
        const cash = cashAmount(c, tripCost, riderSeats);
        const cashOk =
          cash === null ||
          (cash > 0 && cash % 5 === 0 && min <= cash && cash <= max && cash <= equalShare(tripCost, riderSeats));
        if (!cashOk) {
          throw new Error(`tripCost=${tripCost} riderSeats=${riderSeats} contribution=${c} cash=${cash}`);
        }
        checked++;
      }
    }
  }
  if (checked === 0) throw new Error("sweep checked zero cases");
});
