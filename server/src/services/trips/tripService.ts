import { Op, QueryTypes } from "sequelize";
import { primarySequelize, secondarySequelize } from "../../sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripProblem, ChatTripStop } from "../../models/ChatTrip";
import { DriverTrip } from "../../models/DriverTrip";
import { UserProfile } from "../../models/UserProfile";
import User from "../../models/User";
import Role from "../../models/Role";
import UserChannel from "../../models/UserChannel";
import Group from "../../models/Group";
import GroupUser from "../../models/GroupUser";
import { getBotProfileId } from "../flowEngine/botProfile";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { sendSystemMessageToDriver } from "../../sockets/messageHandler";
import { driversInGroup, postToGroup } from "./truckGroup";
import { ActorRole, check, DRIVER_CURRENT, nextStep, TripAction, TripStatus, UNDO_WINDOW_MS } from "./lifecycle";
import { localToDate, stateTimezone } from "./stateTimezone";
import { createRouteRow, isPriced, removeRouteRow, syncRouteRow } from "./routeListSync";
import { formatLoad, loadRef, PROBLEM_KINDS, statusLine } from "./tripMessages";
import { gpsTrail, tripMileage } from "./samsara";
import { matchStops, meetPoint, pointAt } from "./gpsTimes";
import { geocodeStop, placeAt } from "./places";
import { blockingLeg, isLastLeg, legsOf, legTripNo, nextLeg, refreshLoadStatus } from "./legs";
import { liveTrip } from "./liveTrip";
import { linedUpLegs, nextPosition } from "./lineup";

// Trips: created by dispatch (Loads screen, Send load in chat, or a typed load read from chat), run
// by the driver from the app, completed by dispatch, priced by the accountant in the yard's Route
// List. Every change goes through act() so the rules (lifecycle.ts) and the record
// (chat_trip_events) can't be skipped.

export interface Actor {
  role: ActorRole;
  id?: string | null;
  name?: string | null;
}

export interface StopInput {
  /** yard: our yard (the leg drops the trailer there for the next leg) · switch: a meet point */
  type: "pickup" | "drop" | "switch" | "yard";
  name?: string | null;
  street?: string | null;
  city?: string | null;
  state?: string | null;
  zip?: string | null;
  /** Local to the stop: "2026-11-06T03:15". */
  appointment?: string | null;
  ref?: string | null;
}

export interface TripInput {
  /** The chat driver (user_profiles.id). Or give truckNumber and the truck's driver is used. */
  driverProfileId?: string | null;
  truckNumber?: string | null;
  /** Second driver for a team: a chat profile id, or a name as typed in a load ("JAGTAR SINGH"). */
  teamDriverProfileId?: string | null;
  teamNames?: string[];
  trailerNumbers?: string[];
  temperature?: string | null;
  /** The load's invoice number: can be left empty when adding, required to mark completed */
  invoiceNo?: string | null;
  loadedTrailer?: boolean;
  notes?: string | null;
  channelId?: string | null;
  stops: StopInput[];
  source?: "form" | "typed";
  needsReview?: boolean;
  reviewNotes?: string[];
  rawText?: string | null;
  /** A typed load: the message it came in (already in the chat, so nothing is sent). */
  messageId?: string | null;
  /** A plan-only load (a Load # and no stops yet): saved, can't be sent until it has stops */
  plan?: boolean;
  /** A later leg of a load can be saved before its driver is known ("assign later") */
  allowNoDriver?: boolean;
}

/** Which load a new trip is a leg of (loadService.createLoad); without it the trip is its own load. */
export interface LegOf {
  loadId: number;
  legNo: number;
  loadNo?: string | null;
}

/** "  INV-1234 " → "INV-1234"; empty → null */
export const cleanInvoice = (v?: string | null) => (v == null ? null : String(v).trim().slice(0, 64) || null);

export class TripError extends Error {
  constructor(
    message: string,
    public status = 400,
  ) {
    super(message);
  }
}

// ---------- lookups ----------

export const withStops = {
  include: [{ model: ChatTripStop, as: "stops" }],
  order: [[{ model: ChatTripStop, as: "stops" }, "seq", "ASC"]] as any,
};

async function yardOne<T extends object = any>(sql: string, replacements: Record<string, any>): Promise<T | null> {
  const rows = await secondarySequelize.query<T>(sql, {
    replacements,
    type: QueryTypes.SELECT,
  });
  return (rows[0] as T) || null;
}

/** The truck the driver is on (their truck group in chat, named after the truck number). */
export async function truckOfDriver(profileId: string): Promise<string | null> {
  const links = await GroupUser.findAll({
    where: { userProfileId: profileId },
  });
  if (!links.length) return null;
  const group = await Group.findOne({
    where: { id: links.map((g: any) => g.groupId), type: "truck" },
  });
  return (group as any)?.name || null;
}

/** The driver on a truck (members of its truck group who are drivers). */
export async function driverOfTruck(truckNumber: string): Promise<UserProfile | null> {
  const group = await Group.findOne({
    where: { name: truckNumber, type: "truck" },
  });
  if (!group) return null;
  // The main driver is the first by name — the same one the Send load form and the truck chat pick
  const first = (await driversInGroup((group as any).id))[0];
  return first ? UserProfile.findByPk(first.id) : null;
}

export interface TruckAssignment {
  truck: string;
  drivers: { id: string; name: string }[];
}

/** Drivers in a truck's group (the truck's assigned driver, two for a team). */
/** Trucks to pick from (Send load / Add load), each with the driver(s) its truck group assigns. */
export async function truckAssignments(q = ""): Promise<TruckAssignment[]> {
  const groups = await Group.findAll({
    where: {
      type: "truck",
      ...(q.trim() ? { name: { [Op.like]: `%${q.trim()}%` } } : {}),
    },
    order: [["name", "ASC"]],
    limit: 40,
  });
  return Promise.all(
    groups.map(async (g: any) => ({
      truck: String(g.name),
      drivers: await driversInGroup(g.id),
    })),
  );
}

/** The truck a driver is on and everyone assigned to it (so a team fills in both drivers). */
export async function assignmentOfDriver(profileId: string): Promise<TruckAssignment | null> {
  const links = await GroupUser.findAll({
    where: { userProfileId: profileId },
  });
  if (!links.length) return null;
  const group: any = await Group.findOne({
    where: { id: links.map((g: any) => g.groupId), type: "truck" },
  });
  return group ? { truck: String(group.name), drivers: await driversInGroup(group.id) } : null;
}

export async function yardDriverId(profileId: string): Promise<number | null> {
  const profile = await UserProfile.findByPk(profileId);
  const user = profile ? await User.findByPk(profile.userId) : null;
  return user?.yard_id ? Number(user.yard_id) : null;
}

async function yardDriverByName(name: string): Promise<{ id: number; name: string } | null> {
  const clean = name.trim();
  if (!clean) return null;
  return yardOne(`SELECT id, name FROM drivers WHERE name = :n OR name LIKE :like ORDER BY (name = :n) DESC, id DESC LIMIT 1`, {
    n: clean,
    like: `%${clean}%`,
  });
}

async function driverChannel(profileId: string, preferred?: string | null): Promise<string | null> {
  if (preferred) {
    const member = await UserChannel.findOne({
      where: { userProfileId: profileId, channelId: preferred },
    });
    if (member) return preferred;
  }
  const first = await UserChannel.findOne({
    where: { userProfileId: profileId },
    order: [["createdAt", "ASC"]],
  });
  return (first as any)?.channelId || null;
}

/**
 * The driver's chat for this trip. Looked up again when it's missing — a driver added to a channel
 * after the trip was made (or reassigned) must still get their messages — and saved once found.
 */
export async function ensureChannel(trip: ChatTrip): Promise<string | null> {
  if (trip.channel_id || !trip.driver_profile_id) return trip.channel_id || null;
  const channelId = await driverChannel(trip.driver_profile_id);
  if (channelId) await trip.update({ channel_id: channelId });
  return channelId;
}

const profileName = async (id?: string | null) => (id ? (await UserProfile.findByPk(id))?.username || null : null);

/** The load's own number, shown in chat, the app and Loads (the yard trip id comes at completion). */
export const loadNo = (id: number) => `L${String(id).padStart(4, "0")}`;

