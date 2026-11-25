import {
  DismissalType,
  ExtraType,
  InningsStatus,
} from '../../constants/enums';
import {
  EngineDeliveryRecord,
  EngineInningsState,
  applyDelivery,
  calculateEconomy,
  calculateStrikeRate,
  deriveInningsResult,
  formatOvers,
  isInningsComplete,
  rebuildInnings,
} from '../scoringEngine';

const rules = { ballsPerOver: 6, totalOvers: 2 };
const batters = Array.from({ length: 11 }, (_, index) => `batter-${index + 1}`);
const bowlers = ['bowler-1', 'bowler-2', 'bowler-3', 'bowler-4'];

const baseState = (overrides: Partial<EngineInningsState> = {}): EngineInningsState => ({
  battingTeam: 'team-a',
  bowlingTeam: 'team-b',
  battingOrder: batters,
  bowlingOrder: bowlers,
  totalRuns: 0,
  totalWickets: 0,
  totalBalls: 0,
  extras: {
    wides: 0,
    noBalls: 0,
    byes: 0,
    legByes: 0,
    penalties: 0,
    total: 0,
  },
  currentBatters: { striker: batters[0], nonStriker: batters[1] },
  currentBowler: bowlers[0],
  currentOverRuns: 0,
  stateVersion: 0,
  status: InningsStatus.IN_PROGRESS,
  fallOfWickets: [],
  battingStats: [],
  bowlingStats: [],
  partnerships: [],
  ...overrides,
});

const names = {
  striker: batters[0],
  nonStriker: batters[1],
  bowler: bowlers[0],
};

const delivery = (
  overrides: Partial<EngineDeliveryRecord> = {}
): EngineDeliveryRecord => ({
  sequenceNumber: 1,
  batter: batters[0],
  nonStriker: batters[1],
  bowler: bowlers[0],
  runs: { batter: 0, extras: 0, total: 0 },
  extras: { type: ExtraType.NONE, runs: 0 },
  isLegal: true,
  isWicket: false,
  ...overrides,
});

