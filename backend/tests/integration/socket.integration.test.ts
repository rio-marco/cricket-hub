import http from 'http';
import { io as connectSocket, Socket } from 'socket.io-client';
import {
  BallType,
  MatchFormat,
  TossDecision,
} from '../../src/constants/enums';
import { server } from '../../src/server';
import {
  api,
  bearer,
  createPlayerInDb,
  createTeamViaApi,
  createVerifiedUserInDb,
  registerAndVerify,
  uniqueValue,
} from './helpers';

const createScoringFixture = async (prefix: string) => {
  const ownerA = await registerAndVerify(`${prefix}-owner-a`);
  const ownerB = await registerAndVerify(`${prefix}-owner-b`);
  const teamA = await createTeamViaApi(ownerA, `${prefix} A ${uniqueValue()}`);
  const teamB = await createTeamViaApi(ownerB, `${prefix} B ${uniqueValue()}`);

  const playersA = await Promise.all(
    Array.from({ length: 11 }, async () => {
      const user = await createVerifiedUserInDb(`${prefix}-a-player`);
      return createPlayerInDb(user._id);
    })
  );
  const playersB = await Promise.all(
    Array.from({ length: 11 }, async () => {
      const user = await createVerifiedUserInDb(`${prefix}-b-player`);
      return createPlayerInDb(user._id);
    })
  );

  const created = await api()
    .post('/api/v1/matches')
    .set('Authorization', bearer(ownerA.accessToken))
    .send({
      title: `${prefix} Socket Match ${uniqueValue()}`,
      teamA: teamA._id,
      teamB: teamB._id,
      format: MatchFormat.T20,
      totalOvers: 2,
      ballsPerOver: 6,
      ballType: BallType.WHITE,
      venue: 'Socket Ground',
    })
    .expect(201);

  const matchId = created.body.data._id;
  await api()
    .post(`/api/v1/matches/${matchId}/toss`)
    .set('Authorization', bearer(ownerA.accessToken))
    .send({ winner: teamA._id, decision: TossDecision.BAT })
    .expect(200);
  await api()
    .post(`/api/v1/matches/${matchId}/playing-xi`)
    .set('Authorization', bearer(ownerA.accessToken))
    .send({ teamId: teamA._id, playingXI: playersA.map((player) => player._id.toString()) })
    .expect(200);
  await api()
    .post(`/api/v1/matches/${matchId}/playing-xi`)
    .set('Authorization', bearer(ownerB.accessToken))
    .send({ teamId: teamB._id, playingXI: playersB.map((player) => player._id.toString()) })
    .expect(200);
  await api()
    .post(`/api/v1/matches/${matchId}/start`)
    .set('Authorization', bearer(ownerA.accessToken))
    .expect(200);

  return {
    ownerA,
    ownerB,
    teamA,
    matchId,
    playersA: playersA.map((player) => player._id.toString()),
    playersB: playersB.map((player) => player._id.toString()),
  };
};

type Fixture = Awaited<ReturnType<typeof createScoringFixture>>;

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

const wait = (ms: number): Promise<void> =>
  new Promise((resolve) => {
    setTimeout(resolve, ms);
  });

const startInnings = async (
  fixture: Fixture,
  token = fixture.ownerA.accessToken,
  key = `socket-start-${uniqueValue()}`
) => {
  const response = await api()
    .post(`/api/v1/scoring/${fixture.matchId}/start-innings`)
    .set('Authorization', bearer(token))
    .set('Idempotency-Key', key)
    .send({
      striker: fixture.playersA[0],
      nonStriker: fixture.playersA[1],
      bowler: fixture.playersB[0],
    })
    .expect(200);
  return response.body.data;
};

const recordBall = async (
  fixture: Fixture,
  version: number,
  extra: Record<string, unknown> = {},
  key = `socket-ball-${uniqueValue()}`
) => {
  const response = await api()
    .post(`/api/v1/scoring/${fixture.matchId}/ball`)
    .set('Authorization', bearer(fixture.ownerA.accessToken))
    .set('Idempotency-Key', key)
    .send({ runs: 0, expectedVersion: version, ...extra })
    .expect(201);
  return response.body.data;
};

