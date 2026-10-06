// deno-lint-ignore-file no-explicit-any
// Database access shared by commute-day and evening-cutoff (Deno only; not
// loaded by the node tests). Rules live in the pure modules next to this
// file — here rows are loaded, handed to them, and the results written.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { noShowCharge, standing } from "./attendance.ts";
import { findCover } from "./backup.ts";
import type { BackupCandidate, BackupResult, BackupRide, DailyGroup } from "./backup.ts";
import type { Leg } from "./matching.ts";
import { planRotation } from "./rotation.ts";
import { at, cairoNow, monthKey, plusMinutes, weekday } from "./wall_time.ts";

export type Db = SupabaseClient;
export type Row = Record<string, any>;

export const LEGS: Leg[] = ["going", "ret"];

/** A refusal or failure that becomes the HTTP response as is. */
export class HttpError extends Error {
  status: number;
  body: Row;

  constructor(status: number, body: Row) {
    super(String(body.error ?? body.refused ?? "error"));
    this.status = status;
    this.body = body;
  }
}

export async function must<T>(query: PromiseLike<{ data: unknown; error: unknown }>): Promise<T> {
  const { data, error } = await query;
  if (error) throw new HttpError(500, { error: "database", detail: (error as Row).message ?? String(error) });
  return data as T;
}

/** Deterministic ride id (data-model): '<group>:<yyyy-mm-dd>:<going|return>'. */
export const rideIdFor = (groupId: string, date: string, leg: Leg) =>
  `${groupId}:${date}:${leg === "going" ? "going" : "return"}`;

/** Cairo wall time of a timestamptz value. */
export const wall = (ts: string) => cairoNow(new Date(ts));

const hm = (t: string) => t.slice(0, 5);

/** A stop's pickup moment on the ride, delay included. */
export function pickupAt(ride: Row, stopId: string): string {
  const stops = ride.stops as { id: string; time: string }[];
  const stop = stops.find((s) => s.id === stopId) ?? stops[0];
  return plusMinutes(at(ride.ride_date, stop.time), ride.delay_minutes);
}

export const firstPickup = (ride: Row) => pickupAt(ride, (ride.stops as { id: string }[])[0].id);

export async function myGroupId(db: Db, userId: string): Promise<string> {
  const row = await must<Row | null>(
    db.from("group_members").select("group_id").eq("user_id", userId).limit(1).maybeSingle(),
  );
  if (!row) throw new HttpError(409, { error: "noGroup" });
  return row.group_id;
}

export const loadGroup = (db: Db, groupId: string) =>
  must<Row>(db.from("groups").select("*").eq("id", groupId).single());

export async function firstName(db: Db, userId: string | null): Promise<string> {
  if (!userId) return "";
  const p = await must<Row | null>(db.from("profiles").select("first_name").eq("id", userId).maybeSingle());
  return p?.first_name ?? "";
}

export async function notify(db: Db, userIds: string[], kind: string, params: Record<string, string | number>) {
  if (userIds.length === 0) return;
  const text = Object.fromEntries(Object.entries(params).map(([k, v]) => [k, String(v)]));
  await must(db.from("notices").insert(userIds.map((user_id) => ({ user_id, kind, params: text }))));
}

/** Passengers of the ride who are not away on its date and leg. */
export async function ridingPassengers(db: Db, ride: Row): Promise<Row[]> {
  const passengers = await must<Row[]>(db.from("ride_passengers").select("user_id, stop_id").eq("ride_id", ride.id));
  const away = await must<Row[]>(
    db.from("absences").select("user_id").eq("group_id", ride.group_id).eq("ride_date", ride.ride_date)
      .eq("leg", ride.leg),
  );
  return passengers.filter((p) => !away.some((a) => a.user_id === p.user_id));
}

/**
 * Creates the planned rides of [from]..[to] that do not exist yet (rotation
 * from _shared/rotation.ts). Existing rides are never changed, so absences,
 * backups and driver actions survive re-runs.
 */
export async function ensureRides(db: Db, groupId: string, from: string, to: string) {
  const group = await loadGroup(db, groupId);
  const members = await must<Row[]>(
    db.from("group_members").select("user_id, role, legs, seats, days").eq("group_id", groupId),
  );
  const points = await must<Row[]>(
    db.from("group_pickup_points").select("id, label, stop_time").eq("group_id", groupId).order("stop_order"),
  );
  const going = points.map((p) => ({ id: p.id, name: p.label, time: hm(p.stop_time ?? group.going) }));
  const back = [{ id: "work", name: group.destination_area, time: hm(group.return_time) }];
  const boarding = new Map<string, string>();
  for (const m of members) {
    const stop = await must<string | null>(db.rpc("nearest_stop", { p_group: groupId, p_user: m.user_id }));
    boarding.set(m.user_id, stop ?? going[0]?.id ?? "pickup");
  }

  const plan = planRotation(
    {
      days: group.days,
      rotationStart: group.rotation_start,
      members: members.map((m) => ({ id: m.user_id, role: m.role, legs: m.legs, days: m.days })),
    },
    from,
    to,
  );
  for (const [date, ...drivers] of plan) {
    for (const [i, leg] of LEGS.entries()) {
      const driver = drivers[i];
      if (driver === null) continue;
      const id = rideIdFor(groupId, date, leg);
      await must(
        db.from("rides").upsert({
          id,
          group_id: groupId,
          ride_date: date,
          leg,
          planned_driver_id: driver,
          driver_id: driver,
          seats: members.find((m) => m.user_id === driver)?.seats ?? null,
          stops: leg === "going" ? going : back,
        }, { onConflict: "id", ignoreDuplicates: true }),
      );
      // Riders on their legs; drivers ride every leg they do not drive (FR-022a).
      const riding = members.filter((m) =>
        m.user_id !== driver && (m.days ?? group.days).includes(weekday(date)) &&
        (m.role === "driver" || m.legs.includes(leg))
      );
      if (riding.length === 0) continue;
      await must(
        db.from("ride_passengers").upsert(
          riding.map((m) => ({ ride_id: id, user_id: m.user_id, stop_id: leg === "going" ? boarding.get(m.user_id) : "work" })),
          { onConflict: "ride_id,user_id", ignoreDuplicates: true },
        ),
      );
    }
  }
}

