export interface BattingRow {
  matchId?: string;
  inningsNumber?: number;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  isNotOut: boolean;
}

export interface BowlingRow {
  matchId?: string;
  inningsNumber?: number;
  balls: number;
  runs: number;
  wickets: number;
  maidens: number;
  dotBalls: number;
  wides: number;
  noBalls: number;
}

export interface FieldingRow {
  matchId?: string;
  catches: number;
  runOuts: number;
  stumpings: number;
}

export interface BattingSummary {
  innings: number;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  notOuts: number;
  dismissals: number;
  highestScore: string;
  highestScoreRuns: number;
  highestNotOut: number;
  thirties: number;
  fifties: number;
  hundreds: number;
  ducks: number;
  average: number;
  strikeRate: number;
}

export interface BowlingSummary {
  innings: number;
  balls: number;
  overs: number;
  oversLabel: string;
  maidens: number;
  runsConceded: number;
  wickets: number;
  dotBalls: number;
  wides: number;
  noBalls: number;
  bestBowling: string;
  bestBowlingWickets: number;
  bestBowlingRuns: number;
  fourWicketHauls: number;
  fiveWicketHauls: number;
  average: number;
  economy: number;
  strikeRate: number;
}

export interface FieldingSummary {
  catches: number;
  runOuts: number;
  stumpings: number;
  totalDismissals: number;
}

export const roundStat = (value: number): number =>
  Number.isFinite(value) ? Number(value.toFixed(2)) : 0;

const asNumber = (value: unknown): number => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
};

export const formatOversLabel = (balls: number, ballsPerOver: number = 6): string => {
  const safeBallsPerOver = ballsPerOver > 0 ? ballsPerOver : 6;
  return `${Math.floor(balls / safeBallsPerOver)}.${balls % safeBallsPerOver}`;
};

export const calculateBattingSummary = (rows: BattingRow[]): BattingSummary => {
  let runs = 0;
  let balls = 0;
  let fours = 0;
  let sixes = 0;
  let notOuts = 0;
  let highestScoreRuns = 0;
  let highestScoreNotOut = false;
  let highestNotOut = 0;
  let thirties = 0;
  let fifties = 0;
  let hundreds = 0;
  let ducks = 0;

  rows.forEach((row) => {
    const inningsRuns = asNumber(row.runs);
    const isNotOut = Boolean(row.isNotOut);

    runs += inningsRuns;
    balls += asNumber(row.balls);
    fours += asNumber(row.fours);
    sixes += asNumber(row.sixes);
    if (isNotOut) notOuts += 1;

    if (inningsRuns === 0 && !isNotOut) ducks += 1;
    if (inningsRuns >= 30 && inningsRuns < 50) thirties += 1;
    if (inningsRuns >= 50 && inningsRuns < 100) fifties += 1;
    if (inningsRuns >= 100) hundreds += 1;

    if (inningsRuns > highestScoreRuns) {
      highestScoreRuns = inningsRuns;
      highestScoreNotOut = isNotOut;
    } else if (inningsRuns === highestScoreRuns && isNotOut) {
      highestScoreNotOut = true;
    }
    if (isNotOut && inningsRuns > highestNotOut) {
      highestNotOut = inningsRuns;
    }
  });

  const dismissals = Math.max(0, rows.length - notOuts);

  return {
    innings: rows.length,
    runs,
    balls,
    fours,
    sixes,
    notOuts,
    dismissals,
    highestScore: `${highestScoreRuns}${highestScoreNotOut ? '*' : ''}`,
    highestScoreRuns,
    highestNotOut,
    thirties,
    fifties,
    hundreds,
    ducks,
    average: dismissals > 0 ? roundStat(runs / dismissals) : runs,
    strikeRate: balls > 0 ? roundStat((runs / balls) * 100) : 0,
  };
};