export async function getTrip(id: number | string) {
  return ChatTrip.findByPk(id, {
    include: [
      { model: ChatTripStop, as: "stops" },
      { model: ChatTripEvent, as: "events" },
      { model: ChatTripProblem, as: "problems" },
    ],
    order: [
      [{ model: ChatTripStop, as: "stops" }, "seq", "ASC"],
      [{ model: ChatTripEvent, as: "events" }, "happened_at", "ASC"],
    ] as any,
  });
}

// ---------- create / edit ----------

function stopRows(stops: StopInput[], allowEmpty = false) {
  if (!stops.length && !allowEmpty) throw new TripError("Add at least one stop");
  return stops.map((s, i) => {
    const state = (s.state || "").trim().toUpperCase().slice(0, 2) || null;
    const zone = stateTimezone(state);
    const local = s.appointment && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s.appointment) ? s.appointment : null;
    return {
      seq: i + 1,
      type: s.type === "pickup" || s.type === "switch" || s.type === "yard" ? s.type : "drop",
      name: s.name?.trim() || null,
      street: s.street?.trim() || null,
      city: s.city?.trim() || null,
      state,
      zip: s.zip?.trim() || null,
      appointment_local: local,
      appointment_at: local ? localToDate(local, zone) : null,
      timezone: zone,
      ref: s.ref?.trim() || null,
    };
  });
}

async function resolvePeople(input: TripInput) {
  let profileId = input.driverProfileId || null;
  let truckNumber = input.truckNumber?.trim() || null;
  if (!profileId && truckNumber) profileId = (await driverOfTruck(truckNumber))?.id || null;
  if (!profileId && !input.allowNoDriver) throw new TripError(truckNumber ? `No driver found on truck ${truckNumber}` : "Choose a driver or a truck");
  if (!truckNumber && profileId) truckNumber = await truckOfDriver(profileId);

  const driver1 = profileId ? await yardDriverId(profileId) : null;
  const teamNames: string[] = [];
  let driver2: number | null = null;
  if (input.teamDriverProfileId) {
    driver2 = await yardDriverId(input.teamDriverProfileId);
    const n = await profileName(input.teamDriverProfileId);
    if (n) teamNames.push(n);
  } else if (input.teamNames && input.teamNames.length > 1) {
    // "JOGA SINGH + JAGTAR SINGH": the second one that isn't the chat driver
    const own = (profileId ? await profileName(profileId) : null)?.toLowerCase() || "";
    for (const name of input.teamNames) {
      const found = await yardDriverByName(name);
      if (found && found.id !== driver1 && !driver2 && !own.includes(name.toLowerCase())) driver2 = found.id;
    }
    teamNames.push(...input.teamNames);
  }

  // The Route List form only lists the fleet's active trucks / trailers / drivers (no company):
  // prefer those, and say when one isn't there (the accountant would have to pick it by hand)
  const truck = truckNumber
    ? await yardOne<{ id: number; fleet: number }>(
        `SELECT id, (company_id IS NULL AND status = '1') AS fleet FROM trucks WHERE number = :n ORDER BY fleet DESC, id DESC LIMIT 1`,
        { n: truckNumber }
      )
    : null;
  const trailerNumbers = (input.trailerNumbers || []).map((t) => t.trim()).filter(Boolean);
  const trailerIds: number[] = [];
  const notFleet: string[] = [];
  if (truck && !Number(truck.fleet)) notFleet.push(`Truck ${truckNumber}`);
  for (const d of [driver1, driver2].filter(Boolean)) {
    const row = await yardOne<{ name: string; fleet: number }>(
      `SELECT name, (company_id IS NULL AND status = '1') AS fleet FROM drivers WHERE id = :id`,
      { id: d }
    );
    if (row && !Number(row.fleet)) notFleet.push(`Driver ${row.name}`);
  }
  for (const n of trailerNumbers) {
    const t = await yardOne<{ id: number; fleet: number }>(
      `SELECT id, (company_id IS NULL AND is_active = '1') AS fleet FROM trailers WHERE number = :n ORDER BY fleet DESC, id DESC LIMIT 1`,
      { n }
    );
    if (t) trailerIds.push(t.id);
    if (t && !Number(t.fleet)) notFleet.push(`Trailer ${n}`);
  }
  return {
    profileId,
    truckNumber,
    truckId: truck?.id || null,
    driver1,
    driver2,
    teamNames,
    trailerNumbers,
    trailerIds, notFleet,
  };
}

export async function createTrip(input: TripInput, actor: Actor, opts: { send?: boolean; leg?: LegOf; quiet?: boolean } = {}) {
  const people = await resolvePeople(input);
  const rows = stopRows(input.stops, !!input.plan);
  // The channel dispatch is working in, when the driver is in it (drivers can be in several)
  const working = actor.id ? (global as any).staffActiveChannel?.[actor.id]?.channelId : null;
  const channelId = people.profileId ? await driverChannel(people.profileId, input.channelId || working) : null;
  const reviewNotes = [...(input.reviewNotes || [])];
  if (people.profileId && !people.driver1) reviewNotes.push("The driver isn't linked to a yard driver — the Route List row has no driver yet");
  if (people.truckNumber && !people.truckId) reviewNotes.push(`Truck ${people.truckNumber} isn't in the yard`);
  if (people.trailerNumbers.length > people.trailerIds.length) reviewNotes.push("A trailer number isn't in the yard");
  if (people.notFleet.length) reviewNotes.push(`${people.notFleet.join(", ")}: not an active fleet unit in the yard — the Route List form won't show it selected`);

  const firstTime = rows.map((r) => r.appointment_at).filter(Boolean)[0] as Date | undefined;
  const typed = input.source === "typed" && !!input.messageId;
  // Lined up for a driver: it goes to the end of their lineup
  const queuePos = people.profileId && !typed ? await nextPosition(people.profileId) : null;

  // Nothing goes to the yard yet: the Route List entry is created when dispatch marks the trip
  // completed (completeTrip). Until then the load has its own number.
  const trip = await primarySequelize.transaction(async (t) => {
      const created = await ChatTrip.create(
        {
          status: typed ? "planned" : "scheduled",
          source: input.source || "form",
          needs_review: !!input.needsReview || reviewNotes.length > 0,
          review_notes: reviewNotes.join("\n") || null,
          load_id: opts.leg?.loadId ?? null,
          leg_no: opts.leg?.legNo ?? 1,
          queue_pos: queuePos,
          ends_at_yard: rows[rows.length - 1]?.type === "yard",
          driver_profile_id: people.profileId,
          channel_id: channelId,
          message_id: input.messageId || null,
          driver_id_1: people.driver1,
          driver_id_2: people.driver2,
          truck_id: people.truckId,
          trailer_ids: people.trailerIds.join(",") || null,
          truck_number: people.truckNumber,
          trailer_numbers: people.trailerNumbers.join(", ") || null,
          temperature: input.temperature?.trim() || null,
          invoice_no: cleanInvoice(input.invoiceNo),
          loaded_trailer: !!input.loadedTrailer,
          notes: input.notes?.trim() || null,
          planned_start_at: firstTime || null,
          sent_at: typed ? new Date() : null,
          created_by: actor.id || null,
          created_by_name: actor.name || null,
          raw_text: input.rawText?.trim() || null,
        },
        { transaction: t },
      );
      await ChatTripStop.bulkCreate(
        rows.map((r) => ({ ...r, chat_trip_id: created.id })),
        { transaction: t },
      );
      if (opts.leg) {
        // A leg: numbered after its load (L0047, L0047-2 …)
        const number = opts.leg.loadNo ? legTripNo(opts.leg.loadNo, opts.leg.legNo) : loadNo(created.id);
        await created.update({ trip_no: number }, { transaction: t });
      } else {
        // A plain load: one leg, same number and invoice #
        const load = await ChatLoad.create(
          {
            load_no: loadNo(created.id),
            invoice_no: created.invoice_no,
            type: "direct",
            status: created.status === "planned" ? "active" : "scheduled",
            created_by: actor.id || null,
            created_by_name: actor.name || null,
          },
          { transaction: t },
        );
        await created.update({ trip_no: loadNo(created.id), load_id: load.id }, { transaction: t });
      }
      await ChatTripEvent.create(
        {
          chat_trip_id: created.id,
          type: "status",
          to_status: created.status,
          actor_role: actor.role,
          actor_id: actor.id || null,
          actor_name: actor.name || null,
          note: typed ? "Read from the load sent in chat" : "Load added",
          message_id: input.messageId || null,
          happened_at: new Date(),
        },
        { transaction: t },
      );
      return created;
    });

  if (opts.send && !typed) await sendLoad(trip.id, actor);
  // Saved for later / lined up: only dispatch sees it — the driver gets it when it's sent
  else announce(trip.id);
  return getTrip(trip.id);
}

