import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AuctionBidDecision, AuctionPlayerStatus } from '../constants/enums';

export interface IAuctionPlayer {
  auction: Types.ObjectId;
  player: Types.ObjectId;
  basePrice: number;
  soldPrice?: number;
  soldTo?: Types.ObjectId;
  soldAt?: Date;
  status: AuctionPlayerStatus;
  available: boolean;
  category?: string;
  set?: number;
  order?: number;
  currentBid: number;
  highestBidder?: Types.ObjectId;
  bidCount: number;
  lastSequence: number;
  decision: AuctionBidDecision;
  version: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AuctionPlayerDocument = Document<unknown, {}, IAuctionPlayer> & IAuctionPlayer;
export type AuctionPlayerModel = Model<IAuctionPlayer>;

const auctionPlayerSchema = new Schema<IAuctionPlayer, AuctionPlayerModel>(
  {
    auction: {
      type: Schema.Types.ObjectId,
      ref: 'Auction',
      required: [true, 'Auction reference is required'],
      index: true,
    },
    player: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
      required: [true, 'Player reference is required'],
      index: true,
    },
    basePrice: {
      type: Number,
      required: [true, 'Base price is required'],
      min: [0, 'Base price cannot be negative'],
    },
    soldPrice: {
      type: Number,
      min: [0, 'Sold price cannot be negative'],
    },
    soldTo: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      index: true,
    },
    soldAt: {
      type: Date,
    },
    status: {
      type: String,
      enum: Object.values(AuctionPlayerStatus),
      default: AuctionPlayerStatus.AVAILABLE,
      index: true,
    },
    available: {
      type: Boolean,
      default: true,
    },
    category: {
      type: String,
      trim: true,
    },
    set: {
      type: Number,
      min: 1,
    },
    order: {
      type: Number,
      min: 1,
    },
    currentBid: {
      type: Number,
      default: 0,
      min: [0, 'Current bid cannot be negative'],
    },
    highestBidder: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
    },
    bidCount: {
      type: Number,
      default: 0,
      min: [0, 'Bid count cannot be negative'],
    },
    lastSequence: {
      type: Number,
      default: 0,
      min: [0, 'Bid sequence cannot be negative'],
    },
    decision: {
      type: String,
      enum: Object.values(AuctionBidDecision),
      default: AuctionBidDecision.PENDING,
    },
    version: {
      type: Number,
      default: 0,
      min: [0, 'Auction player version cannot be negative'],
    },
  },
  {
    timestamps: true,
  }
);

auctionPlayerSchema.index({ auction: 1, player: 1 }, { unique: true });
auctionPlayerSchema.index({ auction: 1, status: 1, set: 1, order: 1 });
auctionPlayerSchema.index({ auction: 1, available: 1, status: 1 });

export const AuctionPlayer = mongoose.model<IAuctionPlayer, AuctionPlayerModel>(
  'AuctionPlayer',
  auctionPlayerSchema
);

export default AuctionPlayer;
