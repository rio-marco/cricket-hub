import { ApiError } from '../utils/apiError';
import {
  DismissalType,
  ExtraType,
  InningsStatus,
} from '../constants/enums';

export interface ScoringRules {
  ballsPerOver: number;
  totalOvers: number;
}

export interface EngineExtras {
  wides: number;
  noBalls: number;
  byes: number;
  legByes: number;
  penalties: number;
  total: number;
}

export interface EngineDismissal {
  type?: DismissalType;
  bowler?: string;
  fielder?: string;
  description?: string;
}

export interface EngineWicketInput {
  type: DismissalType;
  batter?: string;
  fielder?: string;
  description?: string;
  isStriker?: boolean;
}

export interface EngineFallOfWicket {
  player: string;
  runs: number;
  balls: number;
  teamScore: number;
  teamOvers: string;
  wicketNumber: number;
}

export interface EngineBattingStats {
  player: string;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  strikeRate: number;
  dismissal?: EngineDismissal;
  isNotOut: boolean;
  position?: number;
}

export interface EngineBowlingStats {
  player: string;
  overs: number;
  balls: number;
  maidens: number;
  runs: number;
  wickets: number;
  economy: number;
  wides: number;
  noBalls: number;
  dotBalls: number;
}

export interface EnginePartnership {
  batter1: string;
  batter2: string;
  runs: number;
  balls: number;
  isActive: boolean;
}

export interface EngineInningsState {
  battingTeam: string;
  bowlingTeam: string;
  battingOrder: string[];
  bowlingOrder: string[];
  totalRuns: number;
  totalWickets: number;
  totalBalls: number;
  extras: EngineExtras;
  currentBatters: { striker?: string; nonStriker?: string };
  currentBowler?: string;
  lastOverBowler?: string;
  currentOverRuns: number;
  stateVersion: number;
  target?: number;
  status: InningsStatus;
  fallOfWickets: EngineFallOfWicket[];
  battingStats: EngineBattingStats[];
  bowlingStats: EngineBowlingStats[];
  partnerships: EnginePartnership[];
}

export interface EngineDeliveryInput {
  runs: number;
  extraType: ExtraType;
  extraRuns: number;
  batter: string;
  nonStriker: string;
  bowler: string;
  wicket?: EngineWicketInput;
  commentary?: string;
}

export interface EngineDeliveryRecord {
  sequenceNumber: number;
  batter: string;
  nonStriker: string;
  bowler: string;
  runs: { batter: number; extras: number; total: number };
  extras: { type: ExtraType; runs: number };
  isLegal: boolean;
  isWicket: boolean;
  wicket?: EngineWicketInput;
  commentary?: string;
}

export interface CommentaryNames {
  striker: string;
  nonStriker: string;
  bowler: string;
  fielder?: string;
}

export interface ApplyDeliveryResult {
  state: EngineInningsState;
  totals: {
    batterRuns: number;
    extras: EngineExtras;
    totalRuns: number;
    bowlerRuns: number;
  };
  isLegal: boolean;
  isWicket: boolean;
  isBoundary: boolean;
  isSix: boolean;
  commentary: string;
  overCompleted: boolean;
}

const MAX_WICKETS = 10;

const emptyExtras = (): EngineExtras => ({
  wides: 0,
  noBalls: 0,
  byes: 0,
  legByes: 0,
  penalties: 0,
  total: 0,
});

const clone = <T>(value: T): T => JSON.parse(JSON.stringify(value)) as T;

const samePlayer = (left?: string, right?: string): boolean =>
  Boolean(left && right && String(left) === String(right));

const asString = (value: unknown): string | undefined =>
  value === undefined || value === null ? undefined : String(value);

export const formatOvers = (balls: number, ballsPerOver: number): string =>
  `${Math.floor(balls / ballsPerOver)}.${balls % ballsPerOver}`;

export const calculateStrikeRate = (runs: number, balls: number): number =>
  balls === 0 ? 0 : Number(((runs / balls) * 100).toFixed(2));

export const calculateEconomy = (runs: number, balls: number, ballsPerOver = 6): number =>
  balls === 0 ? 0 : Number(((runs / (balls / ballsPerOver))).toFixed(2));