/** Dispatch fixes a trip (stops, people, notes). Recorded; Route List follows unless priced. */
export async function editTrip(id: number, input: Partial<TripInput>, actor: Actor, opts: { quiet?: boolean } = {}) {
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) throw new TripError("Trip not found", 404);
  if (["completed", "routed", "cancelled"].includes(trip.status)) throw new TripError("This trip is closed");
  const before = trip.toJSON();
  const changes: Record<string, any> = {};

  if (input.driverProfileId || input.truckNumber || input.teamDriverProfileId || input.teamNames || input.trailerNumbers) {
    const people = await resolvePeople({
      driverProfileId: input.driverProfileId || trip.driver_profile_id,
      truckNumber: input.truckNumber ?? trip.truck_number,
      teamDriverProfileId: input.teamDriverProfileId,
      teamNames: input.teamNames,
      trailerNumbers: input.trailerNumbers ?? (trip.trailer_numbers ? trip.trailer_numbers.split(/,\s*/) : []),
      stops: [],
      allowNoDriver: trip.leg_no > 1,
    });
    if (people.profileId && people.profileId !== trip.driver_profile_id) {
      changes.channel_id = await driverChannel(people.profileId, input.channelId);
      if (["scheduled", "offered"].includes(trip.status)) changes.queue_pos = await nextPosition(people.profileId, trip.id);
    }
    Object.assign(changes, {
      driver_profile_id: people.profileId,
      driver_id_1: people.driver1,
      driver_id_2: input.teamDriverProfileId || input.teamNames ? people.driver2 : trip.driver_id_2,
      truck_id: people.truckId,
      truck_number: people.truckNumber,
      trailer_ids: people.trailerIds.join(",") || null,
      trailer_numbers: people.trailerNumbers.join(", ") || null,
    });
  }
  for (const key of ["temperature", "notes"] as const) if (input[key] !== undefined) changes[key] = input[key]?.trim() || null;
  if (input.loadedTrailer !== undefined) changes.loaded_trailer = !!input.loadedTrailer;
  if (input.needsReview === false) Object.assign(changes, { needs_review: false, review_notes: null });

  await primarySequelize.transaction(async (t) => {
    await trip.update(changes, { transaction: t });
    if (input.stops) {
      // Stops already visited keep their arrival/departure times when they're still in the list
      const old = trip.stops || [];
      const rows = stopRows(input.stops);
      await ChatTripStop.destroy({
        where: { chat_trip_id: trip.id },
        transaction: t,
      });
      await ChatTripStop.bulkCreate(
        rows.map((r) => {
          const same = old.find((o) => o.name === r.name && o.city === r.city && o.type === r.type);
          return {
            ...r,
            chat_trip_id: trip.id,
            arrived_at: same?.arrived_at || null,
            departed_at: same?.departed_at || null,
          };
        }),
        { transaction: t },
      );
      const firstTime = rows.map((r) => r.appointment_at).filter(Boolean)[0] as Date | undefined;
      await trip.update({ planned_start_at: firstTime || null, ends_at_yard: rows[rows.length - 1]?.type === "yard" }, { transaction: t });
    }
    await ChatTripEvent.create(
      {
        chat_trip_id: trip.id,
        type: "edit",
        actor_role: actor.role,
        actor_id: actor.id || null,
        actor_name: actor.name || null,
        data: {
          before: pick(before, Object.keys(changes)),
          after: changes,
          stopsChanged: !!input.stops,
        },
        happened_at: new Date(),
      },
      { transaction: t },
    );
  });
  if (input.invoiceNo !== undefined) await setInvoice(trip, input.invoiceNo, actor);
  const fresh = await ChatTrip.findByPk(id, withStops);
  if (fresh) await syncRoute(fresh).catch((e) => console.warn("[trips] route row:", e?.message));
  announce(id);
  return getTrip(id);
}

/** The invoice # belongs to the load: every leg carries the same one. */
export async function setInvoice(trip: Pick<ChatTrip, "id" | "load_id" | "invoice_no">, value: string | null | undefined, actor: Actor) {
  const invoice = cleanInvoice(value);
  if (trip.load_id) {
    const load = await ChatLoad.findByPk(trip.load_id);
    const before = load?.invoice_no ?? trip.invoice_no ?? null;
    if (before === invoice) return;
    await load?.update({ invoice_no: invoice });
    await ChatTrip.update({ invoice_no: invoice }, { where: { load_id: trip.load_id } });
    await record(trip as ChatTrip, { type: "edit", actor, note: `Invoice # ${invoice || "removed"}`, data: { before: { invoice_no: before }, after: { invoice_no: invoice } } });
  } else if (trip.invoice_no !== invoice) {
    await ChatTrip.update({ invoice_no: invoice }, { where: { id: trip.id } });
  }
}

const pick = (o: any, keys: string[]) => Object.fromEntries(keys.map((k) => [k, o?.[k] ?? null]));

// ---------- send / offer ----------

/** Dispatch sends (or confirms) a load: the full load goes to the driver's chat. */
export async function sendLoad(id: number, actor: Actor, opts: { groupId?: string | null } = {}) {
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) throw new TripError("Trip not found", 404);
  const ok = check("send", trip.status, actor.role);
  if (!ok.ok) throw new TripError(ok.error);
  if (!trip.driver_profile_id) throw new TripError("Assign a driver to this leg first");
  const channelId = await ensureChannel(trip);
  if (!channelId) throw new TripError("This driver isn't in a chat channel yet — add them to one first");
  const blocking = await blockingLeg(trip);
  if (blocking) throw new TripError(`Leg ${blocking.leg_no} (${blocking.trip_no}) isn't delivered yet — this leg goes out after it`);

  // No stops yet (a plan-only load): nothing to send
  if (!(trip.stops || []).length) throw new TripError("Add where it goes (the stops) before sending this load");

  const teamNames = trip.driver_id_2 ? await teamNamesOf(trip) : [];
  // A load made from dispatch's own text goes out as dispatch typed it — nothing added or rewritten.
  // Loads made on the form have no text of their own: they get the standard layout.
  const typedText = trip.source === "typed" && trip.raw_text && trip.raw_text.trim() ? trip.raw_text.trim() : null;
  const body = typedText ?? formatLoad(trip, trip.stops || [], teamNames);
  const senderId = actor.id || (await getBotProfileId());
  // Sent from a truck chat: the message shows in that chat (staff + each member, once). Anywhere else
  // it goes to the driver's own chat.
  const inGroup = opts.groupId
    ? await postToGroup({ groupId: opts.groupId, senderId, channelId, body, automated: !typedText }).catch((e) => {
        console.warn("[trips] truck chat post:", e?.message || e);
        return null;
      })
    : null;
  const message =
    inGroup || (await sendSystemMessageToDriver(getSocketInstance(), senderId, trip.driver_profile_id, channelId, body, { automated: !typedText }));
  const from = trip.status;
  await trip.update({
    status: ok.to,
    sent_at: new Date(),
    message_id: (message as any)?.id || null,
  });
  await record(trip, {
    type: "status",
    from,
    to: ok.to,
    actor,
    messageId: (message as any)?.id,
    note: from === "offered" ? "Confirmed and sent" : "Sent",
  });
  announce(trip.id);
  return getTrip(trip.id);
}

export async function teamNamesOf(trip: ChatTrip): Promise<string[]> {
  const ids = [trip.driver_id_1, trip.driver_id_2].filter(Boolean);
  if (!ids.length) return [];
  const rows = await secondarySequelize.query<{ id: number; name: string }>(`SELECT id, name FROM drivers WHERE id IN (:ids)`, {
    replacements: { ids },
    type: QueryTypes.SELECT,
  });
  return ids.map((i) => rows.find((r) => Number(r.id) === Number(i))?.name).filter(Boolean) as string[];
}

/**
 * The driver needs their next load (they asked, or the current one is loaded / delivered). A lined-up
 * load is offered — the driver is told it's waiting for dispatch, dispatch gets a Confirm & send.
 * Nothing is sent to the driver without dispatch.
 */
