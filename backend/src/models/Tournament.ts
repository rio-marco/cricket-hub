import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { TournamentFormat, BallType, MatchFormat, TournamentStatus } from '../constants/enums';

export interface ITournament {
  name: string;
  description?: string;
  logo?: string;
  banner?: string;
  organizer: Types.ObjectId;
  format: TournamentFormat;
  ballType: BallType;
  matchFormat: MatchFormat;
  customOvers?: number;
  venues: string[];
  city?: string;
  startDate: Date;
  endDate: Date;
  registrationStartDate?: Date;
  registrationEndDate?: Date;
  maxTeams: number;
  maxPlayersPerTeam: number;
  rules?: string;
  registrationFee: number;
  status: TournamentStatus;
  createdAt?: Date;
  updatedAt?: Date;
}

export type TournamentDocument = Document<unknown, {}, ITournament> & ITournament;
export type TournamentModel = Model<ITournament>;

const tournamentSchema = new Schema<ITournament, TournamentModel>(
  {
    name: {
      type: String,
      required: [true, 'Tournament name is required'],
      trim: true,
      minlength: [3, 'Tournament name must be at least 3 characters'],
      maxlength: [150, 'Tournament name cannot exceed 150 characters'],
    },
    description: {
      type: String,
      trim: true,
    },
    logo: {
      type: String,
      default: '',
    },
    banner: {
      type: String,
      default: '',
    },
    organizer: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Organizer is required'],
      index: true,
    },
    format: {
      type: String,
      enum: Object.values(TournamentFormat),
      required: [true, 'Tournament format is required'],
    },
    ballType: {
      type: String,
      enum: Object.values(BallType),
      required: [true, 'Ball type is required'],
    },
    matchFormat: {
      type: String,
      enum: Object.values(MatchFormat),
      required: [true, 'Match format is required'],
    },
    customOvers: {
      type: Number,
      min: [1, 'Custom overs must be at least 1'],
      max: [100, 'Custom overs cannot exceed 100'],
    },
    venues: {
      type: [String],
      default: [],
    },
    city: {
      type: String,
      trim: true,
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    registrationStartDate: {
      type: Date,
    },
    registrationEndDate: {
      type: Date,
    },
    maxTeams: {
      type: Number,
      required: [true, 'Maximum number of teams is required'],
      min: [2, 'A tournament must have at least 2 teams'],
      max: [128, 'Maximum teams limit cannot exceed 128'],
    },
    maxPlayersPerTeam: {
      type: Number,
      default: 15,
      min: [7, 'Minimum players per team must be at least 7'],
      max: [30, 'Maximum players per team cannot exceed 30'],
    },
    rules: {
      type: String,
      trim: true,
    },
    registrationFee: {
      type: Number,
      default: 0,
      min: [0, 'Registration fee cannot be negative'],
    },
    status: {
      type: String,
      enum: Object.values(TournamentStatus),
      default: TournamentStatus.DRAFT,
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
tournamentSchema.index({ organizer: 1, status: 1 });
tournamentSchema.index({ city: 1, status: 1 });
tournamentSchema.index({ startDate: 1, endDate: 1 });

export const Tournament = mongoose.model<ITournament, TournamentModel>('Tournament', tournamentSchema);

export default Tournament;
