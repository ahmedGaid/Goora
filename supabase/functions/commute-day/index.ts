// POST /functions/v1/commute-day — every daily action of a member
// (specs/003-daily-commute/contracts/edge-functions.md). Thin adapter: auth,
// loading and writing here and in ../_shared/daily_store.ts; every rule in the
// pure ../_shared/*.ts modules the app's Dart rules are tested against.
// Written, not executed: no Supabase project exists yet.
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  canCancel,
  canMarkNoShow,
  cancelCharge,
  cancelKind,
  canUndo,
  isLate,
  noShowAvailableAt,
} from "../_shared/attendance.ts";
import type { Leg } from "../_shared/matching.ts";
import {
  type Db,
  ensureRides,
  firstName,
  HttpError,
  loadGroup,
  must,
  myGroupId,
  notify,
  notifyNoCover,
  pickupAt,
  rideIdFor,
  ridingPassengers,
  type Row,
  runBackup,
  settleRide,
  wall,
} from "../_shared/daily_store.ts";
import { addDays, cairoNow, DAYS, secondsUntil, weekday } from "../_shared/wall_time.ts";

interface Ctx {
  /** Service role: writes the caller may not make directly, and notices. */
  admin: Db;
  /** The caller's own JWT: reads and writes their RLS policies allow. */
  asUser: Db;
  uid: string;
  /** Cairo wall time (research R2). */
  now: string;
}

type Params = Record<string, unknown>;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

const refuse = (refused: string, extra: Row = {}) => new HttpError(409, { refused, ...extra });

const isLeg = (v: unknown): v is Leg => v === "going" || v === "ret";

function legsOf(p: Params): Leg[] {
  const legs = p.legs;
  if (!Array.isArray(legs) || legs.length === 0 || !legs.every(isLeg)) throw new HttpError(400, { error: "legs" });
  return legs;
}

function dateOf(p: Params): string {
  if (typeof p.date !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(p.date)) throw new HttpError(400, { error: "date" });
  return p.date;
}

function rideIdOf(p: Params): string {
  if (typeof p.rideId !== "string") throw new HttpError(400, { error: "rideId" });
  return p.rideId;
}

/** The ride, readable by the caller (RLS: own group) and driven by them. */
async function drivenRide(c: Ctx, rideId: string): Promise<Row> {
  const ride = await must<Row | null>(c.asUser.from("rides").select("*").eq("id", rideId).maybeSingle());
  if (!ride) throw new HttpError(404, { error: "ride" });
  if (ride.driver_id !== c.uid) throw new HttpError(403, { error: "notDriver" });
  return ride;
}

// Rider actions (also off-duty drivers) ------------------------------------------

async function cancel(c: Ctx, date: string, legs: Leg[]) {
  const groupId = await myGroupId(c.asUser, c.uid);
  const group = await loadGroup(c.asUser, groupId);
  await ensureRides(c.admin, groupId, date, date);
  const charges: Row[] = [];
  for (const leg of legs) {
    const id = rideIdFor(groupId, date, leg);
    const ride = await must<Row | null>(c.asUser.from("rides").select("*").eq("id", id).maybeSingle());
    const seat = ride &&
      await must<Row | null>(
        c.asUser.from("ride_passengers").select("stop_id").eq("ride_id", id).eq("user_id", c.uid).maybeSingle(),
      );
    if (!ride || !seat) throw refuse("notOnRide");
    if (!canCancel(pickupAt(ride, seat.stop_id), c.now)) throw refuse("afterPickup");

    // The rules decide the kind from the Cairo clock; written with the service
    // role so the database stamp (for direct inserts) does not race 9 PM.
    const { error } = await c.admin.from("absences").insert({
      user_id: c.uid,
      group_id: groupId,
      ride_date: date,
      leg,
      kind: cancelKind(date, c.now),
      made_at: new Date().toISOString(),
    });
    if (error?.code === "23505") continue; // already off that trip
    if (error) throw new HttpError(500, { error: "database" });

    const amount = cancelCharge(date, c.now, group.price);
    if (amount === 0) continue;
    await must(c.admin.from("charges").insert({ user_id: c.uid, ride_id: id, reason: "lateCancel", amount, owed_to: ride.driver_id }));
    await must(c.admin.from("reliability_events").upsert({ user_id: c.uid, ride_id: id, ride_date: date, kind: "lateCancel" }));
    await notify(c.admin, [c.uid], "lateCancelCharged", { amount, driver: await firstName(c.admin, ride.driver_id), day: date });
    charges.push({ rideId: id, amount, reason: "lateCancel" });
  }
  return { charges };
}