export async function offerNextLoad(profileId: string, reason: "asked" | "rolling" | "ended") {
  const truck = await truckOfDriver(profileId);
  const truckRow = truck ? await yardOne<{ id: number }>(`SELECT id FROM trucks WHERE number = :n LIMIT 1`, { n: truck }) : null;
  // The driver's lineup, in the order dispatch set (#1 first)
  const candidates = await linedUpLegs(profileId, { truckId: truckRow?.id ?? null });
  // A later leg of a load waits for the leg before it to be delivered
  let next: ChatTrip | null = null;
  for (const c of candidates) {
    if (!(await blockingLeg(c))) {
      next = c;
      break;
    }
  }
  const channelId = next?.channel_id || (await driverChannel(profileId));
  if (next && !next.channel_id && channelId && next.driver_profile_id === profileId) await next.update({ channel_id: channelId });
  const bot = await getBotProfileId().catch(() => null);
  const say = async (text: string) => {
    if (bot && channelId) await sendSystemMessageToDriver(getSocketInstance(), bot, profileId, channelId, text).catch(() => undefined);
  };

  if (!next) {
    if (reason === "asked") {
      await say(statusLine.noLoad());
      alertStaff("trip:no_load", {
        driverProfileId: profileId,
        driverName: await profileName(profileId),
        truck,
      });
    }
    return null;
  }
  if (next.status === "scheduled") {
    // A load lined up for the truck goes to whoever drives it now
    if (next.driver_profile_id !== profileId) {
      await next.update({
        driver_profile_id: profileId,
        driver_id_1: (await yardDriverId(profileId)) ?? next.driver_id_1,
        channel_id: channelId,
      });
    }
    await next.update({ status: "offered" });
    await record(next, {
      type: "offer",
      from: "scheduled",
      to: "offered",
      actor: { role: "system", name: "Dispatch Assistant" },
      note: reason === "asked" ? "Driver asked for the next load" : `Current trip ${reason === "rolling" ? "loaded" : "delivered"}`,
    });
    await say(statusLine.offered());
  } else if (reason === "asked") {
    await say(statusLine.offered());
  }
  alertStaff("trip:offer", {
    tripId: next.id,
    tripNo: next.trip_no,
    driverProfileId: profileId,
    driverName: await profileName(profileId),
    truck,
    reason,
  });
  announce(next.id);
  return next;
}

export async function declineOffer(id: number, actor: Actor) {
  const trip = await ChatTrip.findByPk(id);
  if (!trip) throw new TripError("Trip not found", 404);
  const ok = check("decline_offer", trip.status, actor.role);
  if (!ok.ok) throw new TripError(ok.error);
  await trip.update({ status: ok.to });
  await record(trip, {
    type: "status",
    from: "offered",
    to: ok.to,
    actor,
    note: "Not sent yet",
  });
  const bot = await getBotProfileId().catch(() => null);
  if (bot && trip.driver_profile_id && trip.channel_id) {
    await sendSystemMessageToDriver(getSocketInstance(), bot, trip.driver_profile_id, trip.channel_id, statusLine.declined()).catch(
      () => undefined,
    );
  }
  announce(id);
  return getTrip(id);
}

// ---------- the driver's buttons and dispatch actions ----------

export interface ActOptions {
  stopId?: number | null;
  note?: string | null;
  lat?: number | null;
  lng?: number | null;
  /** When it really happened (a tap made offline arrives later). */
  at?: string | Date | null;
  /** Mark completed: the invoice number, when the trip doesn't have one yet */
  invoiceNo?: string | null;
}

const isTripDriver = async (trip: ChatTrip, profileId?: string | null) => {
  if (!profileId) return false;
  if (trip.driver_profile_id === profileId) return true;
  // The team driver on their own phone
  const yard = await yardDriverId(profileId);
  return !!yard && (yard === Number(trip.driver_id_1) || yard === Number(trip.driver_id_2));
};

function when(at?: string | Date | null): Date {
  const now = Date.now();
  const t = at ? new Date(at).getTime() : now;
  // Taps sent late (offline) keep their time; nothing in the future or older than a week
  if (!Number.isFinite(t) || t > now + 60_000 || t < now - 7 * 24 * 3600_000) return new Date(now);
  return new Date(t);
}

export async function act(id: number, action: TripAction, actor: Actor, opts: ActOptions = {}) {
  if (action === "send") return sendLoad(id, actor);
  if (action === "decline_offer") return declineOffer(id, actor);
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) throw new TripError("Trip not found", 404);
  if (actor.role === "driver" && !(await isTripDriver(trip, actor.id))) throw new TripError("This isn't your trip", 403);

  const ok = check(action, trip.status, actor.role, {
    statusBeforeHold: trip.status_before_hold,
    note: opts.note,
  });
  if (!ok.ok) throw new TripError(ok.error);

  const stops = trip.stops || [];
  const at = when(opts.at);
  const step = nextStep(trip.status, stops);
  const stop =
    stops.find((s) => s.id === Number(opts.stopId)) ||
    (step && "stopId" in step && step.stopId ? stops.find((s) => s.id === step.stopId) : undefined) ||
    null;
  if ((action === "arrive" || action === "depart") && !stop) throw new TripError("Which stop?");

  // What changes, and what it was (so the person can undo it)
  const tripBefore: Record<string, any> = {};
  const tripChanges: Record<string, any> = { status: ok.to };
  let invoiceToSet: string | null = null;
  const stopBefore: Record<string, any> = {};
  const stopChanges: Record<string, any> = {};
  const set = (field: string, value: any) => {
    tripBefore[field] = (trip as any)[field] ?? null;
    tripChanges[field] = value;
  };
  const setStop = (field: "arrived_at" | "departed_at", value: Date) => {
    if (!stop || stop[field]) return;
    stopBefore[field] = null;
    stopChanges[field] = value;
  };
  tripBefore.status = trip.status;

  switch (action) {
    case "start":
      set("started_at", at);
      break;
    case "arrive":
      setStop("arrived_at", at);
      break;
    case "rolling":
      // Rolling straight from "Got it" starts the trip too
      if (!trip.started_at) set("started_at", at);
      break;
    case "depart":
      if (stop && !stop.arrived_at) setStop("arrived_at", at);
      setStop("departed_at", at);
      break;
    case "end":
      set("ended_at", at);
      setStop("arrived_at", at);
      break;
    case "complete": {
      // No invoice number, no completion of the load's last leg: dispatch adds it here if the load was
      // saved without one. Earlier legs (to the yard / a meet point) complete without it.
      const load = trip.load_id ? await ChatLoad.findByPk(trip.load_id) : null;
      const current = load?.invoice_no || trip.invoice_no;
      const invoice = cleanInvoice(opts.invoiceNo) || current;
      if (!invoice && (await isLastLeg(trip))) throw new TripError("Add the invoice number before marking this trip completed", 422);
      // Not undone with the completion: the number stays on the load
      if (invoice && invoice !== current) invoiceToSet = invoice;
      set("completed_at", at);
      set("completed_by_name", actor.name || null);
      break;
    }
    case "hold":
      set("status_before_hold", trip.status);
      break;
    case "resume":
      set("status_before_hold", null);
      break;
  }

  // Mark completed creates the yard Route List entry, with the trip's final details. If the yard can't
  // take it, the trip stays delivered and dispatch sees why — never "completed" without its entry.
  let newRouteId: number | null = null;
  // Multi-leg loads: Route List entries are on hold until the pay rule for legs is decided
  const multiLeg = action === "complete" && (await legsOf(trip)).length > 1;
  if (action === "complete" && !trip.driver_pay_details_id && !multiLeg) {
    try {
      const route = await secondarySequelize.transaction((yardT) => createRouteRow(trip, stops, yardT));
      newRouteId = route.id;
      set("driver_pay_details_id", route.id);
      set("route_trip_no", route.tripNo);
    } catch (e: any) {
      throw new TripError(`Could not create the Route List entry: ${e?.message || e}`, 502);
    }
  }

  try {
    await primarySequelize.transaction(async (t) => {
      await trip.update(tripChanges, { transaction: t });
      if (stop && Object.keys(stopChanges).length) await stop.update(stopChanges, { transaction: t });
    });
  } catch (err) {
    // The trip didn't save: take back the Route List entry made for it a moment ago
    if (newRouteId) await removeRouteRow({ driver_pay_details_id: newRouteId }).catch(() => undefined);
    throw err;
  }
  if (invoiceToSet) await setInvoice(trip, invoiceToSet, actor);
  if (multiLeg) {
    await record(trip, { type: "note", actor: { role: "system", name: "Route List" }, note: "Route List on hold (multi-leg load)" });
  }

  // The chat line both sides see
  const who = actor.name || (actor.role === "driver" ? "Driver" : "Dispatch");
  const line =
    action === "accept"
      ? statusLine.accept(trip, who)
      : action === "start"
        ? statusLine.start(trip, at, stops[0])
        : action === "arrive"
          ? statusLine.arrive(stop!, at)
          : action === "rolling"
            ? statusLine.rolling(trip, stops, stop)
            : action === "depart"
              ? statusLine.depart(stop!, stops, at)
              : action === "end"
                ? statusLine.end(trip, stop)
                : action === "complete"
                  ? statusLine.complete(trip, who)
                  : action === "hold"
                    ? statusLine.hold(trip, opts.note)
                    : action === "resume"
                      ? statusLine.resume(trip)
                      : action === "cancel"
                        ? statusLine.cancel(trip, opts.note)
                        : null;
  const messageId = line ? await postToChat(trip, line) : null;

  await record(trip, {
    type: action === "arrive" ? "stop_arrived" : action === "depart" ? "stop_departed" : "status",
    from: tripBefore.status,
    to: ok.to,
    actor,
    stopId: stop?.id,
    note: opts.note,
    lat: opts.lat,
    lng: opts.lng,
    at,
    messageId,
    data: {
      action,
      before: { trip: tripBefore, stop: stopBefore },
      stopChanges: Object.keys(stopChanges),
    },
  });

  await afterAction(trip, action);
  announce(trip.id);
  return getTrip(trip.id);
}

