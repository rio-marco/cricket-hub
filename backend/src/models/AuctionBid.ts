import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AuctionBidDecision } from '../constants/enums';

export interface IAuctionBid {
  auction: Types.ObjectId;
  auctionPlayer: Types.ObjectId;
  team: Types.ObjectId;
  amount: number;
  bidBy: Types.ObjectId;
  requestKey?: string;
  sequenceNumber: number;
  decision: AuctionBidDecision;
  rejectionReason?: string;
  decidedBy?: Types.ObjectId;
  decidedAt?: Date;
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
    requestKey: {
      type: String,
      trim: true,
    },
    sequenceNumber: {
      type: Number,
      required: [true, 'Bid sequence number is required'],
      min: [1, 'Bid sequence number must be positive'],
    },
    decision: {
      type: String,
      enum: Object.values(AuctionBidDecision),
      default: AuctionBidDecision.PENDING,
      index: true,
    },
    rejectionReason: {
      type: String,
      trim: true,
      maxlength: [300, 'Rejection reason cannot exceed 300 characters'],
    },
    decidedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    decidedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

auctionBidSchema.index({ auctionPlayer: 1, amount: -1 });
auctionBidSchema.index({ auction: 1, team: 1 });
auctionBidSchema.index({ createdAt: -1 });
auctionBidSchema.index(
  { auction: 1, requestKey: 1 },
  { unique: true, partialFilterExpression: { requestKey: { $type: 'string' } } }
);
auctionBidSchema.index(
  { auctionPlayer: 1, sequenceNumber: 1 },
  { unique: true, partialFilterExpression: { sequenceNumber: { $type: 'number' } } }
);

export const AuctionBid = mongoose.model<IAuctionBid, AuctionBidModel>('AuctionBid', auctionBidSchema);

export default AuctionBid;
