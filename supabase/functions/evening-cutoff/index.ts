// POST /functions/v1/evening-cutoff — the 9 PM job (FR-033,
// specs/003-daily-commute/contracts/edge-functions.md). Called by pg_cron at
// 18:00 and 19:00 UTC (migration 20261006000000); does its work only when it
// is 21:xx in Cairo, so Egypt's summer time needs no second schedule.
// Idempotent per (date, step): each step claims a cutoff_runs row first and
// skips when the row exists, so re-running the same evening changes nothing.
// Written, not executed: no Supabase project exists yet.
import { createClient } from "npm:@supabase/supabase-js@2";
import { driverNoShow } from "../_shared/attendance.ts";
import {
  type Db,
  ensureRides,
  firstPickup,
  firstName,
  HttpError,
  must,
  notify,
  notifyNoCover,
  ridingPassengers,
  type Row,
  runBackup,
  settleRide,
} from "../_shared/daily_store.ts";
import { addDays, cairoNow } from "../_shared/wall_time.ts";

/** Rides are planned this many days ahead each evening. */
const PLAN_DAYS = 7;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

async function claim(db: Db, date: string, step: string): Promise<boolean> {
  const rows = await must<Row[]>(
    db.from("cutoff_runs").upsert({ run_date: date, step }, { onConflict: "run_date,step", ignoreDuplicates: true })
      .select(),
  );
  return rows.length > 0;
}

/**
 * Today's trips are over by 9 PM: a driver who never checked in nor cancelled
 * is a no-show (FR-010), and marks left without "End trip" are settled (R11).
 */
async function settleToday(db: Db, today: string, now: string) {
  const rides = await must<Row[]>(
    db.from("rides").select("*, groups(price)").eq("ride_date", today).not("driver_id", "is", null),
  );
  for (const ride of rides) {
    const { count: checkIns } = await db.from("pickup_check_ins").select("*", { count: "exact", head: true })
      .eq("ride_id", ride.id);
    const { count: away } = await db.from("absences").select("*", { count: "exact", head: true })
      .eq("user_id", ride.driver_id).eq("ride_date", today).eq("leg", ride.leg);
    if (driverNoShow(firstPickup(ride), now, (checkIns ?? 0) > 0, (away ?? 0) > 0)) {
      await must(
        db.from("reliability_events").upsert({ user_id: ride.driver_id, ride_id: ride.id, ride_date: today, kind: "noShow" }),
      );
      const riding = await ridingPassengers(db, ride);
      await notify(db, riding.map((r) => r.user_id), "driverNoShow", { driver: await firstName(db, ride.driver_id) });
      continue;
    }
    if (!ride.ended_at) await settleRide(db, ride, ride.groups.price, true);
  }
}

/** Seats freed by free cancels go to the corridor waitlist, oldest first. */
async function offerSeats(db: Db, tomorrow: string) {
  const freed = await must<Row[]>(
    db.from("absences").select("id, group_id, leg, groups(origin_area, destination_area, going, return_time)")
      .eq("ride_date", tomorrow).eq("kind", "freeCancel").eq("driving", false).eq("seat_taken", false),
  );
  const offered = new Set<string>();
  for (const a of freed) {
    const corridor = { origin_area: a.groups.origin_area, destination_area: a.groups.destination_area };
    const queue = await must<Row[]>(db.from("waitlist").select("user_id").match(corridor).order("created_at"));
    const next = queue.find((w) => !offered.has(`${w.user_id}|${a.leg}`));
    if (!next) continue;
    offered.add(`${next.user_id}|${a.leg}`);
    await must(db.from("absences").update({ seat_taken: true }).eq("id", a.id));
    await notify(db, [next.user_id], "seatOffered", {
      day: tomorrow,
      leg: a.leg,
      time: String(a.leg === "going" ? a.groups.going : a.groups.return_time).slice(0, 5),
    });
  }
}

/** Tomorrow's legs whose driver is away and not yet covered: search once more; still none → noCover. */
async function coverTomorrow(db: Db, tomorrow: string) {
  const rides = await must<Row[]>(db.from("rides").select("*").eq("ride_date", tomorrow));
  for (const ride of rides) {
    const { count: away } = await db.from("absences").select("*", { count: "exact", head: true })
      .eq("user_id", ride.planned_driver_id).eq("ride_date", tomorrow).eq("leg", ride.leg).eq("driving", true);
    const uncovered = ride.driver_id === null || ride.driver_id === ride.planned_driver_id;
    if ((away ?? 0) === 0 || !uncovered) continue;
    const result = await runBackup(db, ride.id);
    if (!result.cover) await notifyNoCover(db, ride);
  }
}

Deno.serve(async (req) => {
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (req.headers.get("Authorization") !== `Bearer ${key}`) return json({ error: "unauthorized" }, 401);
  const now = cairoNow();
  if (now.slice(11, 13) !== "21") return json({ skipped: "notNinePmInCairo", now });

  const db = createClient(Deno.env.get("SUPABASE_URL")!, key);
  const today = now.slice(0, 10);
  const tomorrow = addDays(today, 1);
  const ran: string[] = [];
  try {
    if (await claim(db, today, "settle")) {
      await settleToday(db, today, now);
      ran.push("settle");
    }
    if (await claim(db, tomorrow, "plan")) {
      for (const g of await must<Row[]>(db.from("groups").select("id"))) {
        await ensureRides(db, g.id, tomorrow, addDays(tomorrow, PLAN_DAYS - 1));
      }
      ran.push("plan");
    }
    if (await claim(db, tomorrow, "waitlist")) {
      await offerSeats(db, tomorrow);
      ran.push("waitlist");
    }
    if (await claim(db, tomorrow, "backup")) {
      await coverTomorrow(db, tomorrow);
      ran.push("backup");
    }
  } catch (e) {
    if (e instanceof HttpError) return json({ ...e.body, ran }, e.status);
    return json({ error: "internal", ran }, 500);
  }
  return json({ now, ran });
});
