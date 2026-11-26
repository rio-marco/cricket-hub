import { Server as HttpServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { registerMatchHandlers } from '../sockets/matchHandlers';
import { registerAuctionHandlers } from '../sockets/auctionHandlers';
import { MatchSocketServer, setSocketServer, userRoom } from '../sockets/publisher';
import {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketData,
} from '../sockets/types';
import { resolveCorsOrigins } from './cors';

export const configureSocketIO = (server: HttpServer): MatchSocketServer => {
  const corsOrigin = resolveCorsOrigins();
  const io: MatchSocketServer = new SocketIOServer<
    ClientToServerEvents,
    ServerToClientEvents,
    InterServerEvents,
    SocketData
  >(server, {
    cors: {
      origin: corsOrigin,
      methods: ['GET', 'POST'],
      credentials: corsOrigin !== '*',
    },
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  setSocketServer(io);
  registerMatchHandlers(io);
  registerAuctionHandlers(io);

  io.on('connection', (socket) => {
    const user = socket.data.user;
    if (!user) return;
    const room = userRoom(user.id);
    void socket.join(room);
    socket.data.notificationRooms.add(room);
  });

  return io;
};
