import { idParamSchema, idTeamIdParamSchema, idAuctionPlayerIdParamSchema } from '../params.validator';

describe('ObjectId param validators', () => {
  it('rejects invalid id param', () => {
    const { error } = idParamSchema.validate({ id: 'bad-id' });
    expect(error).toBeTruthy();
  });

  it('rejects invalid nested team id param', () => {
    const { error } = idTeamIdParamSchema.validate({ id: '507f1f77bcf86cd799439011', teamId: 'bad' });
    expect(error).toBeTruthy();
  });

  it('accepts valid auction player params', () => {
    const { error } = idAuctionPlayerIdParamSchema.validate({
      id: '507f1f77bcf86cd799439011',
      auctionPlayerId: '507f1f77bcf86cd799439012',
    });
    expect(error).toBeUndefined();
  });
});
