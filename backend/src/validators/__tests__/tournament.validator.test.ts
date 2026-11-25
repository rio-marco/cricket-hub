import {
  BallType,
  MatchFormat,
  TournamentFormat,
  TournamentStatus,
} from '../../constants/enums';
import {
  createTournamentSchema,
  registerTeamSchema,
  tournamentQuerySchema,
  updateTournamentStatusSchema,
} from '../tournament.validator';

describe('tournament validators', () => {
  it('strips client supplied status from create payloads', () => {
    const { error, value } = createTournamentSchema.validate(
      {
        name: 'Mumbai Cup',
        format: TournamentFormat.LEAGUE,
        ballType: BallType.WHITE,
        matchFormat: MatchFormat.T20,
        startDate: '2026-12-01T00:00:00.000Z',
        endDate: '2026-12-10T00:00:00.000Z',
        maxTeams: 8,
        status: TournamentStatus.REGISTRATION_OPEN,
      },
      { stripUnknown: true }
    );

    expect(error).toBeUndefined();
    expect(value).not.toHaveProperty('status');
    expect(value.venues).toEqual([]);
    expect(value.maxPlayersPerTeam).toBe(15);
    expect(value.registrationFee).toBe(0);
  });

  it('validates team registration identifiers', () => {
    expect(registerTeamSchema.validate({ teamId: 'not-an-object-id' }).error).toBeDefined();
    expect(
      registerTeamSchema.validate({ teamId: '507f1f77bcf86cd799439011' }).error
    ).toBeUndefined();
  });

  it('validates lifecycle status updates', () => {
    expect(
      updateTournamentStatusSchema.validate({ status: TournamentStatus.REGISTRATION_OPEN })
        .error
    ).toBeUndefined();
    expect(updateTournamentStatusSchema.validate({ status: 'INVALID' }).error).toBeDefined();
  });

  it('applies list query defaults and rejects invalid filters', () => {
    const { error, value } = tournamentQuerySchema.validate(
      {
        search: '  cup  ',
        page: '2',
        unknown: 'value',
      },
      { stripUnknown: true }
    );

    expect(error).toBeUndefined();
    expect(value).toEqual({ search: 'cup', page: 2, limit: 10 });
    expect(value).not.toHaveProperty('unknown');
    expect(tournamentQuerySchema.validate({ status: 'INVALID' }).error).toBeDefined();
    expect(tournamentQuerySchema.validate({ organizer: 'bad-id' }).error).toBeDefined();
    expect(tournamentQuerySchema.validate({ limit: 101 }).error).toBeDefined();
  });
});
