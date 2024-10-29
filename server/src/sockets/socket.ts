import { Server } from 'socket.io';

let io: Server;

export const initSocket = (httpServer: any) => {
    io = new Server(httpServer, {
        cors: {
            origin: '*',
            methods: ['GET', 'POST'],
        },
    });

    io.on('connection', (socket) => {
        console.log('A user connected');

        socket.on('message', (data) => {
            console.log('Message received:', data);
            io.emit('message', data); // Broadcast the message
        });

        socket.on('disconnect', () => {
            console.log('User disconnected');
        });
    });
};

export const getSocketInstance = () => {
    if (!io) {
        throw new Error('Socket is not initialized');
    }
    return io;
};
