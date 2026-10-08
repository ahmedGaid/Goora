// Per-trip rider price (004 v2, brief §6.7, research R6). Mirror of
// lib/features/commute/domain/pricing_service.dart (serviceFee, riderTotal) — both run
// test/fixtures/pricing_vectors.json.
//
// The contribution goes to the driver in full; Goora's 10% service fee is
// added on top (nearest whole EGP, halves up) and is 0 for subscribers,
// company-plan riders and cash trips.
export const FEE_RATE_PERCENT = 10;

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
