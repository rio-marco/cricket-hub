import { AuctionAuditAction } from '../../src/constants/enums';
import Auction from '../../src/models/Auction';
import AuctionAudit from '../../src/models/AuctionAudit';
import AuctionBid from '../../src/models/AuctionBid';
import AuctionPlayer from '../../src/models/AuctionPlayer';
import { api, bearer, createPlayerViaApi, createTeamViaApi, registerAndVerify, uniqueValue, TestUser } from './helpers';

const createAuctionFixture = async (prefix: string, overrides: Record<string, unknown> = {}) => {
  const organizer = await registerAndVerify(`${prefix}-organizer`);
  const ownerA = await registerAndVerify(`${prefix}-owner-a`);
  const ownerB = await registerAndVerify(`${prefix}-owner-b`);
  const teamA = await createTeamViaApi(ownerA, `${prefix} A ${uniqueValue()}`);
  const teamB = await createTeamViaApi(ownerB, `${prefix} B ${uniqueValue()}`);
  const playerUsers = await Promise.all([
    registerAndVerify(`${prefix}-p1`),
    registerAndVerify(`${prefix}-p2`),
    registerAndVerify(`${prefix}-p3`),
  ]);
  const players = await Promise.all(
    playerUsers.map((user) => createPlayerViaApi(user, { city: `${prefix} City` }))
  );

  const created = await api()
    .post('/api/v1/auctions')
    .set('Authorization', bearer(organizer.accessToken))
    .send({
      name: `${prefix} Auction ${uniqueValue()}`,
      teams: [teamA._id, teamB._id],
      purseAmount: 100000,
      basePrice: 10000,
      minBidIncrement: 5000,
      maxSquadSize: 2,
      minSquadSize: 1,
      playerCategories: ['BATSMAN', 'BOWLER'],
      rules: { localTournament: true },
      status: 'UPCOMING',
      ...overrides,
    })
    .expect(201);

  const auctionId = created.body.data.auction._id as string;
  const registered = await api()
    .post(`/api/v1/auctions/${auctionId}/players`)
    .set('Authorization', bearer(organizer.accessToken))
    .send({
      players: players.map((player, index) => ({
        playerId: player._id,
        basePrice: 10000,
        category: index === 0 ? 'BATSMAN' : 'BOWLER',
        order: index + 1,
      })),
    })
    .expect(201);

  return {
    organizer,
    ownerA,
    ownerB,
    teamA,
    teamB,
    players,
    auctionId,
    state: registered.body.data,
  };
};

type Fixture = Awaited<ReturnType<typeof createAuctionFixture>>;

const getState = async (auctionId: string) => {
  const response = await api().get(`/api/v1/auctions/${auctionId}/state`).expect(200);
  return response.body.data;
};

const start = async (fixture: Fixture) => {
  const response = await api()
    .post(`/api/v1/auctions/${fixture.auctionId}/start`)
    .set('Authorization', bearer(fixture.organizer.accessToken))
    .expect(200);
  return response.body.data;
};

const placeBid = async (
  fixture: Fixture,
  user: TestUser,
  amount: number,
  key: string,
  expectedVersion?: number,
  status: number | null = 201
) => {
  const request = api()
    .post(`/api/v1/auctions/${fixture.auctionId}/bid`)
    .set('Authorization', bearer(user.accessToken))
    .set('Idempotency-Key', key)
    .send({ team: user === fixture.ownerA ? fixture.teamA._id : fixture.teamB._id, amount, expectedVersion });
  return status === null ? request : request.expect(status);
};

