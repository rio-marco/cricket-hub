import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { ExtraType, DismissalType } from '../constants/enums';

export interface IDeliveryRuns {
  batter: number;
  extras: number;
  total: number;
}

export interface IDeliveryExtras {
  type: ExtraType;
  runs: number;
}

export interface IDeliveryWicket {
  type?: DismissalType;
  batter?: Types.ObjectId;
  fielder?: Types.ObjectId;
  isStriker: boolean;
}

export interface IDelivery {
  innings: Types.ObjectId;
  match: Types.ObjectId;
  overNumber: number;
  ballNumber: number;
  sequenceNumber: number;
  idempotencyKey?: string;
  batter: Types.ObjectId;
  bowler: Types.ObjectId;
  nonStriker: Types.ObjectId;
  runs: IDeliveryRuns;
  extras: IDeliveryExtras;
  isLegal: boolean;
  wicket?: IDeliveryWicket;
  isWicket: boolean;
  isBoundary: boolean;
  isSix: boolean;
  commentary?: string;
  isUndone: boolean;
  correctedBy?: Types.ObjectId;
  createdAt?: Date;
  updatedAt?: Date;
}

export type DeliveryDocument = Document<unknown, {}, IDelivery> & IDelivery;
export type DeliveryModel = Model<IDelivery>;

const deliveryRunsSchema = new Schema<IDeliveryRuns>(
  {
    batter: { type: Number, default: 0, min: 0 },
    extras: { type: Number, default: 0, min: 0 },
    total: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const deliveryExtrasSchema = new Schema<IDeliveryExtras>(
  {
    type: {
      type: String,
      enum: Object.values(ExtraType),
      default: ExtraType.NONE,
    },
    runs: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  { _id: false }
);

const deliveryWicketSchema = new Schema<IDeliveryWicket>(
  {
    type: {
      type: String,
      enum: Object.values(DismissalType),
    },
    batter: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    fielder: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    isStriker: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const deliverySchema = new Schema<IDelivery, DeliveryModel>(
  {
    innings: {
      type: Schema.Types.ObjectId,
      ref: 'Innings',
      required: [true, 'Innings reference is required'],
      index: true,
    },
    match: {
      type: Schema.Types.ObjectId,
      ref: 'Match',
      required: [true, 'Match reference is required'],
      index: true,
    },
    overNumber: {
      type: Number,
      required: [true, 'Over number is required'],
      min: 0,
    },
    ballNumber: {
      type: Number,
      required: [true, 'Ball number is required'],
      min: 1,
    },
    sequenceNumber: {
      type: Number,
      required: [true, 'Sequence number is required'],
      min: 1,
    },
    idempotencyKey: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    batter: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
      required: [true, 'Striker batter reference is required'],
    },
    bowler: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
      required: [true, 'Bowler reference is required'],
    },
    nonStriker: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
      required: [true, 'Non-striker reference is required'],
    },
    runs: {
      type: deliveryRunsSchema,
      default: () => ({ batter: 0, extras: 0, total: 0 }),
    },
    extras: {
      type: deliveryExtrasSchema,
      default: () => ({ type: ExtraType.NONE, runs: 0 }),
    },
    isLegal: {
      type: Boolean,
      default: true,
    },
    wicket: {
      type: deliveryWicketSchema,
      default: undefined,
    },
    isWicket: {
      type: Boolean,
      default: false,
    },
    isBoundary: {
      type: Boolean,
      default: false,
    },
    isSix: {
      type: Boolean,
      default: false,
    },
    commentary: {
      type: String,
      trim: true,
    },
    isUndone: {
      type: Boolean,
      default: false,
    },
    correctedBy: {
      type: Schema.Types.ObjectId,
      ref: 'Delivery',
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
deliverySchema.index({ innings: 1, sequenceNumber: 1 });
deliverySchema.index({ innings: 1, overNumber: 1, ballNumber: 1 });
deliverySchema.index({ match: 1, isUndone: 1 });
deliverySchema.index({ batter: 1, match: 1 });
deliverySchema.index({ bowler: 1, match: 1 });
deliverySchema.index({ isUndone: 1, 'wicket.fielder': 1, 'wicket.type': 1 });
deliverySchema.index({ isUndone: 1, match: 1, 'wicket.fielder': 1 });

export const Delivery = mongoose.model<IDelivery, DeliveryModel>('Delivery', deliverySchema);

export default Delivery;
