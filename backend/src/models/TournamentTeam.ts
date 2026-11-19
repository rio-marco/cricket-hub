import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { TournamentTeamStatus } from '../constants/enums';

export interface ITournamentTeam {
  tournament: Types.ObjectId;
  team: Types.ObjectId;
  status: TournamentTeamStatus;
  played: number;
  won: number;
  lost: number;
  tied: number;
  noResult: number;
  points: number;
  netRunRate: number;
  runsScored: number;
  oversPlayed: number;
  runsConceded: number;
  oversBowled: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type TournamentTeamDocument = Document<unknown, {}, ITournamentTeam> & ITournamentTeam;
export type TournamentTeamModel = Model<ITournamentTeam>;

const tournamentTeamSchema = new Schema<ITournamentTeam, TournamentTeamModel>(
  {
    tournament: {
      type: Schema.Types.ObjectId,
      ref: 'Tournament',
      required: [true, 'Tournament reference is required'],
      index: true,
    },
    team: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team reference is required'],
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(TournamentTeamStatus),
      default: TournamentTeamStatus.PENDING,
      index: true,
    },
    played: {
      type: Number,
      default: 0,
      min: 0,
    },
    won: {
      type: Number,
      default: 0,
      min: 0,
    },
    lost: {
      type: Number,
      default: 0,
      min: 0,
    },
    tied: {
      type: Number,
      default: 0,
      min: 0,
    },
    noResult: {
      type: Number,
      default: 0,
      min: 0,
    },
    points: {
      type: Number,
      default: 0,
    },
    netRunRate: {
      type: Number,
      default: 0,
    },
    runsScored: {
      type: Number,
      default: 0,
      min: 0,
    },
    oversPlayed: {
      type: Number,
      default: 0,
      min: 0,
    },
    runsConceded: {
      type: Number,
      default: 0,
      min: 0,
    },
    oversBowled: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index ensuring a team is added only once per tournament
tournamentTeamSchema.index({ tournament: 1, team: 1 }, { unique: true });
// Points table sorting index
tournamentTeamSchema.index({ tournament: 1, points: -1, netRunRate: -1 });

export const TournamentTeam = mongoose.model<ITournamentTeam, TournamentTeamModel>(
  'TournamentTeam',
  tournamentTeamSchema
);

export default TournamentTeam;