const battingStat = (
  state: EngineInningsState,
  player: string,
  position?: number
): EngineBattingStats => {
  let stat = state.battingStats.find((item) => item.player === player);
  if (!stat) {
    stat = {
      player,
      runs: 0,
      balls: 0,
      fours: 0,
      sixes: 0,
      strikeRate: 0,
      isNotOut: true,
      position: position ?? state.battingOrder.indexOf(player) + 1,
    };
    state.battingStats.push(stat);
  }
  return stat;
};

const bowlingStat = (state: EngineInningsState, player: string): EngineBowlingStats => {
  let stat = state.bowlingStats.find((item) => item.player === player);
  if (!stat) {
    stat = {
      player,
      overs: 0,
      balls: 0,
      maidens: 0,
      runs: 0,
      wickets: 0,
      economy: 0,
      wides: 0,
      noBalls: 0,
      dotBalls: 0,
    };
    state.bowlingStats.push(stat);
  }
  return stat;
};

const validateMembership = (
  state: EngineInningsState,
  input: EngineDeliveryInput,
  enforcePlayers: boolean
): void => {
  if (!enforcePlayers) return;

  if (!samePlayer(input.batter, state.currentBatters.striker)) {
    throw ApiError.badRequest('Batter must be the current striker.');
  }
  if (!samePlayer(input.nonStriker, state.currentBatters.nonStriker)) {
    throw ApiError.badRequest('Non-striker must be the current non-striker.');
  }
  if (
    !state.battingOrder.includes(input.batter) ||
    !state.battingOrder.includes(input.nonStriker)
  ) {
    throw ApiError.badRequest('Both batters must be in the batting Playing XI.');
  }
  if (!state.bowlingOrder.includes(input.bowler)) {
    throw ApiError.badRequest('Bowler must be in the bowling Playing XI.');
  }
  if (!input.bowler) {
    throw ApiError.badRequest('A bowler must be selected before recording a ball.');
  }
};

const buildCommentary = (
  input: EngineDeliveryInput,
  totals: ApplyDeliveryResult['totals'],
  isWicket: boolean,
  names: CommentaryNames
): string => {
  const extraLabel: Partial<Record<ExtraType, string>> = {
    [ExtraType.WIDE]: `${totals.extras.wides} wide${totals.extras.wides === 1 ? '' : 's'}`,
    [ExtraType.NO_BALL]: `${totals.extras.noBalls} no-ball${totals.extras.noBalls === 1 ? '' : 's'}`,
    [ExtraType.BYE]: `${totals.extras.byes} bye${totals.extras.byes === 1 ? '' : 's'}`,
    [ExtraType.LEG_BYE]: `${totals.extras.legByes} leg bye${totals.extras.legByes === 1 ? '' : 's'}`,
    [ExtraType.PENALTY]: `${totals.extras.penalties} penalty run${totals.extras.penalties === 1 ? '' : 's'}`,
  };

  const parts: string[] = [];
  if (input.extraType !== ExtraType.NONE && extraLabel[input.extraType]) {
    parts.push(extraLabel[input.extraType] as string);
  }
  if (totals.batterRuns > 0) {
    parts.push(`${totals.batterRuns} run${totals.batterRuns === 1 ? '' : 's'} off the bat`);
  }
  if (parts.length === 0) parts.push('dot ball');

  const suffix = `off ${names.bowler}`;
  let text = `${names.striker}: ${parts.join(', ')} ${suffix}.`;

  if (isWicket && input.wicket) {
    const dismissed = input.wicket.batter && input.wicket.batter === input.nonStriker
      ? names.nonStriker
      : names.striker;
    const fielder = input.wicket.fielder ? ` by ${names.fielder || 'fielder'}` : '';
    text = `WICKET! ${dismissed} ${input.wicket.type.toLowerCase()}${fielder} ${suffix}. ${text}`;
  }

  return text;
};

