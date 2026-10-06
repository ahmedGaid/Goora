// Reliability % (FR-036, 003 research R4). Mirror of
// lib/features/daily/domain/reliability_rules.dart — both run
// test/fixtures/reliability_vectors.json.
//
// Over the 30 days before `today` (today excluded) every event is one booked
// trip; a no-show misses 1, a late cancel or late "can't drive" misses 0.5.
// percent = round half up of kept ÷ booked × 100; nothing booked → 100. The
// month counts are this calendar month's and reset on the 1st; the % does not.
import { addDays, monthKey } from "./wall_time.ts";

export type ReliabilityEventKind = "kept" | "noShow" | "lateCancel" | "lateCantDrive";

export interface ReliabilityEvent {
  date: string;
  kind: ReliabilityEventKind;
}

export interface Reliability {
  percent: number;
  monthLateCancels: number;
  monthNoShows: number;
}

export const WINDOW_DAYS = 30;

const MISSED_HALVES: Record<ReliabilityEventKind, number> = { kept: 0, noShow: 2, lateCancel: 1, lateCantDrive: 1 };

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);

/** Exact integer arithmetic in half trips, so x.5 always rounds up. */
export function percent(booked: number, missedHalves: number): number {
  if (booked === 0) return 100;
  const bookedHalves = 2 * booked;
  const keptHalves = clamp(bookedHalves - missedHalves, 0, bookedHalves);
  return clamp(Math.floor((200 * keptHalves + bookedHalves) / (2 * bookedHalves)), 0, 100);
}

export function computeReliability(events: ReliabilityEvent[], today: string): Reliability {
  const from = addDays(today, -WINDOW_DAYS);
  const inside = events.filter((e) => e.date >= from && e.date < today);
  const missed = inside.reduce((n, e) => n + MISSED_HALVES[e.kind], 0);
  const month = events.filter((e) => monthKey(e.date) === monthKey(today)).map((e) => e.kind);
  return {
    percent: percent(inside.length, missed),
    monthLateCancels: month.filter((k) => k === "lateCancel" || k === "lateCantDrive").length,
    monthNoShows: month.filter((k) => k === "noShow").length,
  };
}
