import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export interface IAuctionBid {
  auction: Types.ObjectId;
  auctionPlayer: Types.ObjectId;
  team: Types.ObjectId;
  amount: number;
  bidBy: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AuctionBidDocument = Document<unknown, {}, IAuctionBid> & IAuctionBid;
export type AuctionBidModel = Model<IAuctionBid>;

const auctionBidSchema = new Schema<IAuctionBid, AuctionBidModel>(
  {
    auction: {
      type: Schema.Types.ObjectId,
      ref: 'Auction',
      required: [true, 'Auction reference is required'],
      index: true,
    },
    auctionPlayer: {
      type: Schema.Types.ObjectId,
      ref: 'AuctionPlayer',
      required: [true, 'AuctionPlayer reference is required'],
      index: true,
    },
    team: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team reference is required'],
      index: true,
    },
    amount: {
      type: Number,
      required: [true, 'Bid amount is required'],
      min: [1, 'Bid amount must be greater than zero'],
    },
    bidBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User placing the bid is required'],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
auctionBidSchema.index({ auctionPlayer: 1, amount: -1 });
auctionBidSchema.index({ auction: 1, team: 1 });
auctionBidSchema.index({ createdAt: -1 });

export const AuctionBid = mongoose.model<IAuctionBid, AuctionBidModel>('AuctionBid', auctionBidSchema);

export default AuctionBid;