export const applyDelivery = (
  current: EngineInningsState,
  input: EngineDeliveryInput,
  rules: ScoringRules,
  names: CommentaryNames,
  options: { enforcePlayers?: boolean } = {}
): ApplyDeliveryResult => {
  const state = clone(current);
  validateMembership(state, input, options.enforcePlayers !== false);
  if (!state.currentBatters.striker || !state.currentBatters.nonStriker) {
    throw ApiError.badRequest('Start the innings by selecting openers and a bowler.');
  }
  if (!state.currentBowler) {
    throw ApiError.badRequest('A bowler must be selected before recording a ball.');
  }
  if (state.status !== InningsStatus.IN_PROGRESS) {
    throw ApiError.badRequest('This innings is not accepting deliveries.');
  }
  if (state.totalWickets >= MAX_WICKETS) {
    throw ApiError.badRequest('The innings is already complete.');
  }
  if (state.target && state.totalRuns >= state.target) {
    throw ApiError.badRequest('The chase has already been completed.');
  }
  if (state.totalBalls >= rules.totalOvers * rules.ballsPerOver) {
    throw ApiError.badRequest('The innings has reached its allotted overs.');
  }

  const isSameBowlerAsLastOver = samePlayer(input.bowler, state.lastOverBowler);
  const isNewOver = state.totalBalls > 0 && state.totalBalls % rules.ballsPerOver === 0;
  if (isNewOver && isSameBowlerAsLastOver) {
    throw ApiError.badRequest('The same bowler cannot bowl consecutive overs.');
  }
  if (!samePlayer(input.bowler, state.currentBowler)) {
    if (!isNewOver) {
      throw ApiError.badRequest('The bowler can only be changed at the end of an over.');
    }
  }

  const extras = emptyExtras();
  let batterRuns = Math.max(0, Math.floor(input.runs || 0));
  let extraRuns = Math.max(0, Math.floor(input.extraRuns || 0));

  switch (input.extraType) {
    case ExtraType.WIDE:
      extras.wides = 1 + extraRuns;
      break;
    case ExtraType.NO_BALL:
      extras.noBalls = 1 + extraRuns;
      break;
    case ExtraType.BYE:
      if (extraRuns === 0 && batterRuns > 0) {
        extraRuns = batterRuns;
        batterRuns = 0;
      }
      extras.byes = extraRuns;
      break;
    case ExtraType.LEG_BYE:
      if (extraRuns === 0 && batterRuns > 0) {
        extraRuns = batterRuns;
        batterRuns = 0;
      }
      extras.legByes = extraRuns;
      break;
    case ExtraType.PENALTY:
      if (extraRuns === 0 && batterRuns > 0) {
        extraRuns = batterRuns;
        batterRuns = 0;
      }
      extras.penalties = extraRuns;
      break;
    default:
      break;
  }

  extras.total = extras.wides + extras.noBalls + extras.byes + extras.legByes + extras.penalties;
  const totalRuns = batterRuns + extras.total;
  if (batterRuns > 6 || totalRuns > 12) {
    throw ApiError.badRequest('Invalid number of runs for a delivery.');
  }

  const isLegal =
    input.extraType === ExtraType.NONE ||
    input.extraType === ExtraType.BYE ||
    input.extraType === ExtraType.LEG_BYE;

  const bowlerRuns =
    input.extraType === ExtraType.WIDE
      ? extras.total
      : input.extraType === ExtraType.NO_BALL
        ? extras.noBalls + batterRuns
        : input.extraType === ExtraType.BYE ||
            input.extraType === ExtraType.LEG_BYE ||
            input.extraType === ExtraType.PENALTY
          ? 0
          : batterRuns;

  const strikerStat = battingStat(state, input.batter);
  const bowlerStat = bowlingStat(state, input.bowler);
  battingStat(state, input.nonStriker);

  state.totalRuns += totalRuns;
  state.extras.wides += extras.wides;
  state.extras.noBalls += extras.noBalls;
  state.extras.byes += extras.byes;
  state.extras.legByes += extras.legByes;
  state.extras.penalties += extras.penalties;
  state.extras.total += extras.total;

  if (isLegal) {
    state.totalBalls += 1;
    strikerStat.balls += 1;
    bowlerStat.balls += 1;
    bowlerStat.wides += extras.wides;
    bowlerStat.noBalls += extras.noBalls;
    if (totalRuns === 0) bowlerStat.dotBalls += 1;
  } else {
    bowlerStat.wides += extras.wides;
    bowlerStat.noBalls += extras.noBalls;
  }

  if (batterRuns > 0 && (input.extraType === ExtraType.NONE || input.extraType === ExtraType.NO_BALL)) {
    strikerStat.runs += batterRuns;
    if (batterRuns === 4) strikerStat.fours += 1;
    if (batterRuns === 6) strikerStat.sixes += 1;
  }

  state.currentOverRuns += bowlerRuns;
  bowlerStat.runs += bowlerRuns;

  let isWicket = false;
  if (input.wicket) {
    isWicket = true;
    const dismissed = input.wicket.batter || state.currentBatters.striker;
    const isStriker = samePlayer(dismissed, state.currentBatters.striker);
    const dismissedStat = battingStat(state, dismissed);
    dismissedStat.isNotOut = false;
    dismissedStat.dismissal = {
      type: input.wicket.type,
      fielder: asString(input.wicket.fielder),
      description: input.wicket.description,
    };

    const creditsBowler =
      input.wicket.type !== DismissalType.RUN_OUT &&
      input.wicket.type !== DismissalType.RETIRED_OUT &&
      input.wicket.type !== DismissalType.OBSTRUCTING_FIELD;
    if (creditsBowler) {
      dismissedStat.dismissal.bowler = input.bowler;
      bowlerStat.wickets += 1;
    }

    state.totalWickets += 1;
    state.fallOfWickets.push({
      player: dismissed,
      runs: batterRuns,
      balls: isLegal ? 1 : 0,
      teamScore: state.totalRuns,
      teamOvers: formatOvers(state.totalBalls, rules.ballsPerOver),
      wicketNumber: state.totalWickets,
    });

    if (state.totalWickets < MAX_WICKETS) {
      const replacement = state.battingOrder.find(
        (player) =>
          !state.battingStats.some(
            (stat) => stat.player === player && !stat.isNotOut
          ) &&
          !samePlayer(player, state.currentBatters.striker) &&
          !samePlayer(player, state.currentBatters.nonStriker)
      );
      if (replacement) {
        if (isStriker) state.currentBatters.striker = replacement;
        else state.currentBatters.nonStriker = replacement;
      }
    }
  }

  if (state.partnerships.length === 0 && state.currentBatters.striker && state.currentBatters.nonStriker) {
    state.partnerships.push({
      batter1: state.currentBatters.striker,
      batter2: state.currentBatters.nonStriker,
      runs: 0,
      balls: 0,
      isActive: true,
    });
  }
  const activePartnership = [...state.partnerships].reverse().find((item) => item.isActive);
  if (activePartnership) {
    activePartnership.runs += totalRuns;
    activePartnership.balls += isLegal ? 1 : 0;
  }
  if (isWicket && state.currentBatters.striker && state.currentBatters.nonStriker) {
    state.partnerships.forEach((item) => {
      item.isActive = false;
    });
    state.partnerships.push({
      batter1: state.currentBatters.striker,
      batter2: state.currentBatters.nonStriker,
      runs: 0,
      balls: 0,
      isActive: true,
    });
  }

  const oddRuns = totalRuns % 2 === 1;
  if (oddRuns && state.currentBatters.striker && state.currentBatters.nonStriker) {
    const striker = state.currentBatters.striker;
    state.currentBatters.striker = state.currentBatters.nonStriker;
    state.currentBatters.nonStriker = striker;
  }

  let overCompleted = false;
  if (isLegal && state.totalBalls % rules.ballsPerOver === 0) {
    overCompleted = true;
    if (state.currentOverRuns === 0) bowlerStat.maidens += 1;
    state.lastOverBowler = input.bowler;
    state.currentBowler = undefined;
    state.currentOverRuns = 0;
    if (state.currentBatters.striker && state.currentBatters.nonStriker) {
      const striker = state.currentBatters.striker;
      state.currentBatters.striker = state.currentBatters.nonStriker;
      state.currentBatters.nonStriker = striker;
    }
  }

  state.battingStats.forEach((stat) => {
    stat.strikeRate = calculateStrikeRate(stat.runs, stat.balls);
  });
  state.bowlingStats.forEach((stat) => {
    stat.overs = Number((stat.balls / rules.ballsPerOver).toFixed(2));
    stat.economy = calculateEconomy(stat.runs, stat.balls, rules.ballsPerOver);
  });

  const commentary = input.commentary?.trim() || buildCommentary(
    input,
    { batterRuns, extras, totalRuns, bowlerRuns },
    isWicket,
    names
  );

  return {
    state,
    totals: { batterRuns, extras, totalRuns, bowlerRuns },
    isLegal,
    isWicket,
    isBoundary: batterRuns === 4,
    isSix: batterRuns === 6,
    commentary,
    overCompleted,
  };
};

