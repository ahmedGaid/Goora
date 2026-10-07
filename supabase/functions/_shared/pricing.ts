// Per-trip rider price (004 v2, brief §6.7, research R6). Mirror of
// lib/features/commute/domain/pricing_service.dart (serviceFee, riderTotal) — both run
// test/fixtures/pricing_vectors.json.
//
// The contribution goes to the driver in full; Goora's 10% service fee is
// added on top (nearest whole EGP, halves up) and is 0 for subscribers,
// company-plan riders and cash trips.
export const FEE_RATE_PERCENT = 10;

export function serviceFee(contribution: number, isSubscriber: boolean, isCashTrial: boolean): number {
  if (isSubscriber || isCashTrial) return 0;
  return Math.floor((contribution * FEE_RATE_PERCENT + 50) / 100);
}

export function riderTotal(contribution: number, isSubscriber: boolean, isCashTrial: boolean): number {
  return contribution + serviceFee(contribution, isSubscriber, isCashTrial);
}
