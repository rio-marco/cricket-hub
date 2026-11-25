import { PlayingRole } from '../../constants/enums';
import { searchPlayerSchema } from '../player.validator';

describe('player validators', () => {
  it('applies player search defaults and strips unknown query keys', () => {
    const { error, value } = searchPlayerSchema.validate(
      {
        search: '  Virat  ',
        page: '2',
        limit: '25',
        unknown: 'value',
      },
      { stripUnknown: true }
    );

    expect(error).toBeUndefined();
    expect(value).toEqual({
      search: 'Virat',
      page: 2,
      limit: 25,
      sort: '-createdAt',
    });
    expect(value).not.toHaveProperty('unknown');
  });

  it('accepts valid playing role filters', () => {
    const { error, value } = searchPlayerSchema.validate({
      playingRole: PlayingRole.ALL_ROUNDER,
    });

    expect(error).toBeUndefined();
    expect(value.playingRole).toBe(PlayingRole.ALL_ROUNDER);
  });

  it('rejects invalid playing role, page, and limit values', () => {
    expect(searchPlayerSchema.validate({ playingRole: 'INVALID' }).error?.message).toMatch(
      /Playing role/
    );
    expect(searchPlayerSchema.validate({ page: 0 }).error?.message).toMatch(/page/);
    expect(searchPlayerSchema.validate({ limit: 101 }).error?.message).toMatch(/limit/);
  });
});
