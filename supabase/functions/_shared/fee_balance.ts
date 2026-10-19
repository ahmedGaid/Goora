// Pay-later due/overdue rule and the 20-trip bundle (008 research R2, R3).
// Mirror of lib/features/wallet/domain/fee_balance.dart — both run
// test/fixtures/fee_balance_vectors.json. Dates are ISO `yyyy-mm-dd`.
export const SETTLE_AT = 150;
export const MONTH_END_MIN = 30;
export const GRACE_DAYS = 3;
export const BUNDLE_PRICE = 75;
export const BUNDLE_TRIPS = 20;

export interface DayBalance {
  date: string;
  balance: number;
}

const DAY_MS = 24 * 60 * 60 * 1000;
const toMs = (iso: string): number => Date.parse(`${iso}T00:00:00Z`);
const toIso = (ms: number): string => new Date(ms).toISOString().slice(0, 10);

function firstOfNextMonth(iso: string): string {
  const d = new Date(toMs(iso));
  return toIso(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1));
}

export function dueDate(days: DayBalance[], today: string): string | null {
  const t = toMs(today);
  const seen = days.filter((d) => toMs(d.date) <= t);
  if (seen.length === 0 || seen[seen.length - 1].balance >= 0) return null;
  let start = 0;
  seen.forEach((d, i) => {
    if (d.balance >= 0) start = i + 1;
  });
  const run = seen.slice(start);

  let due150: string | null = null;
  for (const d of run) {
    if (-d.balance >= SETTLE_AT) {
      due150 = d.date;
      break;
    }
  }

  let dueMonth: string | null = null;
  let monthStart = `${run[0].date.slice(0, 7)}-01`;
  while (true) {
    const next = firstOfNextMonth(monthStart);
    if (toMs(next) > t) break;
    const monthEnd = toMs(next) - DAY_MS;
    const atEnd = [...run].reverse().find((d) => toMs(d.date) <= monthEnd)!;
    if (-atEnd.balance >= MONTH_END_MIN) {
      dueMonth = next;
      break;
    }
    monthStart = next;
  }

  if (due150 === null) return dueMonth;
  if (dueMonth === null) return due150;
  return toMs(due150) < toMs(dueMonth) ? due150 : dueMonth;
}

export function isOverdue(due: string | null, today: string): boolean {
  return due !== null && (toMs(today) - toMs(due)) / DAY_MS >= GRACE_DAYS;
}

export function useBundle(fee: number, tripsLeft: number): boolean {
  return fee > 0 && tripsLeft > 0;
}
