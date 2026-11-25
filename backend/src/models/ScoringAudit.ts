import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export enum ScoringAuditAction {
  START_INNINGS = 'START_INNINGS',
  BALL = 'BALL',
  UNDO = 'UNDO',
  CORRECT = 'CORRECT',
  INNINGS_END = 'INNINGS_END',
}

export interface IScoringAudit {
  match: Types.ObjectId;
  innings: Types.ObjectId;
  action: ScoringAuditAction;
  actor: Types.ObjectId;
  requestKey: string;
  sequenceNumber?: number;
  stateVersion: number;
  payload: Record<string, unknown>;
  result: Record<string, unknown>;
  createdAt?: Date;
  updatedAt?: Date;
}

export type ScoringAuditDocument = Document<unknown, {}, IScoringAudit> & IScoringAudit;
export type ScoringAuditModel = Model<IScoringAudit>;

const scoringAuditSchema = new Schema<IScoringAudit, ScoringAuditModel>(
  {
    match: {
      type: Schema.Types.ObjectId,
      ref: 'Match',
      required: true,
      index: true,
    },
    innings: {
      type: Schema.Types.ObjectId,
      ref: 'Innings',
      required: true,
      index: true,
    },
    action: {
      type: String,
      enum: Object.values(ScoringAuditAction),
      required: true,
      index: true,
    },
    actor: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    requestKey: {
      type: String,
      required: true,
      trim: true,
    },
    sequenceNumber: {
      type: Number,
      min: 1,
    },
    stateVersion: {
      type: Number,
      required: true,
      min: 0,
    },
    payload: {
      type: Schema.Types.Mixed,
      required: true,
    },
    result: {
      type: Schema.Types.Mixed,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

scoringAuditSchema.index({ match: 1, requestKey: 1 }, { unique: true });
scoringAuditSchema.index({ match: 1, createdAt: -1 });

export const ScoringAudit = mongoose.model<IScoringAudit, ScoringAuditModel>(
  'ScoringAudit',
  scoringAuditSchema
);

export default ScoringAudit;
