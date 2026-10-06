// Cairo wall-clock time without time zones (003 research R2): dates are
// "YYYY-MM-DD", moments "YYYY-MM-DDTHH:MM:SS". Both compare correctly as
// strings. Mirror of lib/core/time/{calendar_date,wall_time}.dart.

export type Day = "sun" | "mon" | "tue" | "wed" | "thu" | "fri" | "sat";
export const DAYS: Day[] = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

const DAY_MS = 86_400_000;

const toUtc = (date: string) => {
  const [y, m, d] = date.split("-").map(Number);
  return Date.UTC(y, m - 1, d);
};

const isoDate = (ms: number) => new Date(ms).toISOString().slice(0, 10);

export const addDays = (date: string, days: number) => isoDate(toUtc(date) + days * DAY_MS);

/** Whole days from `a` to `b` (negative when `b` is earlier). */
export const daysUntil = (a: string, b: string) => Math.round((toUtc(b) - toUtc(a)) / DAY_MS);

export const weekday = (date: string): Day => DAYS[new Date(toUtc(date)).getUTCDay()];

export const monthKey = (date: string) => date.slice(0, 7);

/** `date` at "HH:MM" (+ seconds). */
export const at = (date: string, hm: string, second = 0) => `${date}T${hm}:${String(second).padStart(2, "0")}`;

export const dateOf = (wall: string) => wall.slice(0, 10);

const toMs = (wall: string) => {
  const [h, m, s] = wall.slice(11).split(":").map(Number);
  return toUtc(dateOf(wall)) + ((h * 60 + m) * 60 + s) * 1000;
};

export const plusSeconds = (wall: string, seconds: number) =>
  new Date(toMs(wall) + seconds * 1000).toISOString().slice(0, 19);

export const plusMinutes = (wall: string, minutes: number) => plusSeconds(wall, minutes * 60);

/** Seconds from `a` to `b` (negative when `b` is earlier). */
export const secondsUntil = (a: string, b: string) => (toMs(b) - toMs(a)) / 1000;

export const isBefore = (a: string, b: string) => a < b;

/** Cairo wall time of an instant: what the Edge Functions use for `now()`. */
export function cairoNow(instant: Date = new Date()): string {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat("en-CA", {
      timeZone: "Africa/Cairo",
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    }).formatToParts(instant).map((p) => [p.type, p.value]),
  );
  return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}`;
}