export const calculateBowlingSummary = (
  rows: BowlingRow[],
  ballsPerOver: number = 6
): BowlingSummary => {
  let balls = 0;
  let maidens = 0;
  let runsConceded = 0;
  let wickets = 0;
  let dotBalls = 0;
  let wides = 0;
  let noBalls = 0;
  let fourWicketHauls = 0;
  let fiveWicketHauls = 0;
  let bestBowlingWickets = 0;
  let bestBowlingRuns = 0;
  let hasBest = false;

  rows.forEach((row) => {
    const rowBalls = asNumber(row.balls);
    const rowRuns = asNumber(row.runs);
    const rowWickets = asNumber(row.wickets);

    balls += rowBalls;
    maidens += asNumber(row.maidens);
    runsConceded += rowRuns;
    wickets += rowWickets;
    dotBalls += asNumber(row.dotBalls);
    wides += asNumber(row.wides);
    noBalls += asNumber(row.noBalls);

    if (rowWickets >= 5) fiveWicketHauls += 1;
    else if (rowWickets === 4) fourWicketHauls += 1;

    if (
      !hasBest ||
      rowWickets > bestBowlingWickets ||
      (rowWickets === bestBowlingWickets && rowRuns < bestBowlingRuns)
    ) {
      hasBest = true;
      bestBowlingWickets = rowWickets;
      bestBowlingRuns = rowRuns;
    }
  });

  const safeBallsPerOver = ballsPerOver > 0 ? ballsPerOver : 6;

  return {
    innings: rows.length,
    balls,
    overs: roundStat(balls / safeBallsPerOver),
    oversLabel: formatOversLabel(balls, safeBallsPerOver),
    maidens,
    runsConceded,
    wickets,
    dotBalls,
    wides,
    noBalls,
    bestBowling: hasBest ? `${bestBowlingWickets}/${bestBowlingRuns}` : '-',
    bestBowlingWickets,
    bestBowlingRuns,
    fourWicketHauls,
    fiveWicketHauls,
    average: wickets > 0 ? roundStat(runsConceded / wickets) : 0,
    economy: balls > 0 ? roundStat(runsConceded / (balls / 6)) : 0,
    strikeRate: wickets > 0 ? roundStat(balls / wickets) : 0,
  };
};

export const calculateFieldingSummary = (rows: FieldingRow[]): FieldingSummary => {
  const catches = rows.reduce((total, row) => total + asNumber(row.catches), 0);
  const runOuts = rows.reduce((total, row) => total + asNumber(row.runOuts), 0);
  const stumpings = rows.reduce((total, row) => total + asNumber(row.stumpings), 0);

  return {
    catches,
    runOuts,
    stumpings,
    totalDismissals: catches + runOuts + stumpings,
  };
};

export const LEADERBOARD_METRICS = [
  'runs',
  'wickets',
  'battingAverage',
  'battingStrikeRate',
  'bowlingEconomy',
  'bowlingAverage',
  'sixes',
  'fours',
  'catches',
] as const;

export type LeaderboardMetric = (typeof LEADERBOARD_METRICS)[number];

const LEADERBOARD_ALIASES: Record<string, LeaderboardMetric> = {
  batsmen: 'runs',
  bowlers: 'wickets',
  batters: 'runs',
};

export const normalizeLeaderboardMetric = (
  value: unknown
): LeaderboardMetric | undefined => {
  const text = String(value ?? '').trim().toLowerCase();
  const alias = LEADERBOARD_ALIASES[text];
  if (alias) return alias;
  return LEADERBOARD_METRICS.find((metric) => metric.toLowerCase() === text);
};

export const isLowerBetter = (metric: LeaderboardMetric): boolean =>
  metric === 'bowlingEconomy' || metric === 'bowlingAverage';

export interface LeaderboardStats {
  batting: BattingSummary;
  bowling: BowlingSummary;
  fielding: FieldingSummary;
}

export const leaderboardValue = (
  metric: LeaderboardMetric,
  stats: LeaderboardStats
): number => {
  switch (metric) {
    case 'runs':
      return stats.batting.runs;
    case 'wickets':
      return stats.bowling.wickets;
    case 'battingAverage':
      return stats.batting.average;
    case 'battingStrikeRate':
      return stats.batting.strikeRate;
    case 'bowlingEconomy':
      return stats.bowling.economy;
    case 'bowlingAverage':
      return stats.bowling.average;
    case 'sixes':
      return stats.batting.sixes;
    case 'fours':
      return stats.batting.fours;
    case 'catches':
      return stats.fielding.catches;
    default:
      return 0;
  }
};

export interface LeaderboardComparable {
  metricValue: number;
  batting: BattingSummary;
  bowling: BowlingSummary;
  fielding: FieldingSummary;
  playerName: string;
}

export const compareLeaderboardEntries = (
  metric: LeaderboardMetric,
  left: LeaderboardComparable,
  right: LeaderboardComparable
): number => {
  const direction = isLowerBetter(metric) ? 1 : -1;
  const primary = (left.metricValue - right.metricValue) * direction;
  if (primary !== 0) return primary;

  const secondary =
    (left.batting.runs - right.batting.runs) * -1 ||
    (left.bowling.wickets - right.bowling.wickets) * -1 ||
    left.playerName.localeCompare(right.playerName);
  return secondary;
};

export const STATISTICS_FORMAT_VALUES = ['T10', 'T20', 'ODI', 'CUSTOM'];
