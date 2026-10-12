// Per-trip rider price (004 v2, brief §6.7, research R6). Mirror of
// lib/features/commute/domain/pricing_service.dart (suggested, range, serviceFee,
// riderTotal, cashAmount) — both run test/fixtures/pricing_vectors.json.
//
// The contribution goes to the driver in full; Goora's 10% service fee is
// added on top (nearest whole EGP, halves up) and is 0 for subscribers,
// company-plan riders and cash trips.
export const FEE_RATE_PERCENT = 10;
export const STEP = 2;
export const RANGE_PERCENT = 20;

// trip cost ÷ (riders + 1), rounded to the nearest 2 EGP (002, brief §6.2).
export function suggested(tripCost: number, riders: number): number {
  return Math.round(tripCost / ((riders + 1) * STEP)) * STEP;
}

// ±20% of the suggestion in 2 EGP steps, and never more than an equal share of
// the whole trip cost (riders' total ≤ trip cost).
export function range(tripCost: number, riders: number): { min: number; suggested: number; max: number } {
  const s = suggested(tripCost, riders);
  const unit = 100 * STEP;
  const min = Math.floor((s * (100 - RANGE_PERCENT) + unit - 1) / unit) * STEP;
  const upper = Math.floor((s * (100 + RANGE_PERCENT)) / unit) * STEP;
  const cap = Math.floor(tripCost / (riders * STEP)) * STEP;
  return { min, suggested: s, max: Math.min(upper, cap) };
}

// FR-029 (005 research R3): the contribution rounded to the nearest 5 EGP, kept
// inside range(tripCost, riderSeats) — down when the nearest passes the top, up
// when below the floor; null when no multiple of 5 above 0 fits (no cash).
export function cashAmount(contribution: number, tripCost: number, riderSeats: number): number | null {
  const down = contribution - (contribution % 5);
  const up = down + 5;
  const r = range(tripCost, riderSeats);
  let cash = contribution % 5 <= 2 ? down : up;
  if (cash > r.max) cash = down;
  if (cash < r.min) cash = up;
  if (cash === 0 || cash < r.min || cash > r.max) return null;
  return cash;
}

// ⌊tripCost / riderSeats⌋ (004 v2.1 research R15/R17).
export function equalShare(tripCost: number, riderSeats: number): number {
  if (riderSeats < 1) throw new RangeError("riderSeats must be >= 1");
  return Math.floor(tripCost / riderSeats);
}

// 10% of the contribution, nearest whole EGP, halves up, trimmed to the room
// left under the rider's equal share (004 v2.1 research R17); 0 for
// subscribers, company-plan riders and cash trips.
export function serviceFee(
  contribution: number,
  tripCost: number,
  riderSeats: number,
  isSubscriber: boolean,
  isCashTrial: boolean,
): number {
  if (isSubscriber || isCashTrial) return 0;
  const rounded = Math.floor((contribution * FEE_RATE_PERCENT + 50) / 100);
  const room = equalShare(tripCost, riderSeats) - contribution;
  const fee = Math.min(rounded, room);
  return fee < 0 ? 0 : fee;
}

export function riderTotal(
  contribution: number,
  tripCost: number,
  riderSeats: number,
  isSubscriber: boolean,
  isCashTrial: boolean,
): number {
  return contribution + serviceFee(contribution, tripCost, riderSeats, isSubscriber, isCashTrial);
}