describe('scoringEngine', () => {
  it('formats overs and calculates rates', () => {
    expect(formatOvers(11, 6)).toBe('1.5');
    expect(calculateStrikeRate(30, 20)).toBe(150);
    expect(calculateEconomy(48, 36)).toBe(8);
    expect(calculateStrikeRate(10, 0)).toBe(0);
  });

  it('records a legal dot ball and rotates strike for odd totals', () => {
    const dot = applyDelivery(
      baseState(),
      {
        runs: 0,
        extraRuns: 0,
        extraType: ExtraType.NONE,
        batter: batters[0],
        nonStriker: batters[1],
        bowler: bowlers[0],
      },
      rules,
      names
    );

    expect(dot.state.totalRuns).toBe(0);
    expect(dot.state.totalBalls).toBe(1);
    expect(dot.isLegal).toBe(true);
    expect(dot.state.currentBatters).toEqual({
      striker: batters[0],
      nonStriker: batters[1],
    });

    const single = applyDelivery(
      dot.state,
      {
        runs: 1,
        extraRuns: 0,
        extraType: ExtraType.NONE,
        batter: batters[0],
        nonStriker: batters[1],
        bowler: bowlers[0],
      },
      rules,
      names
    );

    expect(single.state.totalRuns).toBe(1);
    expect(single.state.currentBatters).toEqual({
      striker: batters[1],
      nonStriker: batters[0],
    });
    expect(single.state.battingStats[0].runs).toBe(1);
    expect(single.state.bowlingStats[0].runs).toBe(1);
  });

  it('does not count wides or no balls as legal deliveries', () => {
    const wide = applyDelivery(
      baseState(),
      {
        runs: 0,
        extraRuns: 1,
        extraType: ExtraType.WIDE,
        batter: batters[0],
        nonStriker: batters[1],
        bowler: bowlers[0],
      },
      rules,
      names
    );

    expect(wide.isLegal).toBe(false);
    expect(wide.state.totalRuns).toBe(2);
    expect(wide.state.totalBalls).toBe(0);
    expect(wide.state.extras.wides).toBe(2);
    expect(wide.state.bowlingStats[0].wides).toBe(2);

    const noBallWithFour = applyDelivery(
      baseState(),
      {
        runs: 4,
        extraRuns: 0,
        extraType: ExtraType.NO_BALL,
        batter: batters[0],
        nonStriker: batters[1],
        bowler: bowlers[0],
      },
      rules,
      names
    );

    expect(noBallWithFour.isLegal).toBe(false);
    expect(noBallWithFour.state.totalRuns).toBe(5);
    expect(noBallWithFour.state.totalBalls).toBe(0);
    expect(noBallWithFour.state.battingStats[0].runs).toBe(4);
    expect(noBallWithFour.isBoundary).toBe(true);
  });

  it('swaps ends and requires a new bowler after an over', () => {
    let state = baseState();
    for (let index = 0; index < 6; index += 1) {
      const result = applyDelivery(
        state,
        {
          runs: 2,
          extraRuns: 0,
          extraType: ExtraType.NONE,
          batter: state.currentBatters.striker!,
          nonStriker: state.currentBatters.nonStriker!,
          bowler: bowlers[0],
        },
        rules,
        {
          striker: state.currentBatters.striker!,
          nonStriker: state.currentBatters.nonStriker!,
          bowler: bowlers[0],
        }
      );
      expect(result.overCompleted).toBe(index === 5);
      state = result.state;
    }

    expect(state.totalBalls).toBe(6);
    expect(state.totalRuns).toBe(12);
    expect(state.currentBowler).toBeUndefined();
    expect(state.lastOverBowler).toBe(bowlers[0]);
    expect(state.currentBatters.striker).toBe(batters[1]);

    expect(() =>
      applyDelivery(
        { ...state, currentBowler: bowlers[0] },
        {
          runs: 0,
          extraRuns: 0,
          extraType: ExtraType.NONE,
          batter: state.currentBatters.striker!,
          nonStriker: state.currentBatters.nonStriker!,
          bowler: bowlers[0],
        },
        rules,
        names
      )
    ).toThrow('same bowler cannot bowl consecutive overs');
  });

  it('records wickets, brings in the next batter, and credit the bowler', () => {
    const result = applyDelivery(
      baseState(),
      {
        runs: 0,
        extraRuns: 0,
        extraType: ExtraType.NONE,
        batter: batters[0],
        nonStriker: batters[1],
        bowler: bowlers[0],
        wicket: { type: DismissalType.BOWLED, batter: batters[0] },
      },
      rules,
      names
    );

    expect(result.isWicket).toBe(true);
    expect(result.state.totalWickets).toBe(1);
    expect(result.state.currentBatters.striker).toBe(batters[2]);
    expect(result.state.currentBatters.nonStriker).toBe(batters[1]);
    expect(result.state.battingStats[0].isNotOut).toBe(false);
    expect(result.state.bowlingStats[0].wickets).toBe(1);
    expect(result.state.fallOfWickets[0]).toMatchObject({
      teamScore: 0,
      wicketNumber: 1,
      player: batters[0],
    });
  });

  it('rebuilds state from deliveries and derives results', () => {
    const deliveries: EngineDeliveryRecord[] = [
      delivery({
        sequenceNumber: 1,
        runs: { batter: 4, extras: 0, total: 4 },
      }),
      delivery({
        sequenceNumber: 2,
        batter: batters[1],
        nonStriker: batters[0],
        runs: { batter: 1, extras: 0, total: 1 },
      }),
      delivery({
        sequenceNumber: 3,
        batter: batters[0],
        nonStriker: batters[1],
        runs: { batter: 0, extras: 2, total: 2 },
        extras: { type: ExtraType.WIDE, runs: 2 },
        isLegal: false,
      }),
    ];

    const rebuilt = rebuildInnings(baseState(), deliveries, rules);
    expect(rebuilt.totalRuns).toBe(7);
    expect(rebuilt.totalBalls).toBe(2);
    expect(rebuilt.extras.wides).toBe(2);
    expect(isInningsComplete(rebuilt, rules)).toBe(false);

    const chased = rebuildInnings(
      baseState({ target: 7 }),
      deliveries,
      rules
    );
    expect(isInningsComplete(chased, rules)).toBe(true);
    expect(deriveInningsResult(chased, rules, 6)).toMatchObject({
      winner: 'team-a',
      resultType: 'WICKETS',
      margin: 10,
    });
  });
});
