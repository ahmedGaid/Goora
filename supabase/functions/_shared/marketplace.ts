// Driver day rule (005 research R4) and booking refund (research R7). Mirror of
// lib/features/marketplace/domain/driver_day_rules.dart and booking_refund.dart —
// both run test/fixtures/marketplace_vectors.json.
export const MAX_TRIPS = 2;
export const JOIN_WINDOW_MINUTES = 30; // inclusive

export type Leg = "going" | "return";
export type Area = "sheikhZayed" | "october" | "smartVillage";

export interface DayTrip {
  id: string;
  leg: Leg;
  from: Area;
  to: Area;
  departure: number; // minutes of day
  durationMinutes: number;
  seats: number;
  taken: number;
}

export interface Candidate {
  leg: Leg;
  from: Area;
  to: Area;
  departure: number;
  durationMinutes: number;
  daily: boolean;
  leadsGroup: boolean;
}

export type TripFit =
  | { kind: "join" | "full"; tripId: string }
  | { kind: "limitReached" | "doesntFit" | "oneGroupOnly" | "overlap" }
  | { kind: "create"; tripsLeftAfter: number };

export function tripsLeft(trips: DayTrip[]): number {
  return Math.max(0, MAX_TRIPS - trips.length);
}

// First match wins: join → full → limitReached → doesntFit → oneGroupOnly →
// overlap → create.
export function fit(trips: DayTrip[], c: Candidate): TripFit {
  const gap = (t: DayTrip) => Math.abs(t.departure - c.departure);
  const near = trips
    .filter((t) => t.leg === c.leg && t.from === c.from && t.to === c.to && gap(t) <= JOIN_WINDOW_MINUTES)
    .sort((a, b) => gap(a) - gap(b) || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  const open = near.find((t) => t.taken < t.seats);
  if (open) return { kind: "join", tripId: open.id };
  if (near.length > 0) return { kind: "full", tripId: near[0].id };
  if (trips.length >= MAX_TRIPS) return { kind: "limitReached" };
  if (trips.some((t) => t.leg === c.leg)) return { kind: "doesntFit" };
  if (c.daily && c.leadsGroup) return { kind: "oneGroupOnly" };
  const end = c.departure + c.durationMinutes;
  if (trips.some((t) => c.departure < t.departure + t.durationMinutes && t.departure < end)) {
    return { kind: "overlap" };
  }
  return { kind: "create", tripsLeftAfter: tripsLeft(trips) - 1 };
}

// The fee sits inside paidTotal and is never part of owed, so it always comes
// back. Never negative, never above paidTotal.
export function refundAmount(paidTotal: number, _fee: number, owed: number): number {
  return Math.max(0, Math.min(paidTotal, paidTotal - owed));
}
