import type { Server, Socket } from "socket.io";
import type { CustomSocket } from "./socket";

/**
 * Every live connection of one user — several dashboard tabs, the dashboard opened on the IP and on
 * the domain, web + phone — reached as one target.
 *
 * global.userSockets[userId] used to hold the user's LAST socket, so only the newest tab got live
 * messages. It now holds one of these: each of the user's sockets joins the room in `id`, so the
 * existing `io.to(global.userSockets[x].id).emit(...)` and `global.userSockets[x].emit(...)` calls
 * reach all of them unchanged.
 *
 * Rooms live in this process: the IP and the domain must be served by the same server process.
 */
export class UserConnection {
  /** Socket.IO room with all of this user's sockets. */
  readonly id: string;
  /** Same as socket.user on the user's sockets (message helpers read the sender from it). */
  user?: CustomSocket["user"];

  constructor(readonly userId: string) {
    this.id = userRoom(userId);
  }

  emit(event: string, ...args: any[]): boolean {
    server?.to(this.id).emit(event, ...args);
    return true;
  }
}

let server: Server | null = null;

export const userRoom = (userId: string) => `user:${userId}`;

export function initUserConnections(io: Server) {
  server = io;
}

/** How many of this user's sockets are connected right now. */
export function liveSocketCount(userId: string): number {
  return server?.sockets.adapter.rooms.get(userRoom(userId))?.size ?? 0;
}

/** A socket of this user connected (or pinged): make sure it gets the user's events. */
export function addUserSocket(socket: CustomSocket, userId: string): UserConnection {
  socket.join(userRoom(userId));
  if (!global.userSockets[userId]) global.userSockets[userId] = new UserConnection(userId);
  const connection = global.userSockets[userId];
  if (socket.user) connection.user = socket.user;
  return connection;
}

/** A user's socket, or all of their connections (what REST controllers pass to message helpers). */
export type ActingSocket = CustomSocket | UserConnection;

/**
 * One of the user's sockets logged out or disconnected. Returns true when it was the last one —
 * only then is the user offline (and their per-user state should be cleared).
 */
export function removeUserSocket(socket: Socket, userId: string): boolean {
  socket.leave(userRoom(userId));
  if (liveSocketCount(userId) > 0) return false;
  delete global.userSockets[userId];
  return true;
}
