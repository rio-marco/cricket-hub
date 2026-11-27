import { MatchStatus, ResultType } from '../../constants/enums';
import { ScoringAuditAction } from '../../models/ScoringAudit';

jest.mock('../../models/ScoringAudit', () => {
  const actual = jest.requireActual('../../models/ScoringAudit');
  return {
    ...actual,
    __esModule: true,
    default: {
      findOne: jest.fn(),
      create: jest.fn(),
    },
  };
});

jest.mock('../../models/Match', () => ({ __esModule: true, default: { findById: jest.fn() } }));
jest.mock('../../models/Innings', () => ({ __esModule: true, default: { findOne: jest.fn(), findById: jest.fn() } }));
jest.mock('../../models/Delivery', () => ({ __esModule: true, default: { findOne: jest.fn(), find: jest.fn() } }));
jest.mock('../match.service', () => ({ __esModule: true, default: { canManageMatch: jest.fn(), getNotificationRecipients: jest.fn() } }));
jest.mock('../notificationHooks.service', () => ({ __esModule: true, notifySafely: jest.fn() }));
jest.mock('mongoose', () => {
  const actual = jest.requireActual('mongoose');
  return {
    ...actual,
    connection: { startSession: jest.fn() },
  };
});

import mongoose from 'mongoose';
import Match from '../../models/Match';
import ScoringAudit from '../../models/ScoringAudit';
import matchService from '../match.service';
import { ScoringService } from '../scoring.service';

const mockSession = () => {
  const session = { startTransaction: jest.fn(), commitTransaction: jest.fn(), abortTransaction: jest.fn(), endSession: jest.fn() };
  (mongoose.connection.startSession as jest.Mock).mockResolvedValue(session);
  return session;
};

const makeMatch = (overrides: any = {}) => ({
  _id: '507f1f77bcf86cd799439011',
  teamA: '507f1f77bcf86cd799439021',
  teamB: '507f1f77bcf86cd799439022',
  status: MatchStatus.LIVE,
  currentInnings: 2,
  playingXI_A: ['507f1f77bcf86cd799439031'],
  playingXI_B: ['507f1f77bcf86cd799439032'],
  save: jest.fn().mockResolvedValue(undefined),
  ...overrides,
});

