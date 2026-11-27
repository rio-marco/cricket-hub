import http from 'http';
import { io as connectSocket, Socket } from 'socket.io-client';
import AuctionBid from '../../src/models/AuctionBid';
import { server } from '../../src/server';
import { api, bearer, createPlayerViaApi, createTeamViaApi, registerAndVerify, uniqueValue } from './helpers';

const createAuctionFixture = async () => {
  const prefix = `as${uniqueValue()}`.slice(0, 12);
  const organizer = await registerAndVerify(`${prefix}-organizer`);
  const ownerA = await registerAndVerify(`${prefix}-owner-a`);
  const ownerB = await registerAndVerify(`${prefix}-owner-b`);
  const teamA = await createTeamViaApi(ownerA, `${prefix} A`);
  const teamB = await createTeamViaApi(ownerB, `${prefix} B`);
  const playerUser = await registerAndVerify(`${prefix}-player`);
  const player = await createPlayerViaApi(playerUser);

  const created = await api()
    .post('/api/v1/auctions')
    .set('Authorization', bearer(organizer.accessToken))
    .send({
      name: `${prefix} auction`,
      teams: [teamA._id, teamB._id],
      purseAmount: 100000,
      basePrice: 10000,
      minBidIncrement: 5000,
      maxSquadSize: 5,
      minSquadSize: 1,
    })
    .expect(201);
  const auctionId = created.body.data.auction._id as string;
  await api()
    .post(`/api/v1/auctions/${auctionId}/players`)
    .set('Authorization', bearer(organizer.accessToken))
    .send({ players: [{ playerId: player._id, basePrice: 10000, order: 1 }] })
    .expect(201);
  const started = await api()
    .post(`/api/v1/auctions/${auctionId}/start`)
    .set('Authorization', bearer(organizer.accessToken))
    .expect(200);

  return { auctionId, organizer, ownerA, ownerB, teamA, teamB, version: started.body.data.stateVersion };
};

type Fixture = Awaited<ReturnType<typeof createAuctionFixture>>;

let httpServer: http.Server;
let port: number;
const clients: Socket[] = [];

const waitFor = <T = any>(socket: Socket, event: string, timeoutMs = 5000): Promise<T> =>
  new Promise<T>((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${event}`)), timeoutMs);
    socket.once(event, (payload: T) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });

const emitWithAck = <T = any>(socket: Socket, event: string, payload: unknown): Promise<T> =>
  new Promise<T>((resolve) => {
    socket.emit(event, payload, (response: T) => resolve(response));
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

describe('Socket.IO integration: live auction', () => {
  beforeAll(async () => {
    await new Promise<void>((resolve) => {
      httpServer = server.listen(0, '127.0.0.1', resolve);
    });
    const address = httpServer.address();
    if (!address || typeof address === 'string') throw new Error('Auction socket server did not bind to a port.');
    port = address.port;
  });

  afterAll(async () => {
    clients.forEach((socket) => socket.disconnect());
    await new Promise<void>((resolve) => httpServer.close(() => resolve()));
  });

  it('rejects unauthenticated auction socket handshakes', async () => {
    const anonymous = connectClient();
    const error = await waitFor(anonymous, 'connect_error');
    expect(error.message).toMatch(/Authentication token is required/);
  });

  it('authorizes auction rooms and syncs authoritative state', async () => {
    const fixture = await createAuctionFixture();
    const viewer = connectClient(fixture.organizer.accessToken);
    await waitForConnected(viewer);

    const joined = await emitWithAck(viewer, 'auction:join', { auctionId: fixture.auctionId });
    expect(joined.ok).toBe(true);
    expect(joined.canManage).toBe(true);
    expect(joined.stateVersion).toBe(fixture.version);
    expect(joined.state.auction._id).toBe(fixture.auctionId);

    const synced = await emitWithAck(viewer, 'auction:sync', { auctionId: fixture.auctionId });
    expect(synced.ok).toBe(true);
    expect(synced.state.auction.status).toBe('LIVE');

    const denied = connectClient((await registerAndVerify('auction-socket-outsider')).accessToken);
    await waitForConnected(denied);
    const deniedAck = await emitWithAck(denied, 'auction:bid', {
      auctionId: fixture.auctionId,
      team: fixture.teamA._id,
      amount: 10000,
    });
    expect(deniedAck.ok).toBe(false);
    expect(deniedAck.error.code).toBe(403);
  });

  it('persists a bid before broadcasting bid_placed and state', async () => {
    const fixture = await createAuctionFixture();
    const viewer = connectClient(fixture.organizer.accessToken);
    const bidder = connectClient(fixture.ownerA.accessToken);
    await Promise.all([waitForConnected(viewer), waitForConnected(bidder)]);
    await emitWithAck(viewer, 'auction:join', { auctionId: fixture.auctionId });
    await emitWithAck(bidder, 'auction:join', { auctionId: fixture.auctionId });

    const bidPlaced = waitFor(viewer, 'auction:bid_placed');
    const stateEvent = waitFor(viewer, 'auction:state');
    const ack = await emitWithAck(bidder, 'auction:bid', {
      auctionId: fixture.auctionId,
      team: fixture.teamA._id,
      amount: 10000,
      expectedVersion: fixture.version,
      idempotencyKey: `socket-auction-bid-${uniqueValue()}`,
    });
    expect(ack.ok).toBe(true);

    const [bid, state] = await Promise.all([bidPlaced, stateEvent]);
    expect(bid.auctionId).toBe(fixture.auctionId);
    expect(bid.amount).toBeUndefined();
    expect(bid.sequenceNumber).toBe(1);
    expect(state.state.currentPlayer.currentBid).toBe(10000);
    expect(await AuctionBid.countDocuments({ auction: fixture.auctionId })).toBe(1);
  });

  it('emits bid_rejected and an ack failure for invalid bids', async () => {
    const fixture = await createAuctionFixture();
    const bidder = connectClient(fixture.ownerA.accessToken);
    await waitForConnected(bidder);
    await emitWithAck(bidder, 'auction:join', { auctionId: fixture.auctionId });

    const rejection = waitFor(bidder, 'auction:bid_rejected');
    const ack = await emitWithAck(bidder, 'auction:bid', {
      auctionId: fixture.auctionId,
      team: fixture.teamA._id,
      amount: 1,
      expectedVersion: fixture.version,
      idempotencyKey: `socket-auction-invalid-${uniqueValue()}`,
    });
    const event = await rejection;
    expect(ack.ok).toBe(false);
    expect(event.error.message).toMatch(/minimum increment|base/i);
    expect(await AuctionBid.countDocuments({ auction: fixture.auctionId })).toBe(0);
  });
});
