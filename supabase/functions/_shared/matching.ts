// Matching rules (brief §6.3 + founder decisions 2026-10-05).
// Mirror of lib/features/commute/domain/matching_service.dart — both run
// test/fixtures/matching_vectors.json. Erasable TypeScript only, so it runs
// under Deno (Edge Functions) and Node's type stripping (tests).

export type Leg = "going" | "ret";
export type Role = "driver" | "rider";
export type Point = [number, number];

export interface Member {
  id: string;
  role: Role;
  isWoman: boolean;
  company: string | null;
  compound: string | null;
  rating: number;
  reliability: number;
  legs: Leg[];
}

export interface Group {
  id: string;
  destination: string;
  destinationPoint: Point;
  pickupPoints: Point[];
  going: string;
  ret: string;
  days: string[];
  members: Member[];
  freeSeatsGoing: number;
  freeSeatsReturn: number;
  detourMinutes: number;
  womenOnly: boolean;
  sameCompanyOnly: string | null;
  sameCompoundOnly: string | null;
}

export interface Seeker {
  role: Role;
  home: Point;
  work: Point;
  departure: string;
  ret: string;
  days: string[];
  legs: Leg[];
  isWoman: boolean;
  company: string | null;
  compound: string | null;
  womenOnly: boolean;
  sameCompanyOnly: boolean;
  sameCompoundOnly: boolean;
}

export interface Limits {
  pickup: number;
  detour: number;
  time: number;
  dest: number;
}

export const DEFAULT_LIMITS: Limits = { pickup: 1000, detour: 10, time: 20, dest: 1500 };

export type ReasonKind =
  | "destination"
  | "departure"
  | "pickup"
  | "companyReturn"
  | "company"
  | "compound"
  | "ret"
  | "days"
  | "rating";

/** `value`: minutes, metres (rounded to 50), shared days or rating; `area` for destination. */
export interface Reason {
  kind: ReasonKind;
  value?: number;
  area?: string;
}

export interface GroupMatch {
  groupId: string;
  legs: Leg[];
  score: number;
  reasons: Reason[];
  /** Metres from the seeker's home to the nearest pickup (003 backup detour). */
  pickupMeters: number;
}

export interface MatchResult {
  main: GroupMatch | null;
  returnMatch: GroupMatch | null;
  alternatives: GroupMatch[];
}

const EARTH_RADIUS_M = 6371000;

export function distanceMeters(a: Point, b: Point): number {
  const rad = (d: number) => (d * Math.PI) / 180;
  const dLat = rad(b[0] - a[0]);
  const dLng = rad(b[1] - a[1]);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a[0])) * Math.cos(rad(b[0])) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(h));
}

const minutes = (hm: string) => {
  const [h, m] = hm.split(":").map(Number);
  return h * 60 + m;
};

const linear = (weight: number, value: number, limit: number) =>
  weight * Math.min(1, Math.max(0, 1 - value / limit));

function privacyCompatible(s: Seeker, g: Group): boolean {
  if (g.womenOnly && !s.isWoman) return false;
  if (s.womenOnly && g.members.some((m) => !m.isWoman)) return false;
  if (g.sameCompanyOnly !== null && g.sameCompanyOnly !== s.company) return false;
  if (g.sameCompoundOnly !== null && g.sameCompoundOnly !== s.compound) return false;
  if (s.sameCompanyOnly && (s.company === null || g.members.some((m) => m.company !== s.company))) return false;
  if (s.sameCompoundOnly && (s.compound === null || g.members.some((m) => m.compound !== s.compound))) return false;
  return true;
}