describe('ScoringService hardening', () => {
  beforeEach(() => jest.clearAllMocks());

  it('checks authorization before idempotency replay', async () => {
    mockSession();
    const liveQuery: any = Promise.resolve(makeMatch());
    liveQuery.session = jest.fn().mockReturnValue(liveQuery);
    (Match.findById as jest.Mock).mockReturnValue(liveQuery);
    (matchService.canManageMatch as jest.Mock).mockResolvedValue(false);

    await expect(
      new ScoringService().completeMatch('507f1f77bcf86cd799439011', 'user-1', { idempotencyKey: 'dup-key', expectedVersion: 1 } as any)
    ).rejects.toMatchObject({ statusCode: 403 });

    expect(ScoringAudit.findOne).not.toHaveBeenCalled();
  });

  it('rejects scoring mutations on completed matches', async () => {
    mockSession();
    const completedQuery: any = Promise.resolve(makeMatch({ status: MatchStatus.COMPLETED }));
    completedQuery.session = jest.fn().mockReturnValue(completedQuery);
    (Match.findById as jest.Mock).mockReturnValue(completedQuery);
    (matchService.canManageMatch as jest.Mock).mockResolvedValue(true);
    (ScoringAudit.findOne as jest.Mock).mockReturnValue({ session: jest.fn().mockReturnThis(), lean: jest.fn().mockResolvedValue(null) });

    await expect(
      new ScoringService().endInnings('507f1f77bcf86cd799439011', 'user-1', { idempotencyKey: 'k1', expectedVersion: 0 } as any)
    ).rejects.toMatchObject({ statusCode: 400, message: expect.stringMatching(/completed|abandoned|cancelled/i) });
  });

  it('rejects manual complete winner outside match teams', async () => {
    mockSession();
    const innings = { _id: '507f1f77bcf86cd799439041', inningsNumber: 2, stateVersion: 3, status: 'IN_PROGRESS', battingTeam: '507f1f77bcf86cd799439022', bowlingTeam: '507f1f77bcf86cd799439021', totalRuns: 100, totalWickets: 2, totalBalls: 60, battingOrder: [], extras: { wides: 0, noBalls: 0, byes: 0, legByes: 0, penalties: 0, total: 0 }, currentBatters: {}, fallOfWickets: [], battingStats: [], bowlingStats: [], partnerships: [], save: jest.fn().mockResolvedValue(undefined) };
    const first = { ...innings, inningsNumber: 1, totalRuns: 90 };
    const liveQuery2: any = Promise.resolve(makeMatch());
    liveQuery2.session = jest.fn().mockReturnValue(liveQuery2);
    (Match.findById as jest.Mock).mockReturnValue(liveQuery2);
    (matchService.canManageMatch as jest.Mock).mockResolvedValue(true);
    (ScoringAudit.findOne as jest.Mock).mockReturnValue({ session: jest.fn().mockReturnThis(), lean: jest.fn().mockResolvedValue(null) });
    const { default: Innings } = await import('../../models/Innings');
    const q1:any = Promise.resolve(innings); q1.session = jest.fn().mockReturnValue(q1);
    const q2:any = Promise.resolve(first); q2.session = jest.fn().mockReturnValue(q2);
    (Innings.findOne as jest.Mock).mockReturnValueOnce(q1).mockReturnValueOnce(q2);

    await expect(
      new ScoringService().completeMatch('507f1f77bcf86cd799439011', 'user-1', {
        idempotencyKey: 'k2',
        expectedVersion: 3,
        resultType: ResultType.RUNS,
        winner: '507f1f77bcf86cd799439099',
      } as any)
    ).rejects.toMatchObject({ statusCode: 400, message: expect.stringMatching(/Winner must be one of the match teams/i) });
  });

  it('rejects stale expectedVersion on scoring mutation', async () => {
    mockSession();
    const liveQuery: any = Promise.resolve(makeMatch({ status: MatchStatus.LIVE, currentInnings: 1 }));
    liveQuery.session = jest.fn().mockReturnValue(liveQuery);
    (Match.findById as jest.Mock).mockReturnValue(liveQuery);
    (matchService.canManageMatch as jest.Mock).mockResolvedValue(true);
    (ScoringAudit.findOne as jest.Mock).mockReturnValue({ session: jest.fn().mockReturnThis(), lean: jest.fn().mockResolvedValue(null) });
    const { default: Innings } = await import('../../models/Innings');
    const innings = { _id: '507f1f77bcf86cd799439041', inningsNumber: 1, stateVersion: 5, status: 'IN_PROGRESS', battingTeam: '507f1f77bcf86cd799439021', bowlingTeam: '507f1f77bcf86cd799439022', totalRuns: 0, totalWickets: 0, totalBalls: 0, battingOrder: [], extras: { wides:0,noBalls:0,byes:0,legByes:0,penalties:0,total:0 }, currentBatters: { striker: '507f1f77bcf86cd799439031', nonStriker: '507f1f77bcf86cd799439033' }, currentBowler: '507f1f77bcf86cd799439032', fallOfWickets: [], battingStats: [], bowlingStats: [], partnerships: [], currentOverRuns: 0, save: jest.fn().mockResolvedValue(undefined) };
    const q:any = Promise.resolve(innings); q.session = jest.fn().mockReturnValue(q);
    (Innings.findOne as jest.Mock).mockReturnValue(q);

    await expect(
      new ScoringService().undo('507f1f77bcf86cd799439011', 'user-1', { idempotencyKey: 'k3', expectedVersion: 4 } as any)
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('requires expectedVersion for scoring mutations', async () => {
    mockSession();
    const liveQuery: any = Promise.resolve(makeMatch({ status: MatchStatus.LIVE, currentInnings: 1 }));
    liveQuery.session = jest.fn().mockReturnValue(liveQuery);
    (Match.findById as jest.Mock).mockReturnValue(liveQuery);
    (matchService.canManageMatch as jest.Mock).mockResolvedValue(true);
    (ScoringAudit.findOne as jest.Mock).mockReturnValue({ session: jest.fn().mockReturnThis(), lean: jest.fn().mockResolvedValue(null) });
    const { default: Innings } = await import('../../models/Innings');
    const innings = { _id: '507f1f77bcf86cd799439041', inningsNumber: 1, stateVersion: 1, status: 'IN_PROGRESS', battingTeam: '507f1f77bcf86cd799439021', bowlingTeam: '507f1f77bcf86cd799439022', totalRuns: 0, totalWickets: 0, totalBalls: 0, battingOrder: [], extras: { wides:0,noBalls:0,byes:0,legByes:0,penalties:0,total:0 }, currentBatters: { striker: '507f1f77bcf86cd799439031', nonStriker: '507f1f77bcf86cd799439033' }, currentBowler: '507f1f77bcf86cd799439032', fallOfWickets: [], battingStats: [], bowlingStats: [], partnerships: [], currentOverRuns: 0, save: jest.fn().mockResolvedValue(undefined) };
    const q:any = Promise.resolve(innings); q.session = jest.fn().mockReturnValue(q);
    (Innings.findOne as jest.Mock).mockReturnValue(q);

    await expect(
      new ScoringService().undo('507f1f77bcf86cd799439011', 'user-1', { idempotencyKey: 'k4' } as any)
    ).rejects.toMatchObject({ statusCode: 400, message: expect.stringMatching(/expectedVersion is required/i) });
  });
});