describe('Socket.IO integration: live scoring', () => {
  beforeAll(async () => {
    await new Promise<void>((resolve) => {
      httpServer = server.listen(0, '127.0.0.1', resolve);
    });
    const address = httpServer.address();
    if (!address || typeof address === 'string') {
      throw new Error('Socket test server did not bind to a port.');
    }
    port = address.port;
  });

  afterAll(async () => {
    clients.forEach((socket) => socket.disconnect());
    await new Promise<void>((resolve) => httpServer.close(() => resolve()));
  });

  it('rejects unauthenticated and invalid socket handshakes', async () => {
    const anonymous = connectClient();
    const anonymousError = await waitFor(anonymous, 'connect_error');
    expect(anonymousError.message).toMatch(/Authentication token is required/);

    const invalid = connectClient('not-a-token');
    const invalidError = await waitFor(invalid, 'connect_error');
    expect(invalidError.message).toMatch(/Invalid authentication token/);
  });

  it('authorizes rooms and enforces scorer permissions', async () => {
    const fixture = await createScoringFixture('socket-access');
    const viewer = await registerAndVerify('socket-viewer');
    const scorerSocket = connectClient(fixture.ownerA.accessToken);
    const viewerSocket = connectClient(viewer.accessToken);
    await Promise.all([waitFor(scorerSocket, 'connect'), waitFor(viewerSocket, 'connect')]);

    const scorerAck = await emitWithAck<any>(scorerSocket, 'match:join', { matchId: fixture.matchId });
    const viewerAck = await emitWithAck<any>(viewerSocket, 'match:join', { matchId: fixture.matchId });

    expect(scorerAck.ok).toBe(true);
    expect(scorerAck.canScore).toBe(true);
    expect(viewerAck.ok).toBe(true);
    expect(viewerAck.canScore).toBe(false);

    const denied = await emitWithAck<any>(viewerSocket, 'match:join', { matchId: 'invalid-id' });
    expect(denied.ok).toBe(false);
    expect(denied.error.code).toBe('INVALID_MATCH_ID');

    await api()
      .post(`/api/v1/scoring/${fixture.matchId}/start-innings`)
      .set('Authorization', bearer(viewer.accessToken))
      .set('Idempotency-Key', `viewer-${uniqueValue()}`)
      .send({
        striker: fixture.playersA[0],
        nonStriker: fixture.playersA[1],
        bowler: fixture.playersB[0],
      })
      .expect(403);
  });

  it('emits score, wicket, over, innings, and match events after persistence', async () => {
    const fixture = await createScoringFixture('socket-events');
    const socket = connectClient(fixture.ownerA.accessToken);
    await waitFor(socket, 'connect');
    const joined = await emitWithAck<any>(socket, 'match:join', { matchId: fixture.matchId });
    expect(joined.ok).toBe(true);

    let stateEvents = 0;
    socket.on('match:state', () => {
      stateEvents += 1;
    });

    const inningsStarted = waitFor<any>(socket, 'match:innings-started');
    await startInnings(fixture);
    expect((await inningsStarted).inningsNumber).toBe(1);

    const deliveryEvent = waitFor<any>(socket, 'score:delivery');
    const stateEvent = waitFor<any>(socket, 'match:state');
    const firstBall = await recordBall(fixture, 1, {}, 'socket-first-ball');
    const delivery = await deliveryEvent;
    await stateEvent;
    expect(delivery.delivery.id).toBe(firstBall.deliveryId);
    expect(delivery.stateVersion).toBe(2);
    expect(stateEvents).toBeGreaterThan(0);

    const duplicateBaseline = stateEvents;
    await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', 'socket-first-ball')
      .send({ runs: 0, expectedVersion: 2 })
      .expect(201);
    await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', 'socket-first-ball')
      .send({ runs: 0, expectedVersion: 3 })
      .expect(201);
    await wait(200);
    expect(stateEvents).toBe(duplicateBaseline);

    const wicketEvent = waitFor<any>(socket, 'wicket:recorded');
    const afterDuplicate = await api().get(`/api/v1/scoring/${fixture.matchId}/state`).expect(200);
    await recordBall(fixture, afterDuplicate.body.data.activeInnings.stateVersion, {
      wicket: { type: 'BOWLED', batter: fixture.playersA[0] },
    });
    expect((await wicketEvent).delivery.isWicket).toBe(true);

    let version = (await api().get(`/api/v1/scoring/${fixture.matchId}/state`).expect(200)).body.data
      .activeInnings.stateVersion;
    for (let index = 0; index < 3; index += 1) {
      version = (await recordBall(fixture, version)).activeInnings.stateVersion;
    }
    const overEvent = waitFor<any>(socket, 'match:over-completed');
    await recordBall(fixture, version);
    expect((await overEvent).overNumber).toBe(1);

    version = (await api().get(`/api/v1/scoring/${fixture.matchId}/state`).expect(200)).body.data
      .activeInnings.stateVersion;
    const inningsEnded = waitFor<any>(socket, 'match:innings-ended');
    await api()
      .post(`/api/v1/scoring/${fixture.matchId}/innings-end`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `socket-end-${uniqueValue()}`)
      .send({ expectedVersion: version })
      .expect(200);
    expect((await inningsEnded).status).toBe('COMPLETED');

    const matchCompleted = waitFor<any>(socket, 'match:completed');
    await api()
      .post(`/api/v1/scoring/${fixture.matchId}/complete`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `socket-complete-${uniqueValue()}`)
      .send({})
      .expect(200);
    expect((await matchCompleted).matchStatus).toBe('COMPLETED');
  });

  it('isolates match rooms', async () => {
    const fixtureA = await createScoringFixture('socket-room-a');
    const fixtureB = await createScoringFixture('socket-room-b');
    const socketA = connectClient(fixtureA.ownerA.accessToken);
    const socketB = connectClient(fixtureB.ownerA.accessToken);
    await Promise.all([waitFor(socketA, 'connect'), waitFor(socketB, 'connect')]);
    await Promise.all([
      emitWithAck(socketA, 'match:join', { matchId: fixtureA.matchId }),
      emitWithAck(socketB, 'match:join', { matchId: fixtureB.matchId }),
    ]);
    await Promise.all([startInnings(fixtureA), startInnings(fixtureB)]);

    let receivedInA = false;
    socketA.on('score:delivery', () => {
      receivedInA = true;
    });
    const deliveryInB = waitFor<any>(socketB, 'score:delivery');
    await recordBall(fixtureB, 1);
    await deliveryInB;
    await wait(200);
    expect(receivedInA).toBe(false);
  });

  it('recovers authoritative state after reconnecting', async () => {
    const fixture = await createScoringFixture('socket-reconnect');
    const socket = connectClient(fixture.ownerA.accessToken);
    await waitFor(socket, 'connect');
    await emitWithAck(socket, 'match:join', { matchId: fixture.matchId });
    await startInnings(fixture);
    await recordBall(fixture, 1);
    socket.disconnect();

    const reconnected = connectClient(fixture.ownerA.accessToken);
    await waitFor(reconnected, 'connect');
    const synced = await emitWithAck<any>(reconnected, 'match:sync', { matchId: fixture.matchId });
    expect(synced.ok).toBe(true);
    expect(synced.stateVersion).toBe(2);
    expect(synced.state.activeInnings.totalBalls).toBe(1);
  });
});