export async function postToChat(trip: ChatTrip, text: string): Promise<string | null> {
  const channelId = trip.driver_profile_id ? await ensureChannel(trip) : null;
  if (!trip.driver_profile_id || !channelId) return null;
  try {
    const bot = await getBotProfileId();
    const m = await sendSystemMessageToDriver(getSocketInstance(), bot, trip.driver_profile_id, channelId, text);
    return (m as any)?.id || null;
  } catch (e: any) {
    console.warn("[trips] chat message:", e?.message || e);
    return null;
  }
}

/** Route List, the scale agent's route, the next load and Samsara mileage follow the trip. */
async function afterAction(trip: ChatTrip, action: TripAction) {
  const fresh = await ChatTrip.findByPk(trip.id, withStops);
  if (!fresh) return;
  const stops = fresh.stops || [];
  try {
    if (action === "cancel") await removeRouteRow(fresh);
    else if (action === "complete") await syncRoute(fresh);
  } catch (e: any) {
    console.warn("[trips] route row:", e?.message || e);
  }
  if (action === "rolling") await askForScaleTicket(fresh).catch((e) => console.warn("[trips] scale ticket:", e?.message));
  if (action === "rolling") void snapshotEta(fresh.id);
  // A leg that ends at the yard / a meet point hands the load to the next leg
  const handedTo = action === "end" ? await handOver(fresh).catch((e) => (console.warn("[trips] hand over:", e?.message), null)) : null;
  if (action === "start") await openScaleRoute(fresh, stops).catch(() => undefined);
  if (action === "end" || action === "cancel") await closeScaleRoute(fresh).catch(() => undefined);
  // Delivered: a load dispatch lined up "after this one" goes out now — the driver's next main load
  const autoSent = action === "end" && fresh.driver_profile_id ? await sendLinedUpNext(fresh.driver_profile_id).catch(() => null) : null;
  if ((action === "rolling" || action === "end") && !autoSent && fresh.driver_profile_id && handedTo?.driver_profile_id !== fresh.driver_profile_id) {
    void offerNextLoad(fresh.driver_profile_id, action === "end" ? "ended" : "rolling").catch((e) =>
      console.warn("[trips] next load:", e?.message),
    );
  }
  if (action === "end") void addMileage(fresh.id);
  // Samsara had a gap when it ended: try the GPS again now
  if (action === "complete" && fresh.miles_note === NO_GPS_NOTE) void addMileage(fresh.id, { forceGps: true }).catch(() => undefined);
  if (action === "complete" && fresh.route_trip_no) {
    await record(fresh, { type: "note", actor: { role: "system", name: "Route List" }, note: `Route List entry ${fresh.route_trip_no} created` });
  }
}

/**
 * The leg before was delivered to the yard / meet point: the next leg is ready. Its trailer is this
 * leg's unless dispatch chose another; with a driver already on it, it's offered (dispatch still
 * confirms before it's sent); without one, dispatch sees it under Ready to transfer.
 */
async function handOver(leg: ChatTrip): Promise<ChatTrip | null> {
  const next = await nextLeg(leg);
  if (!next || !["scheduled", "offered"].includes(next.status)) return null;
  if (!next.trailer_numbers && leg.trailer_numbers) {
    await next.update({ trailer_numbers: leg.trailer_numbers, trailer_ids: leg.trailer_ids, loaded_trailer: true });
  }
  const where = leg.ends_at_yard ? "dropped the trailer at the yard" : "handed the load over";
  await record(next, { type: "note", actor: { role: "system", name: "Dispatch Assistant" }, note: `Leg ${leg.leg_no} ${where} — this leg is ready` });
  if (next.driver_profile_id && next.status === "scheduled") {
    await next.update({ status: "offered" });
    await record(next, {
      type: "offer",
      from: "scheduled",
      to: "offered",
      actor: { role: "system", name: "Dispatch Assistant" },
      note: `Leg ${leg.leg_no} ${leg.ends_at_yard ? "at the yard" : "handed over"}`,
    });
    await postToChat(next, statusLine.offered());
    alertStaff("trip:offer", {
      tripId: next.id,
      tripNo: next.trip_no,
      driverProfileId: next.driver_profile_id,
      driverName: await profileName(next.driver_profile_id),
      truck: next.truck_number,
      reason: "handover",
    });
  } else if (!next.driver_profile_id) {
    alertStaff("load:transfer", { loadId: next.load_id, tripId: next.id, tripNo: next.trip_no, atYard: leg.ends_at_yard });
  }
  announce(next.id);
  return next;
}

/** The ETA when the leg went Rolling, kept to compare with the real delivery. */
async function snapshotEta(id: number) {
  if (process.env.TRIP_ETA_SNAPSHOT === "off") return;
  try {
    const trip = await ChatTrip.findByPk(id, withStops);
    if (!trip || trip.planned_eta_at) return;
    const live = await liveTrip(trip, trip.stops || []);
    if (live.eta) await trip.update({ planned_eta_at: new Date(live.eta) });
  } catch (e: any) {
    console.warn("[trips] eta snapshot:", e?.message || e);
  }
}

export const NO_GPS_NOTE = "No GPS match — check times / type miles";

async function vehicleOf(truckId: number | null | undefined): Promise<string | null> {
  if (!truckId) return null;
  const truck = await yardOne<{ samsara_vehicle_id: string | null }>(`SELECT samsara_vehicle_id FROM trucks WHERE id = :id`, { id: truckId });
  return truck?.samsara_vehicle_id ? String(truck.samsara_vehicle_id) : null;
}

/** The driver didn't tap everything, or dispatch ended / handed over the leg: its times come from GPS. */
async function needsGpsTimes(trip: ChatTrip): Promise<boolean> {
  if (!trip.started_at || (trip.stops || []).some((s) => !s.arrived_at)) return true;
  const events = await ChatTripEvent.findAll({ where: { chat_trip_id: trip.id, type: ["status", "transfer"] }, attributes: ["type", "data", "actor_role"] });
  return events.some((e) => e.data?.action === "end_by_dispatch" || (e.type === "transfer" && e.data?.transferTo && e.actor_role !== "driver"));
}

const hhmm = (d: Date, tz?: string | null) =>
  d.toLocaleString("en-US", { timeZone: tz || "America/Los_Angeles", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });

/**
 * Fill the leg's missing times (and a late dispatch end) from the truck's GPS trail. Times the driver
 * tapped, and times dispatch corrected by hand, are never changed. Returns whether GPS was matched.
 */
