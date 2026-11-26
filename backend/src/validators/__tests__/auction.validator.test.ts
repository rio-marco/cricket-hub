import {
  auctionActionSchema,
  bidDecisionSchema,
  createAuctionSchema,
  placeBidSchema,
  registerPlayersSchema,
} from '../auction.validator';

describe('auction validators', () => {
  const teamIds = ['507f1f77bcf86cd799439011', '507f1f77bcf86cd799439012'];
  const playerId = '507f1f77bcf86cd799439013';

  it('accepts a flexible local tournament configuration', () => {
    const { error, value } = createAuctionSchema.validate({
      name: 'Local League Auction',
      teams: teamIds,
      purseAmount: 500000,
      basePrice: 10000,
      minBidIncrement: 5000,
      maxSquadSize: 20,
      minSquadSize: 11,
      playerCategories: ['BATSMAN', 'BOWLER'],
      rules: { allowAccelerator: true },
      status: 'UPCOMING',
    });
    expect(error).toBeUndefined();
    expect(value.minBidIncrement).toBe(5000);
    expect(value.status).toBe('UPCOMING');
  });

  it('rejects an auction with fewer than two teams', () => {
    const { error } = createAuctionSchema.validate({ name: 'Auction', teams: [teamIds[0]], purseAmount: 100 });
    expect(error).toBeDefined();
  });

  it('requires a bidding team and validates bidding payloads', () => {
    expect(placeBidSchema.validate({ amount: 100 }).error).toBeDefined();
    const valid = placeBidSchema.validate({ team: teamIds[0], amount: 15000, idempotencyKey: 'bid-1' });
    expect(valid.error).toBeUndefined();
    expect(valid.value.team).toBe(teamIds[0]);
  });

  it('requires player identifiers for registration', () => {
    expect(registerPlayersSchema.validate({ players: [{ basePrice: 100 }] }).error).toBeDefined();
    expect(registerPlayersSchema.validate({ players: [{ playerId }] }).error).toBeUndefined();
  });

  it('requires an explicit bid decision', () => {
    expect(bidDecisionSchema.validate({}).error).toBeDefined();
    expect(bidDecisionSchema.validate({ accept: false, reason: 'Too low' }).error).toBeUndefined();
  });

  it('accepts optimistic concurrency and idempotency headers in action bodies', () => {
    const { error, value } = auctionActionSchema.validate({ expectedVersion: 4, idempotencyKey: 'pause-1' });
    expect(error).toBeUndefined();
    expect(value).toEqual({ expectedVersion: 4, idempotencyKey: 'pause-1' });
  });
});
