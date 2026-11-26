import { Types } from 'mongoose';

import {
  DismissalType,
  ExtraType,
  InningsStatus,
  MatchFormat,
  MatchStatus,
  ResultType,
} from '../../src/constants/enums';
import Delivery from '../../src/models/Delivery';
import Innings from '../../src/models/Innings';
import Match from '../../src/models/Match';
import {
  api,
  createPlayerInDb,
  createTeamViaApi,
  openTournamentViaApi,
  registerAndVerify,
  uniqueValue,
} from './helpers';

describe('MongoDB integration: player statistics and leaderboards', () => {
  let organizer: Awaited<ReturnType<typeof registerAndVerify>>;
  let teamA: any;
  let teamB: any;

  beforeAll(async () => {
    organizer = await registerAndVerify('statistics-organizer');
    teamA = await createTeamViaApi(organizer, `Stats A ${uniqueValue()}`);
    teamB = await createTeamViaApi(organizer, `Stats B ${uniqueValue()}`);
  });

  beforeEach(async () => {
    await Delivery.deleteMany({});
    await Innings.deleteMany({});
    await Match.deleteMany({});
  });

  const createPlayer = async (prefix: string) => {
    const owner = await registerAndVerify(prefix);
    return createPlayerInDb(new Types.ObjectId(owner.userId));
  };

  const createMatchFixture = async (options: {
    title: string;
    playingXI: Types.ObjectId[];
    battingStats: any[];
    bowlingStats?: any[];
    tournament?: Types.ObjectId;
    format?: MatchFormat;
    matchDate?: Date;
    matchStatus?: MatchStatus;
    resultType?: ResultType;
    inningsStatus?: InningsStatus;
  }) => {
    const match = await Match.create({
      title: options.title,
      tournament: options.tournament,
      teamA: teamA._id,
      teamB: teamB._id,
      format: options.format ?? MatchFormat.T20,
      totalOvers: 20,
      ballsPerOver: 6,
      matchDate: options.matchDate ?? new Date('2026-01-15T00:00:00.000Z'),
      status: options.matchStatus ?? MatchStatus.COMPLETED,
      result: { resultType: options.resultType ?? ResultType.RUNS },
      playingXI_A: options.playingXI,
      playingXI_B: [],
      substitutes_A: [],
      substitutes_B: [],
    });

    const innings = await Innings.create({
      match: match._id,
      inningsNumber: 1,
      battingTeam: teamA._id,
      bowlingTeam: teamB._id,
      status: options.inningsStatus ?? InningsStatus.COMPLETED,
      totalRuns: options.battingStats.reduce(
        (total, stat) => total + (stat.runs ?? 0),
        0
      ),
      totalWickets: options.battingStats.filter((stat) => !stat.isNotOut).length,
      battingStats: options.battingStats,
      bowlingStats: options.bowlingStats ?? [],
    });

    return { match, innings };
  };

  it('aggregates completed innings only and ignores undone/corrected deliveries', async () => {
    const batter = await createPlayer('stats-batter');
    const other = await createPlayer('stats-other');

    const { innings } = await createMatchFixture({
      title: 'Completed Stats Match',
      playingXI: [batter._id, other._id],
      battingStats: [
        {
          player: batter._id,
          runs: 84,
          balls: 52,
          fours: 6,
          sixes: 3,
          isNotOut: false,
        },
      ],
      bowlingStats: [
        {
          player: batter._id,
          balls: 24,
          runs: 28,
          wickets: 2,
          maidens: 0,
          dotBalls: 9,
          wides: 2,
          noBalls: 1,
        },
      ],
    });

    const deliveryBase = {
      innings: innings._id,
      match: innings.match,
      batter: other._id,
      bowler: other._id,
      nonStriker: batter._id,
      runs: { batter: 0, extras: 0, total: 0 },
      extras: { type: ExtraType.NONE, runs: 0 },
      isLegal: true,
    };

    await Delivery.create({
      ...deliveryBase,
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      isWicket: true,
      wicket: {
        type: DismissalType.CAUGHT,
        batter: other._id,
        fielder: batter._id,
        isStriker: true,
      },
      isUndone: true,
    });
    await Delivery.create({
      ...deliveryBase,
      overNumber: 0,
      ballNumber: 1,
      sequenceNumber: 1,
      isWicket: true,
      wicket: {
        type: DismissalType.RUN_OUT,
        batter: other._id,
        fielder: batter._id,
        isStriker: true,
      },
      isUndone: false,
    });
    await Delivery.create({
      ...deliveryBase,
      overNumber: 0,
      ballNumber: 2,
      sequenceNumber: 2,
      isWicket: true,
      wicket: {
        type: DismissalType.CAUGHT,
        batter: other._id,
        fielder: batter._id,
        isStriker: true,
      },
      isUndone: false,
    });
    await Delivery.create({
      ...deliveryBase,
      overNumber: 0,
      ballNumber: 3,
      sequenceNumber: 3,
      isWicket: true,
      wicket: {
        type: DismissalType.STUMPED,
        batter: other._id,
        fielder: batter._id,
        isStriker: true,
      },
      isUndone: false,
    });

    await createMatchFixture({
      title: 'Abandoned Stats Match',
      playingXI: [batter._id],
      matchStatus: MatchStatus.ABANDONED,
      resultType: ResultType.ABANDONED,
      battingStats: [
        {
          player: batter._id,
          runs: 999,
          balls: 100,
          fours: 0,
          sixes: 0,
          isNotOut: true,
        },
      ],
    });
    await createMatchFixture({
      title: 'Incomplete Stats Match',
      playingXI: [batter._id],
      inningsStatus: InningsStatus.IN_PROGRESS,
      battingStats: [
        {
          player: batter._id,
          runs: 888,
          balls: 80,
          fours: 0,
          sixes: 0,
          isNotOut: true,
        },
      ],
    });

    const response = await api()
      .get(`/api/v1/statistics/players/${batter._id}/overall`)
      .expect(200);

    expect(response.body.data).toMatchObject({
      matches: 1,
      playerOfMatch: 0,
      batting: {
        innings: 1,
        runs: 84,
        balls: 52,
        fours: 6,
        sixes: 3,
        highestScore: '84',
        average: 84,
        strikeRate: 161.54,
      },
      bowling: {
        innings: 1,
        balls: 24,
        runsConceded: 28,
        wickets: 2,
        wides: 2,
        noBalls: 1,
        economy: 7,
      },
      fielding: {
        catches: 1,
        runOuts: 1,
        stumpings: 1,
        totalDismissals: 3,
      },
    });
    expect(response.body.data.recentForm).toHaveLength(1);
  });

  it('filters statistics by tournament, season, format and date range', async () => {
    const player = await createPlayer('stats-filter-player');
    const tournamentId = await openTournamentViaApi(organizer, `Stats Cup ${uniqueValue()}`);

    await createMatchFixture({
      title: 'Tournament Match',
      playingXI: [player._id],
      tournament: new Types.ObjectId(tournamentId),
      matchDate: new Date('2026-03-10T00:00:00.000Z'),
      battingStats: [
        {
          player: player._id,
          runs: 50,
          balls: 40,
          fours: 4,
          sixes: 1,
          isNotOut: true,
        },
      ],
    });
    await createMatchFixture({
      title: 'Friendly Match',
      playingXI: [player._id],
      format: MatchFormat.ODI,
      matchDate: new Date('2025-03-10T00:00:00.000Z'),
      battingStats: [
        {
          player: player._id,
          runs: 120,
          balls: 100,
          fours: 8,
          sixes: 4,
          isNotOut: false,
        },
      ],
    });

    const all = await api()
      .get(`/api/v1/statistics/players/${player._id}/batting`)
      .expect(200);
    expect(all.body.data.runs).toBe(170);

    const tournamentOnly = await api()
      .get(`/api/v1/statistics/players/${player._id}/batting`)
      .query({ tournament: tournamentId })
      .expect(200);
    expect(tournamentOnly.body.data.runs).toBe(50);

    const seasonOnly = await api()
      .get(`/api/v1/statistics/players/${player._id}/batting`)
      .query({ season: 2025 })
      .expect(200);
    expect(seasonOnly.body.data.runs).toBe(120);

    const formatOnly = await api()
      .get(`/api/v1/statistics/players/${player._id}/batting`)
      .query({ format: MatchFormat.T20 })
      .expect(200);
    expect(formatOnly.body.data.runs).toBe(50);

    const dateRange = await api()
      .get(`/api/v1/statistics/players/${player._id}/batting`)
      .query({ from: '2026-01-01', to: '2026-12-31' })
      .expect(200);
    expect(dateRange.body.data.runs).toBe(50);
  });

  it('sorts leaderboards, applies aliases and paginates results', async () => {
    const topScorer = await createPlayer('stats-top-scorer');
    const secondScorer = await createPlayer('stats-second-scorer');
    const bowler = await createPlayer('stats-bowler');

    await createMatchFixture({
      title: 'High Score Match',
      playingXI: [topScorer._id, bowler._id],
      matchDate: new Date('2026-04-01T00:00:00.000Z'),
      battingStats: [
        {
          player: topScorer._id,
          runs: 120,
          balls: 70,
          fours: 10,
          sixes: 5,
          isNotOut: false,
        },
      ],
      bowlingStats: [
        {
          player: bowler._id,
          balls: 24,
          runs: 16,
          wickets: 5,
          maidens: 1,
          dotBalls: 12,
        },
      ],
    });
    await createMatchFixture({
      title: 'Second Score Match',
      playingXI: [secondScorer._id],
      matchDate: new Date('2026-04-02T00:00:00.000Z'),
      battingStats: [
        {
          player: secondScorer._id,
          runs: 84,
          balls: 52,
          fours: 6,
          sixes: 3,
          isNotOut: true,
        },
      ],
    });

    const runs = await api().get('/api/v1/leaderboards/runs').query({ limit: 1 }).expect(200);
    expect(runs.body.data[0]).toMatchObject({
      rank: 1,
      playerId: topScorer._id.toString(),
      metric: 'runs',
      value: 120,
    });
    expect(runs.body.pagination).toMatchObject({ page: 1, limit: 1, total: 2, totalPages: 2 });

    const batsmenAlias = await api().get('/api/v1/leaderboards/batsmen').expect(200);
    expect(batsmenAlias.body.data[0].playerId).toBe(topScorer._id.toString());

    const bowlersAlias = await api().get('/api/v1/leaderboards/bowlers').expect(200);
    expect(bowlersAlias.body.data[0]).toMatchObject({
      playerId: bowler._id.toString(),
      value: 5,
    });

    const secondPage = await api()
      .get('/api/v1/leaderboards')
      .query({ metric: 'runs', page: 2, limit: 1 })
      .expect(200);
    expect(secondPage.body.data[0]).toMatchObject({
      rank: 2,
      playerId: secondScorer._id.toString(),
      value: 84,
    });
  });

  it('returns empty leaderboards instead of counting incomplete matches', async () => {
    const player = await createPlayer('stats-empty-player');
    await createMatchFixture({
      title: 'Live Only Match',
      playingXI: [player._id],
      matchStatus: MatchStatus.LIVE,
      resultType: undefined as any,
      inningsStatus: InningsStatus.IN_PROGRESS,
      battingStats: [
        {
          player: player._id,
          runs: 77,
          balls: 30,
          fours: 4,
          sixes: 4,
          isNotOut: true,
        },
      ],
    });

    const response = await api().get('/api/v1/leaderboards/runs').expect(200);
    expect(response.body.data).toEqual([]);
    expect(response.body.pagination.total).toBe(0);
  });

  it('rejects invalid leaderboard metrics and filters', async () => {
    await api().get('/api/v1/leaderboards').query({ metric: 'unknown' }).expect(400);
    await api()
      .get('/api/v1/statistics/players/not-an-id/overall')
      .expect(400);
  });
});
