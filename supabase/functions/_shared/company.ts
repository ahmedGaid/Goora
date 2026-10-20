// Company network money rules (010 research R3, contracts/company-rules.md).
// Mirror of lib/features/company/domain/company_rules.dart (CompanyRules) —
// both run test/fixtures/company_vectors.json. Times are whole minutes on the
// shared scale of direct_pay.ts (days since 2000-01-01 × 1440); days are the
// same days without the minutes.

export const DUE_AFTER_DAYS = 15; // Q10 default
export const GRACE_DAYS = 7; // Q10 default
export const SUPPRESS_BELOW = 5; // spec clarification

const MINUTES_PER_DAY = 24 * 60;

// Half-open [from, to); to === null = still open.
export type Window = { from: number; to: number | null };

function end(w: Window): number {
  return w.to ?? Infinity;
}

// Sorted, overlapping or touching windows joined, empty ones dropped.
function merge(windows: Window[]): Window[] {
  const sorted = windows.filter((w) => end(w) > w.from).sort((a, b) => a.from - b.from || end(a) - end(b));
  const out: Window[] = [];
  for (const w of sorted) {
    const last = out[out.length - 1];
    if (last !== undefined && w.from <= end(last)) {
      if (end(w) > end(last)) out[out.length - 1] = { from: last.from, to: w.to };
    } else {
      out.push({ from: w.from, to: w.to });
    }
  }
  return out;
}

// Enrollment windows ∩ company active windows, merged, sorted.
export function coverage(enrolled: Window[], companyActive: Window[]): Window[] {
  const pieces: Window[] = [];
  for (const a of enrolled) {
    for (const b of companyActive) {
      const lo = Math.max(a.from, b.from);
      const hi = Math.min(end(a), end(b));
      if (hi > lo) pieces.push({ from: lo, to: hi === Infinity ? null : hi });
    }
  }
  return merge(pieces);
}

export function covered(windows: Window[], minute: number): boolean {
  return windows.some((w) => w.from <= minute && minute < end(w));
}

// For each day of [monthFromDay, monthToDay): distinct people enrolled at any
// moment of that day; the max over the month's days (spec Q2, FR-010).
export function peakEnrolled(byPerson: Record<string, Window[]>, monthFromDay: number, monthToDay: number): number {
  let best = 0;
  for (let d = monthFromDay; d < monthToDay; d++) {
    const lo = d * MINUTES_PER_DAY;
    const hi = lo + MINUTES_PER_DAY;
    let n = 0;
    for (const windows of Object.values(byPerson)) {
      if (windows.some((w) => end(w) > w.from && w.from < hi && end(w) > lo)) n++;
    }
    if (n > best) best = n;
  }
  return best;
}

export function billedSeats(peak: number, minimumSeats: number): number {
  return Math.max(peak, minimumSeats);
}

export function invoiceTotal(billedSeats: number, pricePerSeat: number): number {
  return billedSeats * pricePerSeat;
}

export function dueDay(issueDay: number): number {
  return issueDay + DUE_AFTER_DAYS;
}

// The first day without coverage, from 00:00: the grace days after the due
// day are still covered.
export function suspendFromDay(dueDay: number): number {
  return dueDay + GRACE_DAYS + 1;
}

// [approvedAt, endedAt) minus every [suspendFrom, paidAt) of an invoice still
// unpaid at its suspendFrom.
export function activeWindows(a: {
  approvedAt: number;
  endedAt: number | null;
  overdue: { suspendFrom: number; paidAt: number | null }[];
}): Window[] {
  const gaps = merge(
    a.overdue
      .filter((o) => o.paidAt === null || o.paidAt > o.suspendFrom)
      .map((o) => ({ from: o.suspendFrom, to: o.paidAt })),
  );
  const stop = a.endedAt ?? Infinity;
  const out: Window[] = [];
  let cur = a.approvedAt;
  for (const g of gaps) {
    if (g.from >= stop) break;
    if (g.from > cur) out.push({ from: cur, to: g.from });
    cur = Math.max(cur, end(g));
    if (cur >= stop) break;
  }
  if (cur < stop) out.push({ from: cur, to: a.endedAt });
  return out;
}

// null = "fewer than 5": a figure that could single one person out.
export function suppress(count: number): number | null {
  return count < SUPPRESS_BELOW ? null : count;
}