/**
 * Backup search for a ride whose driver is away (§6.6). Writes the cover (or
 * no cover) to the ride and backup_assignments and tells the passengers.
 */
export async function runBackup(db: Db, rideId: string): Promise<BackupResult> {
  const ride = await must<Row>(db.from("rides").select("*").eq("id", rideId).single());
  const input = await must<{ ride: BackupRide; group: DailyGroup; candidates: BackupCandidate[] }>(
    db.rpc("backup_input", { p_ride: rideId }),
  );
  // People away on that leg do not ride, so the cover needs no seat for them.
  const riding = await ridingPassengers(db, ride);
  const search = { ...input.ride, passengers: input.ride.passengers.filter((p) => riding.some((r) => r.user_id === p.memberId)) };
  const result = findCover(search, input.group, input.candidates);

  await must(db.from("rides").update({ driver_id: result.cover, backup_step: result.step }).eq("id", rideId));
  await must(
    db.from("backup_assignments").upsert({
      ride_id: rideId,
      planned_id: ride.planned_driver_id,
      cover_id: result.cover,
      step: result.step,
      decided_at: new Date().toISOString(),
    }),
  );
  if (result.cover) {
    const driver = await firstName(db, result.cover);
    await notify(db, [...riding.map((r) => r.user_id), result.cover], "backupCover", {
      driver,
      day: ride.ride_date,
      leg: ride.leg,
    });
  }
  return result;
}

export async function notifyNoCover(db: Db, ride: Row) {
  const riding = await ridingPassengers(db, ride);
  const driver = await firstName(db, ride.planned_driver_id);
  await notify(db, riding.map((r) => r.user_id), "noCover", { driver, day: ride.ride_date, leg: ride.leg });
}

const nextMonth = (key: string) => {
  const [y, m] = key.split("-").map(Number);
  return m === 12 ? `${y + 1}-01-01` : `${y}-${String(m + 1).padStart(2, "0")}-01`;
};

/**
 * Settles the driver's marks: no-shows pay their share to the driver and
 * count toward the month's standing (2 → warning, 3 → removal); once the trip
 * is over everyone else who rode keeps a "kept" event.
 */
export async function settleRide(db: Db, ride: Row, share: number, over: boolean) {
  const outcomes = await must<Row[]>(db.from("passenger_outcomes").select("user_id, outcome").eq("ride_id", ride.id));
  for (const p of await ridingPassengers(db, ride)) {
    const mark = outcomes.find((o) => o.user_id === p.user_id)?.outcome ?? "waiting";
    if (mark === "noShow") {
      const charged = await must<Row[]>(
        db.from("charges").upsert({
          user_id: p.user_id,
          ride_id: ride.id,
          reason: "noShow",
          amount: noShowCharge(share),
          owed_to: ride.driver_id,
        }, { onConflict: "user_id,ride_id,reason", ignoreDuplicates: true }).select(),
      );
      if (charged.length === 0) continue; // settled before
      await must(
        db.from("reliability_events").upsert({ user_id: p.user_id, ride_id: ride.id, ride_date: ride.ride_date, kind: "noShow" }),
      );
      await notify(db, [p.user_id], "noShowCharged", { amount: noShowCharge(share), day: ride.ride_date });
      const month = monthKey(ride.ride_date);
      const { count } = await db.from("reliability_events").select("*", { count: "exact", head: true })
        .eq("user_id", p.user_id).eq("kind", "noShow").gte("ride_date", `${month}-01`).lt("ride_date", nextMonth(month));
      const s = standing(count ?? 0);
      if (s === "warning") await notify(db, [p.user_id], "noShowWarning", {});
      if (s === "removal") {
        await must(db.from("group_members").delete().eq("group_id", ride.group_id).eq("user_id", p.user_id));
        await notify(db, [p.user_id], "removed", {});
      }
    } else if (over) {
      await must(
        db.from("reliability_events").upsert(
          { user_id: p.user_id, ride_id: ride.id, ride_date: ride.ride_date, kind: "kept" },
          { onConflict: "user_id,ride_id", ignoreDuplicates: true },
        ),
      );
    }
  }
  if (over && ride.driver_id) {
    await must(
      db.from("reliability_events").upsert(
        { user_id: ride.driver_id, ride_id: ride.id, ride_date: ride.ride_date, kind: "kept" },
        { onConflict: "user_id,ride_id", ignoreDuplicates: true },
      ),
    );
  }
}