describe('MongoDB integration: auction management and live bidding', () => {
  it('creates, lists, configures, and deletes auctions', async () => {
    const fixture = await createAuctionFixture('auction-crud');
    expect(fixture.state.auction.status).toBe('UPCOMING');
    expect(fixture.state.auction.minBidIncrement).toBe(5000);
    expect(fixture.state.teams).toHaveLength(2);

    const list = await api().get('/api/v1/auctions?status=UPCOMING').expect(200);
    expect(list.body.data.some((item: any) => item._id === fixture.auctionId)).toBe(true);
    expect(list.body.pagination.total).toBeGreaterThan(0);

    const updated = await api()
      .put(`/api/v1/auctions/${fixture.auctionId}`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .send({ name: 'Updated Auction Name', minBidIncrement: 7500, rules: { localTournament: false } })
      .expect(200);
    expect(updated.body.data.auction.name).toBe('Updated Auction Name');
    expect(updated.body.data.auction.minBidIncrement).toBe(7500);
    expect(updated.body.data.auction.rules.localTournament).toBe(false);

    const detail = await api().get(`/api/v1/auctions/${fixture.auctionId}`).expect(200);
    expect(detail.body.data.auction.name).toBe('Updated Auction Name');

    await api()
      .delete(`/api/v1/auctions/${fixture.auctionId}`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);
    expect(await Auction.findById(fixture.auctionId)).toBeNull();
    expect(await AuctionPlayer.countDocuments({ auction: fixture.auctionId })).toBe(0);
  });

  it('registers eligible players, prevents duplicates, and manages availability', async () => {
    const fixture = await createAuctionFixture('auction-players');
    expect(fixture.state.players).toHaveLength(3);
    expect(fixture.state.players[0].category).toBe('BATSMAN');

    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/players`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .send({ players: [{ playerId: fixture.players[0]._id }] })
      .expect(409);

    const auctionPlayerId = fixture.state.players[0]._id;
    const unavailable = await api()
      .patch(`/api/v1/auctions/${fixture.auctionId}/players/${auctionPlayerId}/availability`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .send({ available: false })
      .expect(200);
    expect(unavailable.body.data.players.find((item: any) => item._id === auctionPlayerId).available).toBe(false);

    await api()
      .delete(`/api/v1/auctions/${fixture.auctionId}/players/${auctionPlayerId}`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);
    const state = await getState(fixture.auctionId);
    expect(state.players).toHaveLength(2);
  });

  it('validates increments, idempotency, duplicates, and budget limits', async () => {
    const fixture = await createAuctionFixture('auction-bids', { purseAmount: 25000 });
    const started = await start(fixture);
    const version = started.stateVersion;

    await placeBid(fixture, fixture.ownerA, 10000, 'auction-bid-1', version);
    await placeBid(fixture, fixture.ownerB, 12000, 'auction-bid-2', version + 1, 400);

    const replay = await placeBid(fixture, fixture.ownerA, 10000, 'auction-bid-1', version);
    expect(replay.body.data.commit).toBeUndefined();
    expect(await AuctionBid.countDocuments({ auction: fixture.auctionId })).toBe(1);

    await placeBid(fixture, fixture.ownerA, 15000, 'auction-bid-3', undefined, 409);
    await placeBid(fixture, fixture.ownerB, 25000, 'auction-bid-4');
    await placeBid(fixture, fixture.ownerA, 30000, 'auction-bid-5', undefined, 400);

    const state = await getState(fixture.auctionId);
    const teamB = state.teams.find((item: any) => String(item.team._id) === String(fixture.teamB._id));
    expect(teamB.pendingCommitment).toBe(25000);
    expect(teamB.availableBudget).toBe(0);
    expect(teamB.maxAffordableBid).toBe(0);
    expect(state.currentPlayer.currentBid).toBe(25000);
    expect(String(state.currentPlayer.highestBidder._id)).toBe(String(fixture.teamB._id));
  });

  it('processes simultaneous bids with optimistic concurrency', async () => {
    const fixture = await createAuctionFixture('auction-concurrency');
    const started = await start(fixture);
    const version = started.stateVersion;

    const responses = await Promise.all([
      placeBid(fixture, fixture.ownerA, 10000, 'concurrent-a', version, null),
      placeBid(fixture, fixture.ownerB, 15000, 'concurrent-b', version, null),
    ]);
    expect(responses.filter((response) => response.status === 201)).toHaveLength(1);
    expect(await AuctionBid.countDocuments({ auction: fixture.auctionId })).toBe(1);
    const state = await getState(fixture.auctionId);
    expect(state.stateVersion).toBe(version + 1);
  });

  it('safely sells, marks unsold, advances, completes, and records history', async () => {
    const fixture = await createAuctionFixture('auction-lifecycle');
    await start(fixture);

    const failedSold = await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/sold`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(409);
    expect(failedSold.body.success).toBe(false);

    await placeBid(fixture, fixture.ownerA, 10000, 'lifecycle-bid-unsold');
    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/unsold`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);

    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/next`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);
    await placeBid(fixture, fixture.ownerB, 15000, 'lifecycle-bid-sold');
    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/sold`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);

    const completed = await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/complete`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);
    expect(completed.body.data.auction.status).toBe('COMPLETED');
    expect(completed.body.data.results.sold).toHaveLength(1);
    expect(completed.body.data.results.unsold).toHaveLength(2);

    const history = await api().get(`/api/v1/auctions/${fixture.auctionId}/history`).expect(200);
    expect(history.body.data.map((bid: any) => bid.sequenceNumber).sort()).toEqual([1, 2]);
    expect(await AuctionAudit.countDocuments({ auction: fixture.auctionId, action: AuctionAuditAction.SOLD })).toBe(1);

    const purse = await api()
      .get(`/api/v1/auctions/${fixture.auctionId}/teams/${fixture.teamB._id}/purse`)
      .expect(200);
    expect(purse.body.data.spent).toBe(15000);
    expect(purse.body.data.remainingBudget).toBe(85000);
    expect(purse.body.data.playersPurchased).toBe(1);
  });

  it('enforces authorization for management and bidding', async () => {
    const fixture = await createAuctionFixture('auction-auth');
    const viewer = await registerAndVerify('auction-viewer');

    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/start`)
      .set('Authorization', bearer(viewer.accessToken))
      .expect(403);
    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/players`)
      .set('Authorization', bearer(viewer.accessToken))
      .send({ players: [{ playerId: fixture.players[0]._id }] })
      .expect(403);

    const state = await api().get(`/api/v1/auctions/${fixture.auctionId}/state`).expect(200);
    expect(state.body.data.permissions.canManage).toBe(false);

    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/start`)
      .set('Authorization', bearer(fixture.organizer.accessToken))
      .expect(200);

    await api()
      .post(`/api/v1/auctions/${fixture.auctionId}/bid`)
      .set('Authorization', bearer(viewer.accessToken))
      .send({ team: fixture.teamA._id, amount: 10000 })
      .expect(403);
  });

  it('rolls back invalid mutations without persisting bids or audit records', async () => {
    const fixture = await createAuctionFixture('auction-rollback');
    await start(fixture);
    const beforeBids = await AuctionBid.countDocuments({ auction: fixture.auctionId });
    const beforeAudits = await AuctionAudit.countDocuments({ auction: fixture.auctionId });

    await placeBid(fixture, fixture.ownerA, 1, 'rollback-low-bid', undefined, 400);

    expect(await AuctionBid.countDocuments({ auction: fixture.auctionId })).toBe(beforeBids);
    expect(await AuctionAudit.countDocuments({ auction: fixture.auctionId })).toBe(beforeAudits);
  });
});
