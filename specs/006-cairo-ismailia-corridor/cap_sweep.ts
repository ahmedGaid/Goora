// Constitution II cap proof for feature 006 (trip cost 300 EGP per leg).
// Runs the REAL pricing twin (supabase/functions/_shared/pricing.ts), not a port.
// The Dart side is tied to the same rules by test/fixtures/pricing_vectors.json.
//
// Run from the repo root:
//   node specs/006-cairo-ismailia-corridor/cap_sweep.ts
// Exit code 1 if any allowed price breaks the cap.
import { cashAmount, equalShare, range, serviceFee } from "../../supabase/functions/_shared/pricing.ts";

type Bad = { cost: number; seats: number; price: number; why: string };

function sweep(cost: number): { checked: number; bad: Bad[] } {
  const bad: Bad[] = [];
  let checked = 0;
  for (const seats of [1, 2, 3, 4]) {
    const r = range(cost, seats);
    for (let price = r.min; price <= r.max; price += 2) {
      checked++;
      const total = price + serviceFee(price, cost, seats, false, false);
      if (total > equalShare(cost, seats)) bad.push({ cost, seats, price, why: `total ${total} > equal share` });
      if (seats * total > cost) bad.push({ cost, seats, price, why: `full car ${seats * total} > ${cost}` });
      const cash = cashAmount(price, cost, seats);
      if (cash !== null && seats * cash > cost) bad.push({ cost, seats, price, why: `cash ${cash} full car > cost` });
    }
  }
  return { checked, bad };
}

console.log("trip cost 300 EGP per leg");
for (const seats of [1, 2, 3, 4]) {
  const r = range(300, seats);
  const top = r.max + serviceFee(r.max, 300, seats, false, false);
  console.log(
    `  seats=${seats}: range ${r.min}-${r.max} suggested ${r.suggested} equal share ${equalShare(300, seats)} ` +
      `top price+fee ${top} cash(suggested)=${cashAmount(r.suggested, 300, seats)}`,
  );
}
const corridor = sweep(300);
console.log(`cost 300: ${corridor.checked} price/seat combinations, ${corridor.bad.length} over the cap`);

let checked = 0;
const allBad: Bad[] = [];
for (let cost = 100; cost <= 1000; cost += 20) {
  const s = sweep(cost);
  checked += s.checked;
  allBad.push(...s.bad);
}
console.log(`costs 100-1000 step 20: ${checked} combinations, ${allBad.length} over the cap`);
for (const b of [...corridor.bad, ...allBad].slice(0, 10)) console.log("  BAD", JSON.stringify(b));
process.exit(corridor.bad.length || allBad.length ? 1 : 0);