export function evaluate(s: Seeker, g: Group, limits: Limits = DEFAULT_LIMITS): GroupMatch | null {
  const destM = distanceMeters(s.work, g.destinationPoint);
  if (destM > limits.dest) return null;
  const pickupM = Math.min(...g.pickupPoints.map((p) => distanceMeters(s.home, p)));
  if (pickupM > limits.pickup || g.detourMinutes > limits.detour) return null;
  const shared = s.days.filter((d) => g.days.includes(d)).length;
  if (shared === 0 || !privacyCompatible(s, g)) return null;

  const depDiff = Math.abs(minutes(s.departure) - minutes(g.going));
  const retDiff = Math.abs(minutes(s.ret) - minutes(g.ret));
  const legs = s.legs.filter((leg) => {
    const diff = leg === "going" ? depDiff : retDiff;
    const capacity = s.role === "rider"
      ? (leg === "going" ? g.freeSeatsGoing : g.freeSeatsReturn) > 0
      : g.members.some((m) => m.role === "rider" && m.legs.includes(leg));
    return diff <= limits.time && capacity;
  });
  if (legs.length === 0) return null;

  const community = g.members.some((m) =>
      (s.company !== null && m.company === s.company) || (s.compound !== null && m.compound === s.compound)
    )
    ? 10
    : 0;
  const n = g.members.length;
  const avgRating = n === 0 ? 0 : g.members.reduce((a, m) => a + m.rating, 0) / n;
  const avgReliability = n === 0 ? 0 : g.members.reduce((a, m) => a + m.reliability, 0) / n;

  const f = {
    destination: linear(25, destM, limits.dest),
    departure: linear(20, depDiff, limits.time),
    pickup: linear(15, pickupM, limits.pickup),
    ret: linear(10, retDiff, limits.time),
    days: (10 * shared) / s.days.length,
    community,
    rating: (10 * (avgRating / 5 + avgReliability / 100)) / 2,
  };
  const total = f.destination + f.departure + f.pickup + f.ret + f.days + f.community + f.rating;

  const sameCompany = s.company !== null && g.members.some((m) => m.company === s.company);
  const ranked: [number, Reason][] = [
    [f.destination, { kind: "destination", area: g.destination }],
    [f.departure, { kind: "departure", value: depDiff }],
    [f.pickup, { kind: "pickup", value: Math.round(pickupM / 50) * 50 }],
  ];
  if (f.community > 0 && f.ret > 0) {
    ranked.push([f.community + f.ret, { kind: sameCompany ? "companyReturn" : "compound" }]);
  } else {
    if (f.community > 0) ranked.push([f.community, { kind: sameCompany ? "company" : "compound" }]);
    ranked.push([f.ret, { kind: "ret" }]);
  }
  ranked.push([f.days, { kind: "days", value: shared }]);
  ranked.push([f.rating, { kind: "rating", value: Math.round(avgRating * 10) / 10 }]);
  // Array.prototype.sort is stable: equal points keep the order above.
  const reasons = ranked.filter(([p]) => p > 0).sort((a, b) => b[0] - a[0]).slice(0, 4).map(([, r]) => r);

  return { groupId: g.id, legs, score: Math.round(total), reasons, pickupMeters: pickupM };
}

export function matchGroups(s: Seeker, groups: Group[], limits: Limits = DEFAULT_LIMITS): MatchResult {
  const candidates = groups.map((g) => evaluate(s, g, limits)).filter((m): m is GroupMatch => m !== null);
  const byScore = (a: GroupMatch, b: GroupMatch) => b.score - a.score;

  const full = candidates.filter((m) => s.legs.every((l) => m.legs.includes(l))).sort(byScore);
  if (full.length > 0) return { main: full[0], returnMatch: null, alternatives: full.slice(1) };

  const bestFor = (leg: Leg) => candidates.filter((m) => m.legs.includes(leg)).sort(byScore)[0] ?? null;
  const perLeg = s.legs.map((leg) => [leg, bestFor(leg)] as const);
  if (perLeg.some(([, m]) => m === null)) return { main: null, returnMatch: null, alternatives: [] };

  const going = perLeg.find(([leg]) => leg === "going")?.[1] ?? null;
  const ret = perLeg.find(([leg]) => leg === "ret")?.[1] ?? null;
  const main = (going ?? ret)!;
  return { main, returnMatch: ret !== null && ret !== main ? ret : null, alternatives: [] };
}