async function undo(c: Ctx, date: string) {
  const groupId = await myGroupId(c.asUser, c.uid);
  const group = await loadGroup(c.asUser, groupId);
  const absences = await must<Row[]>(
    c.asUser.from("absences").select("*").eq("user_id", c.uid).eq("ride_date", date).eq("driving", false),
  );
  const { count } = await c.admin.from("waitlist").select("*", { count: "exact", head: true })
    .match({ origin_area: group.origin_area, destination_area: group.destination_area });

  const rideIds: string[] = [];
  for (const a of absences) {
    const id = rideIdFor(groupId, date, a.leg);
    const ride = await must<Row>(c.asUser.from("rides").select("*").eq("id", id).single());
    const seat = await must<Row>(
      c.asUser.from("ride_passengers").select("stop_id").eq("ride_id", id).eq("user_id", c.uid).single(),
    );
    const result = canUndo(a, c.now, pickupAt(ride, seat.stop_id), (count ?? 0) > 0 || a.seat_taken);
    if (result === "refusedSeatTaken") throw refuse("seatTaken");
    if (result === "refusedTooLate") throw refuse("tooLate");
    rideIds.push(id);
  }
  // A late cancel undone before pickup removes its charge (founder decision 2026-10-06).
  await must(c.admin.from("absences").delete().eq("user_id", c.uid).eq("ride_date", date).eq("driving", false));
  if (rideIds.length > 0) {
    await must(c.admin.from("charges").delete().eq("user_id", c.uid).eq("reason", "lateCancel").in("ride_id", rideIds));
    await must(
      c.admin.from("reliability_events").delete().eq("user_id", c.uid).eq("kind", "lateCancel").in("ride_id", rideIds),
    );
  }
  return { ok: true };
}

/** Every trip of next week (Sunday–Saturday) off. */
async function notNextWeek(c: Ctx) {
  const today = c.now.slice(0, 10);
  const sunday = addDays(today, 7 - DAYS.indexOf(weekday(today)));
  const groupId = await myGroupId(c.asUser, c.uid);
  await ensureRides(c.admin, groupId, sunday, addDays(sunday, 6));
  const charges: Row[] = [];
  for (let i = 0; i < 7; i++) {
    const date = addDays(sunday, i);
    const seats = await must<Row[]>(
      c.asUser.from("ride_passengers").select("ride_id, rides!inner(ride_date, leg)").eq("user_id", c.uid)
        .eq("rides.ride_date", date),
    );
    const legs = seats.map((s) => s.rides.leg as Leg);
    if (legs.length > 0) charges.push(...(await cancel(c, date, legs)).charges);
  }
  return { charges };
}

// Driver actions -------------------------------------------------------------------

async function setConfirmed(c: Ctx, rideId: string, confirmed: boolean) {
  const ride = await drivenRide(c, rideId);
  await must(c.admin.from("rides").update({ confirmed }).eq("id", rideId));
  const riding = await ridingPassengers(c.admin, ride);
  await notify(c.admin, riding.map((r) => r.user_id), confirmed ? "driverConfirmed" : "driverUnconfirmed", {
    driver: await firstName(c.admin, c.uid),
    day: ride.ride_date,
    leg: ride.leg,
  });
  return { ok: true };
}

