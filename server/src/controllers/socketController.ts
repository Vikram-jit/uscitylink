import { Request, Response } from 'express';
import { getSocketInstance } from '../sockets/socket';

export const sendMessage = (req: Request, res: Response) => {
    const { message } = req.body;
    const io = getSocketInstance();

    io.emit('message', { userId: req?.userId, message }); 
    res.status(200).send({ status: 'Message sent', message });
};
