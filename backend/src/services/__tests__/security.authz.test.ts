import { AuctionStatus } from '../../constants/enums';
import { ApiError } from '../../utils/apiError';

jest.mock('../../models/Auction', () => ({ __esModule: true, default: { findById: jest.fn() } }));
jest.mock('../../models/AuctionPlayer', () => ({ __esModule: true, default: { find: jest.fn(), findById: jest.fn(), aggregate: jest.fn(), countDocuments: jest.fn() } }));
jest.mock('../../models/AuctionBid', () => ({ __esModule: true, default: { find: jest.fn(), countDocuments: jest.fn() } }));
jest.mock('../../models/AuctionTeam', () => ({ __esModule: true, default: { findOne: jest.fn(), findById: jest.fn(), find: jest.fn() } }));
jest.mock('../../models/AuctionAudit', () => ({ __esModule: true, default: { findOne: jest.fn(), create: jest.fn() } }));
jest.mock('../../models/Team', () => ({ __esModule: true, default: { find: jest.fn(), findById: jest.fn() } }));
jest.mock('../../models/Tournament', () => ({ __esModule: true, default: { findById: jest.fn() } }));
jest.mock('../../models/User', () => ({ __esModule: true, default: { findById: jest.fn() } }));
jest.mock('../../models/Player', () => ({ __esModule: true, default: { countDocuments: jest.fn() } }));
jest.mock('../notificationHooks.service', () => ({ __esModule: true, notifySafely: jest.fn() }));
jest.mock('mongoose', () => {
  const actual = jest.requireActual('mongoose');
  return { ...actual, connection: { startSession: jest.fn() } };
});

import Auction from '../../models/Auction';
import AuctionPlayer from '../../models/AuctionPlayer';
import AuctionBid from '../../models/AuctionBid';
import AuctionTeam from '../../models/AuctionTeam';
import Team from '../../models/Team';
import Tournament from '../../models/Tournament';
import User from '../../models/User';
import { AuctionService } from '../auction.service';

const oid = (n: string) => `507f1f77bcf86cd7994390${n}`;
const q = (value: any) => {
  const query: any = Promise.resolve(value);
  query.session = jest.fn().mockReturnValue(query);
  query.select = jest.fn().mockReturnValue(query);
  query.populate = jest.fn().mockReturnValue(query);
  query.sort = jest.fn().mockReturnValue(query);
  query.limit = jest.fn().mockReturnValue(query);
  query.lean = jest.fn().mockResolvedValue(value);
  return query;
};

describe('Phase 14 authz/PII regressions', () => {
  beforeEach(() => jest.clearAllMocks());

  it('rejects unauthenticated auction state reads', async () => {
    await expect(new AuctionService().getState(oid('11'))).rejects.toMatchObject({ statusCode: 401 });
  });

  it('rejects cross-team purse reads for non-manager users', async () => {
    (Auction.findById as jest.Mock).mockReturnValue(q({ _id: oid('11'), teams: [oid('21')], status: AuctionStatus.LIVE, createdBy: oid('99') }));
    (User.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue({ role: 'NORMAL_USER' }) });
    (Tournament.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(null) });
    (Team.find as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue([]) });

    await expect(new AuctionService().getTeamPurse(oid('11'), oid('21'), oid('02'))).rejects.toMatchObject({ statusCode: 403 });
  });

  it('returns purse without owner PII for authorized team owner', async () => {
    (Auction.findById as jest.Mock).mockReturnValue(q({ _id: oid('11'), teams: [oid('21')], status: AuctionStatus.LIVE, createdBy: oid('99') }));
    (User.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue({ role: 'NORMAL_USER' }) });
    (Tournament.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(null) });
    (Team.find as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue([{ _id: oid('21') }]) });
    (AuctionTeam.findOne as jest.Mock).mockResolvedValue({ _id: oid('31') });
    (AuctionTeam.findById as jest.Mock).mockReturnValue({ populate: jest.fn().mockReturnValue({ lean: jest.fn().mockResolvedValue({ _id: oid('31'), team: { _id: oid('21'), name: 'T1' }, initialBudget: 100, spent: 10, pendingCommitment: 0 }) }) });

    const purse = await new AuctionService().getTeamPurse(oid('11'), oid('21'), oid('02'));
    expect(purse.team).toEqual({ _id: oid('21'), name: 'T1' });
    expect((purse.team as any).owner).toBeUndefined();
  });

  it('redacts auction financial fields for authenticated non-manager/non-owner users', async () => {
    const svc = new AuctionService() as any;
    jest.spyOn(svc, 'findAuction').mockResolvedValue({ _id: oid('11'), createdBy: oid('99'), tournament: null, teams: [oid('21')], stateVersion: 3, currentPlayer: null });
    jest.spyOn(svc, 'getAuctionAccess').mockResolvedValue({ canView: true, canManage: false, canBid: false, ownedTeamIds: [] });
    (AuctionPlayer.find as jest.Mock).mockReturnValue(q([{ _id: oid('41'), basePrice: 100, currentBid: 200, soldPrice: 300, bidCount: 2, status: 'SOLD' }]));
    (AuctionTeam.find as jest.Mock).mockReturnValue(q([{ _id: oid('31'), team: { _id: oid('21'), name: 'T1' }, initialBudget: 1000, spent: 100, pendingCommitment: 50, playersPurchased: 1 }]));
    (AuctionBid.find as jest.Mock).mockReturnValue(q([{ _id: oid('51'), amount: 200, team: { _id: oid('21'), name: 'T1' } }]));
    (AuctionBid.countDocuments as jest.Mock).mockReturnValue({ session: jest.fn().mockResolvedValue(1) });

    const state: any = await svc.getState(oid('11'), oid('02'));
    expect(state.permissions.canViewFinancials).toBe(false);
    expect(state.teams[0].initialBudget).toBeUndefined();
    expect(state.teams[0].spent).toBeUndefined();
    expect(state.players[0].basePrice).toBeUndefined();
    expect(state.players[0].currentBid).toBeUndefined();
    expect(state.players[0].soldPrice).toBeUndefined();
    expect(state.bids[0].amount).toBeUndefined();
  });
});
