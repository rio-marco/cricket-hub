import { Types } from 'mongoose';

import { BallType, MatchFormat, MatchStatus, TossDecision } from '../../src/constants/enums';
import Innings from '../../src/models/Innings';
import Match from '../../src/models/Match';
import User from '../../src/models/User';
import {
  api,
  bearer,
  createPlayerInDb,
  createTeamViaApi,
  createVerifiedUserInDb,
  registerAndVerify,
  uniqueValue,
} from './helpers';

const createMatchFixture = async (prefix: string) => {
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

  const response = await api()
    .post('/api/v1/matches')
    .set('Authorization', bearer(ownerA.accessToken))
    .send({
      title: `${prefix} Match ${uniqueValue()}`,
      teamA: teamA._id,
      teamB: teamB._id,
      format: MatchFormat.T20,
      totalOvers: 20,
      ballType: BallType.WHITE,
      venue: 'Integration Ground',
    })
    .expect(201);

  return {
    ownerA,
    ownerB,
    teamA,
    teamB,
    playersA: playersA.map((player) => player._id.toString()),
    playersB: playersB.map((player) => player._id.toString()),
    matchId: response.body.data._id,
  };
};

describe('MongoDB integration: matches', () => {
  it('creates and filters real matches with validated team references', async () => {
    const fixture = await createMatchFixture('match-create');
    const stored = await Match.findById(fixture.matchId);
    expect(stored).not.toBeNull();
    expect(stored!.status).toBe('UPCOMING');
    expect(stored!.teamA.toString()).toBe(fixture.teamA._id);
    expect(stored!.teamB.toString()).toBe(fixture.teamB._id);
    expect(stored!.totalOvers).toBe(20);

    const sameTeams = await api()
      .post('/api/v1/matches')
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({
        teamA: fixture.teamA._id,
        teamB: fixture.teamA._id,
        format: MatchFormat.T20,
        totalOvers: 20,
      })
      .expect(400);
    expect(sameTeams.body.success).toBe(false);

    const listed = await api()
      .get('/api/v1/matches')
      .query({ teamId: fixture.teamA._id, status: 'UPCOMING', page: 1, limit: 10 })
      .expect(200);
    expect(listed.body.data.some((match: any) => match._id === fixture.matchId)).toBe(true);
    expect(listed.body.pagination.total).toBeGreaterThanOrEqual(1);
  });

  it('allows only match managers to update persisted setup details', async () => {
    const fixture = await createMatchFixture('match-update');
    const outsider = await registerAndVerify('match-update-outsider');

    await api()
      .put(`/api/v1/matches/${fixture.matchId}`)
      .set('Authorization', bearer(outsider.accessToken))
      .send({ venue: 'Unauthorized Ground' })
      .expect(403);

    const updated = await api()
      .put(`/api/v1/matches/${fixture.matchId}`)
      .set('Authorization', bearer(fixture.ownerB.accessToken))
      .send({ venue: 'Authorized Ground', title: 'Updated Title' })
      .expect(200);
    expect(updated.body.data.venue).toBe('Authorized Ground');

    const stored = await Match.findById(fixture.matchId);
    expect(stored?.venue).toBe('Authorized Ground');
    expect(stored?.title).toBe('Updated Title');
  });

  it('records a validated toss once and persists it in MongoDB', async () => {
    const fixture = await createMatchFixture('match-toss');
    const outsider = await registerAndVerify('match-toss-outsider');

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/toss`)
      .set('Authorization', bearer(outsider.accessToken))
      .send({ winner: fixture.teamA._id, decision: TossDecision.BAT })
      .expect(403);

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/toss`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ winner: outsider.userId, decision: TossDecision.BAT })
      .expect(400);

    const tossed = await api()
      .post(`/api/v1/matches/${fixture.matchId}/toss`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ winner: fixture.teamA._id, decision: TossDecision.BAT })
      .expect(200);
    expect(tossed.body.data.status).toBe('TOSS');
    expect(tossed.body.data.toss.winner._id).toBe(fixture.teamA._id);

    const stored = await Match.findById(fixture.matchId);
    expect(stored?.status).toBe('TOSS');
    expect(stored?.toss?.winner?.toString()).toBe(fixture.teamA._id);
    expect(stored?.toss?.decision).toBe(TossDecision.BAT);

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/toss`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ winner: fixture.teamB._id, decision: TossDecision.BOWL })
      .expect(400);
  });

  it('saves both Playing XIs with unique players and assigns a scorer', async () => {
    const fixture = await createMatchFixture('match-xi');
    const scorer = await registerAndVerify('match-scorer');

    const duplicatePlayers = [...fixture.playersA.slice(0, 10), fixture.playersA[0]];
    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ teamId: fixture.teamA._id, playingXI: duplicatePlayers })
      .expect(400);

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ teamId: new Types.ObjectId().toString(), playingXI: fixture.playersA })
      .expect(400);

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ teamId: fixture.teamA._id, playingXI: fixture.playersA })
      .expect(200);
    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerB.accessToken))
      .send({ teamId: fixture.teamB._id, playingXI: fixture.playersB })
      .expect(200);

    const stored = await Match.findById(fixture.matchId);
    expect(stored?.playingXI_A.map((id) => id.toString())).toEqual(fixture.playersA);
    expect(stored?.playingXI_B.map((id) => id.toString())).toEqual(fixture.playersB);

    const outsider = await registerAndVerify('match-scorer-outsider');
    await api()
      .post(`/api/v1/matches/${fixture.matchId}/scorer`)
      .set('Authorization', bearer(outsider.accessToken))
      .send({ scorerId: scorer.userId })
      .expect(403);

    const assigned = await api()
      .post(`/api/v1/matches/${fixture.matchId}/scorer`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ scorerId: scorer.userId })
      .expect(200);
    expect(assigned.body.data.scorer._id).toBe(scorer.userId);

    await api()
      .put(`/api/v1/matches/${fixture.matchId}`)
      .set('Authorization', bearer(scorer.accessToken))
      .send({ venue: 'Scorer Ground' })
      .expect(200);
    expect((await Match.findById(fixture.matchId))?.venue).toBe('Scorer Ground');
  });

  it('starts only fully prepared matches and creates the first innings', async () => {
    const fixture = await createMatchFixture('match-start');

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/start`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .expect(400);

    await api()
      .post(`/api/v1/matches/${fixture.matchId}/toss`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ winner: fixture.teamA._id, decision: TossDecision.BAT })
      .expect(200);
    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .send({ teamId: fixture.teamA._id, playingXI: fixture.playersA })
      .expect(200);
    await api()
      .post(`/api/v1/matches/${fixture.matchId}/playing-xi`)
      .set('Authorization', bearer(fixture.ownerB.accessToken))
      .send({ teamId: fixture.teamB._id, playingXI: fixture.playersB })
      .expect(200);

    const started = await api()
      .post(`/api/v1/matches/${fixture.matchId}/start`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .expect(200);
    expect(started.body.data.match.status).toBe('LIVE');
    expect(started.body.data.innings.battingTeam._id).toBe(fixture.teamA._id);
    expect(started.body.data.innings.bowlingTeam._id).toBe(fixture.teamB._id);

    const inningsCount = await Innings.countDocuments({ match: fixture.matchId });
    expect(inningsCount).toBe(1);
    expect((await Match.findById(fixture.matchId))?.status).toBe('LIVE');

    const details = await api()
      .get(`/api/v1/matches/${fixture.matchId}`)
      .expect(200);
    expect(details.body.data.innings).toHaveLength(1);
    expect(details.body.data.teamA._id).toBe(fixture.teamA._id);

    const scorecard = await api()
      .get(`/api/v1/matches/${fixture.matchId}/scorecard`)
      .expect(200);
    expect(scorecard.body.data.match.status).toBe('LIVE');
    expect(scorecard.body.data.innings[0].battingOrder).toHaveLength(11);

    await api()
      .delete(`/api/v1/matches/${fixture.matchId}`)
      .set('Authorization', bearer(fixture.ownerA.accessToken))
      .expect(400);
  });

  it('deletes an UPCOMING match and cascades any innings records', async () => {
    const fixture = await createMatchFixture('match-delete');
    await Innings.create({
      match: new Types.ObjectId(fixture.matchId),
      inningsNumber: 1,
      battingTeam: fixture.teamA._id,
      bowlingTeam: fixture.teamB._id,
    });

    await api()
      .delete(`/api/v1/matches/${fixture.matchId}`)
      .set('Authorization', bearer(fixture.ownerB.accessToken))
      .expect(200);

    expect(await Match.findById(fixture.matchId)).toBeNull();
    expect(await Innings.countDocuments({ match: fixture.matchId })).toBe(0);
    expect(await User.countDocuments({ email: fixture.ownerA.email })).toBe(1);
  });
});
