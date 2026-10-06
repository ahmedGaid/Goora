// Backup driver search (brief §6.6, FR-017 – FR-019, 003 research R6). Mirror of
// lib/features/daily/domain/backup_service.dart — both run
// test/fixtures/backup_vectors.json.
//
// Steps in order: same group → nearby group → same company → same community.
// A candidate passes when available, with a seat for every passenger, passing
// the 002 hard constraints for that leg and day (matching.ts `evaluate`), and
// accepted by every passenger's privacy preference. Within a step: least
// detour (metres from their home to the group's pickup) → highest rating →
// lowest id. One cover carries the whole leg; the price never changes.
import { evaluate } from "./matching.ts";
import type { Group, Leg, Member, Point } from "./matching.ts";
import { weekday } from "./wall_time.ts";
import type { Day } from "./wall_time.ts";

export type BackupStep = "sameGroup" | "nearbyGroup" | "sameCompany" | "sameCommunity";
export const STEPS: BackupStep[] = ["sameGroup", "nearbyGroup", "sameCompany", "sameCommunity"];

export type Privacy = "verifiedUsers" | "sameCompany" | "sameCompound" | "womenOnly";

export interface DailyMember extends Member {
  privacy: Privacy;
  days?: Day[] | null;
}

export interface DailyGroup extends Group {
  members: DailyMember[];
}

export interface BackupRide {
  date: string;
  leg: Leg;
  passengers: { memberId: string; stopId: string }[];
}

export interface BackupCandidate {
  member: DailyMember;
  step: BackupStep;
  /** Their own commute as a driver; limited to the ride's leg and day here. */
  seeker: { home: Point; work: Point; departure: string; ret: string; days: Day[] };
  /** Seats free in their car on that leg and day. */
  freeSeats: number;
  /** Not away themselves that day. */
  available: boolean;
}

export interface BackupResult {
  cover: string | null;
  step: BackupStep | null;
}

type Facts = Pick<Member, "isWoman" | "company" | "compound">;

/** Whether `owner`, with preference `p`, accepts riding with `other` (003 research R7). */
export function accepts(p: Privacy, owner: Facts, other: Facts): boolean {
  switch (p) {
    case "verifiedUsers":
      return true;
    case "womenOnly":
      return other.isWoman;
    case "sameCompany":
      return owner.company !== null && other.company === owner.company;
    case "sameCompound":
      return owner.compound !== null && other.compound === owner.compound;
  }
}

/** Metres from the candidate's home to the group's pickup, or null when they cannot cover. */
function detour(c: BackupCandidate, ride: BackupRide, g: DailyGroup): number | null {
  const cover = c.member;
  if (!c.available) return null;
  const riders = ride.passengers.filter((p) => p.memberId !== cover.id);
  if (c.freeSeats < riders.length) return null;

  const day = weekday(ride.date);
  const match = evaluate(
    {
      role: "driver",
      home: c.seeker.home,
      work: c.seeker.work,
      departure: c.seeker.departure,
      ret: c.seeker.ret,
      days: c.seeker.days.filter((d) => d === day),
      legs: [ride.leg],
      isWoman: cover.isWoman,
      company: cover.company,
      compound: cover.compound,
      womenOnly: cover.privacy === "womenOnly",
      sameCompanyOnly: cover.privacy === "sameCompany",
      sameCompoundOnly: cover.privacy === "sameCompound",
    },
    g,
  );
  if (match === null) return null;

  for (const p of riders) {
    const rider = g.members.find((m) => m.id === p.memberId);
    if (rider && !accepts(rider.privacy, rider, cover)) return null;
  }
  return match.pickupMeters;
}

export function findCover(ride: BackupRide, g: DailyGroup, candidates: BackupCandidate[]): BackupResult {
  for (const step of STEPS) {
    const passing: [BackupCandidate, number][] = [];
    for (const c of candidates) {
      if (c.step !== step) continue;
      const metres = detour(c, ride, g);
      if (metres !== null) passing.push([c, metres]);
    }
    passing.sort(([a, da], [b, db]) => {
      if (da !== db) return da - db;
      if (a.member.rating !== b.member.rating) return b.member.rating - a.member.rating;
      return a.member.id < b.member.id ? -1 : a.member.id > b.member.id ? 1 : 0;
    });
    if (passing.length > 0) return { cover: passing[0][0].member.id, step };
  }
  return { cover: null, step: null };
}
