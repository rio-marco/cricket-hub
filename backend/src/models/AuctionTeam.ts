import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export interface IAuctionTeam {
  auction: Types.ObjectId;
  team: Types.ObjectId;
  initialBudget: number;
  spent: number;
  pendingCommitment: number;
  playersPurchased: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AuctionTeamDocument = Document<unknown, {}, IAuctionTeam> & IAuctionTeam;
export type AuctionTeamModel = Model<IAuctionTeam>;

const auctionTeamSchema = new Schema<IAuctionTeam, AuctionTeamModel>(
  {
    auction: {
      type: Schema.Types.ObjectId,
      ref: 'Auction',
      required: [true, 'Auction reference is required'],
      index: true,
    },
    team: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team reference is required'],
      index: true,
    },
    initialBudget: {
      type: Number,
      required: [true, 'Initial team budget is required'],
      min: [0, 'Initial team budget cannot be negative'],
    },
    spent: {
      type: Number,
      default: 0,
      min: [0, 'Amount spent cannot be negative'],
    },
    pendingCommitment: {
      type: Number,
      default: 0,
      min: [0, 'Pending commitment cannot be negative'],
    },
    playersPurchased: {
      type: Number,
      default: 0,
      min: [0, 'Players purchased cannot be negative'],
    },
  },
  {
    timestamps: true,
  }
);

auctionTeamSchema.index({ auction: 1, team: 1 }, { unique: true });
auctionTeamSchema.index({ auction: 1, playersPurchased: 1 });

export const AuctionTeam = mongoose.model<IAuctionTeam, AuctionTeamModel>(
  'AuctionTeam',
  auctionTeamSchema
);

export default AuctionTeam;