const deliveryToInput = (delivery: EngineDeliveryRecord): EngineDeliveryInput => {
  const extraRuns = delivery.extras.runs;
  let runs = delivery.runs.batter;
  let extrasRunValue = extraRuns;

  if (delivery.extras.type === ExtraType.WIDE || delivery.extras.type === ExtraType.NO_BALL) {
    extrasRunValue = Math.max(0, extraRuns - 1);
  } else if (
    delivery.extras.type === ExtraType.BYE ||
    delivery.extras.type === ExtraType.LEG_BYE ||
    delivery.extras.type === ExtraType.PENALTY
  ) {
    runs = 0;
  }

  return {
    runs,
    extraRuns: extrasRunValue,
    extraType: delivery.extras.type,
    batter: delivery.batter,
    nonStriker: delivery.nonStriker,
    bowler: delivery.bowler,
    wicket: delivery.wicket,
    commentary: delivery.commentary,
  };
};

export const rebuildInnings = (
  base: EngineInningsState,
  deliveries: EngineDeliveryRecord[],
  rules: ScoringRules
): EngineInningsState => {
  let state: EngineInningsState = {
    ...clone(base),
    totalRuns: 0,
    totalWickets: 0,
    totalBalls: 0,
    extras: emptyExtras(),
    currentBatters: clone(base.currentBatters),
    currentBowler: asString(base.currentBowler),
    lastOverBowler: undefined,
    currentOverRuns: 0,
    fallOfWickets: [],
    battingStats: [],
    bowlingStats: [],
    partnerships: [],
    status: InningsStatus.IN_PROGRESS,
  };

  const ordered = [...deliveries].sort((a, b) => a.sequenceNumber - b.sequenceNumber);
  for (const delivery of ordered) {
    const input = deliveryToInput(delivery);
    state.currentBatters = {
      striker: delivery.batter,
      nonStriker: delivery.nonStriker,
    };
    state.currentBowler = delivery.bowler;
    const result = applyDelivery(
      state,
      input,
      rules,
      {
        striker: delivery.batter,
        nonStriker: delivery.nonStriker,
        bowler: delivery.bowler,
        fielder: delivery.wicket?.fielder || '',
      },
      { enforcePlayers: false }
    );
    state = result.state;
  }

  state.stateVersion = base.stateVersion;
  return state;
};

