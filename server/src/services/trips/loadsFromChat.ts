import { TripError } from "./tripService";
import { loadFeature } from "./loadFeatures";

/**
 * Loads from chat messages — an admin switch (web: Settings → Loads → "Loads from chat messages"), off
 * by default: loads are added only from the Loads form.
 *
 * Off means a load text typed or pasted in a driver / truck chat is just a chat message: no load is made
 * or updated from it, and Convert to load / Repair / Missed loads are not offered. LOADS_FROM_CHAT in the
 * server's .env overrides the panel (the test scripts use it).
 */
export const loadsFromChat = () => loadFeature("loads_from_chat");

export async function requireLoadsFromChat() {
  if (!(await loadsFromChat())) throw new TripError("Loads are added from the Loads form — making a load from a chat message is turned off", 410);
}
