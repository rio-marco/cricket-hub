import {
  calculateBattingSummary,
  calculateBowlingSummary,
  calculateFieldingSummary,
  compareLeaderboardEntries,
  normalizeLeaderboardMetric,
} from '../statistics';

describe('statistics calculator', () => {
  it('calculates batting averages with not-outs and highest score markers', () => {
    const summary = calculateBattingSummary([
      { runs: 84, balls: 52, fours: 6, sixes: 3, isNotOut: false },
      { runs: 42, balls: 30, fours: 2, sixes: 1, isNotOut: true },
      { runs: 0, balls: 3, fours: 0, sixes: 0, isNotOut: false },
    ]);

    expect(summary).toMatchObject({
      innings: 3,
      runs: 126,
      balls: 85,
      fours: 8,
      sixes: 4,
      notOuts: 1,
      dismissals: 2,
      highestScore: '84',
      highestNotOut: 42,
      fifties: 1,
      thirties: 1,
      ducks: 1,
      average: 63,
      strikeRate: 148.24,
    });
  });

  it('marks an unbeaten highest score and does not count it as a dismissal', () => {
    const summary = calculateBattingSummary([
      { runs: 60, balls: 40, fours: 4, sixes: 2, isNotOut: true },
      { runs: 30, balls: 25, fours: 2, sixes: 0, isNotOut: false },
    ]);

    expect(summary.highestScore).toBe('60*');
    expect(summary.dismissals).toBe(1);
    expect(summary.average).toBe(90);
  });

  it('calculates bowling economy, best figures and wicket hauls from recorded balls', () => {
    const summary = calculateBowlingSummary([
      {
        balls: 24,
        runs: 28,
        wickets: 2,
        maidens: 0,
        dotBalls: 9,
        wides: 2,
        noBalls: 1,
      },
      {
        balls: 24,
        runs: 16,
        wickets: 5,
        maidens: 1,
        dotBalls: 12,
        wides: 0,
        noBalls: 0,
      },
    ]);

    expect(summary).toMatchObject({
      innings: 2,
      balls: 48,
      overs: 8,
      oversLabel: '8.0',
      maidens: 1,
      runsConceded: 44,
      wickets: 7,
      dotBalls: 21,
      wides: 2,
      noBalls: 1,
      bestBowling: '5/16',
      fourWicketHauls: 0,
      fiveWicketHauls: 1,
      average: 6.29,
      economy: 5.5,
      strikeRate: 6.86,
    });
  });

  it('respects non-six balls per over when formatting bowling figures', () => {
    const summary = calculateBowlingSummary(
      [
        {
          balls: 16,
          runs: 20,
          wickets: 1,
          maidens: 0,
          dotBalls: 4,
          wides: 0,
          noBalls: 0,
        },
      ],
      8
    );

    expect(summary.overs).toBe(2);
    expect(summary.oversLabel).toBe('2.0');
    expect(summary.economy).toBe(7.5);
  });

  it('aggregates fielding dismissals separately', () => {
    const summary = calculateFieldingSummary([
      { catches: 2, runOuts: 0, stumpings: 1 },
      { catches: 0, runOuts: 1, stumpings: 0 },
    ]);

    expect(summary).toEqual({
      catches: 2,
      runOuts: 1,
      stumpings: 1,
      totalDismissals: 4,
    });
  });

  it('normalizes leaderboard aliases and sorts lower-is-better metrics correctly', () => {
    expect(normalizeLeaderboardMetric('batsmen')).toBe('runs');
    expect(normalizeLeaderboardMetric('BOWLERS')).toBe('wickets');
    expect(normalizeLeaderboardMetric('unknown')).toBeUndefined();

    const stats = {
      batting: calculateBattingSummary([]),
      bowling: calculateBowlingSummary([]),
      fielding: calculateFieldingSummary([]),
    };
    const left = { ...stats, metricValue: 6.5, playerName: 'A' };
    const right = { ...stats, metricValue: 7.2, playerName: 'B' };

    expect(compareLeaderboardEntries('bowlingEconomy', left, right)).toBeLessThan(0);
    expect(compareLeaderboardEntries('runs', left, right)).toBeGreaterThan(0);
  });
});