export async function applyGpsTimes(id: number): Promise<{ matched: boolean; changed: boolean; note?: string }> {
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) return { matched: false, changed: false };
  const vehicle = await vehicleOf(trip.truck_id);
  if (!vehicle) return { matched: false, changed: false, note: "No Samsara truck on this leg" };
  const stops = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq);
  if (!stops.length) return { matched: false, changed: false };

  const events = await ChatTripEvent.findAll({ where: { chat_trip_id: trip.id } });
  const endEvent = events.find((e) => e.type === "status" && e.data?.action === "end_by_dispatch");
  const handedOver = events.some((e) => e.type === "transfer" && e.data?.transferTo && e.actor_role !== "driver");
  const byDispatch = !!endEvent || handedOver;
  const corrected = events.some((e) => e.type === "time_correction" && e.actor_role !== "system");

  const to = new Date(Math.min(Date.now(), (trip.ended_at ? new Date(trip.ended_at).getTime() : Date.now()) + 60 * 60_000));
  const start = trip.sent_at || trip.created_at || trip.started_at || to;
  const from = new Date(Math.max(new Date(start).getTime() - 60 * 60_000, to.getTime() - 5 * 86400_000));
  const trail = await gpsTrail(vehicle, from, to);
  if (!trail?.length) return { matched: false, changed: false, note: "Samsara has no GPS for this truck in that time" };

  // Each stop's point: its address on the map; a handover point with another truck → where both trucks met
  const places = await Promise.all(stops.map((s) => geocodeStop(s).catch(() => null)));
  const meetIdx = (i: number) => stops[i] && ["switch", "yard"].includes(stops[i].type);
  const other =
    meetIdx(stops.length - 1) ? await nextLeg(trip) : meetIdx(0) && trip.leg_no > 1 ? (await legsOf(trip)).filter((l) => l.leg_no < trip.leg_no && l.status !== "cancelled").pop() || null : null;
  let meet: { lat: number; lng: number; at: Date } | null = null;
  if (other && other.truck_id && other.truck_id !== trip.truck_id) {
    const otherVehicle = await vehicleOf(other.truck_id);
    const otherTrail = otherVehicle ? await gpsTrail(otherVehicle, from, to) : null;
    if (otherTrail?.length) meet = meetPoint(trail, otherTrail, trail[0].t);
    const i = meetIdx(stops.length - 1) && other.leg_no > trip.leg_no ? stops.length - 1 : 0;
    // Where the trucks really met beats a typed meet address
    if (meet) places[i] = { lat: meet.lat, lng: meet.lng };
  }

  const endBy = trip.ended_at ? new Date(trip.ended_at) : null;
  const fixes = matchStops(trail, places, { endBy });
  if (!fixes.some(Boolean)) return { matched: false, changed: false, note: "The truck's GPS didn't pass the stops" };

  const legBefore: Record<string, any> = {};
  const legChanges: Record<string, any> = {};
  const stopChanges: { stop: ChatTripStop; before: Record<string, any>; changes: Record<string, any> }[] = [];
  const notes: string[] = [];
  const last = stops.length - 1;
  stops.forEach((s, i) => {
    const f = fixes[i];
    if (!f) return;
    const before: Record<string, any> = {};
    const changes: Record<string, any> = {};
    const lateDispatchEnd = i === last && byDispatch && !corrected && f.arrivedAt && s.arrived_at && f.arrivedAt.getTime() < new Date(s.arrived_at).getTime() - 5 * 60_000;
    if (f.arrivedAt && (!s.arrived_at || lateDispatchEnd)) {
      before.arrived_at = s.arrived_at;
      changes.arrived_at = f.arrivedAt;
    }
    if (i < last && f.departedAt && !s.departed_at) {
      before.departed_at = s.departed_at;
      changes.departed_at = f.departedAt;
    }
    if (Object.keys(changes).length) stopChanges.push({ stop: s, before, changes });
  });
  const firstFix = fixes[0];
  const lastFix = fixes[last];
  const startAt = firstFix?.departedAt || null;
  if (!trip.started_at && startAt) {
    legBefore.started_at = null;
    legChanges.started_at = startAt;
    notes.push(`Rolling (left ${stops[0].name || stops[0].city || "the first stop"}) ${hhmm(startAt, stops[0].timezone)}`);
  }
  if (trip.ended_at && byDispatch && !corrected && lastFix?.arrivedAt && lastFix.arrivedAt.getTime() < new Date(trip.ended_at).getTime() - 5 * 60_000) {
    legBefore.ended_at = trip.ended_at;
    legChanges.ended_at = lastFix.arrivedAt;
    const was = pointAt(trail, new Date(trip.ended_at));
    const wasAt = was ? await placeAt(was.lat, was.lng).catch(() => null) : null;
    notes.push(
      `${handedOver && !endEvent ? "Handed over" : "Delivered"} ${hhmm(lastFix.arrivedAt, stops[last].timezone)} — truck reached ${stops[last].name || stops[last].city || "the stop"} (dispatch ended at ${hhmm(new Date(trip.ended_at), stops[last].timezone)}${wasAt?.city ? `, truck was then at ${wasAt.city}, ${wasAt.state}` : ""})`
    );
  }
  // A meet point with no address gets the place where the trucks met
  const meetStop = meet ? stops[meetIdx(last) && other && other.leg_no > trip.leg_no ? last : 0] : null;
  if (meet && meetStop && !meetStop.city) {
    const p = await placeAt(meet.lat, meet.lng).catch(() => null);
    if (p?.city) {
      const entry = stopChanges.find((c) => c.stop.id === meetStop.id) || (stopChanges.push({ stop: meetStop, before: {}, changes: {} }), stopChanges[stopChanges.length - 1]);
      for (const k of ["name", "street", "city", "state", "zip"] as const) {
        entry.before[k] = (meetStop as any)[k];
        entry.changes[k] = (p as any)[k] || null;
      }
      notes.push(`Handover place from both trucks' GPS: ${p.city}, ${p.state} ${hhmm(meet.at, meetStop.timezone)}`);
    }
  }
  const filled = stopChanges.filter((c) => "arrived_at" in c.changes || "departed_at" in c.changes).length;
  if (filled) notes.push(`${filled} stop time${filled > 1 ? "s" : ""} filled from GPS`);
  if (!Object.keys(legChanges).length && !stopChanges.length) return { matched: true, changed: false };

  await primarySequelize.transaction(async (t) => {
    if (Object.keys(legChanges).length) await trip.update(legChanges, { transaction: t });
    for (const c of stopChanges) await c.stop.update(c.changes, { transaction: t });
  });
  await record(trip, {
    type: "time_correction",
    actor: { role: "system", name: "Samsara GPS" },
    note: `Times from the truck's GPS: ${notes.join(" · ")}`,
    data: {
      gps: true,
      before: { leg: legBefore, stops: stopChanges.map((c) => ({ id: c.stop.id, ...c.before })) },
      after: { leg: legChanges, stops: stopChanges.map((c) => ({ id: c.stop.id, ...c.changes })) },
    },
  });
  return { matched: true, changed: true };
}

/** Samsara odometer difference for the trip and each leg, written to the trip and its Route List row. */
export async function addMileage(id: number, opts: { forceGps?: boolean } = {}) {
  let trip = await ChatTrip.findByPk(id, withStops);
  // Miles typed by dispatch stay as they are
  if (!trip?.truck_id || !trip.ended_at || trip.miles_source === "manual") return;
  const vehicle = await vehicleOf(trip.truck_id);
  if (!vehicle) return;
  // The driver didn't tap / dispatch ended late: the truck's GPS says when it really left and arrived
  let gps = trip.miles_source === "gps";
  if (opts.forceGps || (await needsGpsTimes(trip))) {
    const r = await applyGpsTimes(id).catch((e) => {
      console.warn("[trips] gps times:", e?.message || e);
      return { matched: false, changed: false };
    });
    gps = gps || r.changed;
    trip = (await ChatTrip.findByPk(id, withStops))!;
    if (!r.matched && !trip.started_at) {
      await trip.update({ miles_note: NO_GPS_NOTE });
      announce(id);
      return;
    }
  }
  if (!trip.started_at || !trip.ended_at) return;
  const stops = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq);
  const result = await tripMileage(
    vehicle,
    trip.started_at,
    trip.ended_at,
    stops.map((s) => s.arrived_at),
  );
  if (!result) {
    if (gps) await trip.update({ miles_note: NO_GPS_NOTE });
    return;
  }
  await trip.update({ total_mileage: result.total, miles_source: gps ? "gps" : "samsara", miles_note: null });
  for (let i = 0; i < stops.length; i++) {
    const miles = result.legs[i];
    if (miles !== null && miles !== undefined) await stops[i].update({ mileage: miles });
  }
  await record(trip, {
    type: "note",
    actor: { role: "system", name: "Samsara" },
    note: `Trip mileage ${result.total} mi (odometer${gps ? ", times from GPS" : ""})`,
    data: result,
  });
  const fresh = await ChatTrip.findByPk(id, withStops);
  if (fresh) await syncRoute(fresh).catch(() => undefined);
  announce(id);
}

