import { Op, QueryTypes } from "sequelize";
import { secondarySequelize } from "../../sequelize";
import { ChatLoad, ChatTrip } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import User from "../../models/User";
import Role from "../../models/Role";
import Group from "../../models/Group";
import GroupUser from "../../models/GroupUser";
import { byLeg, HANDED_OVER } from "./legs";

// Who and what is free: the fleet's trucks, trailers and drivers (yard DB, read only) against the legs
// they're on here, plus where trailers are by the yard's security gate log (daily_vehicle_entries:
// entry / depart, loaded / empty). Also the in-yard history of a load and the "already on a load"
// warning dispatch sees while filling in a leg.

/** A leg is using its truck / trailer / driver right now */
export const ON_LOAD = ["planned", "accepted", "started", "rolling", "on_hold"];
/** Lined up for them, not sent yet */
const LINED_UP = ["scheduled", "offered"];

export interface LegRef {
  loadId: number | null;
  tripId: number;
  tripNo: string | null;
  invoiceNo: string | null;
  status: string;
  legNo: number;
}

export interface TruckRow {
  id: number;
  number: string;
  state: "on_load" | "lined_up" | "free";
  leg: LegRef | null;
  drivers: { id: string; name: string }[];
}
export interface TrailerRow {
  id: number;
  number: string;
  type: string | null;
  readiness: string | null;
  state: "on_load" | "waiting_transfer" | "in_yard" | "out" | "unknown";
  leg: LegRef | null;
  /** Last gate event */
  gate: { status: "entry" | "depart"; loaded: string | null; at: Date } | null;
}
export interface DriverRow {
  yardId: number;
  name: string;
  profileId: string | null;
  truck: string | null;
  state: "on_load" | "lined_up" | "free";
  leg: LegRef | null;
  /** How many loads are lined up after the current one, and #1 */
  lineup: number;
  next: LegRef | null;
}

const yard = <T extends object>(sql: string, replacements: Record<string, any> = {}) =>
  secondarySequelize.query<T>(sql, { replacements, type: QueryTypes.SELECT });

const ids = (csv: string | null | undefined) =>
  String(csv || "")
    .split(",")
    .map((x) => Number(x.trim()))
    .filter((n) => Number.isFinite(n) && n > 0);
const numbers = (csv: string | null | undefined) =>
  String(csv || "")
    .split(",")
    .map((x) => x.trim().toUpperCase())
    .filter(Boolean);

function ref(t: ChatTrip, loads: Map<number, ChatLoad>): LegRef {
  const load = t.load_id ? loads.get(Number(t.load_id)) : undefined;
  return { loadId: t.load_id, tripId: t.id, tripNo: t.trip_no, invoiceNo: load?.invoice_no ?? t.invoice_no ?? null, status: t.status, legNo: t.leg_no };
}

/** Legs that hold equipment: on the road, lined up, or delivered to the yard / meet point and waiting for the next leg. */
async function busyLegs() {
  const legs = await ChatTrip.findAll({
    where: { status: { [Op.in]: [...ON_LOAD, ...LINED_UP, ...HANDED_OVER] } },
    attributes: ["id", "load_id", "leg_no", "queue_pos", "trip_no", "invoice_no", "status", "driver_profile_id", "driver_id_1", "driver_id_2", "truck_id", "truck_number", "trailer_ids", "trailer_numbers", "ends_at_yard", "updated_at"],
    order: [["updated_at", "DESC"]],
  });
  const loadIds = [...new Set(legs.map((l) => l.load_id).filter(Boolean))] as number[];
  const loads = new Map((loadIds.length ? await ChatLoad.findAll({ where: { id: loadIds } }) : []).map((l) => [Number(l.id), l]));
  // Legs of those loads, to know if a handed-over leg's next leg already left
  const all = loadIds.length ? await ChatTrip.findAll({ where: { load_id: loadIds }, attributes: ["id", "load_id", "leg_no", "status"] }) : [];
  const waitingAfter = new Set<number>();
  for (const loadId of loadIds) {
    const chain = byLeg(all.filter((l) => Number(l.load_id) === loadId)).filter((l) => l.status !== "cancelled");
    chain.forEach((l, i) => {
      const next = chain[i + 1];
      if (next && HANDED_OVER.includes(l.status) && LINED_UP.includes(next.status)) waitingAfter.add(l.id);
    });
  }
  return { legs, loads, waitingAfter };
}

