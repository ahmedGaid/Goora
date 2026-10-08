// Run: node --test "supabase/functions/_shared/*.test.ts"
// Same vectors as test/unit/rider_total_test.dart.
import { strictEqual } from "node:assert";
import { test } from "node:test";
import { riderTotal, serviceFee } from "./pricing.ts";
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
}

for (const c of loadCases<Case>("pricing")) {
  test(c.name, () => {
    strictEqual(serviceFee(c.contribution, c.tripCost, c.riderSeats, c.isSubscriber, c.isCashTrial), c.fee);
    strictEqual(riderTotal(c.contribution, c.tripCost, c.riderSeats, c.isSubscriber, c.isCashTrial), c.total);
  });
}

test("brief example: 40 EGP trip → 44 (40 to the driver, 4 to Goora)", () => {
  strictEqual(serviceFee(40, 160, 3, false, false), 4);
  strictEqual(riderTotal(40, 160, 3, false, false), 44);
});

// Mirrors lib/features/commute/domain/pricing_service.dart's PricingService.range
// (002) — a local helper, not exported, since no server consumer needs it yet.
const STEP = 2;
const RANGE_PERCENT = 20;

function suggested(tripCost: number, riders: number): number {
  return Math.round(tripCost / ((riders + 1) * STEP)) * STEP;
}

function range(tripCost: number, riders: number): { min: number; max: number } {
  const s = suggested(tripCost, riders);
  const unit = 100 * STEP;
  const min = Math.floor((s * (100 - RANGE_PERCENT) + unit - 1) / unit) * STEP;
  const upper = Math.floor((s * (100 + RANGE_PERCENT)) / unit) * STEP;
  const cap = Math.floor(tripCost / (riders * STEP)) * STEP;
  return { min, max: Math.min(upper, cap) };
}

// 004 v2.1 research R17 — Constitution II's cap (FR-016, spec SC-006), proved by
// sweep rather than inspection. Mirrors test/unit/pricing_cap_sweep_test.dart.
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
        checked++;
      }
    }
  }
  if (checked === 0) throw new Error("sweep checked zero cases");
});