export const isInningsComplete = (
  state: EngineInningsState,
  rules: ScoringRules
): boolean =>
  state.totalWickets >= Math.min(MAX_WICKETS, state.battingOrder.length) ||
  state.totalBalls >= rules.totalOvers * rules.ballsPerOver ||
  Boolean(state.target && state.totalRuns >= state.target);

export const deriveInningsResult = (
  state: EngineInningsState,
  rules: ScoringRules,
  firstInningsRuns: number
): { winner?: string; resultType: string; margin: number; description: string } => {
  if (state.target && state.totalRuns >= state.target) {
    return {
      winner: state.battingTeam,
      resultType: 'WICKETS',
      margin: Math.min(MAX_WICKETS, state.battingOrder.length) - state.totalWickets,
      description: 'Chase completed successfully.',
    };
  }

  if (state.totalRuns === firstInningsRuns) {
    return {
      resultType: 'TIE',
      margin: 0,
      description: 'Match tied.',
    };
  }

  if (state.totalRuns > firstInningsRuns) {
    return {
      winner: state.battingTeam,
      resultType: 'RUNS',
      margin: state.totalRuns - firstInningsRuns,
      description: 'Match won by runs.',
    };
  }

  return {
    winner: state.bowlingTeam,
    resultType: 'RUNS',
    margin: firstInningsRuns - state.totalRuns,
    description: 'Match won by runs.',
  };
};