async function delay(c: Ctx, rideId: string, minutes: unknown) {
  if (minutes !== 5 && minutes !== 10 && minutes !== 15) throw new HttpError(400, { error: "minutes" });
  const ride = await drivenRide(c, rideId);
  if (ride.started_at) throw refuse("tripStarted");
  await must(c.admin.from("rides").update({ delay_minutes: minutes }).eq("id", rideId));
  const moved = { ...ride, delay_minutes: minutes };
  const newTimes = (ride.stops as { id: string }[]).map((s) => ({ stopId: s.id, at: pickupAt(moved, s.id) }));
  const riding = await ridingPassengers(c.admin, ride);
  for (const r of riding) {
    await notify(c.admin, [r.user_id], "delay", { minutes, time: pickupAt(moved, r.stop_id).slice(11, 16), leg: ride.leg });
  }
  return { newTimes };
}

async function cantDrive(c: Ctx, date: string, legs: Leg[]) {
  const groupId = await myGroupId(c.asUser, c.uid);
  await ensureRides(c.admin, groupId, date, date);
  const covers: Partial<Record<Leg, Row | null>> = {};
  for (const leg of legs) {
    const id = rideIdFor(groupId, date, leg);
    const ride = await must<Row | null>(c.asUser.from("rides").select("*").eq("id", id).maybeSingle());
    if (!ride || (ride.planned_driver_id !== c.uid && ride.driver_id !== c.uid)) throw new HttpError(403, { error: "notDriver" });
    if (ride.started_at) throw refuse("tripStarted");

    const late = isLate(date, c.now);
    await must(
      c.admin.from("absences").upsert({
        user_id: c.uid,
        group_id: groupId,
        ride_date: date,
        leg,
        kind: cancelKind(date, c.now),
        driving: true,
        made_at: new Date().toISOString(),
      }, { onConflict: "user_id,ride_date,leg", ignoreDuplicates: true }),
    );
    // Drivers owe no money; a late "can't drive" only moves reliability.
    if (late) {
      await must(c.admin.from("reliability_events").upsert({ user_id: c.uid, ride_id: id, ride_date: date, kind: "lateCantDrive" }));
    }
    const result = await runBackup(c.admin, id);
    // Before 9 PM the evening job searches once more; after it there is no later chance.
    if (!result.cover && late) await notifyNoCover(c.admin, ride);
    covers[leg] = result.cover ? { memberId: result.cover, step: result.step } : null;
  }
  return { cover: covers[legs[0]] ?? null, legs: covers };
}

async function arrive(c: Ctx, rideId: string, stopId: unknown) {
  const ride = await drivenRide(c, rideId);
  if (!(ride.stops as { id: string }[]).some((s) => s.id === stopId)) throw new HttpError(400, { error: "stopId" });
  // RLS: drivers write check-ins for rides they drive (FR-032).
  const { error } = await c.asUser.from("pickup_check_ins").insert({ ride_id: rideId, stop_id: stopId });
  if (error && error.code !== "23505") throw new HttpError(500, { error: "database" });
  const checkIn = await must<Row>(
    c.asUser.from("pickup_check_ins").select("arrived_at").eq("ride_id", rideId).eq("stop_id", stopId).single(),
  );
  if (!error) {
    const boarding = (await ridingPassengers(c.admin, ride)).filter((r) => r.stop_id === stopId);
    await notify(c.admin, boarding.map((r) => r.user_id), "driverArrived", {
      driver: await firstName(c.admin, c.uid),
      stop: String(stopId),
    });
  }
  return { noShowAvailableAt: noShowAvailableAt(wall(checkIn.arrived_at)) };
}

