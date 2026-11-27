import { AuctionAuditAction, AuctionBidDecision, AuctionPlayerStatus, AuctionStatus } from '../../constants/enums';

jest.mock('../../models/Auction', () => ({ __esModule: true, default: { findById: jest.fn(), findOneAndUpdate: jest.fn(), updateOne: jest.fn() } }));
jest.mock('../../models/AuctionPlayer', () => ({ __esModule: true, default: { findById: jest.fn(), findOne: jest.fn(), updateOne: jest.fn(), find: jest.fn(), countDocuments: jest.fn(), aggregate: jest.fn() } }));
jest.mock('../../models/AuctionBid', () => ({ __esModule: true, default: { findOne: jest.fn(), create: jest.fn(), updateMany: jest.fn(), countDocuments: jest.fn(), find: jest.fn() } }));
jest.mock('../../models/AuctionTeam', () => ({ __esModule: true, default: { findOne: jest.fn(), updateOne: jest.fn(), find: jest.fn() } }));
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

import mongoose from 'mongoose';
import Auction from '../../models/Auction';
import AuctionAudit from '../../models/AuctionAudit';
import AuctionBid from '../../models/AuctionBid';
import AuctionPlayer from '../../models/AuctionPlayer';
import AuctionTeam from '../../models/AuctionTeam';
import Team from '../../models/Team';
import Tournament from '../../models/Tournament';
import User from '../../models/User';
import { AuctionService } from '../auction.service';

const mockSession = () => {
  const session = { startTransaction: jest.fn(), commitTransaction: jest.fn(), abortTransaction: jest.fn(), endSession: jest.fn() };
  (mongoose.connection.startSession as jest.Mock).mockResolvedValue(session);
  return session;
};

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

const oid = (n: string) => `507f1f77bcf86cd7994390${n}`;

const makeAuction = (overrides: any = {}) => ({
  _id: oid('11'),
  name: 'Test Auction',
  teams: [oid('21'), oid('22')],
  status: AuctionStatus.LIVE,
  stateVersion: 3,
  nextSequence: 2,
  minBidIncrement: 100,
  maxSquadSize: 15,
  minSquadSize: 1,
  purseAmount: 1000,
  currentPlayer: oid('31'),
  currentPlayerOrder: 1,
  createdBy: oid('01'),
  save: jest.fn().mockResolvedValue(undefined),
  ...overrides,
});

const makePlayer = (overrides: any = {}) => ({
  _id: oid('31'),
  auction: oid('11'),
  player: oid('41'),
  status: AuctionPlayerStatus.AVAILABLE,
  available: true,
  basePrice: 100,
  currentBid: 200,
  highestBidder: oid('21'),
  bidCount: 1,
  lastSequence: 1,
  version: 1,
  order: 1,
  save: jest.fn().mockResolvedValue(undefined),
  ...overrides,
});

describe('AuctionService hardening', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockSession();
    (User.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue({ role: 'ADMIN' }) });
    (Tournament.findById as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(null) });
    (Team.find as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue([]) });
    (AuctionAudit.findOne as jest.Mock).mockReturnValue({ lean: jest.fn().mockResolvedValue(null) });
    (AuctionAudit.create as jest.Mock).mockResolvedValue([{}]);
    (Auction.updateOne as jest.Mock).mockResolvedValue({ matchedCount: 1 });
  });

  it('rejects bid acceptance when bid does not belong to current highest bid', async () => {
    const auction = makeAuction();
    (Auction.findById as jest.Mock).mockReturnValue(q(auction));
    const bid = { _id: oid('51'), auction: oid('11'), auctionPlayer: oid('31'), team: oid('22'), amount: 150, decision: AuctionBidDecision.PENDING, sequenceNumber: 1 };
    (AuctionBid.findOne as jest.Mock).mockResolvedValue(bid);
    const player = makePlayer({ currentBid: 200, highestBidder: oid('21') });
    (AuctionPlayer.findById as jest.Mock).mockReturnValue(q(player));

    await expect(
      new AuctionService().decideBid(oid('11'), oid('51'), oid('01'), { accept: true, expectedVersion: 3, idempotencyKey: 'k1' } as any)
    ).rejects.toMatchObject({ statusCode: 409, message: expect.stringMatching(/highest bid/i) });
  });

  it('rejects bid decision for bid from another player/auction context', async () => {
    const auction = makeAuction({ currentPlayer: oid('32') });
    (Auction.findById as jest.Mock).mockReturnValue(q(auction));
    const bid = { _id: oid('51'), auction: oid('11'), auctionPlayer: oid('31'), team: oid('21'), amount: 200, decision: AuctionBidDecision.PENDING };
    (AuctionBid.findOne as jest.Mock).mockResolvedValue(bid);

    await expect(
      new AuctionService().decideBid(oid('11'), oid('51'), oid('01'), { accept: false, expectedVersion: 3, idempotencyKey: 'k2' } as any)
    ).rejects.toMatchObject({ statusCode: 409, message: expect.stringMatching(/current auction player/i) });
  });

  it('rejects stale expectedVersion on bid placement', async () => {
    const auction = makeAuction({ stateVersion: 5 });
    (Auction.findById as jest.Mock).mockReturnValue(q(auction));
    (Team.find as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue([{ _id: oid('21') }]) });

    await expect(
      new AuctionService().placeBid(oid('11'), oid('01'), { team: oid('21'), amount: 300, expectedVersion: 3, idempotencyKey: 'k3' } as any)
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('rejects completion when pending bids exist', async () => {
    const auction = makeAuction({ currentPlayer: undefined });
    (Auction.findById as jest.Mock).mockReturnValue(q(auction));
    (AuctionBid.countDocuments as jest.Mock).mockReturnValue({ session: jest.fn().mockResolvedValue(1) });

    await expect(
      new AuctionService().completeAuction(oid('11'), oid('01'), { expectedVersion: 3, idempotencyKey: 'k4' } as any)
    ).rejects.toMatchObject({ statusCode: 409, message: expect.stringMatching(/pending/i) });
  });

  it('scopes idempotency replay by actor/action key', async () => {
    const auction = makeAuction();
    (Auction.findById as jest.Mock).mockReturnValue(q(auction));
    (AuctionAudit.findOne as jest.Mock).mockReturnValue({ lean: jest.fn().mockResolvedValue({ _id: 'audit', action: AuctionAuditAction.PAUSE, actor: oid('01') }) });
    // getState called for replay
    const service = new AuctionService();
    jest.spyOn(service, 'getState').mockResolvedValue({ auction, stateVersion: 3 } as any);

    const result = await service.pauseAuction(oid('11'), oid('01'), { expectedVersion: 3, idempotencyKey: 'same-key' } as any);
    expect(result.commit).toBeUndefined();
    expect(AuctionAudit.findOne).toHaveBeenCalledWith(expect.objectContaining({ action: AuctionAuditAction.PAUSE, actor: oid('01') }));
  });
});
