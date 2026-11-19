import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AuctionPlayerStatus } from '../constants/enums';

export interface IAuctionPlayer {
  auction: Types.ObjectId;
  player: Types.ObjectId;
  basePrice: number;
  soldPrice?: number;
  soldTo?: Types.ObjectId;
  status: AuctionPlayerStatus;
  category?: string;
  set?: number;
  order?: number;
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
    status: {
      type: String,
      enum: Object.values(AuctionPlayerStatus),
      default: AuctionPlayerStatus.AVAILABLE,
      index: true,
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
  },
  {
    timestamps: true,
  }
);

// Compound unique index ensuring player is listed only once in an auction
auctionPlayerSchema.index({ auction: 1, player: 1 }, { unique: true });
auctionPlayerSchema.index({ auction: 1, status: 1, set: 1, order: 1 });

export const AuctionPlayer = mongoose.model<IAuctionPlayer, AuctionPlayerModel>(
  'AuctionPlayer',
  auctionPlayerSchema
);

export default AuctionPlayer;