async function mark(c: Ctx, rideId: string, personId: unknown, outcome: unknown) {
  if (outcome !== "waiting" && outcome !== "pickedUp" && outcome !== "noShow") throw new HttpError(400, { error: "outcome" });
  const ride = await drivenRide(c, rideId);
  if (ride.started_at) throw refuse("tripStarted");
  const seat = (await ridingPassengers(c.admin, ride)).find((r) => r.user_id === personId);
  if (!seat) throw refuse("notOnRide");
  if (outcome === "noShow") {
    const checkIn = await must<Row | null>(
      c.admin.from("pickup_check_ins").select("arrived_at").eq("ride_id", rideId).eq("stop_id", seat.stop_id).maybeSingle(),
    );
    // Not arrived yet: the full 5-minute wait is still ahead.
    if (!checkIn) throw refuse("tooEarly", { secondsLeft: null });
    const arrivedAt = wall(checkIn.arrived_at);
    if (!canMarkNoShow(arrivedAt, c.now)) {
      throw refuse("tooEarly", { secondsLeft: secondsUntil(c.now, noShowAvailableAt(arrivedAt)) });
    }
  }
  await must(
    c.admin.from("passenger_outcomes").upsert({ ride_id: rideId, user_id: personId, outcome, marked_at: new Date().toISOString() }),
  );
  return { ok: true };
}

async function startOrEnd(c: Ctx, rideId: string, end: boolean) {
  const ride = await drivenRide(c, rideId);
  const group = await loadGroup(c.admin, ride.group_id);
  const column = end ? "ended_at" : "started_at";
  if (!ride[column]) await must(c.admin.from("rides").update({ [column]: new Date().toISOString() }).eq("id", rideId));
  // Marks are final once the trip starts: no-shows are charged then; "kept"
  // events wait for the end.
  await settleRide(c.admin, ride, group.price, end);
  return { ok: true };
}

async function sos(c: Ctx, rideId: unknown) {
  const contacts = await must<Row[]>(c.asUser.from("trusted_contacts").select("id").eq("user_id", c.uid));
  await must(
    c.asUser.from("sos_alerts").insert({
      user_id: c.uid,
      ride_id: typeof rideId === "string" ? rideId : null,
      contact_ids: contacts.map((x) => x.id),
    }),
  );
  // Real SMS to the contacts waits for a provider (research R10); recorded only.
  if (contacts.length > 0) await notify(c.admin, [c.uid], "sosSent", { count: contacts.length });
  return { alerted: contacts.length };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const url = Deno.env.get("SUPABASE_URL")!;
  const jwt = req.headers.get("Authorization")?.replace("Bearer ", "") ?? "";
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: auth, error: authError } = await admin.auth.getUser(jwt);
  if (authError || !auth.user) return json({ error: "unauthorized" }, 401);

  const asUser = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
  });
  const c: Ctx = { admin, asUser, uid: auth.user.id, now: cairoNow() };

  let p: Params;
  try {
    p = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }

  try {
    switch (p.action) {
      case "cancel":
        return json(await cancel(c, dateOf(p), legsOf(p)));
      case "undo":
        return json(await undo(c, dateOf(p)));
      case "notNextWeek":
        return json(await notNextWeek(c));
      case "confirm":
      case "unconfirm":
        return json(await setConfirmed(c, rideIdOf(p), p.action === "confirm"));
      case "delay":
        return json(await delay(c, rideIdOf(p), p.minutes));
      case "cantDrive":
        return json(await cantDrive(c, dateOf(p), legsOf(p)));
      case "arrive":
        return json(await arrive(c, rideIdOf(p), p.stopId));
      case "mark":
        return json(await mark(c, rideIdOf(p), p.personId, p.outcome));
      case "start":
      case "end":
        return json(await startOrEnd(c, rideIdOf(p), p.action === "end"));
      case "sos":
        return json(await sos(c, p.rideId));
      default:
        return json({ error: "action" }, 400);
    }
  } catch (e) {
    if (e instanceof HttpError) return json(e.body, e.status);
    return json({ error: "internal" }, 500);
  }
});