/** Truck number → drivers of its chat truck group. */
async function truckGroups(): Promise<Map<string, { id: string; name: string }[]>> {
  const groups = await Group.findAll({ where: { type: "truck" } });
  const links = groups.length ? await GroupUser.findAll({ where: { groupId: groups.map((g: any) => g.id) } }) : [];
  const profiles = links.length
    ? await UserProfile.findAll({ where: { id: links.map((l: any) => l.userProfileId) }, include: [{ model: Role, as: "role" }] })
    : [];
  const drivers = new Map(profiles.filter((p: any) => p.role?.name === "driver").map((p) => [p.id, { id: p.id, name: p.username || "Driver" }]));
  const out = new Map<string, { id: string; name: string }[]>();
  for (const g of groups as any[]) {
    const list = links.filter((l: any) => l.groupId === g.id).map((l: any) => drivers.get(l.userProfileId)).filter(Boolean) as { id: string; name: string }[];
    out.set(String(g.name).trim().toUpperCase(), list);
  }
  return out;
}

export async function trucksBoard(): Promise<TruckRow[]> {
  const [rows, busy, groups] = await Promise.all([
    yard<{ id: number; number: string }>(`SELECT id, number FROM trucks WHERE company_id IS NULL AND status = '1' AND deleted_at IS NULL ORDER BY number`),
    busyLegs(),
    truckGroups(),
  ]);
  return rows.map((t) => {
    const number = String(t.number).trim();
    const mine = busy.legs.filter((l) => Number(l.truck_id) === Number(t.id) || (l.truck_number || "").trim().toUpperCase() === number.toUpperCase());
    const on = mine.find((l) => ON_LOAD.includes(l.status));
    const lined = mine.find((l) => LINED_UP.includes(l.status));
    const leg = on || lined;
    return {
      id: Number(t.id),
      number,
      state: on ? "on_load" : lined ? "lined_up" : "free",
      leg: leg ? ref(leg, busy.loads) : null,
      drivers: groups.get(number.toUpperCase()) || [],
    };
  });
}

/** Last gate event per trailer (yard security log). */
async function lastGate(): Promise<Map<number, TrailerRow["gate"]>> {
  const rows = await yard<{ trailer_id: number; status: "entry" | "depart"; empty_loaded: string | null; created_at: Date }>(
    `SELECT e.trailer_id, e.status, e.empty_loaded, e.created_at
       FROM daily_vehicle_entries e
       JOIN (SELECT trailer_id, MAX(id) AS id FROM daily_vehicle_entries WHERE trailer_id IS NOT NULL GROUP BY trailer_id) last ON last.id = e.id`
  );
  return new Map(rows.map((r) => [Number(r.trailer_id), { status: r.status, loaded: r.empty_loaded || null, at: r.created_at }]));
}

export async function trailersBoard(): Promise<TrailerRow[]> {
  const [rows, busy, gates] = await Promise.all([
    yard<{ id: number; number: string; type: string | null; status: string | null }>(
      `SELECT id, number, type, status FROM trailers WHERE company_id IS NULL AND is_active = '1' AND deleted_at IS NULL ORDER BY number`
    ),
    busyLegs(),
    lastGate(),
  ]);
  return rows.map((t) => {
    const number = String(t.number).trim();
    const mine = busy.legs.filter((l) => ids(l.trailer_ids).includes(Number(t.id)) || numbers(l.trailer_numbers).includes(number.toUpperCase()));
    const on = mine.find((l) => ON_LOAD.includes(l.status));
    const waiting = mine.find((l) => busy.waitingAfter.has(l.id));
    const gate = gates.get(Number(t.id)) || null;
    const state: TrailerRow["state"] = on ? "on_load" : waiting ? "waiting_transfer" : gate?.status === "entry" ? "in_yard" : gate?.status === "depart" ? "out" : "unknown";
    const leg = on || waiting;
    return { id: Number(t.id), number, type: t.type || null, readiness: t.status || null, state, leg: leg ? ref(leg, busy.loads) : null, gate };
  });
}

