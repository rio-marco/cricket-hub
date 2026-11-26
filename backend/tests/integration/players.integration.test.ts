import { Types } from 'mongoose';

import {
  InningsStatus,
  MatchFormat,
  MatchStatus,
  ResultType,
  TeamMemberRole,
  TeamMemberStatus,
} from '../../src/constants/enums';
import Innings from '../../src/models/Innings';
import Match from '../../src/models/Match';
import Player from '../../src/models/Player';
import TeamMember from '../../src/models/TeamMember';
import User from '../../src/models/User';
import {
  api,
  bearer,
  createPlayerInDb,
  createPlayerViaApi,
  createTeamViaApi,
  registerAndVerify,
  uniqueValue,
} from './helpers';

describe('MongoDB integration: players', () => {
  it('creates a real player profile and upgrades the owner role once', async () => {
    const user = await registerAndVerify('player-create');
    const player = await createPlayerViaApi(user, { city: 'Pune', jerseyNumber: 7 });

    const stored = await Player.findById(player._id).populate('user', 'name email role');
    expect(stored).not.toBeNull();
    expect((stored!.user as any)._id.toString()).toBe(user.userId);
    expect(stored!.city).toBe('Pune');
    expect(stored!.jerseyNumber).toBe(7);
    expect((await User.findById(user.userId))?.role).toBe('PLAYER');

    await api()
      .post('/api/v1/players')
      .set('Authorization', bearer(user.accessToken))
      .send({ playingRole: 'BATSMAN', battingStyle: 'RIGHT_HAND' })
      .expect(409);
    expect(await Player.countDocuments({ user: user.userId })).toBe(1);
  });

  it('allows only the profile owner to update persisted player details', async () => {
    const owner = await registerAndVerify('player-update-owner');
    const other = await registerAndVerify('player-update-other');
    const player = await createPlayerViaApi(owner);

    await api()
      .put(`/api/v1/players/${player._id}`)
      .set('Authorization', bearer(other.accessToken))
      .send({ city: 'Unauthorized' })
      .expect(403);

    const updated = await api()
      .put(`/api/v1/players/${player._id}`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ city: 'Authorized City', bio: 'Updated bio' })
      .expect(200);
    expect(updated.body.data.city).toBe('Authorized City');

    const stored = await Player.findById(player._id);
    expect(stored?.city).toBe('Authorized City');
    expect(stored?.bio).toBe('Updated bio');
  });

  it('returns correct pagination and search results from MongoDB', async () => {
    const searchPrefix = `SH${uniqueValue().slice(-8)}`;
    const createdPlayers: any[] = [];

    for (let index = 0; index < 3; index += 1) {
      const user = await registerAndVerify(`${searchPrefix}${index}`);
      const player = await createPlayerInDb(new Types.ObjectId(user.userId), {
        city: `SearchCity${index}`,
      });
      createdPlayers.push(player);
    }

    const firstPage = await api()
      .get('/api/v1/players/search')
      .query({ search: searchPrefix, page: 1, limit: 2 })
      .expect(200);
    expect(firstPage.body.success).toBe(true);
    expect(firstPage.body.data).toHaveLength(2);
    expect(firstPage.body.pagination).toMatchObject({
      page: 1,
      limit: 2,
      total: 3,
      totalPages: 2,
      hasNextPage: true,
      hasPrevPage: false,
    });

    const secondPage = await api()
      .get('/api/v1/players')
      .query({ city: 'SearchCity0', page: 1, limit: 10 })
      .expect(200);
    expect(secondPage.body.data).toHaveLength(1);
    expect(secondPage.body.data[0]._id).toBe(createdPlayers[0]._id.toString());
  });

  it('aggregates career statistics and team history from related collections', async () => {
    const owner = await registerAndVerify('player-stats-owner');
    const team = await createTeamViaApi(owner, `Stats Team ${uniqueValue()}`);
    const player = await createPlayerInDb(new Types.ObjectId(owner.userId));

    await TeamMember.create({
      team: team._id,
      player: player._id,
      role: TeamMemberRole.PLAYER,
      status: TeamMemberStatus.ACTIVE,
      joinedAt: new Date(),
    });

    const match = await Match.create({
      title: 'Stats Match',
      teamA: team._id,
      teamB: team._id,
      format: MatchFormat.T20,
      totalOvers: 20,
      status: MatchStatus.COMPLETED,
      result: { resultType: ResultType.RUNS },
      playingXI_A: [player._id],
      playingXI_B: [],
    });
    await Innings.create({
      match: match._id,
      inningsNumber: 1,
      battingTeam: team._id,
      bowlingTeam: team._id,
      status: InningsStatus.COMPLETED,
      battingStats: [
        {
          player: player._id,
          runs: 84,
          balls: 52,
          fours: 6,
          sixes: 3,
          isNotOut: false,
          teamScore: 160,
          teamOvers: '20.0',
          wicketNumber: 1,
        },
      ],
      bowlingStats: [
        {
          player: player._id,
          overs: 4,
          balls: 24,
          maidens: 0,
          runs: 28,
          wickets: 2,
          dotBalls: 9,
        },
      ],
    });

    const stats = await api().get(`/api/v1/players/${player._id}/stats`).expect(200);
    expect(stats.body.data).toMatchObject({
      matches: 1,
      batting: {
        innings: 1,
        runs: 84,
        balls: 52,
        fours: 6,
        sixes: 3,
        highestScore: '84',
        strikeRate: 161.54,
      },
      bowling: {
        innings: 1,
        wickets: 2,
        runsConceded: 28,
        economy: 7,
      },
    });

    const teams = await api().get(`/api/v1/players/${player._id}/teams`).expect(200);
    expect(teams.body.data.activeTeams).toHaveLength(1);
    expect(teams.body.data.activeTeams[0].team._id).toBe(team._id.toString());
  });
});
