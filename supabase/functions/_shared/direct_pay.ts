// Direct driver payment rules (007 research R2–R4). Mirror of
// lib/features/wallet/domain/direct_pay.dart (SharePolicy, DirectPay) — both
// run test/fixtures/direct_pay_vectors.json. Times are whole minutes.
import { cashAmount, equalShare, FEE_RATE_PERCENT } from "./pricing.ts";

export const AUTO_RECEIVE_MINUTES = 24 * 60;
export const REVERSE_AUTO_MINUTES = 7 * 24 * 60;
export const DISPUTE_WINDOW_DAYS = 30;
export const DISPUTE_LIMIT = 2;

export type Outcome = "received" | "didNotPay";
export type ShareStatus = "pending" | "received" | "autoReceived" | "notReceived" | "disputed";
export type Method = "cash" | "instapay";

export function isOpenDebt(s: ShareStatus): boolean {
  return s === "notReceived" || s === "disputed";
}

// A rider's claim counts only when made after the latest "didn't pay" mark.
export function status(
  mark: Outcome | null,
  markedAt: number | null,
  claimAt: number | null,
  tripEnd: number,
  now: number,
): ShareStatus {
  if (mark === "received") return "received";
  if (mark === "didNotPay") {
    const claimed = claimAt !== null && (markedAt === null || claimAt > markedAt);
    return claimed ? "disputed" : "notReceived";
  }
  return now - tripEnd >= AUTO_RECEIVE_MINUTES ? "autoReceived" : "pending";
}

// Any answer within 24 h; "received" always (it only clears a debt); an
// auto-received share may become "didn't pay" once within 7 days.
export function canMark(
  current: ShareStatus,
  outcome: Outcome,
  tripEnd: number,
  now: number,
  reversedOnce: boolean,
): boolean {
  if (now < tripEnd) return false;
  if (outcome === "received" && current !== "received") return true;
  if (now - tripEnd < AUTO_RECEIVE_MINUTES) return true;
  return current === "autoReceived" && outcome === "didNotPay" && !reversedOnce &&
    now - tripEnd < REVERSE_AUTO_MINUTES;
}

export function disputeFlagged(didNotPayDays: number[], today: number): boolean {
  return didNotPayDays.filter((d) => d <= today && today - d < DISPUTE_WINDOW_DAYS).length >= DISPUTE_LIMIT;
}

export function share(contribution: number, method: Method, tripCost: number, riderSeats: number): number {
  if (method === "cash") return cashAmount(contribution, tripCost, riderSeats) ?? contribution;
  return contribution;
}

export function fee(
  contribution: number,
  shareAmount: number,
  tripCost: number,
  riderSeats: number,
  feeFree: boolean,
): number {
  if (feeFree) return 0;
  // Untrimmed 10%, half up: the cap is on what is actually paid (the share).
  const base = Math.floor((contribution * FEE_RATE_PERCENT + 50) / 100);
  const room = equalShare(tripCost, riderSeats) - shareAmount;
  const f = Math.min(base, room);
  return f < 0 ? 0 : f;
}