export async function driversBoard(): Promise<DriverRow[]> {
  const [rows, busy] = await Promise.all([
    yard<{ id: number; name: string }>(`SELECT id, name FROM drivers WHERE company_id IS NULL AND status = '1' AND deleted_at IS NULL ORDER BY name`),
    busyLegs(),
  ]);
  const users = rows.length ? await User.findAll({ where: { yard_id: rows.map((r) => r.id) } as any }) : [];
  const profiles = users.length
    ? await UserProfile.findAll({ where: { userId: users.map((u: any) => u.id) }, include: [{ model: Role, as: "role" }] })
    : [];
  const profileOfYard = new Map<number, UserProfile>();
  for (const u of users as any[]) {
    const p = profiles.find((x: any) => x.userId === u.id && x.role?.name === "driver");
    if (p) profileOfYard.set(Number(u.yard_id), p);
  }
  const links = profiles.length ? await GroupUser.findAll({ where: { userProfileId: profiles.map((p) => p.id) } }) : [];
  const truckGroupsList = links.length ? await Group.findAll({ where: { id: links.map((l: any) => l.groupId), type: "truck" } }) : [];
  const truckOf = (profileId: string) => {
    const groupIds = links.filter((l: any) => l.userProfileId === profileId).map((l: any) => l.groupId);
    return (truckGroupsList.find((g: any) => groupIds.includes(g.id)) as any)?.name || null;
  };

  return rows.map((d) => {
    const profile = profileOfYard.get(Number(d.id)) || null;
    const mine = busy.legs.filter(
      (l) => (profile && l.driver_profile_id === profile.id) || Number(l.driver_id_1) === Number(d.id) || Number(l.driver_id_2) === Number(d.id)
    );
    const on = mine.find((l) => ON_LOAD.includes(l.status));
    const linedAll = mine
      .filter((l) => LINED_UP.includes(l.status))
      .sort((a, b) => (a.queue_pos ?? 1e9) - (b.queue_pos ?? 1e9) || a.id - b.id);
    const lined = linedAll[0];
    const leg = on || lined;
    return {
      lineup: linedAll.length,
      next: lined ? ref(lined, busy.loads) : null,
      yardId: Number(d.id),
      name: d.name,
      profileId: profile?.id || null,
      truck: profile ? truckOf(profile.id) : null,
      state: on ? "on_load" : lined ? "lined_up" : "free",
      leg: leg ? ref(leg, busy.loads) : null,
    };
  });
}

// ---------- "already on a load" while filling in a leg ----------

export interface Conflict {
  kind: "truck" | "trailer" | "driver";
  label: string;
  /** on_load: in use right now · lined_up: another load waits for it */
  severity: "on_load" | "lined_up";
  leg: LegRef;
}

export async function conflictsFor(input: {
  truckNumber?: string | null;
  trailerNumbers?: string[];
  driverProfileIds?: string[];
  /** Legs of the load being edited don't count */
  loadId?: number | null;
  tripId?: number | null;
}): Promise<Conflict[]> {
  const busy = await busyLegs();
  const others = busy.legs.filter(
    (l) => [...ON_LOAD, ...LINED_UP].includes(l.status) && l.id !== input.tripId && !(input.loadId && Number(l.load_id) === Number(input.loadId))
  );
  const out: Conflict[] = [];
  const add = (kind: Conflict["kind"], label: string, l: ChatTrip) =>
    out.push({ kind, label, severity: ON_LOAD.includes(l.status) ? "on_load" : "lined_up", leg: ref(l, busy.loads) });
  const truck = input.truckNumber?.trim().toUpperCase();
  if (truck) for (const l of others.filter((x) => (x.truck_number || "").trim().toUpperCase() === truck)) add("truck", `Truck ${input.truckNumber!.trim()}`, l);
  for (const n of (input.trailerNumbers || []).map((x) => x.trim()).filter(Boolean)) {
    for (const l of others.filter((x) => numbers(x.trailer_numbers).includes(n.toUpperCase()))) add("trailer", `Trailer ${n}`, l);
  }
  for (const id of (input.driverProfileIds || []).filter(Boolean)) {
    const driver = others.filter((x) => x.driver_profile_id === id);
    if (!driver.length) continue;
    const name = (await UserProfile.findByPk(id))?.username || "Driver";
    for (const l of driver) add("driver", name, l);
  }
  // Busiest first
  return out.sort((a, b) => (a.severity === b.severity ? 0 : a.severity === "on_load" ? -1 : 1));
}

