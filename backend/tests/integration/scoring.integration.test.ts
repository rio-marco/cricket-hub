import {
  BallType,
  MatchFormat,
  TossDecision,
} from '../../src/constants/enums';
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
      title: `${prefix} Scoring Match ${uniqueValue()}`,
      teamA: teamA._id,
      teamB: teamB._id,
      format: MatchFormat.T20,
      totalOvers: 2,
      ballsPerOver: 6,
      ballType: BallType.WHITE,
      venue: 'Scoring Ground',
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

const startFirstInnings = async (
  fixture: Awaited<ReturnType<typeof createScoringFixture>>,
  key = `start-${uniqueValue()}`
) => {
  const response = await api()
    .post(`/api/v1/scoring/${fixture.matchId}/start-innings`)
    .set('Authorization', bearer(fixture.ownerA.accessToken))
    .set('Idempotency-Key', key)
    .send({
      striker: fixture.playersA[0],
      nonStriker: fixture.playersA[1],
      bowler: fixture.playersB[0],
    })
    .expect(200);
  return response.body.data;
};

describe('MongoDB integration: scoring', () => {
  it('starts an innings and exposes authoritative scoring state', async () => {
    const fixture = await createScoringFixture('score-start');
    const state = await startFirstInnings(fixture);

    expect(state.activeInnings.status).toBe('IN_PROGRESS');
    expect(state.activeInnings.stateVersion).toBe(1);
    expect(state.activeInnings.currentBatters.striker._id ?? state.activeInnings.currentBatters.striker)
      .toBe(fixture.playersA[0]);
    expect(state.activeInnings.currentBowler._id ?? state.activeInnings.currentBowler)
      .toBe(fixture.playersB[0]);

    const fetched = await api()
      .get(`/api/v1/scoring/${fixture.matchId}/state`)
      .query({ order: 'asc' })
      .expect(200);
    expect(fetched.body.data.activeInnings.totalRuns).toBe(0);
    expect(fetched.body.data.deliveries).toEqual([]);
  });

  it('records balls with idempotency and optimistic version checks', async () => {
    const fixture = await createScoringFixture('score-balls');
    const started = await startFirstInnings(fixture);
    const version = started.activeInnings.stateVersion;

    const key = `ball-${uniqueValue()}`;
    const first = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', key)
      .send({ runs: 4, expectedVersion: version })
      .expect(201);

    expect(first.body.data.activeInnings.totalRuns).toBe(4);
    expect(first.body.data.activeInnings.totalBalls).toBe(1);
    expect(first.body.data.activeInnings.stateVersion).toBe(version + 1);
    expect(first.body.data.deliveries).toHaveLength(1);
    expect(first.body.data.deliveries[0].isBoundary).toBe(true);

    const replay = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', key)
      .send({ runs: 4, expectedVersion: version })
      .expect(201);
    expect(replay.body.data.activeInnings.totalRuns).toBe(4);
    expect(replay.body.data.deliveries).toHaveLength(1);

    const stale = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `stale-${uniqueValue()}`)
      .send({ runs: 1, expectedVersion: version })
      .expect(409);
    expect(stale.body.success).toBe(false);

    const afterUndo = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/undo`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `undo-${uniqueValue()}`)
      .send({ expectedVersion: version + 1 })
      .expect(200);
    expect(afterUndo.body.data.activeInnings.totalRuns).toBe(0);
    expect(afterUndo.body.data.activeInnings.totalBalls).toBe(0);
    expect(afterUndo.body.data.activeInnings.stateVersion).toBe(version + 2);
  });

  it('validates extras and corrections without duplicating deliveries', async () => {
    const fixture = await createScoringFixture('score-extras');
    const started = await startFirstInnings(fixture);

    const wide = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerB.accessToken))
      .set('Idempotency-Key', `wide-${uniqueValue()}`)
      .send({
        runs: 0,
        extraType: 'WIDE',
        extraRuns: 1,
        expectedVersion: started.activeInnings.stateVersion,
      })
      .expect(201);
    expect(wide.body.data.activeInnings.totalRuns).toBe(2);
    expect(wide.body.data.activeInnings.totalBalls).toBe(0);
    expect(wide.body.data.activeInnings.extras.wides).toBe(2);

    const deliveryId = wide.body.data.deliveryId;
    const corrected = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball/${deliveryId}/correct`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `correct-${uniqueValue()}`)
      .send({
        runs: 0,
        extraType: 'NO_BALL',
        extraRuns: 1,
        expectedVersion: wide.body.data.activeInnings.stateVersion,
      })
      .expect(200);
    expect(corrected.body.data.activeInnings.totalRuns).toBe(2);
    expect(corrected.body.data.activeInnings.totalBalls).toBe(0);
    expect(corrected.body.data.activeInnings.extras.wides).toBe(0);
    expect(corrected.body.data.activeInnings.extras.noBalls).toBe(2);
    expect(corrected.body.data.deliveries).toHaveLength(1);
  });

  it('records wickets, prevents bowling the same bowler in consecutive overs, and derives results', async () => {
    const fixture = await createScoringFixture('score-complete');
    const started = await startFirstInnings(fixture);
    let version = started.activeInnings.stateVersion;

    for (let index = 0; index < 6; index += 1) {
      const response = await api()
        .post(`/api/v1/scoring/${fixture.matchId}/ball`)
        .set('Authorization', bearer(fixture.ownerA.accessToken))
        .set('Idempotency-Key', `over-${uniqueValue()}-${index}`)
        .send({ runs: 1, expectedVersion: version })
        .expect(201);
      version = response.body.data.activeInnings.stateVersion;
    }

    expect(version).toBe(7);

    const illegalBowler = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `illegal-${uniqueValue()}`)
      .send({
        runs: 0,
        bowler: fixture.playersB[0],
        expectedVersion: version,
      })
      .expect(400);
    expect(illegalBowler.body.success).toBe(false);

    const wicket = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/ball`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `wicket-${uniqueValue()}`)
      .send({
        runs: 0,
        bowler: fixture.playersB[1],
        wicket: { type: 'BOWLED', batter: fixture.playersA[1] },
        expectedVersion: version,
      })
      .expect(201);
    expect(wicket.body.data.activeInnings.totalWickets).toBe(1);
    expect(wicket.body.data.activeInnings.currentBatters.striker._id ?? wicket.body.data.activeInnings.currentBatters.striker)
      .toBe(fixture.playersA[2]);

    const ended = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/innings-end`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `end-${uniqueValue()}`)
      .send({ expectedVersion: wicket.body.data.activeInnings.stateVersion })
      .expect(200);
    expect(ended.body.data.innings.find((item: any) => Number(item.inningsNumber) === 1).status)
      .toBe('COMPLETED');
    expect(ended.body.data.activeInnings.inningsNumber).toBe(2);

    const completed = await api()
      .post(`/api/v1/scoring/${fixture.matchId}/complete`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .set('Idempotency-Key', `complete-${uniqueValue()}`)
      .send({})
      .expect(200);
    expect(completed.body.data.match.status).toBe('COMPLETED');
    expect(completed.body.data.result).toBeDefined();
  });
});