// ---------- scale ticket ----------

const SCALE_TICKET = "scale_ticket";

/**
 * The driver sent a photo read as a scale ticket (or corrected to one by staff) since the load was
 * sent. Compared inside the database: both times are stored the same way there, whatever the zone.
 */
async function scaleTicketForTrip(trip: ChatTrip): Promise<boolean> {
  const rows = await primarySequelize.query<{ n: number }>(
    `SELECT COUNT(*) AS n FROM message_documents d
       JOIN messages m ON m.id = d.message_id
       JOIN chat_trips t ON t.id = :tripId
      WHERE m.userProfileId = t.driver_profile_id AND m.messageDirection = 'R'
        AND m.createdAt >= COALESCE(t.sent_at, t.created_at)
        AND COALESCE(d.corrected_doc_type, d.doc_type_key) = :type`,
    { replacements: { tripId: trip.id, type: SCALE_TICKET }, type: QueryTypes.SELECT }
  );
  return Number(rows[0]?.n || 0) > 0;
}

/**
 * Once the driver starts the trip (Rolling), ask for the scale ticket — unless one already came in
 * for this trip, so a driver who sent it early is never asked.
 */
async function askForScaleTicket(trip: ChatTrip) {
  if (!trip.driver_profile_id) return;
  if (await scaleTicketForTrip(trip)) return;
  const messageId = await postToChat(trip, statusLine.askScaleTicket(trip));
  await record(trip, { type: "note", actor: { role: "system", name: "Dispatch Assistant" }, note: "Asked for the scale ticket", messageId });
}

/** A document the driver sent was read (documentAnalysisQueue): a scale ticket goes on the trip record. */
export async function onDocumentRead(message: { id: string; userProfileId: string }, docType: string | null | undefined) {
  if (docType !== SCALE_TICKET || !message.userProfileId) return;
  const trip = await ChatTrip.findOne({
    where: { driver_profile_id: message.userProfileId, status: { [Op.in]: ["planned", "accepted", "started", "rolling", "on_hold"] } },
    order: [["sent_at", "DESC"], ["id", "DESC"]],
  });
  if (!trip) return;
  await record(trip, { type: "note", actor: { role: "system", name: "Document reader" }, note: "Scale ticket received", messageId: message.id });
  announce(trip.id);
}

/** The Route List row follows the trip, with the lumper reported on it filled in for the accountant. */
export async function syncRoute(trip: ChatTrip) {
  const lumpers = await ChatTripProblem.findAll({ where: { chat_trip_id: trip.id, kind: "lumper" } });
  const lumper = lumpers.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  return syncRouteRow(trip, trip.stops || [], { lumper: lumper > 0 ? lumper : null });
}

// The scale agent judges tickets against the driver's current route (DriverTrip). A trip from chat
// opens one only when dispatch hasn't entered one, and closes only its own.
const scaleRouteNote = (trip: ChatTrip) => `Chat trip ${trip.trip_no || trip.id}`;

async function openScaleRoute(trip: ChatTrip, stops: ChatTripStop[]) {
  if (!trip.driver_profile_id) return;
  const active = await DriverTrip.findOne({
    where: { driver_id: trip.driver_profile_id, status: "active" },
  });
  if (active) return;
  const where = (s?: ChatTripStop) => (s ? [s.city, s.state].filter(Boolean).join(", ") : null);
  await DriverTrip.create({
    driver_id: trip.driver_profile_id,
    truck: trip.truck_number,
    trailer: trip.trailer_numbers,
    origin: where(stops[0]),
    destination: where(stops[stops.length - 1]),
    status: "active",
    notes: scaleRouteNote(trip),
  });
}

export async function closeScaleRoute(trip: ChatTrip) {
  if (!trip.driver_profile_id) return;
  await DriverTrip.update(
    { status: "closed", closed_at: new Date() },
    {
      where: {
        driver_id: trip.driver_profile_id,
        status: "active",
        notes: scaleRouteNote(trip),
      },
    },
  );
}

/** The person who made the last change takes it back (5 minutes). Recorded, never deleted. */
export async function undo(id: number, actor: Actor) {
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) throw new TripError("Trip not found", 404);
  const last = await ChatTripEvent.findOne({
    where: {
      chat_trip_id: id,
      type: {
        [Op.in]: ["status", "stop_arrived", "stop_departed", "correction"],
      },
    },
    order: [["id", "DESC"]],
  });
  if (!last || last.type === "correction") throw new TripError("Nothing to undo");
  if (last.actor_id !== actor.id) throw new TripError("Only the person who made the change can undo it");
  if (Date.now() - new Date(last.created_at).getTime() > UNDO_WINDOW_MS) throw new TripError("Too late to undo — ask dispatch to fix it");
  const before = last.data?.before;
  if (!before?.trip) throw new TripError("This change can't be undone");

  // Undoing Mark completed takes back the Route List entry it created (unless already priced)
  if (last.data?.action === "complete" && trip.driver_pay_details_id && before.trip.driver_pay_details_id === null) {
    if (!(await removeRouteRow(trip))) throw new TripError("The accountant already priced this trip — it can't be undone");
  }
  await primarySequelize.transaction(async (t) => {
    await trip.update(before.trip, { transaction: t });
    const stop = last.stop_id ? (trip.stops || []).find((s) => s.id === Number(last.stop_id)) : null;
    if (stop && before.stop && Object.keys(before.stop).length) await stop.update(before.stop, { transaction: t });
  });
  await record(trip, {
    type: "correction",
    from: last.to_status,
    to: before.trip.status,
    actor,
    note: `Undid: ${last.data?.action || last.type}`,
    data: { undoes: last.id },
  });
  await postToChat(trip, `↩️ ${actor.name || "Driver"} undid the last update on ${loadRef(trip, false)}`);
  const fresh = await ChatTrip.findByPk(id, withStops);
  if (fresh) await syncRoute(fresh).catch(() => undefined);
  announce(id);
  return getTrip(id);
}

// ---------- problems ----------

export async function addProblem(
  id: number,
  input: {
    kind: string;
    note?: string | null;
    amount?: number | null;
    hold?: boolean;
  },
  actor: Actor,
) {
  const trip = await ChatTrip.findByPk(id);
  if (!trip) throw new TripError("Trip not found", 404);
  if (actor.role === "driver" && !(await isTripDriver(trip, actor.id))) throw new TripError("This isn't your trip", 403);
  const kind = PROBLEM_KINDS[input.kind] ? input.kind : "other";
  const amount = input.amount !== undefined && input.amount !== null && Number.isFinite(Number(input.amount)) ? Number(input.amount) : null;
  const problem = await ChatTripProblem.create({
    chat_trip_id: id,
    kind,
    note: input.note?.trim() || null,
    amount,
    opened_by: actor.id || null,
    opened_by_name: actor.name || null,
  });
  const messageId = await postToChat(trip, statusLine.problem(trip, kind, actor.name || "Dispatch", input.note, amount));
  if (kind === "lumper" && amount) {
    const fresh = await ChatTrip.findByPk(id, withStops);
    if (fresh) await syncRoute(fresh).catch((e) => console.warn("[trips] route row:", e?.message));
  }
  await record(trip, {
    type: "problem",
    actor,
    note: input.note,
    messageId,
    data: { problemId: problem.id, kind, amount },
  });
  if (input.hold && check("hold", trip.status, actor.role).ok) {
    await act(id, "hold", actor, {
      note: `${PROBLEM_KINDS[kind]}${input.note ? `: ${input.note}` : ""}`,
    });
  } else {
    announce(id);
  }
  if (actor.role === "driver")
    alertStaff("trip:problem", {
      tripId: id,
      tripNo: trip.trip_no,
      kind,
      note: input.note,
      driverName: actor.name,
    });
  return getTrip(id);
}