// ---------- a load's time in the yard ----------

export interface YardVisit {
  trailer: string | null;
  inAt: Date;
  outAt: Date | null;
  minutes: number;
  loaded: string | null;
  /** gate: logged by yard security · leg: a leg ended at the yard (no gate entry found) */
  source: "gate" | "leg";
}

const SAME_VISIT_MS = 3 * 3600_000;

/**
 * Every stay in the yard while this load was moving: gate entries / departures of its trailers between
 * the first leg's start and the last leg's end (or now), paired per trailer; legs that ended at the yard
 * with no gate entry near them count too (security didn't log it).
 */
export function yardVisitsFrom(
  legs: Pick<ChatTrip, "leg_no" | "status" | "ends_at_yard" | "ended_at" | "started_at">[],
  gate: { trailer_id: number; status: "entry" | "depart"; empty_loaded: string | null; created_at: Date }[],
  trailerNames: Map<number, string>,
  now = new Date()
): YardVisit[] {
  const visits: YardVisit[] = [];
  const byTrailer = new Map<number, typeof gate>();
  for (const g of [...gate].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())) {
    byTrailer.set(Number(g.trailer_id), [...(byTrailer.get(Number(g.trailer_id)) || []), g]);
  }
  for (const [trailerId, events] of byTrailer) {
    let open: (typeof gate)[number] | null = null;
    for (const e of events) {
      if (e.status === "entry") {
        if (!open) open = e;
      } else if (open) {
        const inAt = new Date(open.created_at);
        const outAt = new Date(e.created_at);
        visits.push({ trailer: trailerNames.get(trailerId) || null, inAt, outAt, minutes: Math.round((outAt.getTime() - inAt.getTime()) / 60000), loaded: open.empty_loaded, source: "gate" });
        open = null;
      }
    }
    if (open) {
      const inAt = new Date(open.created_at);
      visits.push({ trailer: trailerNames.get(trailerId) || null, inAt, outAt: null, minutes: Math.round((now.getTime() - inAt.getTime()) / 60000), loaded: open.empty_loaded, source: "gate" });
    }
  }
  // Yard legs the gate didn't log
  const ordered = byLeg(legs as any[]) as typeof legs;
  ordered.forEach((leg, i) => {
    if (!leg.ends_at_yard || !leg.ended_at) return;
    const at = new Date(leg.ended_at);
    if (visits.some((v) => Math.abs(v.inAt.getTime() - at.getTime()) < SAME_VISIT_MS)) return;
    const next = ordered.slice(i + 1).find((l) => l.status !== "cancelled");
    const outAt = next?.started_at ? new Date(next.started_at) : null;
    visits.push({ trailer: null, inAt: at, outAt, minutes: Math.round(((outAt || now).getTime() - at.getTime()) / 60000), loaded: "loaded", source: "leg" });
  });
  return visits.sort((a, b) => a.inAt.getTime() - b.inAt.getTime());
}

export async function yardVisitsOfLoad(legs: ChatTrip[]): Promise<YardVisit[]> {
  const live = legs.filter((l) => l.status !== "cancelled");
  const trailerIds = [...new Set(live.flatMap((l) => ids(l.trailer_ids)))];
  const starts = live.map((l) => l.started_at).filter(Boolean).map((d) => new Date(d!).getTime());
  if (!starts.length) return [];
  const from = new Date(Math.min(...starts));
  const done = live.every((l) => l.ended_at);
  const to = done ? new Date(Math.max(...live.map((l) => new Date(l.ended_at!).getTime()))) : new Date();
  const gate = trailerIds.length
    ? await yard<{ trailer_id: number; status: "entry" | "depart"; empty_loaded: string | null; created_at: Date }>(
        `SELECT trailer_id, status, empty_loaded, created_at FROM daily_vehicle_entries
          WHERE trailer_id IN (:ids) AND created_at BETWEEN :from AND :to ORDER BY created_at, id`,
        { ids: trailerIds, from, to }
      )
    : [];
  const names = new Map<number, string>();
  if (trailerIds.length) {
    for (const t of await yard<{ id: number; number: string }>(`SELECT id, number FROM trailers WHERE id IN (:ids)`, { ids: trailerIds })) {
      names.set(Number(t.id), String(t.number));
    }
  }
  return yardVisitsFrom(live, gate, names, to);
}
