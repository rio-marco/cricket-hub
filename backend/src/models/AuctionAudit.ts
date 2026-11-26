import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AuctionAuditAction } from '../constants/enums';

export interface IAuctionAudit {
  auction: Types.ObjectId;
  auctionPlayer?: Types.ObjectId;
  action: AuctionAuditAction;
  actor: Types.ObjectId;
  requestKey: string;
  sequenceNumber?: number;
  stateVersion: number;
  payload: Record<string, unknown>;
  result: Record<string, unknown>;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AuctionAuditDocument = Document<unknown, {}, IAuctionAudit> & IAuctionAudit;
export type AuctionAuditModel = Model<IAuctionAudit>;

const auctionAuditSchema = new Schema<IAuctionAudit, AuctionAuditModel>(
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
      index: true,
    },
    action: {
      type: String,
      enum: Object.values(AuctionAuditAction),
      required: [true, 'Audit action is required'],
    },
    actor: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Audit actor is required'],
    },
    requestKey: {
      type: String,
      required: [true, 'Audit request key is required'],
      trim: true,
    },
    sequenceNumber: {
      type: Number,
      min: [1, 'Bid sequence number must be positive'],
    },
    stateVersion: {
      type: Number,
      required: [true, 'Auction state version is required'],
      min: [0, 'Auction state version cannot be negative'],
    },
    payload: {
      type: Schema.Types.Mixed,
      default: {},
    },
    result: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

auctionAuditSchema.index({ auction: 1, requestKey: 1 }, { unique: true });
auctionAuditSchema.index({ auction: 1, createdAt: -1 });

export const AuctionAudit = mongoose.model<IAuctionAudit, AuctionAuditModel>(
  'AuctionAudit',
  auctionAuditSchema
);

export default AuctionAudit;
