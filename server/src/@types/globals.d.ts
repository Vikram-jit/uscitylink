import { Server } from 'socket.io';
import type { UserConnection } from '../sockets/userConnections';

// Define the structure of the user
interface User {
  id: string;
  name: string;
  socketId: string;
}

// Augment the globalThis type
declare global {
  // Declare the global variables and their types
  var userSockets: Record<string, UserConnection>; // user ID → all of that user's live sockets (see sockets/userConnections.ts)
  var socketIO: Server;                 // The Socket.IO server instance
  var userActiveRoom: Record<string, string>;    // A map of user ID to active room ID
  var onlineUsers: User[];                       // List of online users
}

// Ensure this file is treated as a module
export {};