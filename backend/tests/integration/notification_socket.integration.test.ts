import http from 'http';
import { io as connectSocket, Socket } from 'socket.io-client';
import { NotificationType } from '../../src/constants/enums';
import notificationService from '../../src/services/notification.service';
import { server } from '../../src/server';
import { api, bearer, registerAndVerify, uniqueValue } from './helpers';

let httpServer: http.Server;
let port: number;
const clients: Socket[] = [];

const waitFor = <T = any>(socket: Socket, event: string, timeoutMs = 5000): Promise<T> =>
  new Promise<T>((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error(`Timed out waiting for ${event}`)),
      timeoutMs
    );
    socket.once(event, (payload: T) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });

const connectClient = (token?: string): Socket => {
  const socket = connectSocket(`http://127.0.0.1:${port}`, {
    transports: ['websocket'],
    forceNew: true,
    reconnection: false,
    auth: token ? { token } : {},
  });
  clients.push(socket);
  return socket;
};

const waitForConnected = async (socket: Socket): Promise<void> => {
  if (socket.connected) return;
  await waitFor(socket, 'connect');
};

describe('Socket.IO integration: notification events', () => {
  beforeAll(async () => {
    await new Promise<void>((resolve) => {
      httpServer = server.listen(0, '127.0.0.1', resolve);
    });
    const address = httpServer.address();
    if (!address || typeof address === 'string') {
      throw new Error('Notification socket server did not bind to a port.');
    }
    port = address.port;
  });

  afterAll(async () => {
    clients.forEach((socket) => socket.disconnect());
    await new Promise<void>((resolve) => httpServer.close(() => resolve()));
  });

  it('rejects unauthenticated notification socket handshakes', async () => {
    const anonymous = connectClient();
    const error = await waitFor(anonymous, 'connect_error');
    expect(error.message).toMatch(/Authentication token is required/);
  });

  it('pushes created, read, and unread-count events only to the owner', async () => {
    const owner = await registerAndVerify('notify-socket-owner');
    const outsider = await registerAndVerify('notify-socket-outsider');
    const ownerSocket = connectClient(owner.accessToken);
    const outsiderSocket = connectClient(outsider.accessToken);
    await Promise.all([waitForConnected(ownerSocket), waitForConnected(outsiderSocket)]);

    let outsiderReceived = false;
    outsiderSocket.on('notification:new', () => {
      outsiderReceived = true;
    });

    const createdEvent = waitFor(ownerSocket, 'notification:new');
    const initialCountEvent = waitFor(ownerSocket, 'notification:unread-count');

    await notificationService.notifyUser(owner.userId, {
      type: NotificationType.AUCTION_BID_PLACED,
      title: 'New auction bid',
      body: 'A bid was placed in your auction.',
      data: { auctionId: 'auction-1' },
      dedupeKey: `socket-bid-${uniqueValue()}`,
    });

    const [created, count] = await Promise.all([createdEvent, initialCountEvent]);
    expect(created.notification.title).toBe('New auction bid');
    expect(created.notification.type).toBe(NotificationType.AUCTION_BID_PLACED);
    expect(created.eventId).toMatch(/:created$/);
    expect(count.unreadCount).toBe(1);

    await new Promise((resolve) => setTimeout(resolve, 100));
    expect(outsiderReceived).toBe(false);

    const readEvent = waitFor(ownerSocket, 'notification:read');
    const clearedCountEvent = waitFor(ownerSocket, 'notification:unread-count');

    await api()
      .patch(`/api/v1/notifications/${created.notification.id}/read`)
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);

    const [read, cleared] = await Promise.all([readEvent, clearedCountEvent]);
    expect(read.notification.isRead).toBe(true);
    expect(read.unreadCount).toBe(0);
    expect(cleared.unreadCount).toBe(0);
  });
});
