import { Socket ,Server} from 'socket.io';  // Import Socket from socket.io

// Define the structure of the user
interface User {
  id: string;
  name: string;
  socketId: string;
}

// Augment the globalThis type
declare global {
  // Declare the global variables and their types
  var userSockets: Record<string, Socket>;       // A map of user ID to their Socket.IO socket instance
  var socketIO: Server;                 // The Socket.IO server instance
  var userActiveRoom: Record<string, string>;    // A map of user ID to active room ID
  var onlineUsers: User[];                       // List of online users
}

// Ensure this file is treated as a module
export {};