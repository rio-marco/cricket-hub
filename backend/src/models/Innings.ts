import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { InningsStatus, DismissalType } from '../constants/enums';

export interface IExtras {
  wides: number;
  noBalls: number;
  byes: number;
  legByes: number;
  penalties: number;
  total: number;
}

export interface ICurrentBatters {
  striker?: Types.ObjectId;
  nonStriker?: Types.ObjectId;
}

export interface IFallOfWicket {
  player: Types.ObjectId;
  runs: number;
  balls: number;
  teamScore: number;
  teamOvers: string;
  wicketNumber: number;
}

export interface IBattingStatsDismissal {
  type?: DismissalType;
  bowler?: Types.ObjectId;
  fielder?: Types.ObjectId;
  description?: string;
}

export interface IBattingStats {
  player: Types.ObjectId;
  runs: number;
  balls: number;
  fours: number;
  sixes: number;
  strikeRate: number;
  dismissal?: IBattingStatsDismissal;
  isNotOut: boolean;
  position?: number;
}

export interface IBowlingStats {
  player: Types.ObjectId;
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

export interface IPartnership {
  batter1: Types.ObjectId;
  batter2: Types.ObjectId;
  runs: number;
  balls: number;
  isActive: boolean;
}

export interface IInnings {
  match: Types.ObjectId;
  inningsNumber: number;
  battingTeam: Types.ObjectId;
  bowlingTeam: Types.ObjectId;
  totalRuns: number;
  totalWickets: number;
  totalOvers: number;
  totalBalls: number;
  nextSequence: number;
  extras: IExtras;
  currentBatters?: ICurrentBatters;
  currentBowler?: Types.ObjectId;
  lastOverBowler?: Types.ObjectId;
  currentOverRuns: number;
  stateVersion: number;
  target?: number;
  status: InningsStatus;
  fallOfWickets: IFallOfWicket[];
  battingOrder: Types.ObjectId[];
  battingStats: IBattingStats[];
  bowlingStats: IBowlingStats[];
  partnerships: IPartnership[];
  createdAt?: Date;
  updatedAt?: Date;
}

export type InningsDocument = Document<unknown, {}, IInnings> & IInnings;
export type InningsModel = Model<IInnings>;

const extrasSchema = new Schema<IExtras>(
  {
    wides: { type: Number, default: 0, min: 0 },
    noBalls: { type: Number, default: 0, min: 0 },
    byes: { type: Number, default: 0, min: 0 },
    legByes: { type: Number, default: 0, min: 0 },
    penalties: { type: Number, default: 0, min: 0 },
    total: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const currentBattersSchema = new Schema<ICurrentBatters>(
  {
    striker: { type: Schema.Types.ObjectId, ref: 'Player' },
    nonStriker: { type: Schema.Types.ObjectId, ref: 'Player' },
  },
  { _id: false }
);

const fallOfWicketSchema = new Schema<IFallOfWicket>(
  {
    player: { type: Schema.Types.ObjectId, ref: 'Player', required: true },
    runs: { type: Number, required: true },
    balls: { type: Number, required: true },
    teamScore: { type: Number, required: true },
    teamOvers: { type: String, required: true },
    wicketNumber: { type: Number, required: true },
  },
  { _id: false }
);

const battingStatsDismissalSchema = new Schema<IBattingStatsDismissal>(
  {
    type: { type: String, enum: Object.values(DismissalType) },
    bowler: { type: Schema.Types.ObjectId, ref: 'Player' },
    fielder: { type: Schema.Types.ObjectId, ref: 'Player' },
    description: { type: String, trim: true },
  },
  { _id: false }
);

const battingStatsSchema = new Schema<IBattingStats>(
  {
    player: { type: Schema.Types.ObjectId, ref: 'Player', required: true },
    runs: { type: Number, default: 0, min: 0 },
    balls: { type: Number, default: 0, min: 0 },
    fours: { type: Number, default: 0, min: 0 },
    sixes: { type: Number, default: 0, min: 0 },
    strikeRate: { type: Number, default: 0, min: 0 },
    dismissal: { type: battingStatsDismissalSchema, default: undefined },
    isNotOut: { type: Boolean, default: true },
    position: { type: Number },
  },
  { _id: false }
);

const bowlingStatsSchema = new Schema<IBowlingStats>(
  {
    player: { type: Schema.Types.ObjectId, ref: 'Player', required: true },
    overs: { type: Number, default: 0, min: 0 },
    balls: { type: Number, default: 0, min: 0 },
    maidens: { type: Number, default: 0, min: 0 },
    runs: { type: Number, default: 0, min: 0 },
    wickets: { type: Number, default: 0, min: 0 },
    economy: { type: Number, default: 0, min: 0 },
    wides: { type: Number, default: 0, min: 0 },
    noBalls: { type: Number, default: 0, min: 0 },
    dotBalls: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const partnershipSchema = new Schema<IPartnership>(
  {
    batter1: { type: Schema.Types.ObjectId, ref: 'Player', required: true },
    batter2: { type: Schema.Types.ObjectId, ref: 'Player', required: true },
    runs: { type: Number, default: 0, min: 0 },
    balls: { type: Number, default: 0, min: 0 },
    isActive: { type: Boolean, default: true },
  },
  { _id: false }
);

const inningsSchema = new Schema<IInnings, InningsModel>(
  {
    match: {
      type: Schema.Types.ObjectId,
      ref: 'Match',
      required: [true, 'Match reference is required'],
      index: true,
    },
    inningsNumber: {
      type: Number,
      required: [true, 'Innings number is required'],
      min: 1,
      max: 2,
    },
    battingTeam: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Batting team is required'],
    },
    bowlingTeam: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Bowling team is required'],
    },
    totalRuns: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalWickets: {
      type: Number,
      default: 0,
      min: 0,
      max: 10,
    },
    totalOvers: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalBalls: {
      type: Number,
      default: 0,
      min: 0,
    },
    nextSequence: {
      type: Number,
      default: 1,
      min: 1,
    },
    extras: {
      type: extrasSchema,
      default: () => ({
        wides: 0,
        noBalls: 0,
        byes: 0,
        legByes: 0,
        penalties: 0,
        total: 0,
      }),
    },
    currentBatters: {
      type: currentBattersSchema,
      default: undefined,
    },
    currentBowler: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    lastOverBowler: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    currentOverRuns: {
      type: Number,
      default: 0,
      min: 0,
    },
    stateVersion: {
      type: Number,
      default: 0,
      min: 0,
    },
    target: {
      type: Number,
      min: 0,
    },
    status: {
      type: String,
      enum: Object.values(InningsStatus),
      default: InningsStatus.NOT_STARTED,
      index: true,
    },
    fallOfWickets: {
      type: [fallOfWicketSchema],
      default: [],
    },
    battingOrder: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Player',
      },
    ],
    battingStats: {
      type: [battingStatsSchema],
      default: [],
    },
    bowlingStats: {
      type: [bowlingStatsSchema],
      default: [],
    },
    partnerships: {
      type: [partnershipSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index ensuring only one record per innings per match
inningsSchema.index({ match: 1, inningsNumber: 1 }, { unique: true });
inningsSchema.index({ match: 1, status: 1 });
inningsSchema.index({ status: 1, 'battingStats.player': 1 });
inningsSchema.index({ status: 1, 'bowlingStats.player': 1 });

export const Innings = mongoose.model<IInnings, InningsModel>('Innings', inningsSchema);

export default Innings;
