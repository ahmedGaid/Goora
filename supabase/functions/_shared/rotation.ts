// Fair driver rotation (brief §6.4, FR-022, SC-005, 003 research R5). Mirror of
// lib/features/daily/domain/rotation_planner.dart — both run
// test/fixtures/rotation_vectors.json.
//
// Per leg, over consecutive 4-week periods from the group's rotationStart:
// each ride day goes to the eligible driver with the fewest drives on that
// leg this period; ties → longest since their last drive on that leg →
// lowest member id. Returns planned drivers only; absences and backups are
// applied on top.
import type { Leg } from "./matching.ts";
import { addDays, daysUntil, weekday } from "./wall_time.ts";
import type { Day } from "./wall_time.ts";

export interface RotationMember {
  id: string;
  role: "driver" | "rider";
  legs: Leg[];
  /** Days this member commutes; null = the group's days. */
  days?: Day[] | null;
}

export interface RotationGroup {
  days: Day[];
  members: RotationMember[];
  rotationStart?: string | null;
}

/** [date, going driver, return driver]; null = nobody drives that leg. */
export type PlannedDay = [string, string | null, string | null];

export const PERIOD_DAYS = 28;
/** Used when a group has no rotationStart (a Sunday). */
export const DEFAULT_START = "2026-01-04";

const LEGS: Leg[] = ["going", "ret"];

export function planRotation(
  g: RotationGroup,
  from: string,
  to: string,
  unavailable: [string, string, Leg][] = [],
): PlannedDay[] {
  const start = g.rotationStart ?? DEFAULT_START;
  const periodOf = (d: string) => Math.floor(daysUntil(start, d) / PERIOD_DAYS);
  const blocked = new Set(unavailable.map(([id, d, leg]) => `${id}|${d}|${leg}`));
  const counts: Record<Leg, Map<string, number>> = { going: new Map(), ret: new Map() };
  const last: Record<Leg, Map<string, string>> = { going: new Map(), ret: new Map() };
  const out: PlannedDay[] = [];

  // Simulate from the start of `from`'s period so the window never changes who drives.
  let period = periodOf(from);
  for (let date = addDays(start, period * PERIOD_DAYS); date <= to; date = addDays(date, 1)) {
    if (periodOf(date) !== period) {
      period = periodOf(date);
      counts.going.clear();
      counts.ret.clear();
    }
    const day = weekday(date);
    if (!g.days.includes(day)) continue;

    const [going, ret] = LEGS.map((leg) => {
      const eligible = g.members
        .filter((m) => m.role === "driver" && m.legs.includes(leg))
        .filter((m) => (m.days ?? g.days).includes(day) && !blocked.has(`${m.id}|${date}|${leg}`))
        .map((m) => m.id)
        .sort((a, b) => compare(a, b, counts[leg], last[leg]));
      const pick = eligible[0] ?? null;
      if (pick !== null) {
        counts[leg].set(pick, (counts[leg].get(pick) ?? 0) + 1);
        last[leg].set(pick, date);
      }
      return pick;
    });
    if (date >= from) out.push([date, going, ret]);
  }
  return out;
}

function compare(a: string, b: string, counts: Map<string, number>, last: Map<string, string>): number {
  const byCount = (counts.get(a) ?? 0) - (counts.get(b) ?? 0);
  if (byCount !== 0) return byCount;
  const la = last.get(a);
  const lb = last.get(b);
  if (la !== lb) {
    if (la === undefined) return -1;
    if (lb === undefined) return 1;
    return la < lb ? -1 : 1;
  }
  return a < b ? -1 : a > b ? 1 : 0;
}