export async function resolveProblem(id: number, problemId: number, actor: Actor) {
  const trip = await ChatTrip.findByPk(id);
  const problem = await ChatTripProblem.findOne({
    where: { id: problemId, chat_trip_id: id },
  });
  if (!trip || !problem) throw new TripError("Problem not found", 404);
  if (problem.resolved_at) return getTrip(id);
  await problem.update({
    resolved_at: new Date(),
    resolved_by_name: actor.name || null,
  });
  const messageId = await postToChat(trip, statusLine.resolved(trip, problem.kind, actor.name || "Dispatch"));
  await record(trip, {
    type: "problem_resolved",
    actor,
    messageId,
    data: { problemId },
  });
  // Last open problem on a held trip: carry on
  const open = await ChatTripProblem.count({
    where: { chat_trip_id: id, resolved_at: null },
  });
  if (!open && trip.status === "on_hold" && actor.role === "dispatcher") return act(id, "resume", actor);
  announce(id);
  return getTrip(id);
}

// ---------- the record and live updates ----------

export async function record(
  trip: ChatTrip,
  e: {
    type: string;
    from?: string | null;
    to?: string | null;
    actor: Actor;
    stopId?: number | null;
    note?: string | null;
    lat?: number | null;
    lng?: number | null;
    at?: Date;
    messageId?: string | null;
    data?: Record<string, any>;
  },
) {
  return ChatTripEvent.create({
    chat_trip_id: trip.id,
    type: e.type,
    from_status: e.from ?? null,
    to_status: e.to ?? null,
    stop_id: e.stopId ?? null,
    actor_role: e.actor.role,
    actor_id: e.actor.id || null,
    actor_name: e.actor.name || null,
    note: e.note?.trim() || null,
    data: e.data || null,
    lat: Number.isFinite(Number(e.lat)) && e.lat !== null ? e.lat : null,
    lng: Number.isFinite(Number(e.lng)) && e.lng !== null ? e.lng : null,
    message_id: e.messageId || null,
    happened_at: e.at || new Date(),
  });
}

/** Online staff (dashboard + staff app). */
export function alertStaff(event: string, payload: Record<string, any>) {
  try {
    const io = getSocketInstance();
    for (const staffId of Object.keys(global.staffActiveChannel || {})) io.to(userRoom(staffId)).emit(event, payload);
  } catch {
    // socket not up (scripts): nothing to tell
  }
}

/** trip:updated to the driver(s) and staff, so the app card and the dashboard refresh. */
export function announce(id: number) {
  void (async () => {
    const trip = await ChatTrip.findByPk(id);
    if (!trip) return;
    const load = await refreshLoadStatus(trip.load_id).catch(() => null);
    // A load left (or joined) the driver's lineup: number it 1..n again
    if (trip.driver_profile_id) await nextPosition(trip.driver_profile_id).catch(() => undefined);
    const io = getSocketInstance();
    if (load) alertStaff("load:updated", { loadId: load.id, status: load.status });
    const payload = {
      tripId: id,
      status: trip.status,
      driverProfileId: trip.driver_profile_id,
    };
    if (trip.driver_profile_id) io.to(userRoom(trip.driver_profile_id)).emit("trip:updated", payload);
    alertStaff("trip:updated", payload);
  })().catch(() => undefined);
}

/**
 * The yard knows nothing about trips: a completed trip counts as priced once the accountant has added
 * pay to its Route List row. Checked whenever completed trips are listed or opened.
 */
export async function syncPriced(trips: ChatTrip[]) {
  for (const trip of trips) {
    if (trip.status !== "completed" || !trip.driver_pay_details_id) continue;
    if (!(await isPriced(trip.driver_pay_details_id).catch(() => false))) continue;
    const ok = check("route", trip.status, "system");
    if (!ok.ok) continue;
    await trip.update({ status: ok.to });
    await record(trip, { type: "status", from: "completed", to: ok.to, actor: { role: "system", name: "Route List" }, note: "Priced in the Route List" });
  }
}

/**
 * The driver's Loads screen: every load sent to them (or to them as the team driver), newest first.
 * Loads dispatch has lined up but not sent yet stay hidden — the driver gets those when dispatch confirms.
 */
export async function tripsForDriver(profileId: string, page = 1, limit = 20) {
  const yard = await yardDriverId(profileId);
  const { rows, count } = await ChatTrip.findAndCountAll({
    where: {
      status: { [Op.notIn]: ["scheduled", "offered"] },
      [Op.or]: [{ driver_profile_id: profileId }, ...(yard ? [{ driver_id_1: yard }, { driver_id_2: yard }] : [])],
    },
    include: [{ model: ChatTripStop, as: "stops" }],
    order: [
      [primarySequelize.literal("COALESCE(sent_at, created_at)"), "DESC"],
      ["id", "DESC"],
      [{ model: ChatTripStop, as: "stops" }, "seq", "ASC"],
    ] as any,
    distinct: true,
    limit,
    offset: (Math.max(1, page) - 1) * limit,
  });
  return { trips: rows, total: count, page };
}

/** The trip the driver is on now (the app's trip card), with what the big button does. */
/**
 * The trip on the driver's dashboard / chat card. An active one (sent, Got it, rolling, on hold) first.
 * After delivery the card stays only while it's the driver's latest load and still waits for the
 * paperwork / dispatch: once dispatch marks it completed — or a newer load came, or the leg was handed
 * over to another driver — it's only in the Loads history.
 */
export async function currentTripFor(profileId: string) {
  const include = [
    { model: ChatTripStop, as: "stops" },
    { model: ChatTripProblem, as: "problems" },
  ];
  const newest = [
    ["sent_at", "DESC"],
    ["id", "DESC"],
  ] as any;
  let trip = await ChatTrip.findOne({
    where: { driver_profile_id: profileId, status: { [Op.in]: ["planned", "accepted", "started", "rolling", "on_hold"] } },
    order: newest,
    include,
  });
  if (!trip) {
    // The latest load sent to them: shown while delivered and waiting for dispatch, not after
    const latest = await ChatTrip.findOne({
      where: { driver_profile_id: profileId, sent_at: { [Op.ne]: null }, status: { [Op.ne]: "cancelled" } },
      order: newest,
      include,
    });
    const last = latest ? [...(latest.stops || [])].sort((a, b) => a.seq - b.seq).pop() : null;
    const handedOver = !!latest && (latest.ends_at_yard || last?.type === "switch" || last?.type === "yard" || !!latest.handover_reason);
    if (latest && ["ended", "paperwork"].includes(latest.status) && !handedOver) trip = latest;
  }
  if (!trip) return null;
  const stops = (trip.stops || []).sort((a, b) => a.seq - b.seq);
  return { trip, next: nextStep(trip.status as TripStatus, stops) };
}

/**
 * Driver app "Up next": drivers don't see loads lined up for them — only their current load and their
 * history. Kept (empty) so older app builds that still ask don't break.
 */
export async function upcomingFor(_profileId: string) {
  return { trips: [] as any[] };
}

/**
 * The driver is free (ended their load): the first load in their lineup, if dispatch lined it up
 * "after the current one" (auto_send), is sent to them now — it becomes their main load. Loads only
 * saved for later still wait for dispatch to confirm (offerNextLoad).
 */
export async function sendLinedUpNext(profileId: string): Promise<ChatTrip | null> {
  const busy = await ChatTrip.count({ where: { driver_profile_id: profileId, status: { [Op.in]: ["planned", "accepted", "started", "rolling", "on_hold"] } } });
  if (busy) return null;
  for (const leg of await linedUpLegs(profileId)) {
    if (await blockingLeg(leg)) continue; // waits for the leg before it
    if (!leg.auto_send || leg.driver_profile_id !== profileId) return null; // #1 needs dispatch's confirm
    await sendLoad(leg.id, { role: "dispatcher", id: null, name: "Dispatch Assistant" });
    const name = await profileName(profileId);
    alertStaff("trip:reminder", { tripId: leg.id, tripNo: leg.trip_no, kind: "auto_sent", text: `✅ Next load #${leg.trip_no} sent to ${name || "the driver"} — the one before is delivered` });
    return leg;
  }
  return null;
}
