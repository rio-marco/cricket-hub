import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AuctionStatus } from '../constants/enums';

export interface IAuction {
  name: string;
  tournament?: Types.ObjectId;
  teams: Types.ObjectId[];
  purseAmount: number;
  basePrice: number;
  minBidIncrement: number;
  maxSquadSize: number;
  minSquadSize: number;
  playerCategories: string[];
  rules: Record<string, unknown>;
  status: AuctionStatus;
  currentPlayer?: Types.ObjectId;
  stateVersion: number;
  nextSequence: number;
  startedAt?: Date;
  endedAt?: Date;
  createdBy: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AuctionDocument = Document<unknown, {}, IAuction> & IAuction;
export type AuctionModel = Model<IAuction>;

const auctionSchema = new Schema<IAuction, AuctionModel>(
  {
    name: {
      type: String,
      required: [true, 'Auction name is required'],
      trim: true,
      minlength: [3, 'Auction name must be at least 3 characters'],
      maxlength: [120, 'Auction name cannot exceed 120 characters'],
    },
    tournament: {
      type: Schema.Types.ObjectId,
      ref: 'Tournament',
      index: true,
    },
    teams: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Team',
      },
    ],
    purseAmount: {
      type: Number,
      required: [true, 'Purse amount per team is required'],
      min: [0, 'Purse amount cannot be negative'],
    },
    basePrice: {
      type: Number,
      default: 0,
      min: [0, 'Player base price cannot be negative'],
    },
    minBidIncrement: {
      type: Number,
      default: 100000,
      min: [1, 'Minimum bid increment must be positive'],
    },
    maxSquadSize: {
      type: Number,
      default: 25,
      min: [1, 'Maximum squad size must be positive'],
    },
    minSquadSize: {
      type: Number,
      default: 11,
      min: [1, 'Minimum squad size must be positive'],
    },
    playerCategories: {
      type: [String],
      default: [],
    },
    rules: {
      type: Schema.Types.Mixed,
      default: {},
    },
    status: {
      type: String,
      enum: Object.values(AuctionStatus),
      default: AuctionStatus.DRAFT,
      index: true,
    },
    currentPlayer: {
      type: Schema.Types.ObjectId,
      ref: 'AuctionPlayer',
    },
    stateVersion: {
      type: Number,
      default: 0,
      min: [0, 'State version cannot be negative'],
    },
    nextSequence: {
      type: Number,
      default: 1,
      min: [1, 'Bid sequence must be positive'],
    },
    startedAt: {
      type: Date,
    },
    endedAt: {
      type: Date,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'CreatedBy user reference is required'],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

auctionSchema.index({ status: 1, createdAt: -1 });
auctionSchema.index({ tournament: 1, status: 1 });

export const Auction = mongoose.model<IAuction, AuctionModel>('Auction', auctionSchema);

export default Auction;
