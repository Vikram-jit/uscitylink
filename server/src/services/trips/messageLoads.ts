// A chat message and the load it made. When dispatch deletes a load message from the chat, the app
// asks first: "This message made Load 0056034 — delete the load too?" (loadsOfMessage), then
// deleteLegOfMessage removes the leg (the whole load when it was its only leg).
// Links: the standard load message (trip.message_id / the "Sent" event) and a load typed straight in
// the chat (a "source_message" event on the leg). A driver's deleted photo just leaves the Paperwork.

import { Op } from "sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripProblem, ChatTripStop } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { primarySequelize } from "../../sequelize";
import { refreshLoadStatus } from "./legs";
import { nextPosition } from "./lineup";
import { Actor, alertStaff, TripError } from "./tripService";

const CLOSED = ["completed", "routed"];

export interface MessageLoad {
  loadId: number;
  legId: number;
  legNo: number;
  tripNo: string | null;
  loadNo: string | null;
  status: string;
  driverName: string | null;
  /** The load's only leg: deleting it deletes the load */
  onlyLeg: boolean;
  canDelete: boolean;
  /** Why it can't be deleted from here */
  why: string | null;
}

async function legsLinkedTo(messageId: string): Promise<ChatTrip[]> {
  const events = await ChatTripEvent.findAll({
    where: { message_id: messageId, [Op.or]: [{ type: "source_message" }, { type: "status", to_status: { [Op.in]: ["planned", "scheduled"] } }] },
  });
  const ids = [...new Set(events.map((e) => Number(e.chat_trip_id)))];
  return ChatTrip.findAll({ where: { [Op.or]: [{ message_id: messageId }, ...(ids.length ? [{ id: ids }] : [])] } });
}

/** The loads this message made (usually none or one). */
export async function loadsOfMessage(messageId: string): Promise<MessageLoad[]> {
  const out: MessageLoad[] = [];
  for (const leg of await legsLinkedTo(messageId)) {
    if (leg.status === "cancelled" || !leg.load_id) continue;
    const load = await ChatLoad.findByPk(leg.load_id);
    const legs = (await ChatTrip.findAll({ where: { load_id: leg.load_id } })).filter((l) => l.status !== "cancelled");
    const later = legs.filter((l) => l.leg_no > leg.leg_no);
    const driver = leg.driver_profile_id ? await UserProfile.findByPk(leg.driver_profile_id) : null;
    let why: string | null = null;
    if (CLOSED.includes(leg.status) || leg.driver_pay_details_id) why = "It's completed (in the Route List) — it stays on the load";
    else if (later.length) why = `Leg ${later[0].leg_no} comes after it — remove that leg first`;
    out.push({
      loadId: leg.load_id,
      legId: leg.id,
      legNo: leg.leg_no,
      tripNo: leg.trip_no,
      loadNo: load?.invoice_no || load?.load_no || leg.invoice_no || null,
      status: leg.status,
      driverName: driver?.username || null,
      onlyLeg: legs.length <= 1,
      canDelete: !why,
      why,
    });
  }
  return out;
}

/** Delete the leg this message made — the whole load when it's the only leg. */
export async function deleteLegOfMessage(messageId: string, legId: number, actor: Actor): Promise<{ deletedLoad: boolean; loadId: number }> {
  const found = (await loadsOfMessage(messageId)).find((l) => l.legId === Number(legId));
  if (!found) throw new TripError("This message didn't make that load", 404);
  if (!found.canDelete) throw new TripError(found.why || "This load can't be deleted from the chat");
  const leg = (await ChatTrip.findByPk(found.legId))!;
  const all = await ChatTrip.findAll({ where: { load_id: found.loadId } });
  // Only leg left (cancelled / replaced copies included): the load goes with it
  const gone = found.onlyLeg ? all : [leg];
  const ids = gone.map((l) => l.id);
  await primarySequelize.transaction(async (t) => {
    await ChatTripEvent.destroy({ where: { chat_trip_id: ids }, transaction: t });
    await ChatTripStop.destroy({ where: { chat_trip_id: ids }, transaction: t });
    await ChatTripProblem.destroy({ where: { chat_trip_id: ids }, transaction: t });
    await ChatTrip.destroy({ where: { id: ids }, transaction: t });
    if (found.onlyLeg) await ChatLoad.destroy({ where: { id: found.loadId }, transaction: t });
  });
  console.log(`[loads] ${actor.name || "dispatch"} deleted ${found.onlyLeg ? `load ${found.loadNo}` : `leg ${found.legNo} of ${found.loadNo}`} with its chat message ${messageId}`);
  if (!found.onlyLeg) await refreshLoadStatus(found.loadId).catch(() => null);

  // The driver's card / lineup and every dashboard drop it
  const io = getSocketInstance();
  for (const l of gone) {
    const payload = { tripId: l.id, status: "deleted", driverProfileId: l.driver_profile_id, loadId: found.loadId };
    if (l.driver_profile_id) {
      io.to(userRoom(l.driver_profile_id)).emit("trip:updated", payload);
      await nextPosition(l.driver_profile_id).catch(() => undefined);
    }
    alertStaff("trip:updated", payload);
  }
  alertStaff("load:updated", { loadId: found.loadId, status: found.onlyLeg ? "deleted" : undefined });
  return { deletedLoad: found.onlyLeg, loadId: found.loadId };
}

/** A deleted chat message: a driver's photo leaves the load's Paperwork; link notes go too. */
export async function forgetMessage(messageId: string) {
  const docs = await ChatTripEvent.findAll({ where: { message_id: messageId, type: { [Op.in]: ["document", "source_message"] } } });
  if (!docs.length) return;
  await ChatTripEvent.destroy({ where: { id: docs.map((d) => d.id) } });
  for (const id of new Set(docs.map((d) => Number(d.chat_trip_id)))) alertStaff("trip:updated", { tripId: id });
}
