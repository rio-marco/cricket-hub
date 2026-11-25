import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import {
  MatchFormat,
  BallType,
  MatchStatus,
  TossDecision,
  ResultType,
} from '../constants/enums';

export interface IToss {
  winner?: Types.ObjectId;
  decision?: TossDecision;
}

export interface IMatchResult {
  winner?: Types.ObjectId;
  resultType?: ResultType;
  margin?: number;
  description?: string;
}

export interface IMatch {
  title?: string;
  tournament?: Types.ObjectId;
  teamA: Types.ObjectId;
  teamB: Types.ObjectId;
  format: MatchFormat;
  totalOvers: number;
  ballsPerOver: number;
  ballType?: BallType;
  venue?: string;
  city?: string;
  matchDate?: Date;
  playingXI_A: Types.ObjectId[];
  playingXI_B: Types.ObjectId[];
  substitutes_A: Types.ObjectId[];
  substitutes_B: Types.ObjectId[];
  toss?: IToss;
  scorer?: Types.ObjectId;
  status: MatchStatus;
  result?: IMatchResult;
  playerOfMatch?: Types.ObjectId;
  currentInnings: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type MatchDocument = Document<unknown, {}, IMatch> & IMatch;
export type MatchModel = Model<IMatch>;

const tossSchema = new Schema<IToss>(
  {
    winner: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
    },
    decision: {
      type: String,
      enum: Object.values(TossDecision),
    },
  },
  { _id: false }
);

const matchResultSchema = new Schema<IMatchResult>(
  {
    winner: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
    },
    resultType: {
      type: String,
      enum: Object.values(ResultType),
    },
    margin: {
      type: Number,
    },
    description: {
      type: String,
      trim: true,
    },
  },
  { _id: false }
);

const matchSchema = new Schema<IMatch, MatchModel>(
  {
    title: {
      type: String,
      trim: true,
    },
    tournament: {
      type: Schema.Types.ObjectId,
      ref: 'Tournament',
      index: true,
    },
    teamA: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team A is required'],
      index: true,
    },
    teamB: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team B is required'],
      index: true,
    },
    format: {
      type: String,
      enum: Object.values(MatchFormat),
      required: [true, 'Match format is required'],
    },
    totalOvers: {
      type: Number,
      required: [true, 'Total overs per innings is required'],
      min: [1, 'Match must have at least 1 over'],
      max: [50, 'Total overs cannot exceed 50'],
    },
    ballsPerOver: {
      type: Number,
      default: 6,
      min: [1, 'An over must have at least 1 ball'],
      max: [8, 'An over cannot exceed 8 balls'],
    },
    ballType: {
      type: String,
      enum: Object.values(BallType),
    },
    venue: {
      type: String,
      trim: true,
    },
    city: {
      type: String,
      trim: true,
    },
    matchDate: {
      type: Date,
      index: true,
    },
    playingXI_A: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Player',
      },
    ],
    playingXI_B: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Player',
      },
    ],
    substitutes_A: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Player',
      },
    ],
    substitutes_B: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Player',
      },
    ],
    toss: {
      type: tossSchema,
      default: undefined,
    },
    scorer: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(MatchStatus),
      default: MatchStatus.UPCOMING,
      index: true,
    },
    result: {
      type: matchResultSchema,
      default: undefined,
    },
    playerOfMatch: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    currentInnings: {
      type: Number,
      default: 1,
      min: 1,
      max: 2,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
matchSchema.index({ tournament: 1, status: 1 });
matchSchema.index({ teamA: 1, teamB: 1, matchDate: -1 });
matchSchema.index({ status: 1, matchDate: 1 });

export const Match = mongoose.model<IMatch, MatchModel>('Match', matchSchema);

export default Match;
