// Attendance and cancellation rules (brief §6.5, FR-005 – FR-011, 003 research R3).
// Mirror of lib/features/daily/domain/attendance_rules.dart — both run
// test/fixtures/attendance_vectors.json. Erasable TypeScript only (Deno + Node).
import { addDays, at, isBefore, plusMinutes } from "./wall_time.ts";

export interface AttendanceLimits {
  /** "HH:MM" on the calendar day before the ride. */
  cutoff: string;
  noShowWaitMinutes: number;
  warnAt: number;
  removeAt: number;
}

export const LIMITS: AttendanceLimits = { cutoff: "21:00", noShowWaitMinutes: 5, warnAt: 2, removeAt: 3 };

export type AbsenceKind = "freeCancel" | "lateCancel" | "noCover";
export type UndoResult = "ok" | "refusedSeatTaken" | "refusedTooLate";
export type NoShowStanding = "ok" | "warning" | "removal";

/** 9 PM on the calendar day before `rideDate`, even if that day is not a working day. */
export const cutoffFor = (rideDate: string, l = LIMITS) => at(addDays(rideDate, -1), l.cutoff);

/** At or after the cut-off. 8:59:59 PM is free; 9:00 PM is late. */
export const isLate = (rideDate: string, madeAt: string, l = LIMITS) => !isBefore(madeAt, cutoffFor(rideDate, l));

/** EGP for cancelling one trip: free before the cut-off, half the share after (40 → 20). */
export const cancelCharge = (rideDate: string, madeAt: string, share: number, l = LIMITS) =>
  isLate(rideDate, madeAt, l) ? Math.trunc(share / 2) : 0;

export const cancelKind = (rideDate: string, madeAt: string, l = LIMITS): AbsenceKind =>
  isLate(rideDate, madeAt, l) ? "lateCancel" : "freeCancel";

/** Until the trip's pickup time; after that only the no-show path exists. */
export const canCancel = (pickup: string, madeAt: string) => isBefore(madeAt, pickup);

/**
 * A free cancel's seat goes to the waitlist at the cut-off, so its undo ends
 * then (when anyone is waiting). A late cancel's seat is kept, so it can be
 * undone, charge removed, until pickup (founder decision 2026-10-06).
 */
export function canUndo(
  absence: { date: string; kind: AbsenceKind },
  now: string,
  pickup: string,
  waitlistWaiting: boolean,
  l = LIMITS,
): UndoResult {
  if (!isBefore(now, pickup)) return "refusedTooLate";
  if (absence.kind === "freeCancel" && waitlistWaiting && !isBefore(now, cutoffFor(absence.date, l))) {
    return "refusedSeatTaken";
  }
  return "ok";
}

export const noShowAvailableAt = (arrivedAt: string, l = LIMITS) => plusMinutes(arrivedAt, l.noShowWaitMinutes);

/** 4:59 after arrival: not yet. 5:00: allowed. */
export const canMarkNoShow = (arrivedAt: string, now: string, l = LIMITS) =>
  !isBefore(now, noShowAvailableAt(arrivedAt, l));

/** A no-show pays their full share. */
export const noShowCharge = (share: number) => share;

/** No-shows in one calendar month; each trip counts (going + return = 2). */
export function standing(noShowsThisMonth: number, l = LIMITS): NoShowStanding {
  if (noShowsThisMonth >= l.removeAt) return "removal";
  if (noShowsThisMonth >= l.warnAt) return "warning";
  return "ok";
}

/** Neither checked in nor cancelled by the first scheduled pickup + 5 minutes (FR-010). */
export const driverNoShow = (firstPickup: string, now: string, checkedIn: boolean, cancelled: boolean, l = LIMITS) =>
  !checkedIn && !cancelled && !isBefore(now, plusMinutes(firstPickup, l.noShowWaitMinutes));

/** "Can't drive" follows the same cut-off; drivers owe no money, only reliability moves. */
export const driverCantDriveLate = isLate;
