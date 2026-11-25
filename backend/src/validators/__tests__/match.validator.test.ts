import { BallType, MatchFormat, TossDecision } from '../../constants/enums';
import {
  createMatchSchema,
  matchQuerySchema,
  tossSchema,
} from '../match.validator';

const teamA = '507f1f77bcf86cd799439011';
const teamB = '507f1f77bcf86cd799439012';
const tournamentId = '507f1f77bcf86cd799439013';

describe('match validators', () => {
  it('accepts real team and tournament identifiers and strips client managed fields', () => {
    const { error, value } = createMatchSchema.validate(
      {
        teamA,
        teamB,
        tournamentId,
        format: MatchFormat.T20,
        totalOvers: 20,
        ballType: BallType.WHITE,
        status: 'UPCOMING',
        currentInnings: 1,
        tournament: { id: tournamentId },
      },
      { stripUnknown: true }
    );

    expect(error).toBeUndefined();
    expect(value.teamA).toBe(teamA);
    expect(value.teamB).toBe(teamB);
    expect(value.tournamentId).toBe(tournamentId);
    expect(value).not.toHaveProperty('status');
    expect(value).not.toHaveProperty('currentInnings');
    expect(value).not.toHaveProperty('tournament');
  });

  it('rejects synthetic team objects as identifiers', () => {
    const { error } = createMatchSchema.validate({
      teamA: { id: 'team_a_1', name: 'Team A' },
      teamB: { id: 'team_b_1', name: 'Team B' },
      format: MatchFormat.T20,
      totalOvers: 20,
    });

    expect(error).toBeDefined();
  });

  it('requires a team identifier and a valid toss decision', () => {
    expect(
      tossSchema.validate({ winner: teamA, decision: TossDecision.BAT }).error
    ).toBeUndefined();
    expect(
      tossSchema.validate({ winner: 'Team A', decision: TossDecision.BAT }).error
    ).toBeDefined();
    expect(
      tossSchema.validate({ winner: teamA, decision: 'COIN' }).error
    ).toBeDefined();
  });

  it('applies list query defaults and rejects invalid filters', () => {
    const { error, value } = matchQuerySchema.validate(
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
    expect(matchQuerySchema.validate({ status: 'INVALID' }).error).toBeDefined();
    expect(matchQuerySchema.validate({ sort: 'unknownField' }).error).toBeDefined();
    expect(matchQuerySchema.validate({ teamId: 'bad-id' }).error).toBeDefined();
  });
});
